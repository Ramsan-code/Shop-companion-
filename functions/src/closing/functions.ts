import '../setup.js';

import { getFirestore } from 'firebase-admin/firestore';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';

import { recordDayClosing } from './handlers.js';

/** A cash count was saved (possibly offline, synced later): record the day. */
export const onCashCounted = onDocumentWritten('shops/{shopId}/dayClosings/{date}/counts/{uid}', async (event) => {
  if (!event.data?.after.exists) return;
  await recordDayClosing(getFirestore(), event.params.shopId, event.params.date);
});
