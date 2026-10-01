import { assertFails, assertSucceeds, type RulesTestEnvironment } from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  serverTimestamp,
  setDoc,
  updateDoc,
  type Firestore,
} from 'firebase/firestore';
import { afterAll, beforeAll, describe, it } from 'vitest';

import { ACTORS, type Actor, createEnv, db, OTHER_SHOP, seed, SHOP } from './setup';

let env: RulesTestEnvironment;

beforeAll(async () => {
  env = await createEnv('demo-shop-companion');
  await env.clearFirestore();
  await seed(env);
});

afterAll(async () => {
  await env?.cleanup();
});

const shopDoc = (fs: Firestore, ...path: string[]) => doc(fs, 'shops', SHOP, ...path);

let counter = 0;
const newEntry = (actor: Actor, type: string, extra: Record<string, unknown> = {}) => {
  const clientId = `e-${actor}-${type}-${++counter}`;
  return {
    clientId,
    data: {
      clientId,
      shopId: SHOP,
      customerId: 'c1',
      type,
      amountCents: 50000,
      createdBy: actor === 'signedOut' ? 'nobody' : ACTORS[actor],
      createdAt: serverTimestamp(),
      source: 'voice',
      ...extra,
    },
  };
};

const createEntry = (fs: Firestore, actor: Actor, type: string) => {
  const { clientId, data } = newEntry(actor, type);
  return setDoc(shopDoc(fs, 'entries', clientId), data);
};

/**
 * PRD section 6 permission table, as concrete Firestore operations.
 * Each row lists exactly who may do it; every other actor must be denied.
 */
type Row = { name: string; allowed: Actor[]; run: (fs: Firestore, actor: Actor) => Promise<unknown> };

const STAFF: Actor[] = ['owner', 'partner', 'helper'];
const MANAGERS: Actor[] = ['owner', 'partner'];
const ALL_ACTORS: Actor[] = ['owner', 'partner', 'helper', 'removedHelper', 'otherShopOwner', 'admin', 'signedOut'];

