import { createHash, randomBytes } from 'node:crypto';

import type { Auth } from 'firebase-admin/auth';
import { FieldValue, Timestamp, type DocumentReference, type Firestore, type Transaction } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';

import { normalizeLkMobile } from '../phone.js';

/**
 * Shop setup and membership (PRD 6.1, US8, US9).
 *
 * Membership documents are written only here, through the Admin SDK; Security
 * Rules deny all client writes to members, invites and inviteTokens. Every
 * change writes an audit log entry and refreshes the caller's custom claims.
 *
 * Handlers take their dependencies so tests can run them against the
 * emulators without the callable wrapper.
 */

export interface Deps {
  db: Firestore;
  auth: Auth;
  now: () => Date;
  /** Base URL for invite links, e.g. https://shop-companion-prod.web.app */
  inviteBaseUrl: string;
}

export interface Caller {
  uid: string;
  /** `phone_number` from the verified ID token. */
  phone?: string;
}

export type InvitableRole = 'partner' | 'helper';
const INVITABLE_ROLES: readonly string[] = ['partner', 'helper'];

export const INVITE_TTL_MS = 7 * 24 * 3_600_000;
const MAX_NAME_LENGTH = 80;

const DEFAULT_SETTINGS = {
  reminderWindow: { startHour: 8, endHour: 20 },
  tone: 'gentle',
  approvalMode: true,
  closingTime: '20:00',
  partnerCanOverrideLimit: false,
} as const;

/** Invite tokens are stored only as hashes, so a leaked database export can't be replayed. */
export const hashToken = (token: string) => createHash('sha256').update(token).digest('hex');

const shopRef = (db: Firestore, shopId: string) => db.collection('shops').doc(shopId);

function requirePhone(caller: Caller): string {
  if (!caller.phone) throw new HttpsError('failed-precondition', 'Sign in with phone OTP first.');
  return caller.phone;
}

function audit(
  tx: Transaction,
  db: Firestore,
  shopId: string,
  entry: { actorUid: string; action: string; entity: string; entityId: string; before?: unknown; after?: unknown },
) {
  tx.create(shopRef(db, shopId).collection('auditLogs').doc(), {
    ...entry,
    before: entry.before ?? null,
    after: entry.after ?? null,
    at: FieldValue.serverTimestamp(),
  });
}

/** Throws unless the caller is an active member whose role grants `permission`. */
async function requirePermission(db: Firestore, shopId: string, uid: string, permission: string) {
  const member = await shopRef(db, shopId).collection('members').doc(uid).get();
  if (!member.exists || member.get('status') !== 'active') {
    throw new HttpsError('permission-denied', 'Not a member of this shop.');
  }
  const role = await db.collection('roles').doc(member.get('role') as string).get();
  const permissions = (role.get('permissions') as string[] | undefined) ?? [];
  if (!permissions.includes(permission)) throw new HttpsError('permission-denied', `Missing ${permission}.`);
}

/** Keeps the optional `shops: {shopId: role}` claim in step with membership. */
export async function setShopClaim(auth: Auth, uid: string, shopId: string, role: string | null) {
  const user = await auth.getUser(uid);
  const claims = { ...(user.customClaims ?? {}) };
  const shops = { ...((claims.shops as Record<string, string> | undefined) ?? {}) };
  if (role) shops[shopId] = role;
  else delete shops[shopId];
  claims.shops = shops;
  await auth.setCustomUserClaims(uid, claims);
}

/** Whether `uid` already belongs to an active shop (multi-shop is Release 3). */
async function activeShopOf(db: Firestore, tx: Transaction, uid: string): Promise<string | null> {
  const user = await tx.get(db.collection('users').doc(uid));
  const shopId = user.get('activeShopId') as string | undefined;
  if (!shopId) return null;
  const member = await tx.get(shopRef(db, shopId).collection('members').doc(uid));
  return member.exists && member.get('status') === 'active' ? shopId : null;
}

function userUpsert(tx: Transaction, ref: DocumentReference, exists: boolean, phone: string, shopId: string | null) {
  if (exists) {
    tx.update(ref, { activeShopId: shopId ?? FieldValue.delete() });
  } else {
    tx.create(ref, {
      phone,
      locale: 'ta',
      pinSet: false,
      createdAt: FieldValue.serverTimestamp(),
      ...(shopId ? { activeShopId: shopId } : {}),
    });
  }
}

