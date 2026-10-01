import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import {
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, setDoc, Timestamp } from 'firebase/firestore';

const root = resolve(import.meta.dirname, '..');

export const SHOP = 'shop1';
export const OTHER_SHOP = 'shop2';

/** Every actor in the PRD 6 matrix, plus outsiders. */
export const ACTORS = {
  owner: 'uid-owner',
  partner: 'uid-partner',
  helper: 'uid-helper',
  removedHelper: 'uid-removed',
  otherShopOwner: 'uid-other-owner',
  admin: 'uid-admin',
} as const;
export type Actor = keyof typeof ACTORS | 'signedOut';

export async function createEnv(projectId: string): Promise<RulesTestEnvironment> {
  return initializeTestEnvironment({
    projectId,
    firestore: { rules: readFileSync(resolve(root, 'firestore.rules'), 'utf8') },
    storage: { rules: readFileSync(resolve(root, 'storage.rules'), 'utf8') },
  });
}

export function db(env: RulesTestEnvironment, actor: Actor) {
  if (actor === 'signedOut') return env.unauthenticatedContext().firestore();
  // Platform Admin is identified by a custom claim but has no membership.
  const claims = actor === 'admin' ? { admin: true } : {};
  return env.authenticatedContext(ACTORS[actor], claims).firestore();
}

export function storage(env: RulesTestEnvironment, actor: Actor) {
  if (actor === 'signedOut') return env.unauthenticatedContext().storage();
  return env.authenticatedContext(ACTORS[actor]).storage();
}

const hoursAgo = (h: number) => Timestamp.fromMillis(Date.now() - h * 3_600_000);

/** Seeds roles, two shops, members and one document per protected path. */
export async function seed(env: RulesTestEnvironment) {
  const roles = JSON.parse(readFileSync(resolve(root, 'seed/roles.json'), 'utf8'));
  await env.withSecurityRulesDisabled(async (ctx) => {
    const fs = ctx.firestore();
    for (const role of ['owner', 'partner', 'helper', 'admin']) {
      await setDoc(doc(fs, 'roles', role), { permissions: roles[role].permissions });
    }
    const shop = (id: string, owner: string) =>
      setDoc(doc(fs, 'shops', id), {
        name: id,
        ownerUid: owner,
        plan: 'free',
        settings: { tone: 'gentle' },
      });
    await shop(SHOP, ACTORS.owner);
    await shop(OTHER_SHOP, ACTORS.otherShopOwner);

    const member = (shopId: string, uid: string, role: string, status = 'active') =>
      setDoc(doc(fs, 'shops', shopId, 'members', uid), { role, status });
    await member(SHOP, ACTORS.owner, 'owner');
    await member(SHOP, ACTORS.partner, 'partner');
    await member(SHOP, ACTORS.helper, 'helper');
    await member(SHOP, ACTORS.removedHelper, 'helper', 'removed');
    await member(OTHER_SHOP, ACTORS.otherShopOwner, 'owner');

    const s = (...path: string[]) => doc(fs, 'shops', SHOP, ...path);
    await setDoc(s('customers', 'c1'), { name: 'Ravi', balanceCents: 50000, creditLimitCents: 200000 });
    await setDoc(s('customers', 'c1', 'private', 'score'), { trustScore: 72, trustBand: 'good', reasons: [] });
    await setDoc(s('invites', 'i1'), { phone: '+94770000001', role: 'partner', status: 'pending' });
    await setDoc(s('reminders', 'r1'), { customerId: 'c1', status: 'sent' });
    await setDoc(s('items', 'rice'), { name: 'Rice', unit: 'kg', qty: 10, costCents: 20000, priceCents: 24000 });
    await setDoc(s('dayClosings', '2026-10-01'), { salesCents: 1, profitEstimateCents: 1 });
    await setDoc(s('insights', '2026-10-01'), { whoToAsk: [] });
    await setDoc(s('auditLogs', 'a1'), { action: 'entry.create' });

    // One recent entry per role (editable by its author) and one old one.
    for (const role of ['owner', 'partner', 'helper'] as const) {
      await setDoc(s('entries', `recent-${role}`), {
        clientId: `recent-${role}`,
        shopId: SHOP,
        customerId: 'c1',
        type: 'credit',
        amountCents: 10000,
        createdBy: ACTORS[role],
        createdAt: hoursAgo(1),
        source: 'text',
      });
      await setDoc(s('entries', `old-${role}`), {
        clientId: `old-${role}`,
        shopId: SHOP,
        customerId: 'c1',
        type: 'credit',
        amountCents: 10000,
        createdBy: ACTORS[role],
        createdAt: hoursAgo(25),
        source: 'text',
      });
    }

    await setDoc(doc(fs, 'statements', 'valid-token'), {
      shopId: SHOP,
      customerId: 'c1',
      expiresAt: Timestamp.fromMillis(Date.now() + 86_400_000),
    });
    await setDoc(doc(fs, 'statements', 'expired-token'), {
      shopId: SHOP,
      customerId: 'c1',
      expiresAt: hoursAgo(1),
    });
    await setDoc(doc(fs, 'calendars', 'vavuniya'), { events: [] });
  });
}
