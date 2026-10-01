import '../setup.js';

import { getFirestore } from 'firebase-admin/firestore';
import { getFunctions } from 'firebase-admin/functions';
import { logger } from 'firebase-functions';
import { defineSecret, defineString } from 'firebase-functions/params';
import { HttpsError, onCall, onRequest } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { onTaskDispatched } from 'firebase-functions/v2/tasks';

import { fcm } from '../collections/functions.js';
import { loadRemote } from '../config/remote.js';
import { PUBLIC_BASE_URL } from '../params.js';
import { REGION } from '../setup.js';
import { NotifyLkSms, WhatsAppCloudApi } from '../messaging/providers.js';
import { handleWhatsAppWebhook, verifySignature } from '../messaging/webhook.js';
import * as statements from '../statements/handlers.js';
import * as reminders from './handlers.js';

const WHATSAPP_PHONE_NUMBER_ID = defineString('WHATSAPP_PHONE_NUMBER_ID', { default: '' });
const WHATSAPP_TOKEN = defineSecret('WHATSAPP_TOKEN');
const WHATSAPP_APP_SECRET = defineSecret('WHATSAPP_APP_SECRET');
const WHATSAPP_VERIFY_TOKEN = defineSecret('WHATSAPP_VERIFY_TOKEN');
const SMS_USER_ID = defineString('SMS_USER_ID', { default: '' });
const SMS_SENDER_ID = defineString('SMS_SENDER_ID', { default: '' });
const SMS_API_KEY = defineSecret('SMS_API_KEY');

const callableOptions = { enforceAppCheck: process.env.FUNCTIONS_EMULATOR !== 'true' };

const enqueuer: reminders.Enqueuer = {
  async enqueue(task, at) {
    await getFunctions()
      .taskQueue(`locations/${REGION}/functions/sendReminder`)
      .enqueue(task, { scheduleTime: at });
  },
};

async function deps(): Promise<reminders.ReminderDeps> {
  return {
    templates: (await loadRemote()).templates,
    db: getFirestore(),
    enqueuer,
    whatsapp: new WhatsAppCloudApi(WHATSAPP_PHONE_NUMBER_ID.value(), WHATSAPP_TOKEN.value()),
    sms: new NotifyLkSms(SMS_USER_ID.value(), SMS_API_KEY.value(), SMS_SENDER_ID.value()),
    baseUrl: PUBLIC_BASE_URL.value(),
  };
}

function caller(uid: string | undefined) {
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in first.');
  return { uid };
}

/** 09:30 Colombo: plan today's reminders for shops that turned them on. */
export const scheduleReminders = onSchedule(
  { schedule: '30 9 * * *', timeZone: 'Asia/Colombo', timeoutSeconds: 540, secrets: [WHATSAPP_TOKEN, SMS_API_KEY] },
  async () => {
    const db = getFirestore();
    const shops = await db.collection('shops').where('settings.autoReminders', '==', true).select().get();
    let planned = 0;
    for (const shop of shops.docs) planned += await reminders.planShopReminders(await deps(), shop.id, Date.now());
    logger.info('scheduleReminders', { shops: shops.size, planned });
  },
);

export const sendReminder = onTaskDispatched<{ shopId: string; reminderId: string }>(
  {
    retryConfig: { maxAttempts: 3, minBackoffSeconds: 60 },
    rateLimits: { maxConcurrentDispatches: 5 },
    secrets: [WHATSAPP_TOKEN, SMS_API_KEY],
  },
  async (request) => {
    const status = await reminders.sendReminder(await deps(), request.data, Date.now());
    logger.info('sendReminder', { status });
  },
);

export const approveReminders = onCall<Record<string, unknown>>(callableOptions, (req) =>
  reminders.approveReminders({ db: getFirestore(), enqueuer }, caller(req.auth?.uid), req.data, Date.now()),
);

export const previewReminder = onCall<Record<string, unknown>>(callableOptions, async (req) =>
  reminders.previewReminder(
    { db: getFirestore(), baseUrl: PUBLIC_BASE_URL.value(), templates: (await loadRemote()).templates },
    caller(req.auth?.uid),
    req.data,
  ),
);

export const createStatement = onCall<Record<string, unknown>>(callableOptions, (req) =>
  statements.createStatement(
    { db: getFirestore(), baseUrl: PUBLIC_BASE_URL.value(), now: () => Date.now() },
    caller(req.auth?.uid),
    req.data,
  ),
);

/**
 * Public statement page API, served same-origin through Hosting:
 *   GET  /api/statement/{token}
 *   POST /api/statement/{token}/confirm
 *   POST /api/statement/{token}/dispute   {note?}
 */
export const statementApi = onRequest({ maxInstances: 10 }, async (req, res) => {
  const match = /\/api\/statement\/([\w-]+)(?:\/(confirm|dispute))?\/?$/.exec(req.path);
  res.set('Cache-Control', 'no-store');
  res.set('Referrer-Policy', 'no-referrer');
  if (!match) {
    res.status(404).json({ error: 'not-found' });
    return;
  }
  const [, token, action] = match;
  try {
    if (req.method === 'GET' && !action) {
      res.json(await statements.viewStatement(getFirestore(), token!, Date.now()));
    } else if (req.method === 'POST' && action) {
      const note = typeof req.body?.note === 'string' ? (req.body.note as string) : null;
      res.json(
        await statements.statementAction(
          { db: getFirestore(), push: fcm },
          token!,
          action as 'confirm' | 'dispute',
          note,
          Date.now(),
        ),
      );
    } else {
      res.status(405).json({ error: 'method' });
    }
  } catch (e) {
    if (e instanceof statements.StatementGone) {
      res.status(410).json({ error: 'gone' });
      return;
    }
    logger.error('statementApi', { error: (e as Error).name });
    res.status(500).json({ error: 'internal' });
  }
});

/** WhatsApp Cloud API webhook: verification handshake, then signed events. */
export const messagingWebhook = onRequest(
  { secrets: [WHATSAPP_APP_SECRET, WHATSAPP_VERIFY_TOKEN] },
  async (req, res) => {
    if (req.method === 'GET') {
      const ok = req.query['hub.mode'] === 'subscribe' && req.query['hub.verify_token'] === WHATSAPP_VERIFY_TOKEN.value();
      if (ok) res.status(200).send(String(req.query['hub.challenge'] ?? ''));
      else res.sendStatus(403);
      return;
    }
    if (!verifySignature(req.rawBody, req.get('x-hub-signature-256'), WHATSAPP_APP_SECRET.value())) {
      res.sendStatus(401);
      return;
    }
    const counts = await handleWhatsAppWebhook({ db: getFirestore(), push: fcm }, req.body, Date.now());
    logger.info('messagingWebhook', counts);
    res.sendStatus(200);
  },
);
