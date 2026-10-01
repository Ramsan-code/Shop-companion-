import 'entry_type.dart';

/// How an entry moves a customer's balance. Positive = the customer owes.
///
/// Mirrors `functions/src/ledger/balance.ts`; the server is the source of
/// truth, and the app uses this only to show a pending balance before the
/// server confirms.
int balanceDelta(EntryType type, int amountCents) => switch (type) {
  EntryType.credit => amountCents,
  EntryType.payment || EntryType.discount => -amountCents,
  EntryType.sale || EntryType.expense || EntryType.purchase => 0,
};

/// Whether this type of entry belongs to a customer's account.
bool affectsCustomer(EntryType type) => balanceDelta(type, 1) != 0;
