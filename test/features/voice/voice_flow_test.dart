import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_companion/core/rbac/role.dart';
import 'package:shop_companion/features/ledger/data/in_memory_ledger_repository.dart';
import 'package:shop_companion/features/ledger/domain/entry_type.dart';
import 'package:shop_companion/features/ledger/domain/models.dart';
import 'package:shop_companion/features/voice/domain/speech_input.dart';

import '../../helpers.dart';

void main() {
  InMemoryLedgerRepository shop() => InMemoryLedgerRepository(
    uid: 'owner-1',
    customers: const [
      Customer(id: 'ravi', name: 'Ravi', kinship: Kinship.annai),
      Customer(id: 'kumar', name: 'குமார்', kinship: Kinship.thambi),
    ],
  );

  Future<void> openMic(WidgetTester tester, TestApp app) async {
    await app.signInUnlocked(tester, Role.owner);
    await tester.tap(find.byIcon(FluentIcons.mic_24_filled).last);
    await tester.pumpAndSettle();
  }

  Future<List<LedgerEntry>> entriesOf(TestApp app, String customerId) =>
      app.ledger.watchEntries('fake-shop', customerId).first;

  testWidgets('US1: speak, hear it read back, say சரி, saved', (tester) async {
    final app = TestApp(ledger: shop());
    app.speech.results.addAll(const [
      HeardSpeech('Ravi annai 500 kadan'),
      HeardSpeech('சரி'),
    ]);
    await app.pump(tester);
    await openMic(tester, app);

    expect(app.readBack.spoken, ['Ravi அண்ணை, 500 ரூபா கடன். சரியா?']);
    final entries = await entriesOf(app, 'ravi');
    expect(entries.single.amountCents, 50000);
    expect(entries.single.type, EntryType.credit);
    expect(find.text('சேமிக்கப்பட்டது'), findsOneWidget);
  });

  testWidgets('"இல்லை": nothing saved; correct the amount by typing', (
    tester,
  ) async {
    final app = TestApp(ledger: shop());
    app.speech.results.addAll(const [
      HeardSpeech('Ravi annai 5000 kadan'),
      HeardSpeech('இல்லை'),
    ]);
    await app.pump(tester);
    await openMic(tester, app);
    expect(await entriesOf(app, 'ravi'), isEmpty);

    await tester.enterText(find.byKey(const ValueKey('voice-amount')), '500');
    await tester.pump();
    await tester.ensureVisible(find.byKey(const ValueKey('voice-save')));
    await tester.tap(find.byKey(const ValueKey('voice-save')));
    await tester.pumpAndSettle();
    expect((await entriesOf(app, 'ravi')).single.amountCents, 50000);
  });

  testWidgets('Tamil-script customer, payment, Tamil speech', (tester) async {
    final app = TestApp(ledger: shop());
    app.speech.results.addAll(const [
      HeardSpeech('குமார் தம்பி ஆயிரத்து ஐநூறு தந்தார்'),
      HeardSpeech('ஓம்'),
    ]);
    await app.pump(tester);
    await openMic(tester, app);
    final entry = (await entriesOf(app, 'kumar')).single;
    expect(entry.type, EntryType.payment);
    expect(entry.amountCents, 150000);
    expect(entry.method, PaymentMethod.cash);
  });

  testWidgets('keypad fallback when the phone has no Tamil speech', (
    tester,
  ) async {
    final app = TestApp(ledger: shop());
    app.speech.available = false;
    await app.pump(tester);
    await openMic(tester, app);

    expect(
      find.text(
        'இந்தத் தொலைபேசியால் இப்போது தமிழ்ப் பேச்சைப் புரிய முடியவில்லை. கீழே எழுதுங்கள்.',
      ),
      findsOneWidget,
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'வாடிக்கையாளர்'),
      'Ra',
    );
    await tester.pump();
    await tester.tap(find.text('Ravi அண்ணை'));
    await tester.pump();
    await tester.enterText(find.byKey(const ValueKey('voice-amount')), '300');
    await tester.pump();
    await tester.ensureVisible(find.byKey(const ValueKey('voice-save')));
    await tester.tap(find.byKey(const ValueKey('voice-save')));
    await tester.pumpAndSettle();
    expect((await entriesOf(app, 'ravi')).single.amountCents, 30000);
  });

  testWidgets('an unknown name is added as a new customer', (tester) async {
    final app = TestApp(ledger: shop());
    app.speech.results.addAll(const [
      HeardSpeech('Fathima akka 250 kadan'),
      HeardSpeech('sari'),
    ]);
    await app.pump(tester);
    await openMic(tester, app);
    final customers = await app.ledger.watchCustomers('fake-shop').first;
    final fathima = customers.singleWhere((c) => c.name == 'Fathima');
    expect(fathima.kinship, Kinship.akka);
    expect((await entriesOf(app, fathima.id)).single.amountCents, 25000);
  });

  testWidgets(
    'falls back to the cloud when the phone recogniser needs a network it lacks',
    (tester) async {
      final cloud = FakeSpeechInput()
        ..results.add(const HeardSpeech('Ravi annai 700 kadan'));
      final app = TestApp(ledger: shop(), cloud: cloud);
      app.speech.results.add(const SpeechFailed(SpeechFailure.network));
      await app.pump(tester);
      await openMic(tester, app);

      expect(cloud.listens, 1);
      // Cloud results are confirmed with a tap (no quick spoken "சரி").
      expect(await entriesOf(app, 'ravi'), isEmpty);
      expect(find.text('Ravi அண்ணை'), findsWidgets);
      await tester.ensureVisible(find.byKey(const ValueKey('voice-save')));
      await tester.tap(find.byKey(const ValueKey('voice-save')));
      await tester.pumpAndSettle();
      expect((await entriesOf(app, 'ravi')).single.amountCents, 70000);
    },
  );
}