const matrix: Row[] = [
  { name: 'read the shop', allowed: STAFF, run: (fs) => getDoc(doc(fs, 'shops', SHOP)) },
  { name: 'record credit', allowed: STAFF, run: (fs, a) => createEntry(fs, a, 'credit') },
  { name: 'record payment', allowed: STAFF, run: (fs, a) => createEntry(fs, a, 'payment') },
  { name: 'record sale', allowed: STAFF, run: (fs, a) => createEntry(fs, a, 'sale') },
  { name: 'record expense', allowed: MANAGERS, run: (fs, a) => createEntry(fs, a, 'expense') },
  { name: 'record discount', allowed: MANAGERS, run: (fs, a) => createEntry(fs, a, 'discount') },
  { name: 'read entries', allowed: STAFF, run: (fs) => getDocs(collection(fs, 'shops', SHOP, 'entries')) },
  {
    name: 'edit own entry within 24 hours',
    allowed: STAFF,
    run: (fs, a) => {
      // Outsiders target the owner's entry; the rule must still refuse them.
      const id = STAFF.includes(a) ? `recent-${a}` : 'recent-owner';
      return updateDoc(shopDoc(fs, 'entries', id), { amountCents: 12000, updatedAt: serverTimestamp(), updatedBy: a === 'signedOut' ? 'x' : ACTORS[a] });
    },
  },
  {
    name: "edit someone else's entry",
    allowed: [],
    run: (fs, a) => {
      const id = a === 'owner' ? 'recent-helper' : 'recent-owner';
      return updateDoc(shopDoc(fs, 'entries', id), { amountCents: 12000, updatedAt: serverTimestamp(), updatedBy: a === 'signedOut' ? 'x' : ACTORS[a] });
    },
  },
  {
    name: 'edit own entry after 24 hours',
    allowed: [],
    run: (fs, a) => {
      const id = STAFF.includes(a) ? `old-${a}` : 'old-owner';
      return updateDoc(shopDoc(fs, 'entries', id), { amountCents: 12000, updatedAt: serverTimestamp(), updatedBy: a === 'signedOut' ? 'x' : ACTORS[a] });
    },
  },
  { name: 'delete an entry', allowed: [], run: (fs) => deleteDoc(shopDoc(fs, 'entries', 'recent-owner')) },
  { name: 'view customer balance', allowed: STAFF, run: (fs) => getDoc(shopDoc(fs, 'customers', 'c1')) },
  {
    name: 'add a customer',
    allowed: STAFF,
    run: (fs, a) =>
      setDoc(shopDoc(fs, 'customers', `new-${a}`), {
        name: 'Kumar',
        kinshipTerm: 'thambi',
        createdBy: a === 'signedOut' ? 'x' : ACTORS[a],
        createdAt: serverTimestamp(),
      }),
  },
  {
    name: 'write a customer balance',
    allowed: [],
    run: (fs) => updateDoc(shopDoc(fs, 'customers', 'c1'), { balanceCents: 0 }),
  },
  {
    name: 'raise a credit limit directly',
    allowed: [],
    run: (fs) => updateDoc(shopDoc(fs, 'customers', 'c1'), { creditLimitCents: 9_000_000 }),
  },
  {
    name: 'view Trust Score',
    allowed: MANAGERS,
    run: (fs) => getDoc(shopDoc(fs, 'customers', 'c1', 'private', 'score')),
  },
  {
    name: 'write Trust Score',
    allowed: [],
    run: (fs) => setDoc(shopDoc(fs, 'customers', 'c1', 'private', 'score'), { trustScore: 100 }),
  },
  {
    name: 'snooze a customer in Who To Ask',
    allowed: MANAGERS,
    run: (fs, a) =>
      setDoc(shopDoc(fs, 'collectState', 'c1'), {
        snoozedUntil: new Date(Date.now() + 3 * 86_400_000),
        lastAction: 'snooze',
        lastActionAt: serverTimestamp(),
        updatedBy: a === 'signedOut' ? 'x' : ACTORS[a],
      }),
  },
  { name: 'read Who To Ask follow-ups', allowed: MANAGERS, run: (fs) => getDoc(shopDoc(fs, 'collectState', 'c1')) },
  { name: 'view reminders', allowed: MANAGERS, run: (fs) => getDoc(shopDoc(fs, 'reminders', 'r1')) },
  { name: 'send a reminder directly', allowed: [], run: (fs) => setDoc(shopDoc(fs, 'reminders', 'r2'), { customerId: 'c1' }) },
  { name: 'view insights (Who To Ask)', allowed: MANAGERS, run: (fs) => getDoc(shopDoc(fs, 'insights', '2026-10-01')) },
  { name: 'view day closing with profit', allowed: MANAGERS, run: (fs) => getDoc(shopDoc(fs, 'dayClosings', '2026-10-01')) },
  {
    name: 'enter own cash count',
    allowed: STAFF,
    run: (fs, a) =>
      setDoc(shopDoc(fs, 'dayClosings', '2026-10-01', 'counts', a === 'signedOut' ? 'x' : ACTORS[a]), {
        countedCashCents: 123400,
        at: serverTimestamp(),
      }),
  },
  { name: 'view audit log', allowed: ['owner'], run: (fs) => getDoc(shopDoc(fs, 'auditLogs', 'a1')) },
  { name: 'write audit log', allowed: [], run: (fs) => setDoc(shopDoc(fs, 'auditLogs', 'a2'), { action: 'x' }) },
  { name: 'list members', allowed: ['owner'], run: (fs) => getDocs(collection(fs, 'shops', SHOP, 'members')) },
  { name: 'view invites', allowed: ['owner'], run: (fs) => getDoc(shopDoc(fs, 'invites', 'i1')) },
  {
    name: 'add a member directly',
    allowed: [],
    run: (fs) => setDoc(shopDoc(fs, 'members', 'uid-intruder'), { role: 'owner', status: 'active' }),
  },
  {
    name: 'promote yourself',
    allowed: [],
    run: (fs, a) =>
      updateDoc(shopDoc(fs, 'members', a === 'signedOut' ? 'x' : ACTORS[a]), { role: 'owner' }),
  },
  {
    name: 'change shop settings',
    allowed: ['owner'],
    run: (fs) => updateDoc(doc(fs, 'shops', SHOP), { 'settings.tone': 'normal' }),
  },
  { name: 'change plan', allowed: [], run: (fs) => updateDoc(doc(fs, 'shops', SHOP), { plan: 'pro' }) },
  { name: 'delete the shop', allowed: [], run: (fs) => deleteDoc(doc(fs, 'shops', SHOP)) },
  {
    name: 'add a stock item',
    allowed: MANAGERS,
    run: (fs, a) => setDoc(shopDoc(fs, 'items', `item-${a}`), { name: 'Sugar', unit: 'kg', qty: 5 }),
  },
  { name: 'update stock quantity', allowed: STAFF, run: (fs) => updateDoc(shopDoc(fs, 'items', 'rice'), { qty: 9 }) },
  {
    name: 'change stock price',
    allowed: MANAGERS,
    // A distinct value per actor, so an earlier allowed write can't turn a
    // later attempt into a no-op that passes for the wrong reason.
    run: (fs, a) => updateDoc(shopDoc(fs, 'items', 'rice'), { priceCents: 25000 + ALL_ACTORS.indexOf(a) }),
  },
];

