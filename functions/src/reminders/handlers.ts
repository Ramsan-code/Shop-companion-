import { FieldValue, type Firestore, Timestamp } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';

import { overdueDays } from '../collections/scoring.js';
import { type Caller, requirePermission } from '../members/handlers.js';
import type { SmsSender, WhatsAppSender } from '../messaging/providers.js';
import { MessagingError } from '../messaging/providers.js';
import { issueStatement, statementUrl } from '../statements/handlers.js';
import { decideReminder, nextWindowStart } from './policy.js';
import {
  type Kinship,
  type Lang,
  renderReminder,
  type TemplateOverrides,
  templateFor,
  templateParams,
  type Tone,
} from './templates.js';

/**
 * Automatic reminders (PRD C7, D3, D8, flow 7.1-4): plan → (owner approves)
 * → queued task → send WhatsApp utility template → SMS fallback → status.
 * The send policy (08:00–20:00, one per 3 days, consent, STOP) is checked
 * when planning and again at send time, because things change in between.
 */

export type ReminderStatus =
  | 'pendingApproval'
  | 'queued'
  | 'sent'
  | 'delivered'
  | 'read'
  | 'failed'
  | 'skipped'
  | 'cancelled';

/** Monthly message allowance per plan (PRD 12.3; pilot shops as Plus). */
export const PLAN_CAPS: Record<string, { whatsapp: number; sms: number }> = {
  pilot: { whatsapp: 300, sms: 50 },
  plus: { whatsapp: 300, sms: 50 },
  pro: { whatsapp: 1000, sms: 200 },
};

export interface Enqueuer {
  enqueue(task: { shopId: string; reminderId: string }, at: Date): Promise<void>;
}

export interface ReminderDeps {
  db: Firestore;
  enqueuer: Enqueuer;
  whatsapp: WhatsAppSender;
  sms: SmsSender;
  baseUrl: string;
  /** Template wording from Remote Config; built-in text when absent. */
  templates?: TemplateOverrides;
}

const shopRef = (db: Firestore, shopId: string) => db.collection('shops').doc(shopId);
const monthKey = (now: number) => new Date(now + 5.5 * 3_600_000).toISOString().slice(0, 7);
const digits = (phone: string) => phone.replace(/\D/g, '');

/** How long a debt must be unpaid before automatic reminders start. */
export const DEFAULT_REMIND_AFTER_DAYS = 14;

/**
 * Daily planner (scheduleReminders, 09:30 Colombo): for each consenting
 * customer who owes and is due a reminder, issue a statement link and create
 * a reminder: queued to send now, or waiting for the owner when the shop is
 * in approval mode (the default: reminders shouldn't hurt relationships).
 */
export async function planShopReminders(deps: ReminderDeps, shopId: string, now: number): Promise<number> {
  const { db } = deps;
  const shop = await shopRef(db, shopId).get();
  const plan = (shop.get('plan') as string | undefined) ?? 'free';
  if (!PLAN_CAPS[plan] || shop.get('settings.autoReminders') !== true) return 0;
  const approvalMode = shop.get('settings.approvalMode') !== false;
  const remindAfter = (shop.get('settings.remindAfterDays') as number | undefined) ?? DEFAULT_REMIND_AFTER_DAYS;
  const shopTone = ((shop.get('settings.tone') as Tone | undefined) ?? 'gentle') as Tone;

  const customers = await shopRef(db, shopId)
    .collection('customers')
    .where('reminderConsent', '==', true)
    .where('balanceCents', '>', 0)
    .get();
  const open = await shopRef(db, shopId)
    .collection('reminders')
    .where('status', 'in', ['pendingApproval', 'queued'])
    .get();
  const alreadyPlanned = new Set(open.docs.map((d) => d.get('customerId') as string));

  let planned = 0;
  for (const c of customers.docs) {
    if (alreadyPlanned.has(c.id) || !c.get('phone')) continue;
    const oldest = (c.get('oldestUnpaidAt') as Timestamp | undefined)?.toMillis() ?? null;
    if (overdueDays(c.get('balanceCents') as number, oldest, now) < remindAfter) continue;
    const decision = decideReminder(
      {
        balanceCents: c.get('balanceCents') as number,
        reminderConsent: true,
        optedOutAt: (c.get('optedOutAt') as Timestamp | undefined)?.toDate() ?? null,
        lastReminderAt: (c.get('lastReminderAt') as Timestamp | undefined)?.toDate() ?? null,
      },
      // Plan inside the window: a 09:30 run is, but be safe.
      nextWindowStart(new Date(now)),
    );
    if (!decision.send) continue;

    const ref = shopRef(db, shopId).collection('reminders').doc();
    await ref.create({
      customerId: c.id,
      tone: (c.get('reminderTone') as Tone | undefined) ?? shopTone,
      lang: (c.get('reminderLang') as Lang | undefined) ?? 'ta',
      status: approvalMode ? 'pendingApproval' : 'queued',
      createdBy: 'auto',
      createdAt: FieldValue.serverTimestamp(),
      scheduledAt: Timestamp.fromDate(nextWindowStart(new Date(now))),
    });
    if (!approvalMode) await deps.enqueuer.enqueue({ shopId, reminderId: ref.id }, nextWindowStart(new Date(now)));
    planned++;
  }
  return planned;
}