export async function createShop(
  deps: Deps,
  caller: Caller,
  data: { name?: unknown; district?: unknown; type?: unknown },
): Promise<{ shopId: string }> {
  const phone = requirePhone(caller);
  const name = typeof data.name === 'string' ? data.name.trim() : '';
  if (!name || name.length > MAX_NAME_LENGTH) throw new HttpsError('invalid-argument', 'Shop name is required.');
  const district = typeof data.district === 'string' ? data.district.trim() : 'vavuniya';
  const type = typeof data.type === 'string' ? data.type.trim() : 'grocery';

  const { db } = deps;
  const shop = db.collection('shops').doc();
  await db.runTransaction(async (tx) => {
    const userRef = db.collection('users').doc(caller.uid);
    const existing = await activeShopOf(db, tx, caller.uid);
    if (existing) throw new HttpsError('already-exists', 'You already have a shop.');
    const user = await tx.get(userRef);

    tx.create(shop, {
      name,
      type,
      district,
      ownerUid: caller.uid,
      plan: 'free',
      billingCycle: null,
      lankaQrPayload: null,
      settings: DEFAULT_SETTINGS,
      createdAt: FieldValue.serverTimestamp(),
    });
    tx.create(shop.collection('members').doc(caller.uid), {
      role: 'owner',
      status: 'active',
      phone,
      invitedBy: null,
      joinedAt: FieldValue.serverTimestamp(),
    });
    userUpsert(tx, userRef, user.exists, phone, shop.id);
    audit(tx, db, shop.id, { actorUid: caller.uid, action: 'shop.create', entity: 'shop', entityId: shop.id, after: { name } });
  });
  await setShopClaim(deps.auth, caller.uid, shop.id, 'owner');
  return { shopId: shop.id };
}

export async function inviteMember(
  deps: Deps,
  caller: Caller,
  data: { shopId?: unknown; phone?: unknown; role?: unknown },
): Promise<{ inviteId: string; link: string; expiresAt: string }> {
  const { db } = deps;
  const shopId = typeof data.shopId === 'string' ? data.shopId : '';
  const phone = typeof data.phone === 'string' ? normalizeLkMobile(data.phone) : null;
  const role = typeof data.role === 'string' && INVITABLE_ROLES.includes(data.role) ? data.role : null;
  if (!shopId || !phone || !role) throw new HttpsError('invalid-argument', 'shopId, a Sri Lankan mobile number and role are required.');
  await requirePermission(db, shopId, caller.uid, 'member:invite');

  const token = randomBytes(24).toString('base64url');
  const expiresAt = Timestamp.fromMillis(deps.now().getTime() + INVITE_TTL_MS);
  const invite = shopRef(db, shopId).collection('invites').doc();

  await db.runTransaction(async (tx) => {
    // One live invite per phone: a new one replaces the old.
    const pending = await tx.get(
      shopRef(db, shopId).collection('invites').where('phone', '==', phone).where('status', '==', 'pending'),
    );
    for (const old of pending.docs) {
      tx.update(old.ref, { status: 'replaced' });
      tx.delete(db.collection('inviteTokens').doc(old.get('tokenHash') as string));
    }
    tx.create(invite, {
      phone,
      role,
      status: 'pending',
      invitedBy: caller.uid,
      tokenHash: hashToken(token),
      createdAt: FieldValue.serverTimestamp(),
      expiresAt,
    });
    tx.create(db.collection('inviteTokens').doc(hashToken(token)), { shopId, inviteId: invite.id, expiresAt });
    audit(tx, db, shopId, { actorUid: caller.uid, action: 'member.invite', entity: 'invite', entityId: invite.id, after: { role } });
  });

  return {
    inviteId: invite.id,
    link: `${deps.inviteBaseUrl.replace(/\/$/, '')}/invite/${token}`,
    expiresAt: expiresAt.toDate().toISOString(),
  };
}

