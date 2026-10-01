import { describe, expect, it } from 'vitest';

import { averageMarginPercent, colomboDayRange, dayTotals } from './closing.js';

describe('dayTotals (C5, D11 lite)', () => {
  it('cash in and out, credit separate, non-cash not in the drawer', () => {
    const t = dayTotals(
      [
        { type: 'sale', amountCents: 500000 },
        { type: 'sale', amountCents: 100000, method: 'lankaqr' },
        { type: 'credit', amountCents: 200000 },
        { type: 'payment', amountCents: 150000, method: 'cash' },
        { type: 'payment', amountCents: 50000, method: 'bank' },
        { type: 'expense', amountCents: 30000 },
        { type: 'purchase', amountCents: 120000, method: 'cash' },
        { type: 'sale', amountCents: 999999, deletedAt: new Date() },
      ],
      100000,
    );
    expect(t).toEqual({
      salesCents: 600000,
      creditCents: 200000,
      collectedCents: 200000,
      expensesCents: 30000,
      purchasesCents: 120000,
      openingCashCents: 100000,
      // 1000 + (5000 + 1500) − (300 + 1200) = 6000
      expectedCashCents: 600000,
      // 6000 × 15% − 300 = 600
      profitEstimateCents: 60000,
      marginPercent: 15,
    });
  });

  it('a quiet day: just the opening cash', () => {
    expect(dayTotals([], 25000).expectedCashCents).toBe(25000);
  });
});

describe('averageMarginPercent', () => {
  it('needs 3 priced items, else the 15% default', () => {
    expect(averageMarginPercent([{ costCents: 80, priceCents: 100 }])).toBe(15);
    expect(
      averageMarginPercent([
        { costCents: 80, priceCents: 100 },
        { costCents: 90, priceCents: 100 },
        { costCents: 70, priceCents: 100 },
        { costCents: null, priceCents: 100 },
      ]),
    ).toBe(20);
  });
});

it('colomboDayRange covers a Sri Lankan calendar day', () => {
  const [start, end] = colomboDayRange('2026-10-01');
  expect(new Date(start).toISOString()).toBe('2026-09-30T18:30:00.000Z');
  expect(end - start).toBe(86_400_000);
});
