import '../setup.js';

import { getFirestore } from 'firebase-admin/firestore';
import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { HttpsError, onCall, type CallableRequest } from 'firebase-functions/v2/https';

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
