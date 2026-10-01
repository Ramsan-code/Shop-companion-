import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

import { getApps, initializeApp } from 'firebase-admin/app';
import { FieldValue, getFirestore, Timestamp } from 'firebase-admin/firestore';
import { beforeAll, beforeEach, describe, expect, it } from 'vitest';

import { applyEntry, auditEntryEdit, deleteEntry, editEntry, reconcileShop } from './handlers.js';

const PROJECT = 'demo-shop-companion';
if (getApps().length === 0) initializeApp({ projectId: PROJECT });
const db = getFirestore();

const SHOP = 'shop1';
const OWNER = { uid: 'owner1' };
const HELPER = { uid: 'helper1' };
const shop = db.collection('shops').doc(SHOP);

async function reset() {
  const host = process.env.FIRESTORE_EMULATOR_HOST!;
  await fetch(`http://${host}/emulator/v1/projects/${PROJECT}/databases/(default)/documents`, { method: 'DELETE' });
  const roles = JSON.parse(readFileSync(resolve(import.meta.dirname, '../../../seed/roles.json'), 'utf8'));
  for (const role of ['owner', 'partner', 'helper']) {
    await db.collection('roles').doc(role).set({ permissions: roles[role].permissions });
  }
  await shop.set({ name: 'Shop', ownerUid: OWNER.uid });
  await shop.collection('members').doc(OWNER.uid).set({ role: 'owner', status: 'active' });
  await shop.collection('members').doc(HELPER.uid).set({ role: 'helper', status: 'active' });
  for (const id of ['ravi', 'kumar']) {
    await shop.collection('customers').doc(id).set({ name: id, createdBy: OWNER.uid, createdAt: Timestamp.now() });
  }
}

let n = 0;
async function addEntry(type: string, amountCents: number, customerId: string | null = 'ravi', txnDay = 1) {
  const id = `e${++n}`;
  await shop
    .collection('entries')
    .doc(id)
    .set({
      clientId: id,
      shopId: SHOP,
      type,
      amountCents,
      ...(customerId ? { customerId } : {}),
      createdBy: HELPER.uid,
      createdAt: Timestamp.now(),
      txnDate: Timestamp.fromDate(new Date(Date.UTC(2026, 9, txnDay))),
      source: 'text',
      applied: null,
    });
  return id;
}

const balance = async (id: string) => (await shop.collection('customers').doc(id).get()).get('balanceCents') as number | undefined;
const audits = async (action: string) => (await shop.collection('auditLogs').where('action', '==', action).get()).size;

beforeAll(() => {
  if (!process.env.FIRESTORE_EMULATOR_HOST) throw new Error('Run with `npm run test:emulator`.');
});
beforeEach(reset);

describe('applyEntry (onEntryCreated / onEntryUpdated)', () => {
  it('credit then payment move the balance; repeats change nothing', async () => {
    const credit = await addEntry('credit', 50000);
    expect(await applyEntry(db, SHOP, credit)).toBe(true);
    expect(await balance('ravi')).toBe(50000);
    // A retried trigger or a duplicate event.
    expect(await applyEntry(db, SHOP, credit)).toBe(false);
    expect(await balance('ravi')).toBe(50000);

    const payment = await addEntry('payment', 20000);
    await applyEntry(db, SHOP, payment);
    expect(await balance('ravi')).toBe(30000);
    const customer = (await shop.collection('customers').doc('ravi').get()).data()!;
    expect(customer.oldestUnpaidAt).toBeInstanceOf(Timestamp);
    expect(await audits('entry.create')).toBe(2);
  });

  it('concurrent triggers for the same entry still count it once', async () => {
    const id = await addEntry('credit', 1000);
    await Promise.all([applyEntry(db, SHOP, id), applyEntry(db, SHOP, id), applyEntry(db, SHOP, id)]);
    expect(await balance('ravi')).toBe(1000);
    expect(await audits('entry.create')).toBe(1);
  });

  it('cash sales and expenses never touch a customer', async () => {
    await applyEntry(db, SHOP, await addEntry('sale', 1000, null));
    await applyEntry(db, SHOP, await addEntry('expense', 1000, null));
    expect(await balance('ravi')).toBeUndefined();
  });

  it('an edit applies only the difference, and moving customers moves the balance', async () => {
    const id = await addEntry('credit', 50000);
    await applyEntry(db, SHOP, id);
    await shop.collection('entries').doc(id).update({ amountCents: 45000 });
    await applyEntry(db, SHOP, id);
    expect(await balance('ravi')).toBe(45000);

    await shop.collection('entries').doc(id).update({ customerId: 'kumar' });
    await applyEntry(db, SHOP, id);
    expect(await balance('ravi')).toBe(0);
    expect(await balance('kumar')).toBe(45000);
    const ravi = (await shop.collection('customers').doc('ravi').get()).data()!;
    expect(ravi.oldestUnpaidAt).toBeUndefined();
  });
});

