import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

import ExcelJS from 'exceljs';
import { getApps, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { beforeAll, beforeEach, describe, expect, it } from 'vitest';

import { setShopClaim } from '../members/handlers.js';
import { type DataDeps, deleteMyAccount, deleteShop, eraseCustomer, EXPORT_COOLDOWN_MS, exportShop, type FileStore } from './handlers.js';

const PROJECT = 'demo-shop-companion';
if (getApps().length === 0) initializeApp({ projectId: PROJECT });
const db = getFirestore();
const auth = getAuth();

const SHOP = 'shop1';
const shop = db.collection('shops').doc(SHOP);
const OWNER = { uid: 'owner1' };
const PARTNER = { uid: 'partner1' };
const HELPER = { uid: 'helper1' };

class MemoryFiles implements FileStore {
  files = new Map<string, Buffer>();
  deleted: string[] = [];
  async save(path: string, data: Buffer) {
    this.files.set(path, data);
  }
  async deletePrefix(prefix: string) {
    this.deleted.push(prefix);
  }
}

let files: MemoryFiles;
let clock: Date;
const deps = (): DataDeps => ({ db, auth, files, now: () => clock });

beforeAll(() => {
  if (!process.env.FIRESTORE_EMULATOR_HOST) throw new Error('Run with `npm run test:emulator`.');
});

beforeEach(async () => {
  files = new MemoryFiles();
  clock = new Date('2026-10-01T20:00:00+05:30');
  const host = process.env.FIRESTORE_EMULATOR_HOST!;
  await fetch(`http://${host}/emulator/v1/projects/${PROJECT}/databases/(default)/documents`, { method: 'DELETE' });
  const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST!;
  await fetch(`http://${authHost}/emulator/v1/projects/${PROJECT}/accounts`, { method: 'DELETE' });
  const roles = JSON.parse(readFileSync(resolve(import.meta.dirname, '../../../seed/roles.json'), 'utf8'));
  for (const role of ['owner', 'partner', 'helper']) await db.doc(`roles/${role}`).set({ permissions: roles[role].permissions });
  await shop.set({ name: 'Kumar Stores', ownerUid: OWNER.uid, settings: {} });
  for (const [u, role] of [[OWNER, 'owner'], [PARTNER, 'partner'], [HELPER, 'helper']] as const) {
    await auth.createUser({ uid: u.uid });
    await shop.collection('members').doc(u.uid).set({ role, status: 'active' });
    await db.doc(`users/${u.uid}`).set({ activeShopId: SHOP, locale: 'ta' });
    await setShopClaim(auth, u.uid, SHOP, role);
  }
  await shop.collection('customers').doc('ravi').set({ name: 'ரவி', kinshipTerm: 'annai', phone: '+94771234567', balanceCents: 150000 });
  await shop.collection('customers').doc('selvi').set({ name: 'Selvi', phone: '+94777654321', balanceCents: 0 });
  const at = Timestamp.fromDate(new Date('2026-10-01T10:00:00+05:30'));
  for (const [id, customerId, type, cents, note] of [
    ['e1', 'ravi', 'credit', 150000, null],
    ['e2', 'selvi', 'credit', 50000, 'அரிசி 5kg'],
    ['e3', 'selvi', 'payment', 50000, null],
    ['e4', null, 'sale', 300000, null],
  ] as const) {
    await shop.collection('entries').doc(id).set({
      clientId: id, shopId: SHOP, type, amountCents: cents, txnDate: at, createdAt: at, createdBy: HELPER.uid, source: 'text',
      ...(customerId ? { customerId } : {}), ...(note ? { note } : {}),
    });
  }
  await shop.collection('items').doc('rice').set({ name: 'அரிசி', unit: 'kg', qty: 40, costCents: 22000, priceCents: 26000 });
  await shop.collection('dayClosings').doc('2026-10-01').set({ salesCents: 300000, expectedCashCents: 800000, countedCashCents: 790000, differenceCents: -10000, profitEstimateCents: 45000 });
  await db.collection('statements').doc('tok-selvi').set({ shopId: SHOP, customerId: 'selvi' });
  await db.collection('statements').doc('tok-ravi').set({ shopId: SHOP, customerId: 'ravi' });
  await db.collection('optOutIndex').doc('94777654321').set({ targets: [`${SHOP}/selvi`, 'other/x'] });
  await shop.collection('reminders').doc('r1').set({ customerId: 'selvi', status: 'sent' });
  await shop.collection('collectState').doc('selvi').set({ lastAction: 'call' });
});

describe('exportShop', () => {
  it('writes a workbook and complete JSON the owner can open', async () => {
    const { xlsxPath, jsonPath } = await exportShop(deps(), OWNER, { shopId: SHOP });
    expect(xlsxPath).toMatch(/^shops\/shop1\/exports\/.+\/shop-companion\.xlsx$/);

    const wb = new ExcelJS.Workbook();
    await wb.xlsx.load(files.files.get(xlsxPath)! as unknown as ArrayBuffer);
    expect(wb.worksheets.map((w) => w.name)).toEqual(['Customers', 'Entries', 'Stock', 'Close Day']);
    const customers = wb.getWorksheet('Customers')!;
    expect(customers.getRow(2).getCell(1).value).toBe('ரவி');
    expect(customers.getRow(2).getCell(5).value).toBe(1500);
    const entries = wb.getWorksheet('Entries')!;
    expect(entries.rowCount).toBe(5);
    expect(wb.getWorksheet('Close Day')!.getRow(2).getCell(7).value).toBe(-100);

    const json = JSON.parse(files.files.get(jsonPath)!.toString());
    expect(json.shop.name).toBe('Kumar Stores');
    expect(json.collections.entries).toHaveLength(4);
    expect(json.collections.entries[0].txnDate).toMatch(/^2026-10-01T04:30:00/);

    const audit = await shop.collection('auditLogs').where('action', '==', 'shop.export').get();
    expect(audit.size).toBe(1);
  });

  it('is owner-only and rate-limited', async () => {
    await expect(exportShop(deps(), PARTNER, { shopId: SHOP })).rejects.toMatchObject({ code: 'permission-denied' });
    await exportShop(deps(), OWNER, { shopId: SHOP });
    await expect(exportShop(deps(), OWNER, { shopId: SHOP })).rejects.toMatchObject({ code: 'resource-exhausted' });
    clock = new Date(clock.getTime() + EXPORT_COOLDOWN_MS + 1);
    await expect(exportShop(deps(), OWNER, { shopId: SHOP })).resolves.toBeDefined();
  });
});

describe('eraseCustomer', () => {
  it('refuses while money is owed', async () => {
    await expect(eraseCustomer(deps(), OWNER, { shopId: SHOP, customerId: 'ravi' })).rejects.toMatchObject({
      code: 'failed-precondition',
    });
  });

  it('removes the person and keeps the anonymous books', async () => {
    await shop.collection('customers').doc('selvi').collection('private').doc('score').set({ score: 80 });
    await eraseCustomer(deps(), OWNER, { shopId: SHOP, customerId: 'selvi' });
    expect((await shop.collection('customers').doc('selvi').get()).exists).toBe(false);
    expect((await db.doc('shops/shop1/customers/selvi/private/score').get()).exists).toBe(false);
    expect((await shop.collection('collectState').doc('selvi').get()).exists).toBe(false);
    expect((await shop.collection('reminders').doc('r1').get()).exists).toBe(false);
    expect((await db.doc('statements/tok-selvi').get()).exists).toBe(false);
    expect((await db.doc('statements/tok-ravi').get()).exists).toBe(true);
    expect((await db.doc('optOutIndex/94777654321').get()).get('targets')).toEqual(['other/x']);
    const e2 = await shop.collection('entries').doc('e2').get();
    expect(e2.get('amountCents')).toBe(50000);
    expect(e2.get('note')).toBeUndefined();
  });

  it('is owner-only', async () => {
    await expect(eraseCustomer(deps(), HELPER, { shopId: SHOP, customerId: 'selvi' })).rejects.toMatchObject({
      code: 'permission-denied',
    });
  });
});

describe('deleteShop', () => {
  it('needs the exact shop name', async () => {
    await expect(deleteShop(deps(), OWNER, { shopId: SHOP, confirmName: 'Kumar' })).rejects.toMatchObject({
      code: 'failed-precondition',
    });
    await expect(deleteShop(deps(), PARTNER, { shopId: SHOP, confirmName: 'Kumar Stores' })).rejects.toMatchObject({
      code: 'permission-denied',
    });
  });

  it('deletes everything of the shop and frees its members', async () => {
    await deleteShop(deps(), OWNER, { shopId: SHOP, confirmName: ' Kumar Stores ' });
    expect((await shop.get()).exists).toBe(false);
    expect((await shop.collection('entries').get()).size).toBe(0);
    expect((await shop.collection('members').get()).size).toBe(0);
    expect((await db.collection('statements').get()).size).toBe(0);
    expect((await db.doc('optOutIndex/94777654321').get()).get('targets')).toEqual(['other/x']);
    expect((await db.doc(`users/${HELPER.uid}`).get()).get('activeShopId')).toBeUndefined();
    expect((await auth.getUser(HELPER.uid)).customClaims?.shops).toEqual({});
    expect(files.deleted).toEqual(['shops/shop1/']);
    expect((await db.doc('deletedShops/shop1').get()).get('byUid')).toBe(OWNER.uid);
  });
});

describe('deleteMyAccount', () => {
  it('an owner must delete the shop first', async () => {
    await expect(deleteMyAccount(deps(), OWNER)).rejects.toMatchObject({ code: 'failed-precondition' });
  });

  it('a helper leaves the shop and the account is gone', async () => {
    await deleteMyAccount(deps(), HELPER);
    expect((await shop.collection('members').doc(HELPER.uid).get()).get('status')).toBe('removed');
    expect((await db.doc(`users/${HELPER.uid}`).get()).exists).toBe(false);
    await expect(auth.getUser(HELPER.uid)).rejects.toMatchObject({ code: 'auth/user-not-found' });
  });
});
