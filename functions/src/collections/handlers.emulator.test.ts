import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { beforeAll, beforeEach, describe, expect, it } from 'vitest';

import { applyEntry } from '../ledger/handlers.js';
import { buildWhoToAskForShop, colomboDate, nightlyShop, overrideLimit, type Pusher } from './handlers.js';
import { DAY_MS } from './scoring.js';

const PROJECT = 'demo-shop-companion';
if (getApps().length === 0) initializeApp({ projectId: PROJECT });
const db = getFirestore();

const SHOP = 'shop1';
const shop = db.collection('shops').doc(SHOP);
const NOW = Date.UTC(2026, 9, 1, 0, 30); // 06:00 Colombo
const OWNER = { uid: 'owner1' };
const PARTNER = { uid: 'partner1' };
const HELPER = { uid: 'helper1' };

class FakePush implements Pusher {
  sent: { tokens: string[]; title: string; body: string }[] = [];
  dead: string[] = [];
  async send(tokens: string[], m: { title: string; body: string }) {
    this.sent.push({ tokens, title: m.title, body: m.body });
    return tokens.filter((t) => this.dead.includes(t));
  }
}

let n = 0;
async function entry(customerId: string, type: string, rupees: number, daysAgo: number) {
  const id = `e${++n}`;
  await shop.collection('entries').doc(id).set({
    clientId: id, shopId: SHOP, customerId, type, amountCents: rupees * 100, createdBy: HELPER.uid,
    createdAt: Timestamp.fromMillis(NOW - daysAgo * DAY_MS), txnDate: Timestamp.fromMillis(NOW - daysAgo * DAY_MS),
    source: 'text', applied: null,
  });
  await applyEntry(db, SHOP, id);
  return id;
}

const score = async (id: string) => (await shop.collection('customers').doc(id).collection('private').doc('score').get()).data();

beforeAll(() => {
  if (!process.env.FIRESTORE_EMULATOR_HOST) throw new Error('Run with `npm run test:emulator`.');
});

beforeEach(async () => {
  const host = process.env.FIRESTORE_EMULATOR_HOST!;
  await fetch(`http://${host}/emulator/v1/projects/${PROJECT}/databases/(default)/documents`, { method: 'DELETE' });
  const roles = JSON.parse(readFileSync(resolve(import.meta.dirname, '../../../seed/roles.json'), 'utf8'));
  for (const role of ['owner', 'partner', 'helper']) await db.doc(`roles/${role}`).set({ permissions: roles[role].permissions });
  await shop.set({ name: 'Shop', ownerUid: OWNER.uid, settings: { partnerCanOverrideLimit: false } });
  for (const [u, role] of [[OWNER, 'owner'], [PARTNER, 'partner'], [HELPER, 'helper']] as const) {
    await shop.collection('members').doc(u.uid).set({ role, status: 'active' });
  }
  await db.doc(`users/${OWNER.uid}`).set({ locale: 'ta', fcmTokens: ['owner-phone', 'old-phone'] });
  await db.doc(`users/${PARTNER.uid}`).set({ locale: 'en', fcmTokens: ['partner-phone'] });
  await db.doc(`users/${HELPER.uid}`).set({ locale: 'ta', fcmTokens: ['helper-phone'] });
  for (const [id, name, payDay] of [['ravi', 'Ravi', null], ['selvi', 'Selvi', 2], ['kumar', 'Kumar', null]] as const) {
    await shop.collection('customers').doc(id).set({ name, ...(payDay ? { payDay } : {}) });
  }
});

describe('nightlyShop (recalcTrustScores)', () => {
  it('writes reproducible scores, reasons and limits; keeps an owner override', async () => {
    await entry('ravi', 'credit', 1500, 95);
    await entry('ravi', 'credit', 1500, 70);
    await entry('selvi', 'credit', 1000, 300);
    await entry('selvi', 'payment', 1000, 280);

    const first = await nightlyShop(db, SHOP, NOW);
    expect(first.scored).toBe(3);
    expect(await score('ravi')).toMatchObject({
      trustBand: 'risky',
      reasons: [{ code: 'overdue', value: 95 }, { code: 'noRecentPayment' }, { code: 'paysLittle', value: 0 }],
      creditLimitCents: 50000,
      overrideLimitCents: null,
    });
    expect(await score('selvi')).toMatchObject({ trustBand: 'excellent' });

    await overrideLimit(db, OWNER, { shopId: SHOP, customerId: 'ravi', limitCents: 300000 });
    const second = await nightlyShop(db, SHOP, NOW);
    expect(second.scored).toBe(0); // nothing changed: no writes
    expect(await score('ravi')).toMatchObject({ computedLimitCents: 50000, overrideLimitCents: 300000, creditLimitCents: 300000 });
  });
});

