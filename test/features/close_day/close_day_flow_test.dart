import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_companion/core/rbac/role.dart';
import 'package:shop_companion/features/close_day/presentation/close_day_screen.dart';
import 'package:shop_companion/features/ledger/data/in_memory_ledger_repository.dart';
import 'package:shop_companion/features/ledger/domain/entry_type.dart';
import 'package:shop_companion/features/ledger/domain/models.dart';

import 'package:shop_companion/features/voice/domain/speech_input.dart';

import '../../helpers.dart';

final closeDayList = find
    .descendant(
      of: find.byType(CloseDayScreen),
      matching: find.byType(Scrollable),
    )
    .first;

void main() {
  InMemoryLedgerRepository shop() {
    final ledger = InMemoryLedgerRepository(
      customers: const [
        Customer(id: 'ravi', name: 'Ravi', kinship: Kinship.annai),
      ],
    );
    final yesterday = clock.now().subtract(const Duration(days: 1));
    ledger
      ..addEntry(
        'fake-shop',
        EntryDraft(
          type: EntryType.credit,
          amountCents: 150000,
          customerId: 'ravi',
          txnDate: yesterday,
        ),
      )
      ..addEntry(
        'fake-shop',
        EntryDraft(
          type: EntryType.payment,
          amountCents: 50000,
          customerId: 'ravi',
          txnDate: clock.now(),
          method: PaymentMethod.cash,
        ),
      );
    return ledger;
  }

  Future<void> quickEntry(
    WidgetTester tester,
    TestApp app,
    String button,
    String category,
    String amount,
  ) async {
    await tester.tap(find.byKey(ValueKey(button)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(category));
    await tester.enterText(find.byKey(const ValueKey('quick-amount')), amount);
    await app.tapInSheet(tester, find.byKey(const ValueKey('quick-save')));
  }

  testWidgets('owner: sale and expense by category, then Close Day', (
    tester,
  ) async {
    final app = TestApp(ledger: shop());
    await app.pump(tester);
    await app.signInUnlocked(tester, Role.owner);

    await quickEntry(tester, app, 'quick-sale', 'மரக்கறி', '3000');
    await quickEntry(tester, app, 'quick-expense', 'போக்குவரத்து', '300');
    final today = await app.ledger
        .watchDayEntries('fake-shop', clock.now())
        .first;
    final sale = today.firstWhere((e) => e.type == EntryType.sale);
    expect(sale.category, 'vegetables');
    expect(sale.method, PaymentMethod.cash);
    expect(sale.customerId, isNull);
    expect(
      today.firstWhere((e) => e.type == EntryType.expense).category,
      'transport',
    );

    // Let the "saved" snack bar go before it covers the buttons.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('quick-close-day')));
    await tester.pumpAndSettle();

    // Opening float 5000 + sale 3000 + payment 500 − expense 300.
    expect(find.text('Rs. 8,200'), findsOneWidget);
    // Demo stock margins average 15 %: 450 − 300.
    expect(find.text('இன்று சுமார் Rs. 150 இலாபம்'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('count-amount')), '8100');
    // Clear of the convex bar's raised mic button.
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('count-save')).hitTestable(),
      100,
      scrollable: closeDayList,
    );
    await tester.tap(find.byKey(const ValueKey('count-save')));
    await tester.pumpAndSettle();

    expect(find.text('பெட்டியில் Rs. 100 குறைவு'), findsOneWidget);
    expect(find.text('கடைக்குச் சேமிக்கப்பட்டது'), findsOneWidget);
    expect(app.readBack.spoken.last, contains('விற்பனை 3000 ரூபா'));
    expect(app.readBack.spoken.last, endsWith('பெட்டியில் 100 ரூபா குறைவு'));

    // Tomorrow: Ravi still owes 1000; sugar is below its alert level.
    await tester.scrollUntilVisible(
      find.text('சீனி வாங்க வேண்டும்'),
      200,
      scrollable: closeDayList,
    );
    expect(find.textContaining('Ravi அண்ணை இடம்'), findsOneWidget);
  });

  testWidgets('owner: say the counted cash', (tester) async {
    final app = TestApp(ledger: shop());
    await app.pump(tester);
    await app.signInUnlocked(tester, Role.owner);
    await tester.tap(find.byKey(const ValueKey('quick-close-day')));
    await tester.pumpAndSettle();

    app.speech.results.add(const HeardSpeech('ஐயாயிரத்து ஐநூறு'));
    await tester.tap(find.byKey(const ValueKey('count-mic')));
    await tester.pumpAndSettle();
    expect(find.text('5500'), findsOneWidget);

    // A second go works too (the first listen has finished).
    app.speech.results.add(const HeardSpeech('6000'));
    await tester.tap(find.byKey(const ValueKey('count-mic')));
    await tester.pumpAndSettle();
    expect(find.text('6000'), findsOneWidget);
  });

  testWidgets('helper enters the count only and never sees profit', (
    tester,
  ) async {
    final app = TestApp(ledger: shop());
    await app.pump(tester);
    await app.signInUnlocked(tester, Role.helper);
    await tester.tap(find.text('நாள் முடிவு').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('profit-mirror')), findsNothing);
    expect(find.textContaining('இலாபம்'), findsNothing);
    await tester.enterText(find.byKey(const ValueKey('count-amount')), '4000');
    await tester.tap(find.byKey(const ValueKey('count-save')));
    await tester.pumpAndSettle();
    expect(find.text('உங்கள் எண்ணிக்கை: Rs. 4,000'), findsOneWidget);
  });
}