/** approveReminders callable: Owner/Partner approve (send) or cancel pending ones. */
export async function approveReminders(
  deps: Pick<ReminderDeps, 'db' | 'enqueuer'>,
  caller: Caller,
  data: { shopId?: unknown; reminderIds?: unknown; approve?: unknown },
  now: number,
): Promise<{ updated: number }> {
  const shopId = typeof data.shopId === 'string' ? data.shopId : '';
  const ids = Array.isArray(data.reminderIds) ? data.reminderIds.filter((x): x is string => typeof x === 'string') : [];
  if (!shopId || ids.length === 0 || ids.length > 100) throw new HttpsError('invalid-argument', 'shopId and 1–100 reminderIds.');
  await requirePermission(deps.db, shopId, caller.uid, 'reminder:send');
  const approve = data.approve !== false;
  const at = nextWindowStart(new Date(now));
  let updated = 0;
  for (const id of ids) {
    const ref = shopRef(deps.db, shopId).collection('reminders').doc(id);
    const changed = await deps.db.runTransaction(async (tx) => {
      const r = await tx.get(ref);
      if (!r.exists || r.get('status') !== 'pendingApproval') return false;
      tx.update(ref, {
        status: approve ? 'queued' : 'cancelled',
        approvedBy: caller.uid,
        scheduledAt: Timestamp.fromDate(at),
      });
      return true;
    });
    if (changed && approve) await deps.enqueuer.enqueue({ shopId, reminderId: id }, at);
    if (changed) updated++;
  }
  return { updated };
}

/**
 * sendReminder task. Rechecks everything, sends WhatsApp, falls back to SMS
 * when the number has no WhatsApp or the WhatsApp allowance is used up, and
 * records the result. Idempotent: only a `queued` reminder is sent.
 */
