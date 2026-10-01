import '../setup.js';

import { getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { logger } from 'firebase-functions';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';

import * as collections from './handlers.js';

const DEAD_TOKEN = new Set(['messaging/registration-token-not-registered', 'messaging/invalid-registration-token']);

/** Firebase Cloud Messaging; returns tokens FCM says no longer exist. */
export const fcm: collections.Pusher = {
  async send(tokens, message) {
    const response = await getMessaging().sendEachForMulticast({
      tokens,
      notification: { title: message.title, body: message.body },
      data: message.data,
      android: { priority: 'high' },
    });
    return response.responses.flatMap((r, i) => (!r.success && DEAD_TOKEN.has(r.error?.code ?? '') ? [tokens[i]!] : []));
  },
};

/** 02:30 Colombo: reconcile balances, then Trust Scores and Safe Credit Limits. */
export const recalcTrustScores = onSchedule(
  { schedule: '30 2 * * *', timeZone: 'Asia/Colombo', timeoutSeconds: 540, memory: '512MiB' },
  async () => {
    const db = getFirestore();
    const shops = await db.collection('shops').select().get();
    let corrected = 0;
    let scored = 0;
    for (const shop of shops.docs) {
      const r = await collections.nightlyShop(db, shop.id, Date.now());
      corrected += r.corrected;
      scored += r.scored;
    }
    // Counts only: logs never contain names, phones or amounts (PRD 11).
    logger.info('recalcTrustScores', { shops: shops.size, corrected, scored });
  },
);

/** 06:00 Colombo (PRD US2): the morning list and its push. */
export const buildWhoToAsk = onSchedule(
  { schedule: '0 6 * * *', timeZone: 'Asia/Colombo', timeoutSeconds: 540 },
  async () => {
    const db = getFirestore();
    const shops = await db.collection('shops').select().get();
    let failed = 0;
    for (const shop of shops.docs) {
      try {
        await collections.buildWhoToAskForShop({ db, push: fcm }, shop.id, Date.now());
      } catch (e) {
        failed++;
        logger.error('buildWhoToAsk shop failed', { error: (e as Error).name });
      }
    }
    logger.info('buildWhoToAsk', { shops: shops.size, failed });
  },
);

export const overrideLimit = onCall<Record<string, unknown>>(
  { enforceAppCheck: process.env.FUNCTIONS_EMULATOR !== 'true' },
  (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in first.');
    return collections.overrideLimit(getFirestore(), { uid: request.auth.uid }, request.data);
  },
);
