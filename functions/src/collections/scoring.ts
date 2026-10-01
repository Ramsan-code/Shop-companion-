import { balanceDelta, type EntryType } from '../ledger/balance.js';

/**
 * Collections Brain rules (PRD D1 Trust Score, D2 Safe Credit Limit, D5 Who
 * To Ask Today). Pure and rules-based on purpose: every number can be
 * explained to the shopkeeper and reproduced from the same entries.
 */

export const DAY_MS = 86_400_000;

export type Band = 'excellent' | 'good' | 'watch' | 'risky';

export type ReasonCode =
  | 'newCustomer'
  | 'overdue'
  | 'regularPayer'
  | 'noRecentPayment'
  | 'paysMost'
  | 'paysLittle'
  | 'highBalance'
  | 'longCustomer'
  | 'settled'
  | 'payDay';

/** Plain reason; the app turns the code into a Tamil or English sentence. */
export interface Reason {
  code: ReasonCode;
  value?: number;
}

export interface ScoredEntry {
  type: EntryType;
  amountCents: number;
  txnMillis: number;
  deletedAt?: unknown;
}

export interface TrustResult {
  score: number;
  band: Band;
  /** Most important first. */
  reasons: Reason[];
}

export function bandFor(score: number): Band {
  if (score >= 80) return 'excellent';
  if (score >= 60) return 'good';
  if (score >= 40) return 'watch';
  return 'risky';
}

/** Days since the oldest credit still unpaid (0 when nothing is owed). */
export function overdueDays(balanceCents: number, oldestUnpaidMillis: number | null, now: number): number {
  if (balanceCents <= 0 || oldestUnpaidMillis == null) return 0;
  return Math.max(0, Math.floor((now - oldestUnpaidMillis) / DAY_MS));
}

const live = (entries: ScoredEntry[]) =>
  entries.filter((e) => e.deletedAt == null && balanceDelta(e.type, e.amountCents) !== 0);

export function trustScore(input: {
  now: number;
  balanceCents: number;
  oldestUnpaidMillis: number | null;
  entries: ScoredEntry[];
}): TrustResult {
  const { now, balanceCents } = input;
  const entries = live(input.entries);
  const credits = entries.filter((e) => e.type === 'credit');
  const payments = entries.filter((e) => e.type === 'payment' || e.type === 'discount');
  const scored: { reason: Reason; delta: number }[] = [];
  const add = (delta: number, reason: Reason) => scored.push({ delta, reason });

  const firstMillis = Math.min(...entries.map((e) => e.txnMillis), now);
  const ageDays = Math.floor((now - firstMillis) / DAY_MS);
  // New customers start at the bottom of "good"; their protection is the
  // smaller new-customer credit limit, not a low score.
  const isNew = entries.length < 3 && ageDays < 30;
  if (isNew) add(-10, { code: 'newCustomer' });

  const overdue = overdueDays(balanceCents, input.oldestUnpaidMillis, now);
  if (overdue > 90) add(-45, { code: 'overdue', value: overdue });
  else if (overdue > 60) add(-30, { code: 'overdue', value: overdue });
  else if (overdue > 30) add(-15, { code: 'overdue', value: overdue });

  const recentPayments = payments.filter((e) => e.type === 'payment' && now - e.txnMillis <= 90 * DAY_MS);
  const hasOldCredit = credits.some((e) => now - e.txnMillis > 30 * DAY_MS);
  if (recentPayments.length >= 3) add(10, { code: 'regularPayer', value: recentPayments.length });
  else if (recentPayments.length === 0 && balanceCents > 0 && hasOldCredit) add(-10, { code: 'noRecentPayment' });

  const within180 = (e: ScoredEntry) => now - e.txnMillis <= 180 * DAY_MS;
  const credit180 = credits.filter(within180).reduce((s, e) => s + e.amountCents, 0);
  const paid180 = payments.filter(within180).reduce((s, e) => s + e.amountCents, 0);
  // Too early to judge repayment for a new customer.
  if (credit180 > 0 && !isNew) {
    const ratio = paid180 / credit180;
    if (ratio >= 0.8) add(10, { code: 'paysMost', value: Math.round(ratio * 100) });
    else if (ratio < 0.3) add(-10, { code: 'paysLittle', value: Math.round(ratio * 100) });
  }

  const avgCredit = credits.length ? credits.reduce((s, e) => s + e.amountCents, 0) / credits.length : 0;
  if (avgCredit > 0 && balanceCents > 3 * avgCredit) add(-10, { code: 'highBalance' });

  if (ageDays >= 180) add(5, { code: 'longCustomer', value: Math.floor(ageDays / 30) });
  if (balanceCents <= 0 && credits.length > 0) add(5, { code: 'settled' });

  const score = Math.max(0, Math.min(100, 70 + scored.reduce((s, x) => s + x.delta, 0)));
  const reasons = scored.sort((a, b) => Math.abs(b.delta) - Math.abs(a.delta)).map((x) => x.reason);
  return { score, band: bandFor(score), reasons };
}