describe('PRD 6 role × permission matrix', () => {
  for (const row of matrix) {
    for (const actor of ALL_ACTORS) {
      const allowed = row.allowed.includes(actor);
      it(`${actor} ${allowed ? 'can' : 'cannot'} ${row.name}`, async () => {
        const attempt = row.run(db(env, actor), actor);
        await (allowed ? assertSucceeds(attempt) : assertFails(attempt));
      });
    }
  }
});

describe('entry create validation (PRD 10.2)', () => {
  const tryCreate = (overrides: Record<string, unknown>, idOverride?: string) => {
    const fs = db(env, 'owner');
    const { clientId, data } = newEntry('owner', 'credit', overrides);
    return setDoc(shopDoc(fs, 'entries', idOverride ?? clientId), data);
  };

  it('accepts a valid entry', async () => {
    await assertSucceeds(tryCreate({}));
  });

  it('rejects a document ID that is not the clientId', async () => {
    await assertFails(tryCreate({}, 'something-else'));
  });

  it('rejects createdBy for another user', async () => {
    await assertFails(tryCreate({ createdBy: ACTORS.partner }));
  });

  it('rejects a mismatched shopId', async () => {
    await assertFails(tryCreate({ shopId: OTHER_SHOP }));
  });

  it.each([0, -500, 12.5, 2_000_000_000, '500'])('rejects amountCents = %s', async (amount) => {
    await assertFails(tryCreate({ amountCents: amount }));
  });

  it('rejects a client-supplied createdAt', async () => {
    await assertFails(tryCreate({ createdAt: new Date() }));
  });

  it('rejects an unknown source', async () => {
    await assertFails(tryCreate({ source: 'magic' }));
  });

  it('rejects server-only fields on create', async () => {
    await assertFails(tryCreate({ confirmedAt: serverTimestamp() }));
    await assertFails(tryCreate({ deletedAt: serverTimestamp() }));
  });

  it('rejects credit for a customer that does not exist', async () => {
    await assertFails(tryCreate({ customerId: 'ghost' }));
  });

  it('allows a sale without a customer', async () => {
    const fs = db(env, 'helper');
    const { clientId, data } = newEntry('helper', 'sale');
    delete (data as Record<string, unknown>).customerId;
    await assertSucceeds(setDoc(shopDoc(fs, 'entries', clientId), data));
  });

  it('accepts payment methods, back-dates and notes; rejects bad ones', async () => {
    await assertSucceeds(tryCreate({ type: 'payment', method: 'lankaqr', txnDate: new Date('2026-09-20'), note: 'harvest' }));
    await assertFails(tryCreate({ type: 'payment', method: 'cheque' }));
    await assertFails(tryCreate({ txnDate: '2026-09-20' }));
    await assertFails(tryCreate({ note: 'x'.repeat(201) }));
  });

  it('applied may only start as null', async () => {
    await assertSucceeds(tryCreate({ applied: null }));
    await assertFails(tryCreate({ applied: { customerId: 'c1', deltaCents: -999999 } }));
  });

  it('an edit must be stamped with the editor', async () => {
    const fs = db(env, 'partner');
    await assertFails(
      updateDoc(shopDoc(fs, 'entries', 'recent-partner'), { note: 'x', updatedAt: serverTimestamp(), updatedBy: ACTORS.owner }),
    );
  });

  it('a retried offline write with the same clientId is not a new entry', async () => {
    const fs = db(env, 'owner');
    const { clientId, data } = newEntry('owner', 'credit');
    await assertSucceeds(setDoc(shopDoc(fs, 'entries', clientId), data));
    // The second set becomes an update of a fixed doc: refused, so the
    // ledger keeps exactly one entry.
    await assertFails(setDoc(shopDoc(fs, 'entries', clientId), data));
  });

  it('an edit may not change the author or type', async () => {
    const fs = db(env, 'owner');
    await assertFails(
      updateDoc(shopDoc(fs, 'entries', 'recent-owner'), {
        type: 'payment',
        updatedAt: serverTimestamp(),
        updatedBy: ACTORS.owner,
      }),
    );
    await assertFails(
      updateDoc(shopDoc(fs, 'entries', 'recent-owner'), {
        createdBy: ACTORS.helper,
        updatedAt: serverTimestamp(),
        updatedBy: ACTORS.owner,
      }),
    );
  });
});

