import '../setup.js';

import { getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

import { parseVoice as handle } from './handlers.js';
import { GoogleSpeechProvider } from './speech.js';

const speech = new GoogleSpeechProvider();

export const parseVoice = onCall<Record<string, unknown>>(
  { enforceAppCheck: process.env.FUNCTIONS_EMULATOR !== 'true', memory: '512MiB', timeoutSeconds: 30 },
  (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in first.');
    const bucket = getStorage().bucket();
    return handle(
      { db: getFirestore(), file: (path) => bucket.file(path), speech },
      { uid: request.auth.uid, phone: request.auth.token.phone_number },
      request.data,
    );
  },
);
