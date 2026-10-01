import { createHmac } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { beforeAll, beforeEach, describe, expect, it } from 'vitest';

import { DAY_MS } from '../collections/scoring.js';
import { applyEntry } from '../ledger/handlers.js';
import { MessagingError, type SmsSender, type TemplateMessage, type WhatsAppSender } from '../messaging/providers.js';
import { handleWhatsAppWebhook, verifySignature } from '../messaging/webhook.js';
import { createStatement, StatementGone, statementAction, viewStatement } from '../statements/handlers.js';
import { approveReminders, type Enqueuer, planShopReminders, previewReminder, sendReminder } from './handlers.js';

const PROJECT = 'demo-shop-companion';
if (getApps().length === 0) initializeApp({ projectId: PROJECT });
const db = getFirestore();

const SHOP = 'shop1';
const shop = db.collection('shops').doc(SHOP);
const OWNER = { uid: 'owner1' };
const HELPER = { uid: 'helper1' };
// 10:00 Colombo on 1 Oct 2026: inside the sending window.
const NOW = Date.UTC(2026, 9, 1, 4, 30);

class FakeWhatsApp implements WhatsAppSender {
  sent: TemplateMessage[] = [];
  fail: MessagingError | null = null;
  async sendTemplate(m: TemplateMessage) {
    if (this.fail) throw this.fail;
    this.sent.push(m);
    return { id: `wamid.${this.sent.length}` };
  }
}
class FakeSms implements SmsSender {
  sent: { to: string; text: string }[] = [];
  async send(to: string, text: string) {
    this.sent.push({ to, text });
    return { id: `sms.${this.sent.length}` };
  }
}
class FakeQueue implements Enqueuer {
  tasks: { task: { shopId: string; reminderId: string }; at: Date }[] = [];
  async enqueue(task: { shopId: string; reminderId: string }, at: Date) {
    this.tasks.push({ task, at });
  }
}

let whatsapp: FakeWhatsApp;
let sms: FakeSms;
let queue: FakeQueue;
const deps = () => ({ db, enqueuer: queue, whatsapp, sms, baseUrl: 'https://sc.test' });

let n = 0;
async function credit(customerId: string, rupees: number, daysAgo: number) {
  const id = `e${++n}`;
  await shop.collection('entries').doc(id).set({
    clientId: id, shopId: SHOP, customerId, type: 'credit', amountCents: rupees * 100, createdBy: OWNER.uid,
    createdAt: Timestamp.fromMillis(NOW - daysAgo * DAY_MS), txnDate: Timestamp.fromMillis(NOW - daysAgo * DAY_MS),
    source: 'text', applied: null,
  });
  await applyEntry(db, SHOP, id);
  return id;
}

const reminders = async () => (await shop.collection('reminders').get()).docs.map((d) => ({ id: d.id, ...d.data() }));

beforeAll(() => {
  if (!process.env.FIRESTORE_EMULATOR_HOST) throw new Error('Run with `npm run test:emulator`.');
});

beforeEach(async () => {
  const host = process.env.FIRESTORE_EMULATOR_HOST!;
  await fetch(`http://${host}/emulator/v1/projects/${PROJECT}/databases/(default)/documents`, { method: 'DELETE' });
  const roles = JSON.parse(readFileSync(resolve(import.meta.dirname, '../../../seed/roles.json'), 'utf8'));
  for (const role of ['owner', 'helper']) await db.doc(`roles/${role}`).set({ permissions: roles[role].permissions });
  await shop.set({
    name: 'Selvarasa Stores', ownerUid: OWNER.uid, plan: 'pilot', lankaQrPayload: '00020101021229300012LK.LANKAQR.0102',
    settings: { autoReminders: true, approvalMode: true, tone: 'gentle' },
  });
  await shop.collection('members').doc(OWNER.uid).set({ role: 'owner', status: 'active' });
  await shop.collection('members').doc(HELPER.uid).set({ role: 'helper', status: 'active' });
  await db.doc(`users/${OWNER.uid}`).set({ locale: 'ta', fcmTokens: ['owner-phone'] });
  const c = (id: string, extra: Record<string, unknown>) => shop.collection('customers').doc(id).set({ name: id, ...extra });
  await c('ravi', { name: 'Ravi', kinshipTerm: 'annai', phone: '+94771234567', reminderConsent: true, reminderTone: 'firm' });
  await c('selvi', { name: 'Selvi', phone: '+94771000002', reminderConsent: false });
  await c('kumar', { name: 'Kumar', phone: '+94771000003', reminderConsent: true });
  await c('nophone', { name: 'NoPhone', reminderConsent: true });
  await credit('ravi', 1500, 20);
  await credit('selvi', 900, 30);
  await credit('kumar', 300, 3); // too recent
  await credit('nophone', 500, 40);
  whatsapp = new FakeWhatsApp();
  sms = new FakeSms();
  queue = new FakeQueue();
});

