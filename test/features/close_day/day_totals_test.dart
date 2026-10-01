import 'package:flutter_test/flutter_test.dart';
import 'package:shop_companion/features/close_day/data/close_day_repositories.dart';
import 'package:shop_companion/features/close_day/domain/day_totals.dart';
import 'package:shop_companion/features/ledger/domain/entry_type.dart';
import 'package:shop_companion/features/ledger/domain/models.dart';

LedgerEntry e(
  EntryType type,
  int rupees, {
  PaymentMethod? method,
  bool deleted = false,
}) => LedgerEntry(
  id: '$type$rupees',
  type: type,
  amountCents: rupees * 100,
  txnDate: DateTime(2026, 10, 1, 10),
  createdBy: 'u',
  method: method,
  deletedAt: deleted ? DateTime(2026, 10, 1, 11) : null,
);

void main() {
  // Same case as functions/src/closing/closing.test.ts, so the phone and
  // the server agree.
  test('totals, expected cash and Profit Mirror match the server', () {
    final t = DayTotals.of([
      e(EntryType.sale, 2000),
      e(EntryType.sale, 1000, method: PaymentMethod.lankaqr),
      e(EntryType.payment, 500, method: PaymentMethod.cash),
      e(EntryType.credit, 700),
      e(EntryType.expense, 300),
      e(EntryType.purchase, 1000, method: PaymentMethod.bank),
      e(EntryType.sale, 9999, deleted: true),
    ], openingCashCents: 50000);
    expect(
      t,
      const DayTotals(
        salesCents: 300000,
        creditCents: 70000,
        collectedCents: 50000,
        expensesCents: 30000,
        purchasesCents: 100000,
        openingCashCents: 50000,
        // 500 + 2000 (cash sale) + 500 (cash payment) − 300 (cash expense)
        expectedCashCents: 270000,
        // 15 % of 3000 − 300; stock bought isn't a cost here
        profitEstimateCents: 15000,
      ),
    );
  });

  test('a loss shows as a negative estimate', () {
    final t = DayTotals.of([
      e(EntryType.sale, 1000),
      e(EntryType.expense, 400),
    ], openingCashCents: 0);
    expect(t.profitEstimateCents, -25000);
  });

  test('margin from priced items needs at least three', () {
    expect(
      averageMarginPercent([
        (costCents: 8000, priceCents: 10000),
        (costCents: 8000, priceCents: 10000),
      ]),
      defaultMarginPercent,
    );
    expect(
      averageMarginPercent([
        (costCents: 8000, priceCents: 10000),
        (costCents: 7500, priceCents: 10000),
        (costCents: 8500, priceCents: 10000),
        (costCents: null, priceCents: 10000),
      ]),
      20,
    );
  });

  test('day keys and the week before', () {
    expect(dayKey(DateTime(2026, 3, 1, 23, 59)), '2026-03-01');
    expect(previousDays('2026-03-01', 2), ['2026-02-28', '2026-02-27']);
  });
}
