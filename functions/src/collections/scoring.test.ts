import { describe, expect, it } from 'vitest';

import {
  bandFor,
  type Candidate,
  colomboDay,
  DAY_MS,
  DEFAULT_NEW_CUSTOMER_LIMIT_CENTS,
  rankWhoToAsk,
  safeCreditLimit,
  type ScoredEntry,
  trustScore,
} from './scoring.js';

const NOW = Date.UTC(2026, 9, 1, 0, 30); // 06:00 Colombo, 1 Oct 2026
const ago = (days: number) => NOW - days * DAY_MS;
const credit = (rupees: number, daysAgo: number): ScoredEntry => ({ type: 'credit', amountCents: rupees * 100, txnMillis: ago(daysAgo) });
const pay = (rupees: number, daysAgo: number): ScoredEntry => ({ type: 'payment', amountCents: rupees * 100, txnMillis: ago(daysAgo) });

describe('trustScore (D1) — fixtures', () => {
  it('a long, regular, paid-up customer is excellent', () => {
    const r = trustScore({
      now: NOW,
      balanceCents: 0,
      oldestUnpaidMillis: null,
      entries: [credit(1000, 300), pay(1000, 280), credit(800, 80), pay(400, 60), pay(200, 40), pay(200, 20)],
    });
    expect(r).toEqual({
      score: 100,
      band: 'excellent',
      reasons: [
        { code: 'regularPayer', value: 3 },
        { code: 'paysMost', value: 100 },
        { code: 'longCustomer', value: 10 },
        { code: 'settled' },
      ],
    });
  });

  it('95 days overdue, no recent payment, small repayments: risky', () => {
    const r = trustScore({
      now: NOW,
      balanceCents: 450000,
      oldestUnpaidMillis: ago(95),
      entries: [credit(1500, 95), credit(1500, 70), credit(1500, 50)],
    });
    expect(r.band).toBe('risky');
    expect(r.score).toBe(5);
    expect(r.reasons[0]).toEqual({ code: 'overdue', value: 95 });
    expect(r.reasons.map((x) => x.code)).toEqual(['overdue', 'noRecentPayment', 'paysLittle']);
  });

  it('a new customer starts at the bottom of good, not judged on repayment yet', () => {
    const r = trustScore({ now: NOW, balanceCents: 30000, oldestUnpaidMillis: ago(3), entries: [credit(300, 3)] });
    expect(r).toEqual({ score: 60, band: 'good', reasons: [{ code: 'newCustomer' }] });
  });

  it('deleted entries never count', () => {
    const base = { now: NOW, balanceCents: 0, oldestUnpaidMillis: null };
    const withDeleted = trustScore({ ...base, entries: [{ ...credit(5000, 200), deletedAt: new Date() }] });
    expect(withDeleted).toEqual(trustScore({ ...base, entries: [] }));
  });

  it('bands', () => {
    expect([80, 79, 60, 59, 40, 39].map(bandFor)).toEqual(['excellent', 'good', 'good', 'watch', 'watch', 'risky']);
  });
});

describe('safeCreditLimit (D2)', () => {
  it('new customers get the shop default; risky new ones at most Rs. 500', () => {
    expect(safeCreditLimit({ now: NOW, band: 'good', entries: [credit(300, 2)] })).toBe(DEFAULT_NEW_CUSTOMER_LIMIT_CENTS);
    expect(safeCreditLimit({ now: NOW, band: 'risky', entries: [] })).toBe(50000);
    expect(safeCreditLimit({ now: NOW, band: 'good', entries: [], newCustomerLimitCents: 500000 })).toBe(500000);
  });

  it('scales a month of repayments or usual credit by band, rounded to Rs. 100', () => {
    const entries = [credit(1000, 80), credit(1200, 40), pay(1500, 60), pay(1500, 30), pay(1000, 10)];
    // Monthly paid = 4000/3 = 1333.33; usual credit = median(1000,1200)*2 = 2200 → 2200.
    expect(safeCreditLimit({ now: NOW, band: 'excellent', entries })).toBe(440000);
    expect(safeCreditLimit({ now: NOW, band: 'good', entries })).toBe(330000);
    expect(safeCreditLimit({ now: NOW, band: 'risky', entries })).toBe(110000);
  });

  it('never below Rs. 500 unless risky', () => {
    expect(safeCreditLimit({ now: NOW, band: 'watch', entries: [credit(50, 10), pay(50, 5)] })).toBe(50000);
  });
});

describe('rankWhoToAsk (D5)', () => {
  const cand = (over: Partial<Candidate> & { customerId: string }): Candidate => ({
    name: over.customerId,
    kinship: null,
    balanceCents: 100000,
    oldestUnpaidMillis: ago(10),
    payDay: null,
    score: 70,
    band: 'good',
    reasons: [],
    snoozedUntilMillis: null,
    lastContactMillis: null,
    ...over,
  });

  it('long overdue first, then balance; nothing owed, snoozed or just contacted are left out', () => {
    const ranked = rankWhoToAsk(
      [
        cand({ customerId: 'small-recent', balanceCents: 20000 }),
        cand({ customerId: 'old', oldestUnpaidMillis: ago(100), band: 'risky' }),
        cand({ customerId: 'big', balanceCents: 5_000_000 }),
        cand({ customerId: 'paid', balanceCents: 0 }),
        cand({ customerId: 'snoozed', snoozedUntilMillis: NOW + DAY_MS }),
        cand({ customerId: 'called', lastContactMillis: ago(1) }),
      ],
      NOW,
    );
    expect(ranked.map((r) => r.customerId)).toEqual(['old', 'big', 'small-recent']);
    expect(ranked[0]!.reason).toEqual({ code: 'overdue', value: 100 });
  });

  it('pay day today or in two days moves someone up, wrapping the month', () => {
    expect(colomboDay(NOW)).toBe(1);
    const ranked = rankWhoToAsk(
      [cand({ customerId: 'a', balanceCents: 300000 }), cand({ customerId: 'payday', payDay: 3 })],
      NOW,
    );
    expect(ranked[0]).toMatchObject({ customerId: 'payday', reason: { code: 'payDay', value: 3 } });
    const lastDay = Date.UTC(2026, 9, 30, 1);
    expect(rankWhoToAsk([cand({ customerId: 'x', payDay: 1 })], lastDay)[0]!.reason).toEqual({ code: 'payDay', value: 1 });
  });

  it('keeps at most the limit', () => {
    const many = Array.from({ length: 25 }, (_, i) => cand({ customerId: `c${i}` }));
    expect(rankWhoToAsk(many, NOW)).toHaveLength(10);
  });
});
