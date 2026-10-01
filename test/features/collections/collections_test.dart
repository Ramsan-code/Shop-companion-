import 'package:clock/clock.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_companion/core/rbac/role.dart';
import 'package:shop_companion/features/collections/data/collections_repositories.dart';
import 'package:shop_companion/features/collections/domain/collections.dart';
import 'package:shop_companion/features/collections/presentation/who_to_ask_cubit.dart';
import 'package:shop_companion/features/ledger/data/in_memory_ledger_repository.dart';
import 'package:shop_companion/features/ledger/domain/entry_type.dart';
import 'package:shop_companion/features/ledger/domain/models.dart';
import 'package:shop_companion/features/voice/domain/speech_input.dart';

import '../../helpers.dart';

void main() {
  final today = DateTime.now();

  InMemoryLedgerRepository shop() {
    final repo = InMemoryLedgerRepository(
      uid: 'owner-1',
      customers: const [
        Customer(
          id: 'ravi',
          name: 'Ravi',
          kinship: Kinship.annai,
          phone: '+94771234567',
          payDay: 25,
        ),
        Customer(id: 'selvi', name: 'Selvi', kinship: Kinship.akka),
        Customer(id: 'kumar', name: 'Kumar'),
      ],
    );
    for (final (id, rupees) in [
      ('ravi', 1800),
      ('selvi', 900),
      ('kumar', 400),
    ]) {
      repo.addEntry(
        'fake-shop',
        EntryDraft(
          type: EntryType.credit,
          amountCents: rupees * 100,
          customerId: id,
          txnDate: today,
        ),
      );
    }
    return repo;
  }

  InMemoryCollectionsRepository trust() => InMemoryCollectionsRepository(
    trust: const {
      'ravi': TrustInfo(
        score: 35,
        band: TrustBand.risky,
        reasons: [TrustReason('overdue', 75), TrustReason('noRecentPayment')],
        creditLimitCents: 200000,
        computedLimitCents: 200000,
      ),
    },
  );

  group('domain', () {
    test('checkCreditLimit warns only above the limit', () {
      const t = TrustInfo(
        score: 50,
        band: TrustBand.watch,
        creditLimitCents: 200000,
      );
      expect(
        checkCreditLimit(trust: t, balanceCents: 180000, creditCents: 20000),
        isNull,
      );
      expect(
        checkCreditLimit(trust: t, balanceCents: 180000, creditCents: 20100),
        const LimitWarning(limitCents: 200000, balanceAfterCents: 200100),
      );
      expect(
        checkCreditLimit(
          trust: null,
          balanceCents: 9e9.toInt(),
          creditCents: 1,
        ),
        isNull,
      );
    });

    test('colomboDate rolls over at Sri Lankan midnight', () {
      expect(colomboDate(DateTime.utc(2026, 9, 30, 18, 29)), '2026-09-30');
      expect(colomboDate(DateTime.utc(2026, 9, 30, 18, 30)), '2026-10-01');
    });

    test(
      'nextPayDay: this month if still ahead, else next; short months clamp',
      () {
        expect(
          nextPayDay(25, DateTime(2026, 10, 1, 9)),
          DateTime(2026, 10, 25, 6),
        );
        expect(
          nextPayDay(1, DateTime(2026, 10, 1, 9)),
          DateTime(2026, 11, 1, 6),
        );
        expect(nextPayDay(31, DateTime(2027, 2, 2)), DateTime(2027, 2, 28, 6));
      },
    );
  });

  group('WhoToAskCubit', () {
    test(
      'uses the 06:00 list with live balances; paid people are marked',
      () async {
        final ledger = shop();
        final collections = InMemoryCollectionsRepository(
          whoToAsk: WhoToAsk(
            date: colomboDate(clock.now()),
            totalDueCents: 270000,
            items: const [
              WhoToAskItem(
                customerId: 'ravi',
                name: 'Ravi',
                balanceCents: 180000,
                band: TrustBand.risky,
                reason: TrustReason('overdue', 75),
              ),
              WhoToAskItem(
                customerId: 'selvi',
                name: 'Selvi',
                balanceCents: 90000,
              ),
            ],
          ),
        );
        final cubit = WhoToAskCubit(
          collections: collections,
          ledger: ledger,
          shopId: 'fake-shop',
        );
        await pumpEventQueue();
        expect(cubit.state.fallback, isFalse);
        expect(cubit.state.rows.map((r) => r.customer.id), ['ravi', 'selvi']);

        ledger.addEntry(
          'fake-shop',
          EntryDraft(
            type: EntryType.payment,
            amountCents: 90000,
            customerId: 'selvi',
            txnDate: today,
          ),
        );
        await pumpEventQueue();
        expect(cubit.state.rows.last.paidSinceMorning, isTrue);
        expect(cubit.state.stillToAsk, 1);
        expect(cubit.state.totalDueCents, 180000);

        cubit.snooze('ravi', today.add(const Duration(days: 3)));
        expect(cubit.state.rows.map((r) => r.customer.id), ['selvi']);
        expect(collections.actions.single.$2, CollectAction.snooze);
        await cubit.close();
      },
    );

    test('before 06:00 (no list yet): highest dues as a fallback', () async {
      final cubit = WhoToAskCubit(
        collections: InMemoryCollectionsRepository(),
        ledger: shop(),
        shopId: 'fake-shop',
      );
      await pumpEventQueue();
      expect(cubit.state.fallback, isTrue);
      expect(cubit.state.rows.map((r) => r.customer.id), [
        'ravi',
        'selvi',
        'kumar',
      ]);
      await cubit.close();
    });
  });

  testWidgets('home shows Who To Ask with reasons and actions', (tester) async {
    final collections = trust()
      ..whoToAsk = WhoToAsk(
        date: colomboDate(clock.now()),
        totalDueCents: 180000,
        items: const [
          WhoToAskItem(
            customerId: 'ravi',
            name: 'Ravi',
            balanceCents: 180000,
            band: TrustBand.risky,
            reason: TrustReason('overdue', 75),
          ),
        ],
      );
    final app = TestApp(ledger: shop(), collections: collections);
    await app.pump(tester);
    await app.signInUnlocked(tester, Role.owner);

    expect(find.text('இன்று கேட்க வேண்டியவர்கள்'), findsOneWidget);
    expect(find.text('Ravi அண்ணை'), findsOneWidget);
    expect(
      find.text('பழைய கடன் 75 நாட்களாகச் செலுத்தப்படவில்லை'),
      findsOneWidget,
    );
    expect(find.text('ஆபத்து'), findsOneWidget);
    expect(find.text('WhatsApp'), findsOneWidget);

    await tester.tap(find.text('பின்னர்'));
    await tester.pumpAndSettle();
    expect(find.text('சம்பள நாளில் கேள் (25)'), findsOneWidget);
    await tester.tap(find.text('3 நாட்களில் கேள்'));
    await tester.pumpAndSettle();
    expect(find.text('Ravi அண்ணை'), findsNothing);
    expect(collections.actions.single.$1, 'ravi');
  });

  testWidgets(
    'owner sees trust and limit; changing the limit calls overrideLimit',
    (tester) async {
      final collections = trust();
      final app = TestApp(ledger: shop(), collections: collections);
      await app.pump(tester);
      await app.signInUnlocked(tester, Role.owner);
      await tester.tap(find.text('வாடிக்கையாளர்').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ravi அண்ணை'));
      await tester.pumpAndSettle();

      expect(find.text('ஆபத்து · நம்பிக்கை 35/100'), findsOneWidget);
      expect(find.text('• 3 மாதங்களாகச் செலுத்தவில்லை'), findsOneWidget);
      expect(find.text('பாதுகாப்பான கடன் வரம்பு: Rs. 2,000'), findsOneWidget);

      await tester.tap(find.text('வரம்பை மாற்று'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('limit-amount')),
        '3000',
      );
      await tester.tap(find.text('சேமி'));
      await tester.pumpAndSettle();
      expect(find.text('பாதுகாப்பான கடன் வரம்பு: Rs. 3,000'), findsOneWidget);
      expect(find.text('உரிமையாளர் அமைத்தது'), findsOneWidget);
    },
  );

  testWidgets(
    'credit above the safe limit needs "give anyway"; helpers see no limit',
    (tester) async {
      final app = TestApp(ledger: shop(), collections: trust());
      await app.pump(tester);
      await app.signInUnlocked(tester, Role.owner);
      await tester.tap(find.text('வாடிக்கையாளர்').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ravi அண்ணை'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('கடன் கொடு'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const ValueKey('entry-amount')), '100');
      await tester.pump();
      expect(find.byKey(const ValueKey('give-anyway')), findsNothing);
      await tester.enterText(find.byKey(const ValueKey('entry-amount')), '500');
      await tester.pump();
      expect(
        find.text(
          'இது Ravi அண்ணை இன் நிலுவையை Rs. 2,300 ஆக்கும். பாதுகாப்பான வரம்பு Rs. 2,000.',
        ),
        findsOneWidget,
      );
      final save = find.byKey(const ValueKey('entry-save'));
      expect(tester.widget<FilledButton>(save).onPressed, isNull);
      await tester.tap(find.byKey(const ValueKey('give-anyway')));
      await tester.pump();
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(
        (await app.ledger.watchCustomer('fake-shop', 'ravi').first)!
            .balance
            .cents,
        230000,
      );
    },
  );

  testWidgets('voice: an over-limit credit is not saved by "சரி" alone', (
    tester,
  ) async {
    final app = TestApp(ledger: shop(), collections: trust());
    app.speech.results.addAll(const [
      HeardSpeech('Ravi annai 500 kadan'),
      HeardSpeech('சரி'),
    ]);
    await app.pump(tester);
    await app.signInUnlocked(tester, Role.owner);
    await tester.tap(find.byIcon(FluentIcons.mic_24_filled).last);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('give-anyway')), findsOneWidget);
    expect(
      (await app.ledger.watchCustomer('fake-shop', 'ravi').first)!
          .balance
          .cents,
      180000,
    );
  });

  testWidgets('helper: no trust card and no limit warning', (tester) async {
    final app = TestApp(ledger: shop(), collections: trust());
    await app.pump(tester);
    await app.signInUnlocked(tester, Role.helper);
    await tester.tap(find.text('வாடிக்கையாளர்').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ravi அண்ணை'));
    await tester.pumpAndSettle();
    expect(find.textContaining('நம்பிக்கை'), findsNothing);
    await tester.tap(find.text('கடன் கொடு'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('entry-amount')), '5000');
    await tester.pump();
    expect(find.byKey(const ValueKey('give-anyway')), findsNothing);
  });
}
