import { defineConfig } from 'vitest/config';

// `npm test` runs pure unit tests; `npm run test:emulator` runs the
// *.emulator.test.ts files against the Firestore and Auth emulators.
const emulator = process.env.FIRESTORE_EMULATOR_HOST !== undefined;

export default defineConfig({
  test: {
    include: emulator ? ['src/**/*.emulator.test.ts'] : ['src/**/*.test.ts'],
    exclude: emulator ? [] : ['src/**/*.emulator.test.ts'],
    fileParallelism: false,
    testTimeout: 20_000,
  },
});