export async function sendReminder(
  deps: ReminderDeps,
  task: { shopId: string; reminderId: string },
  now: number,
): Promise<ReminderStatus> {
  const { db } = deps;
  const shop = shopRef(db, task.shopId);
  const ref = shop.collection('reminders').doc(task.reminderId);
  const reminder = await ref.get();
  if (!reminder.exists || reminder.get('status') !== 'queued') return (reminder.get('status') as ReminderStatus) ?? 'skipped';
  const [shopDoc, customer] = await Promise.all([shop.get(), shop.collection('customers').doc(reminder.get('customerId')).get()]);
  const skip = async (reason: string) => {
    await ref.update({ status: 'skipped', skipReason: reason, updatedAt: FieldValue.serverTimestamp() });
    return 'skipped' as const;
  };
  if (!customer.exists || !customer.get('phone')) return skip('noPhone');

  const decision = decideReminder(
    {
      balanceCents: (customer.get('balanceCents') as number | undefined) ?? 0,
      reminderConsent: customer.get('reminderConsent') === true,
      optedOutAt: (customer.get('optedOutAt') as Timestamp | undefined)?.toDate() ?? null,
      lastReminderAt: (customer.get('lastReminderAt') as Timestamp | undefined)?.toDate() ?? null,
    },
    new Date(now),
  );
  if (!decision.send) {
    if (decision.reason === 'outside-window') {
      await deps.enqueuer.enqueue(task, decision.retryAt);
      return 'queued';
    }
    return skip(decision.reason);
  }

  const caps = PLAN_CAPS[(shopDoc.get('plan') as string | undefined) ?? 'free'];
  if (!caps) return skip('plan');
  const usageRef = shop.collection('usage').doc(monthKey(now));
  const usage = (await usageRef.get()).data() ?? {};

  const tone = reminder.get('tone') as Tone;
  const lang = reminder.get('lang') as Lang;
  const token = await issueStatement(db, task.shopId, customer.id, now);
  const params = {
    customerName: customer.get('name') as string,
    kinship: (customer.get('kinshipTerm') as Kinship | undefined) ?? undefined,
    shopName: shopDoc.get('name') as string,
    amountCents: customer.get('balanceCents') as number,
    statementUrl: statementUrl(deps.baseUrl, token),
  };
  const to = digits(customer.get('phone') as string);

  let channel: 'whatsapp' | 'sms' | null = null;
  let messageId = '';
  let error: string | null = null;
  if (((usage.whatsapp as number | undefined) ?? 0) < caps.whatsapp) {
    try {
      const template = templateFor(tone, lang, deps.templates);
      ({ id: messageId } = await deps.whatsapp.sendTemplate({
        to,
        template: template.id,
        lang,
        bodyParams: templateParams(params, lang),
        buttonPayloads: [`CONFIRM:${token}`, `DISPUTE:${token}`],
      }));
      channel = 'whatsapp';
    } catch (e) {
      error = e instanceof MessagingError ? e.message : 'whatsapp';
      // Only fall back to SMS when WhatsApp can't reach the person.
      if (!(e instanceof MessagingError && e.unreachable)) return fail(ref, error);
    }
  }
  if (channel == null) {
    if (((usage.sms as number | undefined) ?? 0) >= caps.sms) return skip('capReached');
    try {
      ({ id: messageId } = await deps.sms.send(to, renderReminder(tone, lang, params, deps.templates)));
      channel = 'sms';
    } catch (e) {
      return fail(ref, e instanceof MessagingError ? e.message : 'sms');
    }
  }

  const batch = db.batch();
  batch.update(ref, {
    status: 'sent',
    channel,
    providerMessageId: messageId,
    statementToken: token,
    amountCents: params.amountCents,
    sentAt: Timestamp.fromMillis(now),
    error,
  });
  batch.update(customer.ref, { lastReminderAt: Timestamp.fromMillis(now) });
  batch.set(usageRef, { [channel]: FieldValue.increment(1) }, { merge: true });
  // Webhook lookups: delivery status by message ID, STOP by phone.
  if (messageId) batch.set(db.collection('messageIndex').doc(messageId), { shopId: task.shopId, reminderId: ref.id });
  batch.set(
    db.collection('optOutIndex').doc(to),
    { targets: FieldValue.arrayUnion(`${task.shopId}/${customer.id}`) },
    { merge: true },
  );
  await batch.commit();
  return 'sent';
}

async function fail(ref: FirebaseFirestore.DocumentReference, error: string): Promise<ReminderStatus> {
  await ref.update({ status: 'failed', error, updatedAt: FieldValue.serverTimestamp() });
  return 'failed';
}

/**
 * previewReminder callable (PRD US3: "Tone preview before sending"): the
 * exact text this customer would get, rendered from the same templates.
 */
export async function previewReminder(
  deps: { db: Firestore; baseUrl: string; templates?: TemplateOverrides },
  caller: Caller,
  data: { shopId?: unknown; customerId?: unknown; tone?: unknown; lang?: unknown },
): Promise<{ text: string }> {
  const shopId = typeof data.shopId === 'string' ? data.shopId : '';
  const customerId = typeof data.customerId === 'string' ? data.customerId : '';
  const tone = (['gentle', 'normal', 'firm'] as const).find((t) => t === data.tone) ?? 'gentle';
  const lang = data.lang === 'en' ? 'en' : 'ta';
  if (!shopId || !customerId) throw new HttpsError('invalid-argument', 'shopId and customerId are required.');
  await requirePermission(deps.db, shopId, caller.uid, 'reminder:send');
  const [shop, customer] = await Promise.all([
    shopRef(deps.db, shopId).get(),
    shopRef(deps.db, shopId).collection('customers').doc(customerId).get(),
  ]);
  if (!customer.exists) throw new HttpsError('not-found', 'No such customer.');
  const amountCents = Math.max((customer.get('balanceCents') as number | undefined) ?? 0, 100);
  return {
    text: renderReminder(tone, lang, {
      customerName: customer.get('name') as string,
      kinship: (customer.get('kinshipTerm') as Kinship | undefined) ?? undefined,
      shopName: shop.get('name') as string,
      amountCents,
      statementUrl: statementUrl(deps.baseUrl, '…'),
    }, deps.templates),
  };
}
