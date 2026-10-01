import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_companion/core/rbac/role.dart';
import 'package:shop_companion/features/ledger/data/in_memory_ledger_repository.dart';
import 'package:shop_companion/features/ledger/domain/models.dart';
import 'package:shop_companion/features/reminders/data/reminders_repositories.dart';
import 'package:shop_companion/features/reminders/domain/reminders.dart';

import '../../helpers.dart';

void main() {
  const lankaQr =
      '00020101021126360014LK.LANKAQR.0102010211123456789012520459995303144'
      '5802LK5914SELVARASA STORE6008VAVUNIYA6304ABCD';

  InMemoryLedgerRepository shop() => InMemoryLedgerRepository(
    uid: 'owner-1',
    customers: const [
      Customer(
        id: 'ravi',
        name: 'Ravi',
        kinship: Kinship.annai,
        phone: '+94771234567',
        optedOut: true,
      ),
      Customer(
        id: 'selvi',
        name: 'Selvi',
        kinship: Kinship.akka,
        disputeOpen: true,
      ),
    ],
  );

  final shared = <MethodCall>[];
  setUp(() {
    shared.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/share'),
          (call) async {
            shared.add(call);
            return 'dev.fluttercommunity.plus/share/unavailable';
          },
        );
  });

  Future<void> openCustomer(
    WidgetTester tester,
    TestApp app,
    Role role,
    String name,
  ) async {
    await app.signInUnlocked(tester, role);
    await tester.tap(find.text('வாடிக்கையாளர்').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(name));
    await tester.pumpAndSettle();
  }

  test('LankaQR payload check', () {
    expect(looksLikeLankaQr(lankaQr), isTrue);
    expect(looksLikeLankaQr('https://example.com'), isFalse);
    expect(looksLikeLankaQr('000201'), isFalse);
  });

  testWidgets('customer page: STOP and dispute chips; share statement link', (
    tester,
  ) async {
    final app = TestApp(ledger: shop());
    await app.pump(tester);
    await openCustomer(tester, app, Role.owner, 'Ravi அண்ணை');
    expect(find.text('நினைவூட்டல்களை நிறுத்தினார் (STOP)'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('share-statement')));
    await tester.pumpAndSettle();
    final text = (shared.single.arguments as Map)['text'] as String;
    expect(text, contains('Ravi அண்ணை'));
    expect(text, contains('https://shop-companion-dev.web.app/s/demo-ravi'));
  });

  testWidgets(
    'customer form: consent, tone and language saved; preview from the server',
    (tester) async {
      final app = TestApp(ledger: shop());
      await app.pump(tester);
      await openCustomer(tester, app, Role.owner, 'Selvi அக்கா');
      expect(find.text('கணக்கை மறுத்துள்ளார்'), findsOneWidget);

      await tester.tap(find.byTooltip('வாடிக்கையாளரைத் திருத்து'));
      await tester.pumpAndSettle();
      final consent = find.byKey(const ValueKey('reminder-consent'));
      await tester.ensureVisible(consent);
      await tester.tap(consent);
      await tester.pump();
      await tester.tap(find.text('உறுதி'));
      await tester.tap(find.text('English').last);
      await tester.pump();

      await tester.tap(find.text('செய்தியை முன்னோட்டம் பார்'));
      await tester.pumpAndSettle();
      expect(find.text('[firm/en] preview for selvi'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextButton),
        ),
      );
      await tester.pumpAndSettle();

      await app.tapInSheet(tester, find.text('சேமி'));
      final selvi = (await app.ledger
          .watchCustomer('fake-shop', 'selvi')
          .first)!;
      expect(selvi.reminderConsent, isTrue);
      expect(selvi.reminderTone, ReminderTone.firm);
      expect(selvi.reminderLang, ReminderLang.en);
    },
  );

  testWidgets(
    'reminders screen: owner turns on reminders, approves, sees LankaQR',
    (tester) async {
      final reminders = InMemoryRemindersRepository(
        settings: const ReminderSettings(
          plan: 'pilot',
          lankaQrPayload: lankaQr,
        ),
        reminders: const [
          Reminder(
            id: 'r1',
            customerId: 'ravi',
            status: ReminderStatus.pendingApproval,
          ),
          Reminder(
            id: 'r2',
            customerId: 'selvi',
            status: ReminderStatus.pendingApproval,
          ),
          Reminder(
            id: 'r3',
            customerId: 'selvi',
            status: ReminderStatus.read,
            channel: 'whatsapp',
          ),
          Reminder(
            id: 'r4',
            customerId: 'ravi',
            status: ReminderStatus.sent,
            channel: 'sms',
          ),
        ],
      );
      final app = TestApp(ledger: shop(), reminders: reminders);
      await app.pump(tester);
      await app.signInUnlocked(tester, Role.owner);
      await tester.tap(find.text('மேலும்'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('நினைவூட்டல்கள்'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('lankaqr-preview')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('auto-reminders')));
      await tester.pump();
      expect(reminders.settings.autoReminders, isTrue);

      final list = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('அனுப்பப்பட்டது · SMS மூலம்'),
        200,
        scrollable: list,
      );
      expect(find.text('வாசிக்கப்பட்டது'), findsOneWidget);
      final approveAll = find.byKey(const ValueKey('approve-all'));
      await tester.scrollUntilVisible(
        approveAll.hitTestable(),
        -200,
        scrollable: list,
      );
      await tester.tap(approveAll);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('approve-all')), findsNothing);
      expect(find.text('வரிசையில்'), findsNWidgets(2));
    },
  );

  testWidgets('free plan: automatic reminders cannot be turned on', (
    tester,
  ) async {
    final app = TestApp(
      ledger: shop(),
      reminders: InMemoryRemindersRepository(
        settings: const ReminderSettings(),
      ),
    );
    await app.pump(tester);
    await app.signInUnlocked(tester, Role.owner);
    await tester.tap(find.text('மேலும்'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('நினைவூட்டல்கள்'));
    await tester.pumpAndSettle();
    expect(
      find.text('தானியங்கி நினைவூட்டல்கள் Plus திட்டத்தில் உள்ளன.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<SwitchListTile>(find.byKey(const ValueKey('auto-reminders')))
          .onChanged,
      isNull,
    );
  });

  testWidgets(
    'partner sees reminders but not shop settings; helper has no Reminders',
    (tester) async {
      final app = TestApp(ledger: shop());
      await app.pump(tester);
      await app.signInUnlocked(tester, Role.partner);
      await tester.tap(find.text('மேலும்'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('நினைவூட்டல்கள்'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('auto-reminders')), findsNothing);
      expect(find.text('இன்னும் நினைவூட்டல்கள் இல்லை.'), findsOneWidget);
    },
  );
}