describe('buildWhoToAskForShop (06:00)', () => {
  it('ranks, saves today\'s insight and pushes only to owner and partner, in their language', async () => {
    await entry('ravi', 'credit', 1500, 95);
    await entry('selvi', 'credit', 800, 5);
    await entry('kumar', 'credit', 200, 3);
    await shop.collection('collectState').doc('kumar').set({ snoozedUntil: Timestamp.fromMillis(NOW + DAY_MS) });
    await nightlyShop(db, SHOP, NOW);

    const push = new FakePush();
    push.dead = ['old-phone'];
    const insight = await buildWhoToAskForShop({ db, push }, SHOP, NOW);

    expect(insight.date).toBe('2026-10-01');
    expect(insight.whoToAsk.map((x) => x.customerId)).toEqual(['ravi', 'selvi']);
    expect(insight.whoToAsk[1]!.reason).toEqual({ code: 'payDay', value: 2 });
    expect((await shop.collection('insights').doc(colomboDate(NOW)).get()).get('count')).toBe(2);

    expect(push.sent.map((p) => p.tokens).flat().sort()).toEqual(['old-phone', 'owner-phone', 'partner-phone']);
    expect(push.sent.find((p) => p.tokens.includes('owner-phone'))).toMatchObject({
      title: 'இன்று கேட்க வேண்டியவர்கள்',
      body: '2 பேர் · மொத்தம் Rs. 2,300',
    });
    expect(push.sent.find((p) => p.tokens.includes('partner-phone'))!.body).toBe('2 people · Rs. 2,300 due');
    // No names or per-customer amounts in a notification.
    expect(JSON.stringify(push.sent)).not.toMatch(/Ravi|Selvi/);
    expect((await db.doc(`users/${OWNER.uid}`).get()).get('fcmTokens')).toEqual(['owner-phone']);
  });

  it('no push when nobody needs asking', async () => {
    const push = new FakePush();
    const insight = await buildWhoToAskForShop({ db, push }, SHOP, NOW);
    expect(insight.count).toBe(0);
    expect(push.sent).toHaveLength(0);
  });
});

describe('overrideLimit', () => {
  it('owner yes; partner only when the shop allows; helper never; null clears', async () => {
    await entry('ravi', 'credit', 500, 10);
    await nightlyShop(db, SHOP, NOW);
    await expect(overrideLimit(db, PARTNER, { shopId: SHOP, customerId: 'ravi', limitCents: 1 })).rejects.toMatchObject({
      code: 'permission-denied',
    });
    await shop.update({ 'settings.partnerCanOverrideLimit': true });
    expect(await overrideLimit(db, PARTNER, { shopId: SHOP, customerId: 'ravi', limitCents: 900000 })).toEqual({
      creditLimitCents: 900000,
    });
    await expect(overrideLimit(db, HELPER, { shopId: SHOP, customerId: 'ravi', limitCents: 1 })).rejects.toMatchObject({
      code: 'permission-denied',
    });
    const cleared = await overrideLimit(db, OWNER, { shopId: SHOP, customerId: 'ravi', limitCents: null });
    expect(cleared.creditLimitCents).toBe((await score('ravi'))!.computedLimitCents);
    const audits = await shop.collection('auditLogs').where('action', '==', 'limit.override').get();
    expect(audits.size).toBe(2);
    await expect(overrideLimit(db, OWNER, { shopId: SHOP, customerId: 'ravi', limitCents: -5 })).rejects.toMatchObject({
      code: 'invalid-argument',
    });
  });
});

describe('Safe Credit Limit check on new credit', () => {
  it('flags and audits a credit that takes the customer over the limit', async () => {
    await entry('ravi', 'credit', 500, 10);
    await nightlyShop(db, SHOP, NOW);
    await overrideLimit(db, OWNER, { shopId: SHOP, customerId: 'ravi', limitCents: 100000 });

    const ok = await entry('ravi', 'credit', 400, 0); // 900 ≤ 1000
    const over = await entry('ravi', 'credit', 300, 0); // 1200 > 1000
    expect((await shop.collection('entries').doc(ok).get()).get('overLimit')).toBeUndefined();
    expect((await shop.collection('entries').doc(over).get()).get('overLimit')).toBe(true);
    const audit = (await shop.collection('auditLogs').doc(`limit-exceeded-${over}`).get()).data();
    expect(audit).toMatchObject({ actorUid: HELPER.uid, before: { limitCents: 100000 }, after: { balanceCents: 120000 } });
    // Payments are never flagged.
    const payment = await entry('ravi', 'payment', 100, 0);
    expect((await shop.collection('entries').doc(payment).get()).get('overLimit')).toBeUndefined();
  });
});
