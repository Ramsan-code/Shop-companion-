import type { Auth } from 'firebase-admin/auth';
import { FieldValue, type Firestore, Timestamp } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';

import { requirePermission, setShopClaim } from '../members/handlers.js';
import { dumpShop, workbook } from './export.js';

/**
 * PDPA rights and shop data ownership (PRD N1, C9, section 11 Privacy):
 * export everything, erase a customer, delete the shop, delete an account.
 * Each is a server call so it is checked, complete and audited.
 */

export interface FileStore {
  save(path: string, data: Buffer, contentType: string): Promise<void>;
  deletePrefix(prefix: string): Promise<void>;
}

export interface DataDeps {
  db: Firestore;
  auth: Auth;
  files: FileStore;
  now: () => Date;
}

interface Caller {
  uid: string;
}

const str = (v: unknown) => (typeof v === 'string' ? v : '');
const shopRef = (db: Firestore, shopId: string) => db.collection('shops').doc(shopId);

/** One export per 10 minutes per shop: it reads every document. */
export const EXPORT_COOLDOWN_MS = 10 * 60_000;

async function requireOwner(db: Firestore, shopId: string, uid: string) {
  await requirePermission(db, shopId, uid, 'shop:manage');
}

async function audit(db: Firestore, shopId: string, actorUid: string, action: string, entity: string, entityId: string) {
  await shopRef(db, shopId).collection('auditLogs').add({
    actorUid,
    action,
    entity,
    entityId,
    before: null,
    after: null,
    at: FieldValue.serverTimestamp(),
  });
}

/**
 * exportShop callable: writes `shop-companion.xlsx` and `shop-companion.json`
 * under shops/{shopId}/exports/{stamp}/, readable only by the owner
 * (storage.rules), and returns their paths.
 */
export async function exportShop(
  deps: DataDeps,
  caller: Caller,
  data: { shopId?: unknown },
): Promise<{ xlsxPath: string; jsonPath: string }> {
  const shopId = str(data.shopId);
  if (!shopId) throw new HttpsError('invalid-argument', 'shopId is required.');
  await requireOwner(deps.db, shopId, caller.uid);
  const now = deps.now();
  const shop = shopRef(deps.db, shopId);
  await deps.db.runTransaction(async (tx) => {
    const last = (await tx.get(shop)).get('lastExportAt') as Timestamp | undefined;
    if (last && now.getTime() - last.toMillis() < EXPORT_COOLDOWN_MS) {
      throw new HttpsError('resource-exhausted', 'An export was made a few minutes ago.');
    }
    tx.update(shop, { lastExportAt: Timestamp.fromDate(now) });
  });

  const dump = await dumpShop(deps.db, shopId, now);
  const stamp = now.toISOString().replace(/[:.]/g, '-');
  const base = `shops/${shopId}/exports/${stamp}/shop-companion`;
  await Promise.all([
    deps.files.save(
      `${base}.xlsx`,
      await workbook(dump),
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    ),
    deps.files.save(`${base}.json`, Buffer.from(JSON.stringify(dump, null, 1)), 'application/json'),
  ]);
  await audit(deps.db, shopId, caller.uid, 'shop.export', 'shop', shopId);
  return { xlsxPath: `${base}.xlsx`, jsonPath: `${base}.json` };
}

/**
 * eraseCustomer callable (PDPA erasure for a customer). Only once nothing
 * is owed either way: a running balance is the shop's legal claim. Removes
 * the customer, their score, follow-up state, reminders, statement links and
 * entry notes; the entries' amounts stay as the shop's anonymous books.
 */
export async function eraseCustomer(
  deps: DataDeps,
  caller: Caller,
  data: { shopId?: unknown; customerId?: unknown },
): Promise<{ erased: true }> {
  const shopId = str(data.shopId);
  const customerId = str(data.customerId);
  if (!shopId || !customerId) throw new HttpsError('invalid-argument', 'shopId and customerId are required.');
  await requireOwner(deps.db, shopId, caller.uid);
  const { db } = deps;
  const shop = shopRef(db, shopId);
  const customer = await shop.collection('customers').doc(customerId).get();
  if (!customer.exists) throw new HttpsError('not-found', 'No such customer.');
  if (((customer.get('balanceCents') as number | undefined) ?? 0) !== 0) {
    throw new HttpsError('failed-precondition', 'balance-not-zero');
  }
  const phone = customer.get('phone') as string | undefined;

  const [entries, reminders, statements] = await Promise.all([
    shop.collection('entries').where('customerId', '==', customerId).get(),
    shop.collection('reminders').where('customerId', '==', customerId).get(),
    db.collection('statements').where('shopId', '==', shopId).where('customerId', '==', customerId).get(),
  ]);
  const writer = db.bulkWriter();
  for (const e of entries.docs) {
    if (e.get('note') != null) void writer.update(e.ref, { note: FieldValue.delete() });
  }
  for (const d of [...reminders.docs, ...statements.docs]) void writer.delete(d.ref);
  void writer.delete(shop.collection('collectState').doc(customerId));
  if (phone) {
    void writer.set(
      db.collection('optOutIndex').doc(phone.replace(/\D/g, '')),
      { targets: FieldValue.arrayRemove(`${shopId}/${customerId}`) },
      { merge: true },
    );
  }
  await writer.close();
  await db.recursiveDelete(customer.ref);
  await audit(db, shopId, caller.uid, 'customer.erase', 'customer', customerId);
  return { erased: true };
}