describe('statements (N8, D8, D18)', () => {
  it('a link shows balance, lines and the LankaQR; confirm marks the entries', async () => {
    const { url } = await createStatement({ db, baseUrl: 'https://sc.test/', now: () => NOW }, HELPER, { shopId: SHOP, customerId: 'ravi' });
    const token = url.split('/s/')[1]!;
    expect(url).toMatch(/^https:\/\/sc\.test\/s\/[\w-]{32}$/);
    const view = await viewStatement(db, token, NOW);
    expect(view).toMatchObject({ shopName: 'Selvarasa Stores', customerName: 'Ravi', kinship: 'annai', balanceCents: 150000 });
    expect(view.lines).toHaveLength(1);
    expect(view.qrSvg).toContain('<svg');
    expect(JSON.stringify(view)).not.toContain('LK.LANKAQR'); // payload only as the QR picture

    await statementAction({ db }, token, 'confirm', null, NOW);
    const entry = (await shop.collection('entries').doc(view.lines[0]!.entryId).get()).data()!;
    expect(entry.confirmedAt).toBeInstanceOf(Timestamp);
    expect((await viewStatement(db, token, NOW)).confirmed).toBe(true);
  });

  it('dispute flags the customer and tells the owner without naming them', async () => {
    const { url } = await createStatement({ db, baseUrl: 'https://sc.test', now: () => NOW }, OWNER, { shopId: SHOP, customerId: 'ravi' });
    const pushes: string[] = [];
    await statementAction(
      { db, push: { send: async (_t, m) => (pushes.push(`${m.title} ${m.body}`), []) } },
      url.split('/s/')[1]!,
      'dispute',
      ' I paid 500 last week ',
      NOW,
    );
    expect((await shop.collection('customers').doc('ravi').get()).get('disputeOpenAt')).toBeInstanceOf(Timestamp);
    expect(pushes).toHaveLength(1);
    expect(pushes[0]).not.toContain('Ravi');
  });

  it('expired or made-up tokens are gone', async () => {
    const { url } = await createStatement({ db, baseUrl: 'x', now: () => NOW }, OWNER, { shopId: SHOP, customerId: 'ravi' });
    await expect(viewStatement(db, url.split('/s/')[1]!, NOW + 31 * DAY_MS)).rejects.toBeInstanceOf(StatementGone);
    await expect(viewStatement(db, 'not-a-real-token-at-all-xx', NOW)).rejects.toBeInstanceOf(StatementGone);
    await expect(viewStatement(db, '../../shops', NOW)).rejects.toBeInstanceOf(StatementGone);
  });

  it('non-members cannot create a link', async () => {
    await expect(
      createStatement({ db, baseUrl: 'x', now: () => NOW }, { uid: 'stranger' }, { shopId: SHOP, customerId: 'ravi' }),
    ).rejects.toMatchObject({ code: 'permission-denied' });
  });
});

