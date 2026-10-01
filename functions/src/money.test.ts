import { describe, expect, it } from 'vitest';

import { formatLkr } from './money.js';

describe('formatLkr', () => {
  it('drops .00 and groups thousands', () => {
    expect(formatLkr(150000)).toBe('Rs. 1,500');
    expect(formatLkr(1234567890)).toBe('Rs. 12,345,678.90');
    expect(formatLkr(5)).toBe('Rs. 0.05');
    expect(formatLkr(-2500)).toBe('-Rs. 25');
  });

  it('refuses non-integer cents', () => {
    expect(() => formatLkr(10.5)).toThrow(RangeError);
  });
});
