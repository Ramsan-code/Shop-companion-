import type { Firestore } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';

import { type Caller, requirePermission } from '../members/handlers.js';
import type { SpeechProvider } from './speech.js';

/** Matches storage.rules: voice clips are at most 1 MB. */
export const MAX_CLIP_BYTES = 1024 * 1024;
const CLIP_ID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;

/** The parts of a Cloud Storage file this needs (a fake in tests). */
export interface StoredFile {
  exists(): Promise<[boolean, ...unknown[]]>;
  getMetadata(): Promise<[{ size?: string | number }, ...unknown[]]>;
  download(): Promise<[Buffer, ...unknown[]]>;
  delete(options?: { ignoreNotFound?: boolean }): Promise<unknown>;
}

export interface VoiceDeps {
  db: Firestore;
  file: (path: string) => StoredFile;
  speech: SpeechProvider;
}

/**
 * parseVoice (PRD 10.3): cloud fallback for phones with no Tamil recogniser.
 * Transcribes the uploaded clip, biased to this shop's customer names, and
 * deletes it straight away (PDPA: voice is kept only as long as needed).
 *
 * Returns the transcript only. The app parses it with the same parser it
 * uses on-device, so there is one parser to keep right, not two.
 */
export async function parseVoice(
  deps: VoiceDeps,
  caller: Caller,
  data: { shopId?: unknown; clipId?: unknown },
): Promise<{ transcript: string; alternatives: string[] }> {
  const shopId = typeof data.shopId === 'string' ? data.shopId : '';
  const clipId = typeof data.clipId === 'string' ? data.clipId : '';
  if (!shopId || !CLIP_ID.test(clipId)) throw new HttpsError('invalid-argument', 'shopId and clipId are required.');
  await requirePermission(deps.db, shopId, caller.uid, 'ledger:create');

  const file = deps.file(`shops/${shopId}/voice/${clipId}.amr`);
  const [exists] = await file.exists();
  if (!exists) throw new HttpsError('not-found', 'Clip not uploaded.');
  try {
    const [metadata] = await file.getMetadata();
    if (Number(metadata.size ?? 0) > MAX_CLIP_BYTES) throw new HttpsError('invalid-argument', 'Clip too long.');
    const [audio] = await file.download();
    const customers = await deps.db.collection(`shops/${shopId}/customers`).select('name').limit(500).get();
    const phrases = customers.docs.map((d) => d.get('name') as string | undefined).filter((n): n is string => !!n);
    try {
      const result = await deps.speech.recognize({ audio, languageCode: 'ta-LK', phrases });
      return { transcript: result.transcript, alternatives: result.alternatives };
    } catch (e) {
      if (e instanceof HttpsError) throw e;
      throw new HttpsError('unavailable', 'Speech service unavailable.');
    }
  } finally {
    await file.delete({ ignoreNotFound: true });
  }
}
