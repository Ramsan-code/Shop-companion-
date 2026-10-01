import { FieldValue, Timestamp, type Firestore } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';

import type { Caller } from '../members/handlers.js';
import { requirePermission } from '../members/handlers.js';
import {
  type Applied,
  balanceChanges,
  type DatedEntry,
  desiredApplication,
  type EntryLike,
  NOTHING_APPLIED,
  recomputeBalance,
  sameApplication,
} from './balance.js';

/**
 * Ledger maintenance (PRD 9.2, 10.3). Clients only create entries; balances
 * are computed here so the phone can never forge them.
 *
 * Idempotency: each entry stores `applied` = the balance change already made
 * for it. `applyEntry` moves balances by (desired − applied) and records the
 * new `applied` in the same transaction, so a retried or duplicated trigger,
 * or create/update triggers arriving out of order, can't double-count.
 */

const CLIENT_EDITABLE = ['amountCents', 'customerId', 'method', 'txnDate', 'note'] as const;

const entryRef = (db: Firestore, shopId: string, entryId: string) =>
  db.collection('shops').doc(shopId).collection('entries').doc(entryId);

function asEntry(data: FirebaseFirestore.DocumentData): EntryLike {
  return {
    type: data.type,
    amountCents: data.amountCents,
    customerId: (data.customerId as string | undefined) ?? null,
    deletedAt: data.deletedAt ?? null,
  };
}

/** Brings the customer balances in line with one entry. Returns whether anything changed. */
export async function applyEntry(db: Firestore, shopId: string, entryId: string): Promise<boolean> {
  return db.runTransaction(async (tx) => {
    const ref = entryRef(db, shopId, entryId);
    const snap = await tx.get(ref);
    if (!snap.exists) return false;
    const data = snap.data()!;
    const firstTime = data.applied == null;
    const applied: Applied = (data.applied as Applied | null) ?? NOTHING_APPLIED;
    const desired = desiredApplication(asEntry(data));
    if (!firstTime && sameApplication(applied, desired)) return false;

    const changes = balanceChanges(applied, desired);
    const customers = db.collection('shops').doc(shopId).collection('customers');
    const customerSnaps = await Promise.all([...changes.keys()].map((id) => tx.get(customers.doc(id))));
    const txnDate = (data.txnDate as Timestamp | undefined) ?? (data.createdAt as Timestamp | undefined) ?? Timestamp.now();

    for (const customer of customerSnaps) {
      if (!customer.exists) continue; // Rules require the customer; reconciliation catches anything odd.
      const before = (customer.get('balanceCents') as number | undefined) ?? 0;
      const after = before + changes.get(customer.id)!;
      const update: Record<string, unknown> = { balanceCents: after, lastActivityAt: FieldValue.serverTimestamp() };
      // Exact oldest-unpaid dates come from the nightly reconciliation; this
      // keeps the field roughly right in between.
      if (after <= 0) update.oldestUnpaidAt = FieldValue.delete();
      else if (before <= 0) update.oldestUnpaidAt = txnDate;
      tx.update(customer.ref, update);
    }
    tx.update(ref, { applied: desired, appliedAt: FieldValue.serverTimestamp() });
    if (firstTime) {
      tx.set(db.collection('shops').doc(shopId).collection('auditLogs').doc(`entry-create-${entryId}`), {
        actorUid: data.createdBy ?? null,
        action: 'entry.create',
        entity: 'entry',
        entityId: entryId,
        before: null,
        after: { type: data.type, amountCents: data.amountCents, customerId: data.customerId ?? null },
        at: FieldValue.serverTimestamp(),
      });
    }
    return true;
  });
}

/**
 * Audit record for any edit to an entry's editable fields, whether the
 * author's own fix within 24 hours or an Owner/Partner edit through
 * `editEntry`. Called from the update trigger and keyed by the event ID, so a
 * retried trigger writes it once.
 */
export async function auditEntryEdit(
  db: Firestore,
  shopId: string,
  entryId: string,
  eventId: string,
  before: FirebaseFirestore.DocumentData,
  after: FirebaseFirestore.DocumentData,
): Promise<boolean> {
  const changed = CLIENT_EDITABLE.filter((k) => JSON.stringify(before[k] ?? null) !== JSON.stringify(after[k] ?? null));
  if (changed.length === 0) return false;
  const pick = (d: FirebaseFirestore.DocumentData) => Object.fromEntries(changed.map((k) => [k, d[k] ?? null]));
  await db
    .collection('shops')
    .doc(shopId)
    .collection('auditLogs')
    .doc(`entry-edit-${eventId}`)
    .set({
      actorUid: after.updatedBy ?? null,
      action: 'entry.edit',
      entity: 'entry',
      entityId: entryId,
      before: pick(before),
      after: pick(after),
      at: FieldValue.serverTimestamp(),
    });
  return true;
}

interface EditData {
  shopId?: unknown;
  entryId?: unknown;
  amountCents?: unknown;
  customerId?: unknown;
  note?: unknown;
}

