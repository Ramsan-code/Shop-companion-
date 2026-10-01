/**
 * How each ledger entry moves a customer's balance (PRD 10.1). Positive
 * balance = the customer owes the shop. Mirrored in Dart by
 * lib/features/ledger/domain/ledger_math.dart for the pending balance the app
 * shows before the server confirms.
 */

export type EntryType = 'credit' | 'payment' | 'sale' | 'expense' | 'purchase' | 'discount';

export interface EntryLike {
  type: EntryType;
  amountCents: number;
  customerId?: string | null;
  deletedAt?: unknown;
}

/** The balance change an entry applies, and to which customer. */
export interface Applied {
  customerId: string | null;
  deltaCents: number;
}

export const NOTHING_APPLIED: Applied = { customerId: null, deltaCents: 0 };

export function balanceDelta(type: EntryType, amountCents: number): number {
  switch (type) {
    case 'credit':
      return amountCents;
    case 'payment':
    case 'discount':
      return -amountCents;
    // Cash sales, expenses and purchases don't touch a customer's account.
    case 'sale':
    case 'expense':
    case 'purchase':
      return 0;
  }
}

/** What an entry should currently contribute; deleted entries contribute nothing. */
export function desiredApplication(entry: EntryLike): Applied {
  if (entry.deletedAt != null || !entry.customerId) return NOTHING_APPLIED;
  const deltaCents = balanceDelta(entry.type, entry.amountCents);
  return deltaCents === 0 ? NOTHING_APPLIED : { customerId: entry.customerId, deltaCents };
}

export function sameApplication(a: Applied, b: Applied): boolean {
  return a.customerId === b.customerId && a.deltaCents === b.deltaCents;
}

/**
 * Per-customer balance changes that move an entry from `from` to `to`.
 * Moving an entry between customers reverses it on one and applies it to
 * the other.
 */
export function balanceChanges(from: Applied, to: Applied): Map<string, number> {
  const changes = new Map<string, number>();
  const add = (id: string | null, delta: number) => {
    if (!id || delta === 0) return;
    changes.set(id, (changes.get(id) ?? 0) + delta);
  };
  add(from.customerId, -from.deltaCents);
  add(to.customerId, to.deltaCents);
  for (const [id, delta] of changes) if (delta === 0) changes.delete(id);
  return changes;
}

export interface DatedEntry extends EntryLike {
  txnMillis: number;
}

/**
 * Exact balance and the date of the oldest credit not yet paid off, paying
 * credits off oldest first (used by the nightly reconciliation and, later,
 * by the Trust Score's "days overdue").
 */
export function recomputeBalance(entries: DatedEntry[]): { balanceCents: number; oldestUnpaidMillis: number | null } {
  const sorted = [...entries].sort((a, b) => a.txnMillis - b.txnMillis);
  const openCredits: { millis: number; remaining: number }[] = [];
  let credit = 0;
  let balance = 0;
  for (const e of sorted) {
    const { deltaCents } = desiredApplication(e);
    if (deltaCents === 0) continue;
    balance += deltaCents;
    if (deltaCents > 0) {
      openCredits.push({ millis: e.txnMillis, remaining: deltaCents });
    } else {
      credit += -deltaCents;
      while (credit > 0 && openCredits.length > 0) {
        const first = openCredits[0]!;
        const used = Math.min(first.remaining, credit);
        first.remaining -= used;
        credit -= used;
        if (first.remaining === 0) openCredits.shift();
      }
    }
  }
  return { balanceCents: balance, oldestUnpaidMillis: balance > 0 ? (openCredits[0]?.millis ?? null) : null };
}
