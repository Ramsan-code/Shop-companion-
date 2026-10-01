import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // One emulator is shared, so files must not clear each other's data.
    fileParallelism: false,
    testTimeout: 20_000,
    hookTimeout: 30_000,
  },
});