/** Owner/Partner edit of any entry, at any age (PRD 6: "Yes, logged"). */
export async function editEntry(db: Firestore, caller: Caller, data: EditData): Promise<{ edited: true }> {
  const { shopId, entryId } = requireIds(data);
  await requirePermission(db, shopId, caller.uid, 'ledger:editAny');
  const changes: Record<string, unknown> = {};
  if (data.amountCents !== undefined) {
    if (!Number.isInteger(data.amountCents) || (data.amountCents as number) <= 0 || (data.amountCents as number) > 1_000_000_000) {
      throw new HttpsError('invalid-argument', 'amountCents must be a positive integer.');
    }
    changes.amountCents = data.amountCents;
  }
  if (data.customerId !== undefined) {
    if (typeof data.customerId !== 'string' || !data.customerId) throw new HttpsError('invalid-argument', 'Bad customerId.');
    changes.customerId = data.customerId;
  }
  if (data.note !== undefined) {
    if (typeof data.note !== 'string' || data.note.length > 200) throw new HttpsError('invalid-argument', 'Bad note.');
    changes.note = data.note;
  }
  if (Object.keys(changes).length === 0) throw new HttpsError('invalid-argument', 'Nothing to change.');

  await db.runTransaction(async (tx) => {
    const ref = entryRef(db, shopId, entryId);
    const snap = await tx.get(ref);
    if (!snap.exists) throw new HttpsError('not-found', 'No such entry.');
    if (snap.get('deletedAt') != null) throw new HttpsError('failed-precondition', 'Entry is deleted.');
    if (changes.customerId) {
      const customer = await tx.get(db.doc(`shops/${shopId}/customers/${changes.customerId as string}`));
      if (!customer.exists) throw new HttpsError('not-found', 'No such customer.');
    }
    // The update trigger writes the audit entry (auditEntryEdit).
    tx.update(ref, { ...changes, updatedAt: FieldValue.serverTimestamp(), updatedBy: caller.uid });
  });
  // The update trigger also applies it; doing it now gives the caller the new balance at once.
  await applyEntry(db, shopId, entryId);
  return { edited: true };
}

/** Soft delete (entries are append-only); the balance is reversed by applyEntry. */
export async function deleteEntry(
  db: Firestore,
  caller: Caller,
  data: { shopId?: unknown; entryId?: unknown; reason?: unknown },
): Promise<{ deleted: true }> {
  const { shopId, entryId } = requireIds(data);
  await requirePermission(db, shopId, caller.uid, 'ledger:editAny');
  const reason = typeof data.reason === 'string' ? data.reason.slice(0, 200) : null;
  await db.runTransaction(async (tx) => {
    const ref = entryRef(db, shopId, entryId);
    const snap = await tx.get(ref);
    if (!snap.exists) throw new HttpsError('not-found', 'No such entry.');
    if (snap.get('deletedAt') != null) throw new HttpsError('failed-precondition', 'Already deleted.');
    tx.update(ref, { deletedAt: FieldValue.serverTimestamp(), deletedBy: caller.uid, deleteReason: reason });
    tx.create(db.collection(`shops/${shopId}/auditLogs`).doc(), {
      actorUid: caller.uid,
      action: 'entry.delete',
      entity: 'entry',
      entityId: entryId,
      before: { type: snap.get('type'), amountCents: snap.get('amountCents'), customerId: snap.get('customerId') ?? null },
      after: { reason },
      at: FieldValue.serverTimestamp(),
    });
  });
  await applyEntry(db, shopId, entryId);
  return { deleted: true };
}

function requireIds(data: { shopId?: unknown; entryId?: unknown }) {
  const shopId = typeof data.shopId === 'string' ? data.shopId : '';
  const entryId = typeof data.entryId === 'string' ? data.entryId : '';
  if (!shopId || !entryId) throw new HttpsError('invalid-argument', 'shopId and entryId are required.');
  return { shopId, entryId };
}

/**
 * Nightly safety net (PRD 13 risk: duplicate balance updates): recomputes
 * every customer's balance from the entries, fixes and audits any drift, and
 * sets the exact oldest-unpaid date. Returns the number of corrected customers.
 */
export async function reconcileShop(db: Firestore, shopId: string): Promise<number> {
  const shop = db.collection('shops').doc(shopId);
  const [customers, entries] = await Promise.all([shop.collection('customers').get(), shop.collection('entries').get()]);
  const byCustomer = new Map<string, DatedEntry[]>();
  for (const doc of entries.docs) {
    const data = doc.data();
    const entry = asEntry(data);
    if (!entry.customerId) continue;
    const when = (data.txnDate as Timestamp | undefined) ?? (data.createdAt as Timestamp | undefined);
    const list = byCustomer.get(entry.customerId) ?? [];
    list.push({ ...entry, txnMillis: when?.toMillis() ?? 0 });
    byCustomer.set(entry.customerId, list);
  }

  let corrected = 0;
  let batch = db.batch();
  let ops = 0;
  const flush = async () => {
    if (ops > 0) await batch.commit();
    batch = db.batch();
    ops = 0;
  };
  for (const customer of customers.docs) {
    const { balanceCents, oldestUnpaidMillis } = recomputeBalance(byCustomer.get(customer.id) ?? []);
    const stored = (customer.get('balanceCents') as number | undefined) ?? 0;
    const storedOldest = (customer.get('oldestUnpaidAt') as Timestamp | undefined)?.toMillis() ?? null;
    if (stored === balanceCents && storedOldest === oldestUnpaidMillis) continue;
    batch.update(customer.ref, {
      balanceCents,
      oldestUnpaidAt: oldestUnpaidMillis == null ? FieldValue.delete() : Timestamp.fromMillis(oldestUnpaidMillis),
    });
    ops++;
    if (stored !== balanceCents) {
      corrected++;
      batch.create(shop.collection('auditLogs').doc(), {
        actorUid: null,
        action: 'balance.reconcile',
        entity: 'customer',
        entityId: customer.id,
        before: { balanceCents: stored },
        after: { balanceCents },
        at: FieldValue.serverTimestamp(),
      });
      ops++;
    }
    if (ops >= 400) await flush();
  }
  await flush();
  return corrected;
}
