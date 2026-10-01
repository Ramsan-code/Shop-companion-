import '../setup.js';

import firestoreAdmin from '@google-cloud/firestore';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { logger } from 'firebase-functions';
import { defineString } from 'firebase-functions/params';
import { HttpsError, onCall, type CallableRequest } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';

import { backupPrefix, expiredBackups } from './backup.js';
import * as data from './handlers.js';

/** Bucket for nightly Firestore exports, e.g. `shop-companion-prod-backups`. */
const BACKUP_BUCKET = defineString('BACKUP_BUCKET', { default: '' });

const callableOptions = { enforceAppCheck: process.env.FUNCTIONS_EMULATOR !== 'true' };

const files: data.FileStore = {
  async save(path, bytes, contentType) {
    await getStorage().bucket().file(path).save(bytes, { contentType, resumable: false });
  },
  async deletePrefix(prefix) {
    await getStorage().bucket().deleteFiles({ prefix });
  },
};

function deps(): data.DataDeps {
  return { db: getFirestore(), auth: getAuth(), files, now: () => new Date() };
}

function caller(request: CallableRequest) {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in first.');
  return { uid: request.auth.uid };
}

type Data = Record<string, unknown>;

export const exportShop = onCall<Data>({ ...callableOptions, memory: '1GiB', timeoutSeconds: 300 }, (req) =>
  data.exportShop(deps(), caller(req), req.data),
);
export const eraseCustomer = onCall<Data>(callableOptions, (req) => data.eraseCustomer(deps(), caller(req), req.data));
export const deleteShop = onCall<Data>({ ...callableOptions, timeoutSeconds: 540 }, (req) =>
  data.deleteShop(deps(), caller(req), req.data),
);
export const deleteMyAccount = onCall<Data>(callableOptions, (req) => data.deleteMyAccount(deps(), caller(req)));

/** 02:30 Colombo: export the whole database; drop exports older than 30 days. */
export const dailyBackup = onSchedule({ schedule: '30 2 * * *', timeZone: 'Asia/Colombo', timeoutSeconds: 540 }, async () => {
  const project = process.env.GCLOUD_PROJECT ?? '';
  const bucket = BACKUP_BUCKET.value() || `${project}-backups`;
  const now = new Date();
  const client = new firestoreAdmin.v1.FirestoreAdminClient();
  const [operation] = await client.exportDocuments({
    name: client.databasePath(project, '(default)'),
    outputUriPrefix: `gs://${bucket}/${backupPrefix(now).replace(/\/$/, '')}`,
    collectionIds: [],
  });
  logger.info('dailyBackup started', { operation: operation.name });

  const [, , response] = await getStorage().bucket(bucket).getFiles({ prefix: 'backups/', delimiter: '/', autoPaginate: false });
  const prefixes = ((response as { prefixes?: string[] } | undefined)?.prefixes) ?? [];
  for (const prefix of expiredBackups(prefixes, now)) {
    await getStorage().bucket(bucket).deleteFiles({ prefix });
  }
});
