import { FieldValue, type Firestore, Timestamp } from 'firebase-admin/firestore';

import type { EntryType } from '../ledger/balance.js';
import { averageMarginPercent, colomboDayRange, type DayTotals, dayTotals } from './closing.js';

const DATE = /^\d{4}-\d{2}-\d{2}$/;

/** The [n] calendar days before [date], newest first. */
function previousDates(date: string, n: number): string[] {
  const [y, m, d] = date.split('-').map(Number) as [number, number, number];
  return Array.from({ length: n }, (_, i) => new Date(Date.UTC(y, m - 1, d - i - 1)).toISOString().slice(0, 10));
}

/**
 * When anyone saves a cash count (dayClosings/{date}/counts/{uid}, which
 * works offline), rebuild that day's closing from the entries. The closing
 * holds profit, so only Owner/Partner can read it (PRD 6).
 */
export async function recordDayClosing(
  db: Firestore,
  shopId: string,
  date: string,
): Promise<(DayTotals & { countedCashCents: number | null; differenceCents: number | null }) | null> {
  if (!DATE.test(date)) return null;
  const shop = db.collection('shops').doc(shopId);
  const [start, end] = colomboDayRange(date);
  const [entries, counts, previous, shopDoc, items] = await Promise.all([
    shop
      .collection('entries')
      .where('txnDate', '>=', Timestamp.fromMillis(start))
      .where('txnDate', '<', Timestamp.fromMillis(end))
      .get(),
    shop.collection('dayClosings').doc(date).collection('counts').get(),
    // Firestore can't scan document IDs backwards, so look at the last week.
    db.getAll(...previousDates(date, 7).map((d) => shop.collection('dayClosings').doc(d))),
    shop.get(),
    shop.collection('items').select('costCents', 'priceCents').get(),
  ]);

  const opening =
    (previous.find((d) => typeof d.get('countedCashCents') === 'number')?.get('countedCashCents') as number | undefined) ??
    (shopDoc.get('settings.openingFloatCents') as number | undefined) ??
    0;
  const margin =
    (shopDoc.get('settings.marginPercent') as number | undefined) ??
    averageMarginPercent(items.docs.map((d) => ({ costCents: d.get('costCents'), priceCents: d.get('priceCents') })));
  const totals = dayTotals(
    entries.docs.map((d) => ({
      type: d.get('type') as EntryType,
      amountCents: d.get('amountCents') as number,
      method: (d.get('method') as string | undefined) ?? null,
      deletedAt: d.get('deletedAt') ?? null,
    })),
    opening,
    margin,
  );
  // The latest count wins (owner recounting after a helper, say).
  const latest = counts.docs
    .map((c) => ({ cents: c.get('countedCashCents') as number, at: (c.get('at') as Timestamp | undefined)?.toMillis() ?? 0, by: c.id }))
    .sort((a, b) => b.at - a.at)[0];
  const counted = latest?.cents ?? null;
  const closing = {
    ...totals,
    countedCashCents: counted,
    differenceCents: counted == null ? null : counted - totals.expectedCashCents,
  };
  await shop
    .collection('dayClosings')
    .doc(date)
    .set({ ...closing, countedBy: latest?.by ?? null, closedAt: FieldValue.serverTimestamp() });
  return closing;
}
