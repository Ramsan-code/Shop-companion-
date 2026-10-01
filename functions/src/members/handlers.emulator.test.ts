import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

import { getApps, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { beforeAll, beforeEach, describe, expect, it } from 'vitest';

import {
  acceptInvite,
  createShop,
  type Deps,
  expireInvites,
  hashToken,
  INVITE_TTL_MS,
  inviteMember,
  removeMember,
} from './handlers.js';

const PROJECT = 'demo-shop-companion';
if (getApps().length === 0) initializeApp({ projectId: PROJECT });
const db = getFirestore();
const auth = getAuth();

let clock = new Date('2026-10-01T09:00:00+05:30');
const deps: Deps = { db, auth, now: () => clock, inviteBaseUrl: 'https://sc.test/' };

const OWNER = { uid: 'owner1', phone: '+94771000001' };
const WIFE = { uid: 'wife1', phone: '+94771000002' };
const HELPER = { uid: 'helper1', phone: '+94771000003' };
const STRANGER = { uid: 'stranger1', phone: '+94771000009' };

async function resetEmulators() {
  const host = process.env.FIRESTORE_EMULATOR_HOST!;
  await fetch(`http://${host}/emulator/v1/projects/${PROJECT}/databases/(default)/documents`, { method: 'DELETE' });
  const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST!;
  await fetch(`http://${authHost}/emulator/v1/projects/${PROJECT}/accounts`, { method: 'DELETE' });
  for (const u of [OWNER, WIFE, HELPER, STRANGER]) await auth.createUser({ uid: u.uid, phoneNumber: u.phone });
  const roles = JSON.parse(readFileSync(resolve(import.meta.dirname, '../../../seed/roles.json'), 'utf8'));
  for (const role of ['owner', 'partner', 'helper', 'admin']) {
    await db.collection('roles').doc(role).set({ permissions: roles[role].permissions });
  }
}

const tokenOf = (link: string) => link.split('/invite/')[1]!;
const member = (shopId: string, uid: string) => db.doc(`shops/${shopId}/members/${uid}`).get();
const claimsOf = async (uid: string) => (await auth.getUser(uid)).customClaims;
const auditActions = async (shopId: string) =>
  (await db.collection(`shops/${shopId}/auditLogs`).get()).docs.map((d) => d.get('action') as string).sort();

beforeAll(() => {
  if (!process.env.FIRESTORE_EMULATOR_HOST) throw new Error('Run with `npm run test:emulator`.');
});

beforeEach(async () => {
  clock = new Date('2026-10-01T09:00:00+05:30');
  await resetEmulators();
});

describe('createShop (setup flow, PRD 7.1-1)', () => {
  it('creates the shop, owner membership, user profile, audit log and claim', async () => {
    const { shopId } = await createShop(deps, OWNER, { name: ' Selvarasa Stores ' });

    const shop = await db.doc(`shops/${shopId}`).get();
    expect(shop.get('name')).toBe('Selvarasa Stores');
    expect(shop.get('ownerUid')).toBe(OWNER.uid);
    expect(shop.get('plan')).toBe('free');
    expect(shop.get('settings.tone')).toBe('gentle');
    expect((await member(shopId, OWNER.uid)).data()).toMatchObject({ role: 'owner', status: 'active' });
    expect((await db.doc(`users/${OWNER.uid}`).get()).data()).toMatchObject({
      phone: OWNER.phone,
      activeShopId: shopId,
      pinSet: false,
    });
    expect(await auditActions(shopId)).toEqual(['shop.create']);
    expect(await claimsOf(OWNER.uid)).toEqual({ shops: { [shopId]: 'owner' } });
  });

  it('requires a phone-verified caller and a name', async () => {
    await expect(createShop(deps, { uid: OWNER.uid }, { name: 'X' })).rejects.toMatchObject({ code: 'failed-precondition' });
    await expect(createShop(deps, OWNER, { name: '  ' })).rejects.toMatchObject({ code: 'invalid-argument' });
    await expect(createShop(deps, OWNER, { name: 'x'.repeat(81) })).rejects.toMatchObject({ code: 'invalid-argument' });
  });

  it('refuses a second shop (multi-shop is Release 3)', async () => {
    await createShop(deps, OWNER, { name: 'One' });
    await expect(createShop(deps, OWNER, { name: 'Two' })).rejects.toMatchObject({ code: 'already-exists' });
  });
});

describe('invite and accept (US9)', () => {
  let shopId: string;
  beforeEach(async () => {
    shopId = (await createShop(deps, OWNER, { name: 'Selvarasa Stores' })).shopId;
  });

  it('the wife joins as Partner from her own phone', async () => {
    const invite = await inviteMember(deps, OWNER, { shopId, phone: '077 100 0002', role: 'partner' });
    expect(invite.link).toMatch(/^https:\/\/sc\.test\/invite\/[\w-]{32}$/);
    expect(new Date(invite.expiresAt).getTime() - clock.getTime()).toBe(INVITE_TTL_MS);

    // Only the hash is stored.
    const token = tokenOf(invite.link);
    const stored = await db.doc(`shops/${shopId}/invites/${invite.inviteId}`).get();
    expect(stored.get('tokenHash')).toBe(hashToken(token));
    expect(JSON.stringify(stored.data())).not.toContain(token);

    const result = await acceptInvite(deps, WIFE, { token });
    expect(result).toEqual({ shopId, role: 'partner' });
    expect((await member(shopId, WIFE.uid)).data()).toMatchObject({ role: 'partner', status: 'active', invitedBy: OWNER.uid });
    expect((await db.doc(`users/${WIFE.uid}`).get()).get('activeShopId')).toBe(shopId);
    expect(await claimsOf(WIFE.uid)).toEqual({ shops: { [shopId]: 'partner' } });
    expect(await auditActions(shopId)).toEqual(['member.invite', 'member.join', 'shop.create']);
    // The token is single use.
    await expect(acceptInvite(deps, WIFE, { token })).rejects.toMatchObject({ code: 'not-found' });
  });

  it('a forwarded link does not work for another phone', async () => {
    const { link } = await inviteMember(deps, OWNER, { shopId, phone: WIFE.phone, role: 'partner' });
    await expect(acceptInvite(deps, STRANGER, { token: tokenOf(link) })).rejects.toMatchObject({ code: 'permission-denied' });
    expect((await member(shopId, STRANGER.uid)).exists).toBe(false);
  });

  it('expired invites are refused, then cleaned up by the scheduler', async () => {
    const { link, inviteId } = await inviteMember(deps, OWNER, { shopId, phone: HELPER.phone, role: 'helper' });
    clock = new Date(clock.getTime() + INVITE_TTL_MS + 1);
    await expect(acceptInvite(deps, HELPER, { token: tokenOf(link) })).rejects.toMatchObject({ code: 'deadline-exceeded' });
    expect(await expireInvites(deps)).toBe(1);
    expect((await db.doc(`shops/${shopId}/invites/${inviteId}`).get()).get('status')).toBe('expired');
    await expect(acceptInvite(deps, HELPER, { token: tokenOf(link) })).rejects.toMatchObject({ code: 'not-found' });
  });

  it('a new invite to the same phone replaces the old one', async () => {
    const first = await inviteMember(deps, OWNER, { shopId, phone: HELPER.phone, role: 'helper' });
    const second = await inviteMember(deps, OWNER, { shopId, phone: HELPER.phone, role: 'partner' });
    await expect(acceptInvite(deps, HELPER, { token: tokenOf(first.link) })).rejects.toMatchObject({ code: 'not-found' });
    expect(await acceptInvite(deps, HELPER, { token: tokenOf(second.link) })).toMatchObject({ role: 'partner' });
  });

  it('only roles with member:invite can invite, and never as owner', async () => {
    const { link } = await inviteMember(deps, OWNER, { shopId, phone: WIFE.phone, role: 'partner' });
    await acceptInvite(deps, WIFE, { token: tokenOf(link) });
    await expect(inviteMember(deps, WIFE, { shopId, phone: HELPER.phone, role: 'helper' })).rejects.toMatchObject({
      code: 'permission-denied',
    });
    await expect(inviteMember(deps, STRANGER, { shopId, phone: HELPER.phone, role: 'helper' })).rejects.toMatchObject({
      code: 'permission-denied',
    });
    await expect(inviteMember(deps, OWNER, { shopId, phone: HELPER.phone, role: 'owner' })).rejects.toMatchObject({
      code: 'invalid-argument',
    });
    await expect(inviteMember(deps, OWNER, { shopId, phone: '0241234567', role: 'helper' })).rejects.toMatchObject({
      code: 'invalid-argument',
    });
  });

  it('someone who already has a shop cannot join another', async () => {
    const other = (await createShop(deps, STRANGER, { name: 'Other' })).shopId;
    const { link } = await inviteMember(deps, OWNER, { shopId, phone: STRANGER.phone, role: 'helper' });
    await expect(acceptInvite(deps, STRANGER, { token: tokenOf(link) })).rejects.toMatchObject({ code: 'already-exists' });
    expect((await db.doc(`users/${STRANGER.uid}`).get()).get('activeShopId')).toBe(other);
  });
});

describe('removeMember', () => {
  let shopId: string;
  beforeEach(async () => {
    shopId = (await createShop(deps, OWNER, { name: 'Shop' })).shopId;
    const { link } = await inviteMember(deps, OWNER, { shopId, phone: HELPER.phone, role: 'helper' });
    await acceptInvite(deps, HELPER, { token: tokenOf(link) });
  });

  it('removes a helper: status, user profile, claim and audit', async () => {
    await removeMember(deps, OWNER, { shopId, uid: HELPER.uid });
    expect((await member(shopId, HELPER.uid)).get('status')).toBe('removed');
    expect((await db.doc(`users/${HELPER.uid}`).get()).get('activeShopId')).toBeUndefined();
    expect(await claimsOf(HELPER.uid)).toEqual({ shops: {} });
    expect(await auditActions(shopId)).toContain('member.remove');
  });

  it('a removed member can be invited back', async () => {
    await removeMember(deps, OWNER, { shopId, uid: HELPER.uid });
    const { link } = await inviteMember(deps, OWNER, { shopId, phone: HELPER.phone, role: 'helper' });
    await acceptInvite(deps, HELPER, { token: tokenOf(link) });
    expect((await member(shopId, HELPER.uid)).get('status')).toBe('active');
  });

  it('the owner cannot be removed and helpers cannot remove anyone', async () => {
    await expect(removeMember(deps, OWNER, { shopId, uid: OWNER.uid })).rejects.toMatchObject({ code: 'failed-precondition' });
    await expect(removeMember(deps, HELPER, { shopId, uid: OWNER.uid })).rejects.toMatchObject({ code: 'permission-denied' });
  });
});

describe('new phone (US8)', () => {
  it('everything needed to restore lives on the server', async () => {
    const { shopId } = await createShop(deps, OWNER, { name: 'Shop' });
    // A fresh install signs in with the same phone (same uid) and reads these.
    const user = await db.doc(`users/${OWNER.uid}`).get();
    expect(user.get('activeShopId')).toBe(shopId);
    expect((await member(shopId, OWNER.uid)).get('role')).toBe('owner');
  });
});