describe('editEntry and deleteEntry callables', () => {
  it('owner edits any entry; helper may not', async () => {
    const id = await addEntry('credit', 50000);
    await applyEntry(db, SHOP, id);
    await expect(editEntry(db, HELPER, { shopId: SHOP, entryId: id, amountCents: 1 })).rejects.toMatchObject({
      code: 'permission-denied',
    });
    await editEntry(db, OWNER, { shopId: SHOP, entryId: id, amountCents: 40000 });
    expect(await balance('ravi')).toBe(40000);
    const entry = (await shop.collection('entries').doc(id).get()).data()!;
    expect(entry.updatedBy).toBe(OWNER.uid);
  });

  it('validates the change', async () => {
    const id = await addEntry('credit', 100);
    for (const bad of [{ amountCents: -1 }, { amountCents: 1.5 }, { customerId: 'ghost' }, {}]) {
      await expect(editEntry(db, OWNER, { shopId: SHOP, entryId: id, ...bad })).rejects.toHaveProperty('code');
    }
  });

  it('delete is soft, reverses the balance, is audited, and only once', async () => {
    const id = await addEntry('credit', 50000);
    await applyEntry(db, SHOP, id);
    await expect(deleteEntry(db, HELPER, { shopId: SHOP, entryId: id })).rejects.toMatchObject({ code: 'permission-denied' });
    await deleteEntry(db, OWNER, { shopId: SHOP, entryId: id, reason: 'wrong customer' });
    expect(await balance('ravi')).toBe(0);
    const entry = (await shop.collection('entries').doc(id).get()).data()!;
    expect(entry.deletedAt).toBeInstanceOf(Timestamp);
    expect(entry.deleteReason).toBe('wrong customer');
    expect(await audits('entry.delete')).toBe(1);
    await expect(deleteEntry(db, OWNER, { shopId: SHOP, entryId: id })).rejects.toMatchObject({ code: 'failed-precondition' });
    await expect(editEntry(db, OWNER, { shopId: SHOP, entryId: id, amountCents: 5 })).rejects.toMatchObject({
      code: 'failed-precondition',
    });
  });
});

describe('auditEntryEdit', () => {
  it('logs changed editable fields once per event, and ignores server-only changes', async () => {
    const before = { amountCents: 100, note: null, applied: null, createdBy: HELPER.uid };
    const after = { ...before, amountCents: 150, updatedBy: HELPER.uid };
    expect(await auditEntryEdit(db, SHOP, 'e1', 'evt-1', before, after)).toBe(true);
    expect(await auditEntryEdit(db, SHOP, 'e1', 'evt-1', before, after)).toBe(true);
    expect(await audits('entry.edit')).toBe(1);
    const log = (await shop.collection('auditLogs').doc('entry-edit-evt-1').get()).data()!;
    expect(log).toMatchObject({ actorUid: HELPER.uid, before: { amountCents: 100 }, after: { amountCents: 150 } });
    expect(await auditEntryEdit(db, SHOP, 'e1', 'evt-2', after, { ...after, applied: { customerId: 'c', deltaCents: 1 } })).toBe(false);
  });
});

describe('reconcileShop (nightly)', () => {
  it('fixes drift, audits it, and sets the exact oldest unpaid date', async () => {
    await applyEntry(db, SHOP, await addEntry('credit', 500, 'ravi', 1));
    await applyEntry(db, SHOP, await addEntry('credit', 300, 'ravi', 5));
    await applyEntry(db, SHOP, await addEntry('payment', 600, 'ravi', 7));
    // Simulate a bad double-apply.
    await shop.collection('customers').doc('ravi').update({ balanceCents: FieldValue.increment(500) });

    expect((await reconcileShop(db, SHOP)).corrected).toBe(1);
    expect(await balance('ravi')).toBe(200);
    const ravi = (await shop.collection('customers').doc('ravi').get()).data()!;
    expect((ravi.oldestUnpaidAt as Timestamp).toDate()).toEqual(new Date(Date.UTC(2026, 9, 5)));
    expect(await audits('balance.reconcile')).toBe(1);
    // A second run finds nothing to fix.
    expect((await reconcileShop(db, SHOP)).corrected).toBe(0);
  });
});