export async function acceptInvite(
  deps: Deps,
  caller: Caller,
  data: { token?: unknown },
): Promise<{ shopId: string; role: InvitableRole }> {
  const phone = requirePhone(caller);
  if (typeof data.token !== 'string' || !data.token) throw new HttpsError('invalid-argument', 'token is required.');
  const { db } = deps;
  const tokenRef = db.collection('inviteTokens').doc(hashToken(data.token));

  const result = await db.runTransaction(async (tx) => {
    const tokenDoc = await tx.get(tokenRef);
    if (!tokenDoc.exists) throw new HttpsError('not-found', 'This invite is no longer valid.');
    const shopId = tokenDoc.get('shopId') as string;
    const inviteRef = shopRef(db, shopId).collection('invites').doc(tokenDoc.get('inviteId') as string);
    const invite = await tx.get(inviteRef);
    const userRef = db.collection('users').doc(caller.uid);
    const user = await tx.get(userRef);
    const memberRef = shopRef(db, shopId).collection('members').doc(caller.uid);
    const member = await tx.get(memberRef);
    const existingShop = await activeShopOf(db, tx, caller.uid);

    if (!invite.exists || invite.get('status') !== 'pending') {
      throw new HttpsError('not-found', 'This invite is no longer valid.');
    }
    if ((invite.get('expiresAt') as Timestamp).toMillis() <= deps.now().getTime()) {
      throw new HttpsError('deadline-exceeded', 'This invite has expired. Ask for a new one.');
    }
    // The invite is for one phone number; a forwarded link is useless.
    if (invite.get('phone') !== phone) {
      throw new HttpsError('permission-denied', 'This invite was sent to a different phone number.');
    }
    if (member.exists && member.get('status') === 'active') {
      throw new HttpsError('already-exists', 'You are already a member of this shop.');
    }
    if (existingShop) throw new HttpsError('already-exists', 'You already belong to a shop.');

    const role = invite.get('role') as InvitableRole;
    tx.set(memberRef, {
      role,
      status: 'active',
      phone,
      invitedBy: invite.get('invitedBy'),
      joinedAt: FieldValue.serverTimestamp(),
    });
    tx.update(inviteRef, { status: 'accepted', acceptedBy: caller.uid, acceptedAt: FieldValue.serverTimestamp() });
    tx.delete(tokenRef);
    userUpsert(tx, userRef, user.exists, phone, shopId);
    audit(tx, db, shopId, {
      actorUid: caller.uid,
      action: 'member.join',
      entity: 'member',
      entityId: caller.uid,
      after: { role },
    });
    return { shopId, role };
  });

  await setShopClaim(deps.auth, caller.uid, result.shopId, result.role);
  return result;
}

export async function removeMember(
  deps: Deps,
  caller: Caller,
  data: { shopId?: unknown; uid?: unknown },
): Promise<{ removed: true }> {
  const { db } = deps;
  const shopId = typeof data.shopId === 'string' ? data.shopId : '';
  const uid = typeof data.uid === 'string' ? data.uid : '';
  if (!shopId || !uid) throw new HttpsError('invalid-argument', 'shopId and uid are required.');
  await requirePermission(db, shopId, caller.uid, 'member:invite');

  await db.runTransaction(async (tx) => {
    const memberRef = shopRef(db, shopId).collection('members').doc(uid);
    const member = await tx.get(memberRef);
    const userRef = db.collection('users').doc(uid);
    const user = await tx.get(userRef);
    if (!member.exists || member.get('status') !== 'active') throw new HttpsError('not-found', 'Not an active member.');
    if (member.get('role') === 'owner') throw new HttpsError('failed-precondition', 'The owner cannot be removed.');

    tx.update(memberRef, { status: 'removed', removedBy: caller.uid, removedAt: FieldValue.serverTimestamp() });
    if (user.exists && user.get('activeShopId') === shopId) tx.update(userRef, { activeShopId: FieldValue.delete() });
    audit(tx, db, shopId, {
      actorUid: caller.uid,
      action: 'member.remove',
      entity: 'member',
      entityId: uid,
      before: { role: member.get('role') },
    });
  });
  await setShopClaim(deps.auth, uid, shopId, null);
  return { removed: true };
}

/** Scheduled: marks pending invites past their expiry and drops their tokens. */
export async function expireInvites(deps: Pick<Deps, 'db' | 'now'>): Promise<number> {
  const { db } = deps;
  const expired = await db
    .collection('inviteTokens')
    .where('expiresAt', '<=', Timestamp.fromDate(deps.now()))
    .limit(400)
    .get();
  if (expired.empty) return 0;
  const batch = db.batch();
  for (const token of expired.docs) {
    const invite = shopRef(db, token.get('shopId') as string).collection('invites').doc(token.get('inviteId') as string);
    batch.update(invite, { status: 'expired' });
    batch.delete(token.ref);
  }
  await batch.commit();
  return expired.size;
}
