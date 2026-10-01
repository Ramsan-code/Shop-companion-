import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_companion/core/rbac/role.dart';
import 'package:shop_companion/features/data/data/data_rights_repositories.dart';
import 'package:shop_companion/features/data/presentation/data_screen.dart';
import 'package:shop_companion/features/data/presentation/dues_report_screen.dart';
import 'package:shop_companion/features/ledger/data/in_memory_ledger_repository.dart';
import 'package:shop_companion/features/ledger/domain/entry_type.dart';
import 'package:shop_companion/features/ledger/domain/models.dart';
import 'package:shop_companion/features/voice/domain/speech_input.dart';

import '../../helpers.dart';

final base64Png = Uint8List.fromList(const [
  137,
  80,
  78,
  71,
  13,
  10,
  26,
  10,
  0,
  0,
  0,
  13,
  73,
  72,
  68,
  82,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  1,
  8,
  2,
  0,
  0,
  0,
  144,
  119,
  83,
  222,
  0,
  0,
  0,
  12,
  73,
  68,
  65,
  84,
  120,
  156,
  99,
  248,
  255,
  255,
  63,
  0,
  5,
  254,
  2,
  254,
  13,
  239,
  70,
  184,
  0,
  0,
  0,
  0,
  73,
  69,
  78,
  68,
  174,
  66,
  96,
  130,
]);

final _dataList = find
    .descendant(of: find.byType(DataScreen), matching: find.byType(Scrollable))
    .first;

/// Taps a Data screen tile once it is clear of the bottom bar.
Future<void> tapTile(WidgetTester tester, String key) async {
  final tile = find.byKey(ValueKey(key));
  await tester.scrollUntilVisible(
    tile.hitTestable(),
    100,
    scrollable: _dataList,
  );
  await tester.tap(tile);
  await tester.pumpAndSettle();
}

