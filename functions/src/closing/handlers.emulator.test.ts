import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { beforeAll, beforeEach, describe, expect, it } from 'vitest';

import { colomboDayRange } from './closing.js';
import { recordDayClosing } from './handlers.js';

const PROJECT = 'demo-shop-companion';
if (getApps().length === 0) initializeApp({ projectId: PROJECT });
const db = getFirestore();

const SHOP = 'shop1';
const shop = db.collection('shops').doc(SHOP);
const DATE = '2026-10-01';
const [START] = colomboDayRange(DATE);

let n = 0;
async function entry(type: string, rupees: number, extra: Record<string, unknown> = {}, at = START + 3_600_000) {
  const id = `e${++n}`;
  await shop.collection('entries').doc(id).set({
    clientId: id, shopId: SHOP, type, amountCents: rupees * 100, createdBy: 'helper1',
    createdAt: Timestamp.fromMillis(at), txnDate: Timestamp.fromMillis(at), source: 'text', applied: null, ...extra,
  });
}

const count = (uid: string, rupees: number, atMs: number, date = DATE) =>
  shop.collection('dayClosings').doc(date).collection('counts').doc(uid)
    .set({ countedCashCents: rupees * 100, at: Timestamp.fromMillis(atMs) });

beforeAll(() => {
  if (!process.env.FIRESTORE_EMULATOR_HOST) throw new Error('Run with `npm run test:emulator`.');
});

beforeEach(async () => {
  const host = process.env.FIRESTORE_EMULATOR_HOST!;
  await fetch(`http://${host}/emulator/v1/projects/${PROJECT}/databases/(default)/documents`, { method: 'DELETE' });
  await shop.set({ name: 'Shop', ownerUid: 'owner1', settings: { openingFloatCents: 50_000 } });
});

describe('recordDayClosing', () => {
  it('totals only that Colombo day and compares the latest count', async () => {
    await entry('sale', 2000);
    await entry('sale', 1000, { method: 'lankaqr' });
    await entry('payment', 500, { customerId: 'c1', method: 'cash' });
    await entry('credit', 700, { customerId: 'c1' });
    await entry('expense', 300, { category: 'transport' });
    await entry('sale', 9999, { deletedAt: Timestamp.now() });
    await entry('sale', 4000, {}, START - 60_000); // yesterday, 23:59 Colombo
    await count('helper1', 2600, START + 10 * 3_600_000);
    await count('owner1', 2700, START + 11 * 3_600_000);

    const c = await recordDayClosing(db, SHOP, DATE);
    expect(c).toMatchObject({
      salesCents: 300_000, creditCents: 70_000, collectedCents: 50_000, expensesCents: 30_000,
      openingCashCents: 50_000,
      // 500 + 2000 + 500 − 300
      expectedCashCents: 270_000,
      countedCashCents: 270_000, differenceCents: 0,
      marginPercent: 15, profitEstimateCents: 45_000 - 30_000,
    });
    const doc = (await shop.collection('dayClosings').doc(DATE).get()).data()!;
    expect(doc.countedBy).toBe('owner1');
    expect(doc.closedAt).toBeDefined();
  });

  it("opens with yesterday's counted cash and uses the shop's item margins", async () => {
    await shop.collection('dayClosings').doc('2026-09-30').set({ countedCashCents: 120_000 });
    for (const [cost, price] of [[80, 100], [80, 100], [80, 100]]) {
      await shop.collection('items').add({ name: 'x', qty: 1, costCents: cost * 100, priceCents: price * 100 });
    }
    await entry('sale', 1000);
    await count('helper1', 2100, START + 3_600_000);
    const c = await recordDayClosing(db, SHOP, DATE);
    expect(c?.openingCashCents).toBe(120_000);
    expect(c?.expectedCashCents).toBe(220_000);
    expect(c?.differenceCents).toBe(-10_000);
    expect(c?.marginPercent).toBe(20);
    expect(c?.profitEstimateCents).toBe(20_000);
  });

  it('ignores a malformed date', async () => {
    expect(await recordDayClosing(db, SHOP, 'today')).toBeNull();
  });
});