describe('planning (scheduleReminders)', () => {
  it('only consenting customers with a phone, owing long enough; waits for approval by default', async () => {
    expect(await planShopReminders(deps(), SHOP, NOW)).toBe(1);
    const [r] = await reminders();
    expect(r).toMatchObject({ customerId: 'ravi', status: 'pendingApproval', tone: 'firm', lang: 'ta' });
    expect(queue.tasks).toHaveLength(0);
    // Not planned twice.
    expect(await planShopReminders(deps(), SHOP, NOW)).toBe(0);
  });

  it('without approval mode they are queued at once', async () => {
    await shop.update({ 'settings.approvalMode': false });
    await planShopReminders(deps(), SHOP, NOW);
    expect((await reminders())[0]!.status).toBe('queued');
    expect(queue.tasks).toHaveLength(1);
  });

  it('free plan or reminders off: nothing', async () => {
    await shop.update({ plan: 'free' });
    expect(await planShopReminders(deps(), SHOP, NOW)).toBe(0);
    await shop.update({ plan: 'plus', 'settings.autoReminders': false });
    expect(await planShopReminders(deps(), SHOP, NOW)).toBe(0);
  });

  it('owner approves or cancels; helpers cannot', async () => {
    await planShopReminders(deps(), SHOP, NOW);
    const [r] = await reminders();
    await expect(approveReminders({ db, enqueuer: queue }, HELPER, { shopId: SHOP, reminderIds: [r!.id] }, NOW)).rejects.toMatchObject({
      code: 'permission-denied',
    });
    expect(await approveReminders({ db, enqueuer: queue }, OWNER, { shopId: SHOP, reminderIds: [r!.id] }, NOW)).toEqual({ updated: 1 });
    expect((await reminders())[0]!.status).toBe('queued');
    expect(queue.tasks).toHaveLength(1);
    // Approving again does nothing.
    expect(await approveReminders({ db, enqueuer: queue }, OWNER, { shopId: SHOP, reminderIds: [r!.id] }, NOW)).toEqual({ updated: 0 });
  });
});