void main() {
  InMemoryLedgerRepository shop() {
    final ledger = InMemoryLedgerRepository(
      customers: const [
        Customer(id: 'ravi', name: 'Ravi', kinship: Kinship.annai),
        Customer(id: 'selvi', name: 'Selvi', phone: '+94771112222'),
        Customer(id: 'anbu', name: 'Anbu'),
      ],
    );
    for (final (id, rupees) in [('ravi', 1500), ('selvi', 2400)]) {
      ledger.addEntry(
        'fake-shop',
        EntryDraft(
          type: EntryType.credit,
          amountCents: rupees * 100,
          customerId: id,
          txnDate: DateTime(2026, 9, 20),
        ),
      );
    }
    return ledger;
  }

  Future<void> openData(WidgetTester tester, TestApp app, Role role) async {
    await app.pump(tester);
    await app.signInUnlocked(tester, role);
    if (role == Role.helper) {
      await tester.tap(find.byKey(const ValueKey('helper-data')));
    } else {
      await tester.tap(find.text('மேலும்').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('more-data')));
    }
    await tester.pumpAndSettle();
  }

  testWidgets('owner exports Excel and JSON in one share', (tester) async {
    final app = TestApp(ledger: shop());
    await openData(tester, app, Role.owner);
    await tapTile(tester, 'data-export');
    final files = app.shared.shared.single;
    expect(files.map((f) => f.name), [
      matches(r'^shop-companion-\d{4}-\d{2}-\d{2}\.xlsx$'),
      matches(r'^shop-companion-\d{4}-\d{2}-\d{2}\.json$'),
    ]);
    expect(app.telemetry.events.last.$1, 'export_done');
  });

  testWidgets('helper sees privacy and delete account, no export', (
    tester,
  ) async {
    final app = TestApp(dataRights: FakeDataRightsRepository(isOwner: false));
    await openData(tester, app, Role.helper);
    expect(find.byKey(const ValueKey('data-export')), findsNothing);
    expect(find.byKey(const ValueKey('data-delete-shop')), findsNothing);

    await tapTile(tester, 'data-privacy');
    expect(find.textContaining('விளம்பரம் ஒருபோதும் இல்லை'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tapTile(tester, 'data-delete-account');
    await tester.tap(find.byKey(const ValueKey('confirm-delete')));
    await tester.pumpAndSettle();
    expect(app.dataRights.calls, ['deleteMyAccount']);
    // Signed out: back at the phone number screen.
    expect(find.byKey(const ValueKey('data-delete-account')), findsNothing);
  });

  testWidgets('owner account deletion asks to delete the shop first', (
    tester,
  ) async {
    final app = TestApp();
    await openData(tester, app, Role.owner);
    await tapTile(tester, 'data-delete-account');
    await tester.tap(find.byKey(const ValueKey('confirm-delete')));
    await tester.pumpAndSettle();
    expect(find.textContaining('முதலில் கடையை நீக்கி'), findsOneWidget);
  });

  testWidgets('deleting the shop needs its exact name', (tester) async {
    final app = TestApp();
    await openData(tester, app, Role.owner);
    Future<void> attempt(String typed) async {
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('data-delete-shop')),
        100,
      );
      await tapTile(tester, 'data-delete-shop');
      await tester.enterText(
        find.byKey(const ValueKey('confirm-shop-name')),
        typed,
      );
      await tester.tap(find.byKey(const ValueKey('confirm-delete')));
      await tester.pumpAndSettle();
    }

    await attempt('Selvarasa');
    expect(find.text('அது கடையின் பெயர் அல்ல.'), findsOneWidget);
    expect(app.dataRights.calls, isEmpty);

    await tester.pump(const Duration(seconds: 5));
    await attempt('Selvarasa Stores');
    expect(app.dataRights.calls, ['deleteShop']);
  });

  testWidgets('erase: refused while owing, done when settled', (tester) async {
    final app = TestApp(ledger: shop());
    await app.pump(tester);
    await app.signInUnlocked(tester, Role.owner);
    Future<void> eraseFrom(String name) async {
      await tester.tap(find.text('வாடிக்கையாளர்').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(name).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('customer-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('erase-customer')));
      await tester.pumpAndSettle();
    }

    await eraseFrom('Selvi');
    expect(
      find.textContaining('முதலில் நிலுவையைத் தீர்க்கவும்'),
      findsOneWidget,
    );
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));

    await eraseFrom('Anbu');
    await tester.tap(find.byKey(const ValueKey('confirm-erase')));
    await tester.pumpAndSettle();
    expect(app.dataRights.calls, ['eraseCustomer:anbu']);
    expect(find.text('வாடிக்கையாளர் அழிக்கப்பட்டார்'), findsOneWidget);
  });

  testWidgets('import a Khatabook workbook in one step', (tester) async {
    final app = TestApp(ledger: shop());
    app.opener.next = (
      name: 'Customers.xlsx',
      bytes: File('test/fixtures/khatabook_customers.xlsx').readAsBytesSync(),
    );
    await openData(tester, app, Role.owner);
    await tapTile(tester, 'data-import');
    await tester.tap(find.byKey(const ValueKey('import-pick')));
    await tester.pumpAndSettle();

    // Ravi is already a customer and the nameless row can't come in.
    expect(find.textContaining('ஏற்கனவே பட்டியலில் உள்ளார்'), findsOneWidget);
    expect(find.text('2 வாடிக்கையாளர் · நிலுவை Rs. 2,250'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('import-save')));
    await tester.pumpAndSettle();

    final customers = await app.ledger.watchCustomers('fake-shop').first;
    final murugan = customers.firstWhere((c) => c.name == 'முருகன் அண்ணை');
    expect(murugan.balance.cents, 225050);
    expect(murugan.phone, '+94711234567');
    expect(
      customers.firstWhere((c) => c.name == 'Kamala').balance.cents,
      -30000,
    );
    final opening =
        (await app.ledger.watchEntries('fake-shop', murugan.id).first).single;
    expect(opening.note, 'ஆரம்ப நிலுவை (இறக்குமதி)');
    final (event, params) = app.telemetry.events.last;
    expect((event, params['customers']), ('import_done', '1-9'));
  });

  testWidgets('dues report lists who owes, highest first', (tester) async {
    final app = TestApp(ledger: shop());
    await openData(tester, app, Role.owner);
    await tapTile(tester, 'data-dues');
    expect(find.text('2 வாடிக்கையாளர்கள், மொத்தம் Rs. 3,900'), findsOneWidget);
    final selvi = tester.getTopLeft(find.text('Selvi'));
    final ravi = tester.getTopLeft(find.textContaining('Ravi'));
    expect(selvi.dy, lessThan(ravi.dy));
    expect(find.text('Anbu'), findsNothing);
  });

  testWidgets('say customers one by one, then save', (tester) async {
    final app = TestApp(ledger: shop());
    app.speech.results.addAll(const [
      HeardSpeech('முருகன் அண்ணை ஆயிரத்து ஐநூறு'),
      HeardSpeech('Kamala akka 750'),
    ]);
    await openData(tester, app, Role.owner);
    await tapTile(tester, 'data-import');
    await tester.tap(find.byKey(const ValueKey('import-speak')));
    await tester.pumpAndSettle();
    // Two silences in a row end the list.
    expect(find.text('2 வாடிக்கையாளர் · நிலுவை Rs. 2,250'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('import-save')));
    await tester.pumpAndSettle();
    final customers = await app.ledger.watchCustomers('fake-shop').first;
    final kamala = customers.firstWhere((c) => c.name == 'Kamala');
    expect((kamala.kinship, kamala.balance.cents), (Kinship.akka, 75000));
  });

  test('image PDF has one page per image', () async {
    // A 1×1 PNG.
    final png = base64Png;
    final pdf = await buildImagePdf([png, png]);
    final text = String.fromCharCodes(pdf);
    expect(text.startsWith('%PDF'), isTrue);
    expect(RegExp(r'/Type\s*/Page[^s]').allMatches(text), hasLength(2));
  });
}