/**
 * deleteShop callable: the owner types the shop's name to confirm. Deletes
 * every document and file of the shop, its statement links and invite
 * tokens, and takes the shop off every member. Daily backups age out in 30
 * days (dailyBackup), which the privacy notice says.
 */
export async function deleteShop(
  deps: DataDeps,
  caller: Caller,
  data: { shopId?: unknown; confirmName?: unknown },
): Promise<{ deleted: true }> {
  const shopId = str(data.shopId);
  if (!shopId) throw new HttpsError('invalid-argument', 'shopId is required.');
  const { db } = deps;
  const shop = shopRef(db, shopId);
  const shopDoc = await shop.get();
  if (!shopDoc.exists) throw new HttpsError('not-found', 'No such shop.');
  if (shopDoc.get('ownerUid') !== caller.uid) throw new HttpsError('permission-denied', 'Only the owner can delete the shop.');
  const name = String(shopDoc.get('name') ?? '').trim();
  if (str(data.confirmName).trim() !== name) throw new HttpsError('failed-precondition', 'name-mismatch');

  const [members, customers, statements, tokens, messages] = await Promise.all([
    shop.collection('members').get(),
    shop.collection('customers').select('phone').get(),
    db.collection('statements').where('shopId', '==', shopId).get(),
    db.collection('inviteTokens').where('shopId', '==', shopId).get(),
    db.collection('messageIndex').where('shopId', '==', shopId).get(),
  ]);
  const writer = db.bulkWriter();
  for (const d of [...statements.docs, ...tokens.docs, ...messages.docs]) void writer.delete(d.ref);
  for (const c of customers.docs) {
    const phone = c.get('phone') as string | undefined;
    if (!phone) continue;
    void writer.set(
      db.collection('optOutIndex').doc(phone.replace(/\D/g, '')),
      { targets: FieldValue.arrayRemove(`${shopId}/${c.id}`) },
      { merge: true },
    );
  }
  for (const m of members.docs) {
    const user = db.collection('users').doc(m.id);
    void writer.set(user, { activeShopId: FieldValue.delete() }, { merge: true });
  }
  await writer.close();
  await deps.files.deletePrefix(`shops/${shopId}/`);
  await db.recursiveDelete(shop);
  for (const m of members.docs) {
    await setShopClaim(deps.auth, m.id, shopId, null).catch(() => undefined);
  }
  // Kept without names or numbers, to answer "was this shop deleted?".
  await db.collection('deletedShops').doc(shopId).set({ deletedAt: FieldValue.serverTimestamp(), byUid: caller.uid });
  return { deleted: true };
}

/**
 * deleteMyAccount callable (Play Store account deletion, PDPA). A member
 * leaves their shop; an owner must delete the shop first, since a shop
 * can't be left without its owner.
 */
export async function deleteMyAccount(deps: DataDeps, caller: Caller): Promise<{ deleted: true }> {
  const { db } = deps;
  const userRef = db.collection('users').doc(caller.uid);
  const user = await userRef.get();
  const shopId = user.get('activeShopId') as string | undefined;
  if (shopId) {
    const shop = await shopRef(db, shopId).get();
    if (shop.exists && shop.get('ownerUid') === caller.uid) {
      throw new HttpsError('failed-precondition', 'delete-shop-first');
    }
    const member = shopRef(db, shopId).collection('members').doc(caller.uid);
    if ((await member.get()).exists) {
      await member.update({ status: 'removed', removedBy: caller.uid, removedAt: FieldValue.serverTimestamp(), phone: FieldValue.delete() });
      await audit(db, shopId, caller.uid, 'member.leave', 'member', caller.uid);
    }
  }
  await userRef.delete();
  await deps.auth.deleteUser(caller.uid);
  return { deleted: true };
}