describe('customer validation', () => {
  const base = () => ({ name: 'Selvi', createdBy: ACTORS.helper, createdAt: serverTimestamp() });
  const create = (data: Record<string, unknown>) =>
    setDoc(shopDoc(db(env, 'helper'), 'customers', `v-${++counter}`), data);

  it('accepts the full profile', async () => {
    await assertSucceeds(
      create({ ...base(), phoneticKeys: ['slv'], phone: '+94771234567', kinshipTerm: 'akka', village: 'Nedunkerny', incomeType: 'farmer', payDay: 10, reminderConsent: true }),
    );
  });

  it.each([
    ['empty name', { name: '' }],
    ['unknown kinship', { kinshipTerm: 'boss' }],
    ['unknown income type', { incomeType: 'lottery' }],
    ['pay day 32', { payDay: 32 }],
    ['a balance', { balanceCents: 0 }],
    ['someone else as creator', { createdBy: ACTORS.owner }],
    ['an unknown field', { secret: 1 }],
    ['phonetic keys that are not a list', { phoneticKeys: 'rv' }],
    ['too many phonetic keys', { phoneticKeys: Array.from({ length: 11 }, (_, i) => `k${i}`) }],
  ])('rejects %s', async (_, extra) => {
    await assertFails(create({ ...base(), ...extra }));
  });

  it('updates profile fields but never server fields', async () => {
    const fs = db(env, 'helper');
    await assertSucceeds(updateDoc(shopDoc(fs, 'customers', 'c1'), { village: 'Cheddikulam', updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(shopDoc(fs, 'customers', 'c1'), { lastActivityAt: serverTimestamp() }));
  });
});

describe('other paths', () => {
  it('statements and webhook indexes are function-only (the page uses statementApi)', async () => {
    for (const actor of ['signedOut', 'owner'] as const) {
      const fs = db(env, actor);
      await assertFails(getDoc(doc(fs, 'statements', 'valid-token')));
      await assertFails(getDocs(collection(fs, 'statements')));
      await assertFails(getDoc(doc(fs, 'messageIndex', 'wamid.1')));
      await assertFails(getDoc(doc(fs, 'optOutIndex', '94771234567')));
    }
  });

  it('customers: reminder tone and language; opt-out and dispute fields are server-only', async () => {
    const fs = db(env, 'owner');
    const c1 = shopDoc(fs, 'customers', 'c1');
    await assertSucceeds(updateDoc(c1, { reminderTone: 'firm', reminderLang: 'en', reminderConsent: true, updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(c1, { reminderTone: 'angry' }));
    await assertFails(updateDoc(c1, { optedOutAt: null }));
    await assertFails(updateDoc(c1, { disputeOpenAt: null }));
    await assertFails(updateDoc(c1, { lastReminderAt: new Date() }));
  });

  it('shop LankaQR payload: owner sets a string up to 512 characters', async () => {
    const fs = db(env, 'owner');
    await assertSucceeds(updateDoc(doc(fs, 'shops', SHOP), { lankaQrPayload: '000201010211' }));
    await assertFails(updateDoc(doc(fs, 'shops', SHOP), { lankaQrPayload: 'x'.repeat(513) }));
    await assertFails(updateDoc(doc(db(env, 'partner'), 'shops', SHOP), { lankaQrPayload: '000201' }));
  });

  it('calendars and roles need sign-in and are read-only', async () => {
    await assertFails(getDoc(doc(db(env, 'signedOut'), 'calendars', 'vavuniya')));
    await assertSucceeds(getDoc(doc(db(env, 'helper'), 'calendars', 'vavuniya')));
    await assertSucceeds(getDoc(doc(db(env, 'helper'), 'roles', 'owner')));
    await assertFails(setDoc(doc(db(env, 'owner'), 'roles', 'helper'), { permissions: ['profit:read'] }));
  });

  it('users can write only their own profile, never a PIN or their shop', async () => {
    const phone = '+94770000002';
    const fs = env.authenticatedContext(ACTORS.helper, { phone_number: phone }).firestore();
    const me = doc(fs, 'users', ACTORS.helper);
    await assertFails(setDoc(me, { phone: '+94770000099', locale: 'ta' }));
    await assertFails(setDoc(me, { phone, pinHash: 'x' }));
    await assertFails(setDoc(me, { phone, activeShopId: OTHER_SHOP }));
    await assertSucceeds(setDoc(me, { phone, locale: 'ta', pinSet: false }));
    await assertSucceeds(updateDoc(me, { locale: 'en', pinSet: true }));
    await assertFails(updateDoc(me, { phone: '+94770000099' }));
    await assertFails(getDoc(doc(fs, 'users', ACTORS.owner)));
  });

  it('server-set activeShopId does not block profile edits, and cannot be changed', async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      setDoc(doc(ctx.firestore(), 'users', ACTORS.partner), { phone: '+94770000003', activeShopId: SHOP, pinSet: false }),
    );
    const me = doc(db(env, 'partner'), 'users', ACTORS.partner);
    await assertSucceeds(updateDoc(me, { pinSet: true }));
    await assertFails(updateDoc(me, { activeShopId: OTHER_SHOP }));
  });

  it('collect state: no long snoozes, known actions, server time', async () => {
    const fs = db(env, 'owner');
    const ref = shopDoc(fs, 'collectState', 'c2');
    const base = { updatedBy: ACTORS.owner, lastActionAt: serverTimestamp() };
    await assertFails(setDoc(ref, { ...base, lastAction: 'shout' }));
    await assertFails(setDoc(ref, { ...base, snoozedUntil: new Date(Date.now() + 60 * 86_400_000) }));
    await assertFails(setDoc(ref, { lastAction: 'call', lastActionAt: new Date(), updatedBy: ACTORS.owner }));
    await assertSucceeds(setDoc(ref, { ...base, lastAction: 'whatsapp' }));
  });

  it('at most 10 push tokens per user', async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      setDoc(doc(ctx.firestore(), 'users', ACTORS.owner), { phone: '+94770000001', pinSet: true }),
    );
    const me = doc(db(env, 'owner'), 'users', ACTORS.owner);
    await assertSucceeds(updateDoc(me, { fcmTokens: ['a', 'b'] }));
    await assertFails(updateDoc(me, { fcmTokens: Array.from({ length: 11 }, (_, i) => `t${i}`) }));
  });

  it('invite tokens are closed to every client', async () => {
    await assertFails(getDoc(doc(db(env, 'owner'), 'inviteTokens', 'abc')));
    await assertFails(setDoc(doc(db(env, 'owner'), 'inviteTokens', 'abc'), { shopId: SHOP }));
  });

  it('a member can read their own membership', async () => {
    await assertSucceeds(getDoc(shopDoc(db(env, 'helper'), 'members', ACTORS.helper)));
    await assertFails(getDoc(shopDoc(db(env, 'helper'), 'members', ACTORS.partner)));
  });

  it("nobody reads another shop's data", async () => {
    const fs = db(env, 'otherShopOwner');
    await assertSucceeds(getDoc(doc(fs, 'shops', OTHER_SHOP)));
    await assertFails(getDoc(shopDoc(fs, 'customers', 'c1')));
  });
});