const MULTIPLIER: Record<Band, number> = { excellent: 2, good: 1.5, watch: 1, risky: 0.5 };

/** Default for customers with no payment history yet (shop setting). */
export const DEFAULT_NEW_CUSTOMER_LIMIT_CENTS = 200_000;
const FLOOR_CENTS = 50_000;

function median(values: number[]): number {
  if (values.length === 0) return 0;
  const sorted = [...values].sort((a, b) => a - b);
  const mid = Math.floor(sorted.length / 2);
  return sorted.length % 2 ? sorted[mid]! : (sorted[mid - 1]! + sorted[mid]!) / 2;
}

/**
 * Safe Credit Limit (D2): how much this customer can owe in total. Based on
 * what they actually repay (a month's payments) or their usual credit, scaled
 * by their band, rounded to Rs. 100.
 */
export function safeCreditLimit(input: {
  now: number;
  band: Band;
  entries: ScoredEntry[];
  newCustomerLimitCents?: number;
}): number {
  const entries = live(input.entries);
  const payments = entries.filter((e) => e.type === 'payment');
  const newLimit = input.newCustomerLimitCents ?? DEFAULT_NEW_CUSTOMER_LIMIT_CENTS;
  if (payments.length === 0) {
    return input.band === 'risky' ? Math.min(newLimit, FLOOR_CENTS) : newLimit;
  }
  const monthlyPaid =
    payments.filter((e) => input.now - e.txnMillis <= 90 * DAY_MS).reduce((s, e) => s + e.amountCents, 0) / 3;
  const usualCredit = median(entries.filter((e) => e.type === 'credit').map((e) => e.amountCents)) * 2;
  const raw = Math.max(monthlyPaid, usualCredit) * MULTIPLIER[input.band];
  const rounded = Math.round(raw / 10_000) * 10_000;
  return input.band === 'risky' ? rounded : Math.max(FLOOR_CENTS, rounded);
}

export interface Candidate {
  customerId: string;
  name: string;
  kinship: string | null;
  balanceCents: number;
  oldestUnpaidMillis: number | null;
  payDay: number | null;
  score: number | null;
  band: Band | null;
  reasons: Reason[];
  snoozedUntilMillis: number | null;
  lastContactMillis: number | null;
}

export interface WhoToAskItem {
  customerId: string;
  name: string;
  kinship: string | null;
  balanceCents: number;
  band: Band | null;
  score: number | null;
  reason: Reason | null;
  priority: number;
}

/** Colombo calendar day-of-month for [millis] (UTC+05:30, no DST). */
export function colomboDay(millis: number): number {
  return new Date(millis + 5.5 * 3_600_000).getUTCDate();
}

/** Today or within the next 2 days, wrapping round the month end. */
function payDaySoon(payDay: number | null, now: number): boolean {
  if (payDay == null) return false;
  for (let d = 0; d <= 2; d++) if (colomboDay(now + d * DAY_MS) === payDay) return true;
  return false;
}

/**
 * Who To Ask Today (D5, US2): up to [limit] people who owe, most worth asking
 * first: long overdue, larger balances, pay day now, weaker trust band.
 * Skips the snoozed and anyone contacted in the last 2 days.
 */
export function rankWhoToAsk(candidates: Candidate[], now: number, limit = 10): WhoToAskItem[] {
  const items: WhoToAskItem[] = [];
  for (const c of candidates) {
    if (c.balanceCents <= 0) continue;
    if (c.snoozedUntilMillis != null && c.snoozedUntilMillis > now) continue;
    if (c.lastContactMillis != null && now - c.lastContactMillis < 2 * DAY_MS) continue;
    const overdue = overdueDays(c.balanceCents, c.oldestUnpaidMillis, now);
    const payDay = payDaySoon(c.payDay, now);
    const priority =
      (Math.min(overdue, 120) / 120) * 50 +
      (Math.log10(c.balanceCents / 100 + 1) / 5) * 30 +
      (payDay ? 20 : 0) +
      (c.band === 'risky' ? 10 : c.band === 'watch' ? 5 : 0);
    const reason: Reason | null = payDay
      ? { code: 'payDay', value: c.payDay! }
      : overdue > 30
        ? { code: 'overdue', value: overdue }
        : (c.reasons[0] ?? null);
    items.push({
      customerId: c.customerId,
      name: c.name,
      kinship: c.kinship,
      balanceCents: c.balanceCents,
      band: c.band,
      score: c.score,
      reason,
      priority: Math.round(priority * 10) / 10,
    });
  }
  return items.sort((a, b) => b.priority - a.priority || b.balanceCents - a.balanceCents).slice(0, limit);
}
