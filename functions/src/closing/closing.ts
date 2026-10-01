import type { EntryType } from '../ledger/balance.js';

/**
 * Close Day (PRD C5, D11 lite, flow 7.1-5). Pure, and mirrored in Dart by
 * lib/features/close_day/domain/day_totals.dart so the phone can show the
 * same numbers offline before the server records them.
 */

export interface DayEntry {
  type: EntryType;
  amountCents: number;
  method?: string | null;
  deletedAt?: unknown;
}

export interface DayTotals {
  salesCents: number;
  /** Credit given today. */
  creditCents: number;
  /** Payments received today (all methods). */
  collectedCents: number;
  expensesCents: number;
  purchasesCents: number;
  openingCashCents: number;
  /** What should be in the drawer: opening + cash in − cash out. */
  expectedCashCents: number;
  /** Profit Mirror lite: sales × margin − expenses (purchases are stock, not cost). */
  profitEstimateCents: number;
  marginPercent: number;
}

/** Cash unless another method was recorded (old entries have none). */
const isCash = (e: DayEntry) => e.method == null || e.method === 'cash';

export const DEFAULT_MARGIN_PERCENT = 15;

export function dayTotals(entries: DayEntry[], openingCashCents: number, marginPercent = DEFAULT_MARGIN_PERCENT): DayTotals {
  const live = entries.filter((e) => e.deletedAt == null);
  const sum = (pred: (e: DayEntry) => boolean) => live.filter(pred).reduce((s, e) => s + e.amountCents, 0);
  const salesCents = sum((e) => e.type === 'sale');
  const creditCents = sum((e) => e.type === 'credit');
  const collectedCents = sum((e) => e.type === 'payment');
  const expensesCents = sum((e) => e.type === 'expense');
  const purchasesCents = sum((e) => e.type === 'purchase');
  const cashIn = sum((e) => (e.type === 'sale' || e.type === 'payment') && isCash(e));
  const cashOut = sum((e) => (e.type === 'expense' || e.type === 'purchase') && isCash(e));
  return {
    salesCents,
    creditCents,
    collectedCents,
    expensesCents,
    purchasesCents,
    openingCashCents,
    expectedCashCents: openingCashCents + cashIn - cashOut,
    profitEstimateCents: Math.round((salesCents * marginPercent) / 100) - expensesCents,
    marginPercent,
  };
}

/** Average margin from items with both a cost and a price, else the default. */
export function averageMarginPercent(items: { costCents?: number | null; priceCents?: number | null }[]): number {
  const priced = items.filter((i) => (i.costCents ?? 0) > 0 && (i.priceCents ?? 0) > (i.costCents ?? 0));
  if (priced.length < 3) return DEFAULT_MARGIN_PERCENT;
  const avg = priced.reduce((s, i) => s + (i.priceCents! - i.costCents!) / i.priceCents!, 0) / priced.length;
  return Math.round(avg * 100);
}

/** [start, end) in UTC millis of a Colombo calendar day "yyyy-mm-dd". */
export function colomboDayRange(date: string): [number, number] {
  const [y, m, d] = date.split('-').map(Number) as [number, number, number];
  const start = Date.UTC(y, m - 1, d) - 5.5 * 3_600_000;
  return [start, start + 86_400_000];
}
