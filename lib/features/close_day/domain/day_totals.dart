import 'package:equatable/equatable.dart';

import '../../ledger/domain/entry_type.dart';
import '../../ledger/domain/models.dart';

/// Profit Mirror lite's margin when the shop hasn't priced enough items.
const defaultMarginPercent = 15;

/// A day's numbers for Close Day (PRD C5, D11 lite, flow 7.1-5).
///
/// Mirrors `functions/src/closing/closing.ts`, so the phone shows the same
/// numbers offline that `onCashCounted` records once the count syncs.
class DayTotals extends Equatable {
  const DayTotals({
    this.salesCents = 0,
    this.creditCents = 0,
    this.collectedCents = 0,
    this.expensesCents = 0,
    this.purchasesCents = 0,
    this.openingCashCents = 0,
    this.expectedCashCents = 0,
    this.profitEstimateCents = 0,
    this.marginPercent = defaultMarginPercent,
  });

  factory DayTotals.of(
    Iterable<LedgerEntry> entries, {
    required int openingCashCents,
    int marginPercent = defaultMarginPercent,
  }) {
    final live = entries.where((e) => !e.isDeleted).toList();
    int sum(bool Function(LedgerEntry) test) =>
        live.where(test).fold(0, (total, e) => total + e.amountCents);
    // Cash unless another method was recorded (old entries have none).
    bool cash(LedgerEntry e) =>
        e.method == null || e.method == PaymentMethod.cash;

    final sales = sum((e) => e.type == EntryType.sale);
    final expenses = sum((e) => e.type == EntryType.expense);
    final cashIn = sum(
      (e) =>
          (e.type == EntryType.sale || e.type == EntryType.payment) && cash(e),
    );
    final cashOut = sum(
      (e) =>
          (e.type == EntryType.expense || e.type == EntryType.purchase) &&
          cash(e),
    );
    return DayTotals(
      salesCents: sales,
      creditCents: sum((e) => e.type == EntryType.credit),
      collectedCents: sum((e) => e.type == EntryType.payment),
      expensesCents: expenses,
      purchasesCents: sum((e) => e.type == EntryType.purchase),
      openingCashCents: openingCashCents,
      expectedCashCents: openingCashCents + cashIn - cashOut,
      // Purchases are stock, not cost; the margin stands in for cost of goods.
      profitEstimateCents: (sales * marginPercent / 100).round() - expenses,
      marginPercent: marginPercent,
    );
  }

  final int salesCents;
  final int creditCents;
  final int collectedCents;
  final int expensesCents;
  final int purchasesCents;
  final int openingCashCents;
  final int expectedCashCents;
  final int profitEstimateCents;
  final int marginPercent;

  @override
  List<Object?> get props => [
    salesCents,
    creditCents,
    collectedCents,
    expensesCents,
    purchasesCents,
    openingCashCents,
    expectedCashCents,
    profitEstimateCents,
    marginPercent,
  ];
}

/// Average margin of items with both a cost and a higher price; the default
/// until at least three items are priced. Same rule as the server.
int averageMarginPercent(Iterable<({int? costCents, int? priceCents})> items) {
  final priced = [
    for (final i in items)
      if ((i.costCents ?? 0) > 0 && (i.priceCents ?? 0) > (i.costCents ?? 0)) i,
  ];
  if (priced.length < 3) return defaultMarginPercent;
  final avg =
      priced.fold<double>(
        0,
        (s, i) => s + (i.priceCents! - i.costCents!) / i.priceCents!,
      ) /
      priced.length;
  return (avg * 100).round();
}

/// The `dayClosings/{date}` key for a calendar day: `2026-10-01`.
String dayKey(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';
