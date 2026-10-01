import { describe, expect, it } from 'vitest';

import { normalizeLkMobile } from './phone.js';

describe('normalizeLkMobile', () => {
  it.each(['0771234567', '771234567', '94771234567', '+94771234567', '+94 77 123 4567', '077-123-4567', '0094771234567'])(
    '%s → +94771234567',
    (input) => expect(normalizeLkMobile(input)).toBe('+94771234567'),
  );

  it.each(['0241234567', '+919876543210', '07712345', '', 'abc'])('rejects %s', (input) => {
    expect(normalizeLkMobile(input)).toBeNull();
  });
});
