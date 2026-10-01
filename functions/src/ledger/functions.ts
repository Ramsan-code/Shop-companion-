import '../setup.js';

import { getFirestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { HttpsError, onCall, type CallableRequest } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';

import * as ledger from './handlers.js';

const ENTRY = 'shops/{shopId}/entries/{entryId}';
const callableOptions = { enforceAppCheck: process.env.FUNCTIONS_EMULATOR !== 'true' };

function caller(request: CallableRequest) {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in first.');
  return { uid: request.auth.uid, phone: request.auth.token.phone_number };
}

export const onEntryCreated = onDocumentCreated(ENTRY, async (event) => {
  await ledger.applyEntry(getFirestore(), event.params.shopId, event.params.entryId);
});

export const onEntryUpdated = onDocumentUpdated(ENTRY, async (event) => {
  const db = getFirestore();
  const { shopId, entryId } = event.params;
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after) return;
  await ledger.auditEntryEdit(db, shopId, entryId, event.id, before, after);
  // No-op when only `applied` changed (our own write), so this can't loop.
  await ledger.applyEntry(db, shopId, entryId);
});

type Data = Record<string, unknown>;

export const editEntry = onCall<Data>(callableOptions, (req) => ledger.editEntry(getFirestore(), caller(req), req.data));
export const deleteEntry = onCall<Data>(callableOptions, (req) =>
  ledger.deleteEntry(getFirestore(), caller(req), req.data),
);

export const reconcileBalances = onSchedule({ schedule: '30 2 * * *', timeZone: 'Asia/Colombo' }, async () => {
  const db = getFirestore();
  const shops = await db.collection('shops').select().get();
  let corrected = 0;
  for (const shop of shops.docs) corrected += await ledger.reconcileShop(db, shop.id);
  // Counts only: logs never contain names, phones or amounts (PRD 11).
  logger.info('reconcileBalances', { shops: shops.size, corrected });
});
