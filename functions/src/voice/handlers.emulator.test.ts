import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { beforeAll, beforeEach, describe, expect, it } from 'vitest';

import { MAX_CLIP_BYTES, parseVoice, type VoiceDeps } from './handlers.js';
import type { RecognizeRequest, SpeechProvider } from './speech.js';

const PROJECT = 'demo-shop-companion';
if (getApps().length === 0) initializeApp({ projectId: PROJECT, storageBucket: `${PROJECT}.appspot.com` });
const db = getFirestore();
const bucket = getStorage().bucket();

const SHOP = 'shop1';
const CLIP = '0b4f8c2e-6a1d-4e5f-9b7a-3c2d1e0f9a8b';
const HELPER = { uid: 'helper1' };

class FakeSpeech implements SpeechProvider {
  requests: RecognizeRequest[] = [];
  fail = false;
  async recognize(request: RecognizeRequest) {
    this.requests.push(request);
    if (this.fail) throw new Error('quota');
    return { transcript: 'ரவி அண்ணை 500 கடன்', alternatives: ['ரவி அண்ணா 500 கடன்'], confidence: 0.9 };
  }
}

let speech: FakeSpeech;
let deps: VoiceDeps;
const clipPath = `shops/${SHOP}/voice/${CLIP}.amr`;

beforeAll(() => {
  if (!process.env.FIREBASE_STORAGE_EMULATOR_HOST) throw new Error('Run with `npm run test:emulator`.');
});

beforeEach(async () => {
  const host = process.env.FIRESTORE_EMULATOR_HOST!;
  await fetch(`http://${host}/emulator/v1/projects/${PROJECT}/databases/(default)/documents`, { method: 'DELETE' });
  const roles = JSON.parse(readFileSync(resolve(import.meta.dirname, '../../../seed/roles.json'), 'utf8'));
  for (const role of ['owner', 'helper']) await db.doc(`roles/${role}`).set({ permissions: roles[role].permissions });
  await db.doc(`shops/${SHOP}/members/${HELPER.uid}`).set({ role: 'helper', status: 'active' });
  await db.doc(`shops/${SHOP}/customers/ravi`).set({ name: 'Ravi' });
  await db.doc(`shops/${SHOP}/customers/kumar`).set({ name: 'குமார்' });
  await bucket.file(clipPath).save(Buffer.from('#!AMR-WB\n fake audio'), { contentType: 'audio/amr-wb' });
  speech = new FakeSpeech();
  deps = { db, file: (path) => bucket.file(path), speech };
});

const clipExists = async () => (await bucket.file(clipPath).exists())[0];

describe('parseVoice', () => {
  it('transcribes in ta-LK biased to the shop names, then deletes the clip', async () => {
    const result = await parseVoice(deps, HELPER, { shopId: SHOP, clipId: CLIP });
    expect(result).toEqual({ transcript: 'ரவி அண்ணை 500 கடன்', alternatives: ['ரவி அண்ணா 500 கடன்'] });
    expect(speech.requests[0]!.languageCode).toBe('ta-LK');
    expect(speech.requests[0]!.phrases.sort()).toEqual(['Ravi', 'குமார்'].sort());
    expect(speech.requests[0]!.audio.toString()).toContain('AMR-WB');
    expect(await clipExists()).toBe(false);
  });

  it('deletes the clip even when the speech service fails', async () => {
    speech.fail = true;
    await expect(parseVoice(deps, HELPER, { shopId: SHOP, clipId: CLIP })).rejects.toMatchObject({ code: 'unavailable' });
    expect(await clipExists()).toBe(false);
  });

  it('only members who can record entries, and only well-formed clip IDs', async () => {
    await expect(parseVoice(deps, { uid: 'stranger' }, { shopId: SHOP, clipId: CLIP })).rejects.toMatchObject({
      code: 'permission-denied',
    });
    await expect(parseVoice(deps, HELPER, { shopId: SHOP, clipId: '../../other/x' })).rejects.toMatchObject({
      code: 'invalid-argument',
    });
    expect(await clipExists()).toBe(true);
    expect(speech.requests).toHaveLength(0);
  });

  it('refuses a missing or oversized clip', async () => {
    await expect(
      parseVoice(deps, HELPER, { shopId: SHOP, clipId: '11111111-2222-4333-8444-555555555555' }),
    ).rejects.toMatchObject({ code: 'not-found' });
    await bucket.file(clipPath).save(Buffer.alloc(MAX_CLIP_BYTES + 1), { contentType: 'audio/amr-wb' });
    await expect(parseVoice(deps, HELPER, { shopId: SHOP, clipId: CLIP })).rejects.toMatchObject({ code: 'invalid-argument' });
    expect(await clipExists()).toBe(false);
  });
});
