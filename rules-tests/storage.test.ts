import { assertFails, assertSucceeds, type RulesTestEnvironment } from '@firebase/rules-unit-testing';
import { getBytes, ref, uploadBytes } from 'firebase/storage';
import { afterAll, beforeAll, describe, it } from 'vitest';

import { createEnv, seed, SHOP, storage } from './setup';

let env: RulesTestEnvironment;

beforeAll(async () => {
  env = await createEnv('demo-shop-companion');
  await env.clearFirestore();
  await env.clearStorage();
  await seed(env);
});

afterAll(async () => {
  await env?.cleanup();
});

const bytes = (n: number) => new Uint8Array(n);

describe('storage rules', () => {
  it('members upload receipts; outsiders cannot', async () => {
    const path = `shops/${SHOP}/receipts/r1.pdf`;
    await assertSucceeds(
      uploadBytes(ref(storage(env, 'helper'), path), bytes(100), { contentType: 'application/pdf' }),
    );
    await assertFails(
      uploadBytes(ref(storage(env, 'otherShopOwner'), `shops/${SHOP}/receipts/r2.pdf`), bytes(100), {
        contentType: 'application/pdf',
      }),
    );
    await assertFails(
      uploadBytes(ref(storage(env, 'removedHelper'), `shops/${SHOP}/receipts/r3.pdf`), bytes(100), {
        contentType: 'application/pdf',
      }),
    );
  });

  it('rejects wrong types and oversized files', async () => {
    const s = storage(env, 'owner');
    await assertFails(uploadBytes(ref(s, `shops/${SHOP}/receipts/x.exe`), bytes(10), { contentType: 'application/x-msdownload' }));
    await assertFails(
      uploadBytes(ref(s, `shops/${SHOP}/voice/big.m4a`), bytes(1024 * 1024 + 1), { contentType: 'audio/mp4' }),
    );
  });

  it('voice clips and exports are function-only to read', async () => {
    const s = storage(env, 'owner');
    await assertSucceeds(uploadBytes(ref(s, `shops/${SHOP}/voice/v1.m4a`), bytes(100), { contentType: 'audio/mp4' }));
    await assertFails(getBytes(ref(s, `shops/${SHOP}/voice/v1.m4a`)));
    await assertFails(getBytes(ref(s, `shops/${SHOP}/exports/e.xlsx`)));
  });
});
