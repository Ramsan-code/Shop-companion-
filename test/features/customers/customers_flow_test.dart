import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_companion/core/rbac/role.dart';
import 'package:shop_companion/features/ledger/data/in_memory_ledger_repository.dart';
import 'package:shop_companion/features/ledger/domain/entry_type.dart';
import 'package:shop_companion/features/ledger/domain/models.dart';
import 'package:shop_companion/features/ledger/presentation/receipt.dart';

import '../../helpers.dart';

void main() {
  final day = DateTime(2026, 10, 1, 12);

  InMemoryLedgerRepository shop({bool autoApply = true}) {
    final repo = InMemoryLedgerRepository(
      // Entries authored by someone other than the signed-in test user.
      uid: 'owner-1',
      autoApply: autoApply,
      customers: const [
        Customer(
          id: 'ravi',
          name: 'Ravi',
          kinship: Kinship.annai,
          village: 'Nedunkerny',
        ),
        Customer(id: 'selvi', name: 'Selvi', kinship: Kinship.akka),
      ],
    );
    repo.addEntry(
      'fake-shop',
      EntryDraft(
        type: EntryType.credit,
        amountCents: 50000,
        customerId: 'ravi',
        txnDate: day,
      ),
    );
    repo.addEntry(
      'fake-shop',
      EntryDraft(
        type: EntryType.credit,
        amountCents: 240000,
        customerId: 'selvi',
        txnDate: day,
      ),
    );
    return repo;
  }

  Future<void> openCustomers(WidgetTester tester, TestApp app) async {
    await app.signInUnlocked(tester, Role.owner);
    await tester.tap(find.text('வாடிக்கையாளர்').last);
    await tester.pumpAndSettle();
  }

  testWidgets('list shows highest dues first, with Tamil kinship terms', (
    tester,
  ) async {
    final app = TestApp(ledger: shop());
    await app.pump(tester);
    await openCustomers(tester, app);

    final selvi = tester.getTopLeft(find.text('Selvi அக்கா'));
    final ravi = tester.getTopLeft(find.text('Ravi அண்ணை'));
    expect(selvi.dy, lessThan(ravi.dy));
    expect(find.text('Rs. 2,400.00'), findsOneWidget);
    expect(find.text('Rs. 500.00'), findsOneWidget);
  });

  testWidgets(
    'add a customer, give credit, take a partial payment with receipt',
    (tester) async {
      final app = TestApp(ledger: shop());
      await app.pump(tester);
      await openCustomers(tester, app);

      await tester.tap(find.text('வாடிக்கையாளரைச் சேர்'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('customer-name')),
        'Kumar',
      );
      await tester.tap(find.text('தம்பி'));
      await tester.ensureVisible(find.text('சேமி'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('சேமி'));
      await tester.pumpAndSettle();
      expect(find.text('Kumar தம்பி'), findsOneWidget);

      await tester.tap(find.text('Kumar தம்பி'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('கடன் கொடு'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('entry-amount')),
        '1,500',
      );
      await tester.ensureVisible(find.byKey(const ValueKey('entry-save')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('entry-save')));
      await tester.pumpAndSettle();
      expect(find.text('Rs. 1,500.00'), findsWidgets);

      await tester.tap(find.text('பணம் பெற்றதைப் பதி'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('entry-amount')),
        '1000',
      );
      await tester.pump();
      await tester.tap(find.text('வங்கி'));
      await tester.ensureVisible(find.byKey(const ValueKey('entry-save')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('entry-save')));
      await tester.pumpAndSettle();

      // Receipt with the new balance.
      expect(find.byType(ReceiptCard), findsOneWidget);
      expect(find.text('Rs. 1,000.00'), findsWidgets);
      expect(find.text('வங்கி'), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('receipt-close')));
      await tester.pumpAndSettle();
      expect(find.text('Rs. 500.00'), findsWidgets);
    },
  );

  testWidgets('owner settles with a discount', (tester) async {
    final app = TestApp(ledger: shop());
    await app.pump(tester);
    await openCustomers(tester, app);
    await tester.tap(find.text('Ravi அண்ணை'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('பணம் பெற்றதைப் பதி'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('entry-amount')), '450');
    await tester.pump();
    await tester.tap(
      find.text('மீதி Rs. 50.00 ஐத் தள்ளுபடி செய்து கணக்கை முடி'),
    );
    await tester.ensureVisible(find.byKey(const ValueKey('entry-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('entry-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('receipt-close')));
    await tester.pumpAndSettle();

    expect(find.text('தீர்ந்தது'), findsOneWidget); // settled
    expect(find.text('தள்ளுபடி  Rs. 50.00'), findsOneWidget);
  });

  testWidgets(
    'offline: balance and badge show pending until the server confirms',
    (tester) async {
      final ledger = shop(autoApply: false);
      final app = TestApp(ledger: ledger);
      await app.pump(tester);
      await openCustomers(tester, app);

      expect(find.text('Rs. 500.00'), findsOneWidget);
      expect(find.byTooltip('2 ஒத்திசைக்கக் காத்திருக்கின்றன'), findsOneWidget);

      ledger.applyPending();
      await tester.pumpAndSettle();
      expect(find.text('Rs. 500.00'), findsOneWidget);
      expect(find.byTooltip('2 ஒத்திசைக்கக் காத்திருக்கின்றன'), findsNothing);
      expect(find.byTooltip('அனைத்தும் ஒத்திசைக்கப்பட்டன'), findsOneWidget);
    },
  );

  testWidgets('helper records a payment from the Entry tab but cannot delete', (
    tester,
  ) async {
    final app = TestApp(ledger: shop());
    await app.pump(tester);
    await app.signInUnlocked(tester, Role.helper);

    await tester.tap(find.text('பணம் பெற்றதைப் பதி'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ravi அண்ணை'));
    await tester.pumpAndSettle();
    // Helpers can't write off a balance.
    await tester.enterText(find.byKey(const ValueKey('entry-amount')), '200');
    await tester.pump();
    expect(find.textContaining('தள்ளுபடி'), findsNothing);
    await tester.ensureVisible(find.byKey(const ValueKey('entry-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('entry-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('receipt-close')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('வாடிக்கையாளர்').last);
    await tester.pumpAndSettle();
    expect(find.text('Rs. 300.00'), findsOneWidget);
    await tester.tap(find.text('Ravi அண்ணை'));
    await tester.pumpAndSettle();
    // The owner's credit: not the helper's to change.
    await tester.tap(find.text('கடன்  Rs. 500.00'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'இப்போது இந்தப் பதிவை உரிமையாளர் அல்லது பங்காளர் மட்டுமே மாற்றலாம்.',
      ),
      findsOneWidget,
    );
    expect(find.text('பதிவை நீக்கு'), findsNothing);
  });
}
