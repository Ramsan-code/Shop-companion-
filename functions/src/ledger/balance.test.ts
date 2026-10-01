import { describe, expect, it } from 'vitest';

import { balanceChanges, balanceDelta, desiredApplication, NOTHING_APPLIED, recomputeBalance } from './balance.js';

describe('balanceDelta', () => {
  it('credit raises, payment and discount lower, the rest do nothing', () => {
    expect(balanceDelta('credit', 500)).toBe(500);
    expect(balanceDelta('payment', 500)).toBe(-500);
    expect(balanceDelta('discount', 500)).toBe(-500);
    for (const t of ['sale', 'expense', 'purchase'] as const) expect(balanceDelta(t, 500)).toBe(0);
  });
});

describe('desiredApplication', () => {
  it('nothing for deleted entries or entries without a customer', () => {
    expect(desiredApplication({ type: 'credit', amountCents: 5, customerId: 'c', deletedAt: new Date() })).toEqual(NOTHING_APPLIED);
    expect(desiredApplication({ type: 'credit', amountCents: 5 })).toEqual(NOTHING_APPLIED);
    expect(desiredApplication({ type: 'credit', amountCents: 5, customerId: 'c' })).toEqual({ customerId: 'c', deltaCents: 5 });
  });
});

describe('balanceChanges', () => {
  it('applies the difference only', () => {
    expect(balanceChanges({ customerId: 'a', deltaCents: 500 }, { customerId: 'a', deltaCents: 700 })).toEqual(new Map([['a', 200]]));
    expect(balanceChanges({ customerId: 'a', deltaCents: 500 }, { customerId: 'a', deltaCents: 500 }).size).toBe(0);
  });

  it('moves an entry between customers', () => {
    expect(balanceChanges({ customerId: 'a', deltaCents: 500 }, { customerId: 'b', deltaCents: 500 })).toEqual(
      new Map([
        ['a', -500],
        ['b', 500],
      ]),
    );
  });

  it('reverses a deleted entry', () => {
    expect(balanceChanges({ customerId: 'a', deltaCents: -300 }, NOTHING_APPLIED)).toEqual(new Map([['a', 300]]));
  });
});

describe('recomputeBalance', () => {
  const day = (d: number) => Date.UTC(2026, 9, d);
  const e = (type: 'credit' | 'payment' | 'discount', amountCents: number, d: number, deleted = false) => ({
    type,
    amountCents,
    customerId: 'c',
    txnMillis: day(d),
    deletedAt: deleted ? new Date() : null,
  });

  it('pays the oldest credit first', () => {
    const result = recomputeBalance([e('credit', 500, 1), e('credit', 300, 5), e('payment', 600, 7)]);
    expect(result).toEqual({ balanceCents: 200, oldestUnpaidMillis: day(5) });
  });

  it('ignores deleted entries and sorts back-dated ones', () => {
    const result = recomputeBalance([e('payment', 100, 9), e('credit', 400, 2), e('credit', 999, 1, true)]);
    expect(result).toEqual({ balanceCents: 300, oldestUnpaidMillis: day(2) });
  });

  it('has no unpaid date when settled or in credit', () => {
    expect(recomputeBalance([e('credit', 500, 1), e('payment', 400, 2), e('discount', 100, 3)])).toEqual({
      balanceCents: 0,
      oldestUnpaidMillis: null,
    });
    expect(recomputeBalance([e('payment', 100, 1)]).oldestUnpaidMillis).toBeNull();
  });
});