describe('sending (sendReminder)', () => {
  async function queued() {
    await shop.update({ 'settings.approvalMode': false });
    await planShopReminders(deps(), SHOP, NOW);
    return queue.tasks[0]!.task;
  }

  it('sends the WhatsApp template with a statement link and Confirm/Dispute buttons', async () => {
    const task = await queued();
    expect(await sendReminder(deps(), task, NOW)).toBe('sent');
    const m = whatsapp.sent[0]!;
    expect(m).toMatchObject({ to: '94771234567', template: 'due_reminder_firm_ta', lang: 'ta' });
    expect(m.bodyParams.slice(0, 3)).toEqual(['Ravi அண்ணை', 'Selvarasa Stores', 'Rs. 1,500']);
    expect(m.bodyParams[3]).toMatch(/^https:\/\/sc\.test\/s\//);
    expect(m.buttonPayloads[0]).toMatch(/^CONFIRM:/);
    const r = (await reminders())[0]!;
    expect(r).toMatchObject({ status: 'sent', channel: 'whatsapp', providerMessageId: 'wamid.1', amountCents: 150000 });
    expect((await shop.collection('customers').doc('ravi').get()).get('lastReminderAt')).toBeInstanceOf(Timestamp);
    expect((await shop.collection('usage').doc('2026-10').get()).get('whatsapp')).toBe(1);
    // Idempotent: a retried task doesn't send twice.
    expect(await sendReminder(deps(), task, NOW)).toBe('sent');
    expect(whatsapp.sent).toHaveLength(1);
  });

  it('falls back to SMS when the number has no WhatsApp', async () => {
    const task = await queued();
    whatsapp.fail = new MessagingError('whatsapp 131026', true);
    expect(await sendReminder(deps(), task, NOW)).toBe('sent');
    expect(sms.sent[0]!.text).toContain('Ravi அண்ணை');
    expect(sms.sent[0]!.text).toContain('STOP');
    expect((await reminders())[0]).toMatchObject({ channel: 'sms' });
  });

  it('other WhatsApp errors fail the reminder instead of spamming SMS', async () => {
    const task = await queued();
    whatsapp.fail = new MessagingError('whatsapp 500');
    expect(await sendReminder(deps(), task, NOW)).toBe('failed');
    expect(sms.sent).toHaveLength(0);
  });

  it('rechecks at send time: paid since → skipped; evening → queued for 08:00', async () => {
    const task = await queued();
    const evening = Date.UTC(2026, 9, 1, 15); // 20:30 Colombo
    expect(await sendReminder(deps(), task, evening)).toBe('queued');
    expect(queue.tasks.at(-1)!.at.toISOString()).toBe('2026-10-02T02:30:00.000Z');

    await shop.collection('customers').doc('ravi').update({ balanceCents: 0 });
    expect(await sendReminder(deps(), task, NOW)).toBe('skipped');
    expect((await reminders())[0]).toMatchObject({ status: 'skipped', skipReason: 'nothing-owed' });
  });

  it('respects the plan allowance', async () => {
    const task = await queued();
    await shop.collection('usage').doc('2026-10').set({ whatsapp: 300, sms: 50 });
    expect(await sendReminder(deps(), task, NOW)).toBe('skipped');
    expect((await reminders())[0]!.skipReason).toBe('capReached');
  });
});

describe('webhook', () => {
  it('verifies Meta signatures', () => {
    const body = Buffer.from('{"a":1}');
    const sig = `sha256=${createHmac('sha256', 'secret').update(body).digest('hex')}`;
    expect(verifySignature(body, sig, 'secret')).toBe(true);
    expect(verifySignature(body, sig, 'other')).toBe(false);
    expect(verifySignature(body, undefined, 'secret')).toBe(false);
  });

  it('updates delivery status forwards only; STOP opts out and cancels queued reminders', async () => {
    await shop.update({ 'settings.approvalMode': false });
    await planShopReminders(deps(), SHOP, NOW);
    await sendReminder(deps(), queue.tasks[0]!.task, NOW);
    const value = (v: object) => ({ entry: [{ changes: [{ value: v }] }] });

    await handleWhatsAppWebhook({ db }, value({ statuses: [{ id: 'wamid.1', status: 'read' }] }), NOW);
    await handleWhatsAppWebhook({ db }, value({ statuses: [{ id: 'wamid.1', status: 'delivered' }] }), NOW);
    expect((await reminders())[0]!.status).toBe('read');

    // A new reminder is waiting when the customer replies STOP.
    await shop.collection('reminders').doc('next').set({ customerId: 'ravi', status: 'queued' });
    const counts = await handleWhatsAppWebhook({ db }, value({ messages: [{ from: '94771234567', type: 'text', text: { body: 'நிறுத்து' } }] }), NOW);
    expect(counts.optOuts).toBe(1);
    expect((await shop.collection('customers').doc('ravi').get()).get('optedOutAt')).toBeInstanceOf(Timestamp);
    expect((await shop.collection('reminders').doc('next').get()).get('status')).toBe('cancelled');
  });

  it('a Confirm button reply confirms the statement', async () => {
    await shop.update({ 'settings.approvalMode': false });
    await planShopReminders(deps(), SHOP, NOW);
    await sendReminder(deps(), queue.tasks[0]!.task, NOW);
    const confirm = whatsapp.sent[0]!.buttonPayloads[0]!;
    const counts = await handleWhatsAppWebhook(
      { db },
      { entry: [{ changes: [{ value: { messages: [{ from: '94771234567', type: 'button', button: { payload: confirm, text: 'சரி' } }] } }] }] },
      NOW,
    );
    expect(counts.actions).toBe(1);
    const token = confirm.split(':')[1]!;
    expect((await viewStatement(db, token, NOW)).confirmed).toBe(true);
  });
});

describe('previewReminder', () => {
  it('renders the exact text for this customer and tone', async () => {
    const { text } = await previewReminder({ db, baseUrl: 'https://sc.test' }, OWNER, {
      shopId: SHOP, customerId: 'ravi', tone: 'gentle', lang: 'ta',
    });
    expect(text).toContain('வணக்கம் Ravi அண்ணை');
    expect(text).toContain('Rs. 1,500');
    await expect(
      previewReminder({ db, baseUrl: 'x' }, HELPER, { shopId: SHOP, customerId: 'ravi' }),
    ).rejects.toMatchObject({ code: 'permission-denied' });
  });
});
