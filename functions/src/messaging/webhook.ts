import { createHmac, timingSafeEqual } from 'node:crypto';

import { FieldValue, type Firestore, Timestamp } from 'firebase-admin/firestore';

import type { Pusher } from '../collections/handlers.js';
import { isStopReply } from '../reminders/policy.js';
import { StatementGone, statementAction } from '../statements/handlers.js';

/** Meta signs each webhook POST with the app secret (X-Hub-Signature-256). */
export function verifySignature(rawBody: Buffer, header: string | undefined, appSecret: string): boolean {
  if (!header?.startsWith('sha256=') || !appSecret) return false;
  const expected = createHmac('sha256', appSecret).update(rawBody).digest();
  const given = Buffer.from(header.slice('sha256='.length), 'hex');
  return given.length === expected.length && timingSafeEqual(given, expected);
}

interface WebhookPayload {
  entry?: {
    changes?: {
      value?: {
        statuses?: { id?: string; status?: string }[];
        messages?: { from?: string; type?: string; text?: { body?: string }; button?: { payload?: string; text?: string } }[];
      };
    }[];
  }[];
}

const STATUS_ORDER: Record<string, number> = { sent: 1, delivered: 2, read: 3 };

/**
 * messagingWebhook (PRD 10.3): delivery status, STOP (honoured within a
 * minute, PRD 11), and Confirm / Dispute button replies.
 */
export async function handleWhatsAppWebhook(
  deps: { db: Firestore; push?: Pusher },
  payload: WebhookPayload,
  now: number,
): Promise<{ statuses: number; optOuts: number; actions: number }> {
  const counts = { statuses: 0, optOuts: 0, actions: 0 };
  for (const entry of payload.entry ?? []) {
    for (const change of entry.changes ?? []) {
      for (const s of change.value?.statuses ?? []) {
        if (s.id && s.status && (await applyStatus(deps.db, s.id, s.status))) counts.statuses++;
      }
      for (const m of change.value?.messages ?? []) {
        const payloadText = m.button?.payload ?? '';
        const [action, token] = payloadText.split(':', 2);
        if ((action === 'CONFIRM' || action === 'DISPUTE') && token) {
          try {
            await statementAction(deps, token, action === 'CONFIRM' ? 'confirm' : 'dispute', null, now);
            counts.actions++;
          } catch (e) {
            if (!(e instanceof StatementGone)) throw e;
          }
          continue;
        }
        const text = m.text?.body ?? m.button?.text ?? '';
        if (m.from && isStopReply(text)) counts.optOuts += await optOut(deps.db, m.from, now);
      }
    }
  }
  return counts;
}

async function applyStatus(db: Firestore, messageId: string, status: string): Promise<boolean> {
  const index = await db.collection('messageIndex').doc(messageId).get();
  if (!index.exists) return false;
  const ref = db.doc(`shops/${index.get('shopId') as string}/reminders/${index.get('reminderId') as string}`);
  return db.runTransaction(async (tx) => {
    const reminder = await tx.get(ref);
    if (!reminder.exists) return false;
    const current = reminder.get('status') as string;
    // Statuses can arrive out of order: only move forward.
    const forward = status === 'failed' ? current === 'sent' : (STATUS_ORDER[status] ?? 0) > (STATUS_ORDER[current] ?? 0);
    if (!forward) return false;
    tx.update(ref, { status, [`${status}At`]: FieldValue.serverTimestamp() });
    return true;
  });
}

/** STOP: opt the number out of every shop that reminded it, cancel what's queued. */
export async function optOut(db: Firestore, phone: string, now: number): Promise<number> {
  const index = await db.collection('optOutIndex').doc(phone.replace(/\D/g, '')).get();
  const targets = (index.get('targets') as string[] | undefined) ?? [];
  let changed = 0;
  for (const target of targets) {
    const [shopId, customerId] = target.split('/');
    if (!shopId || !customerId) continue;
    const shop = db.collection('shops').doc(shopId);
    const customer = shop.collection('customers').doc(customerId);
    const open = await shop
      .collection('reminders')
      .where('customerId', '==', customerId)
      .where('status', 'in', ['pendingApproval', 'queued'])
      .get();
    const batch = db.batch();
    batch.update(customer, { optedOutAt: Timestamp.fromMillis(now) });
    for (const r of open.docs) batch.update(r.ref, { status: 'cancelled', cancelReason: 'optOut' });
    batch.create(shop.collection('auditLogs').doc(), {
      actorUid: null,
      action: 'reminder.optOut',
      entity: 'customer',
      entityId: customerId,
      before: null,
      after: { cancelled: open.size },
      at: FieldValue.serverTimestamp(),
    });
    await batch.commit();
    changed++;
  }
  return changed;
}
