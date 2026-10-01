import 'package:clock/clock.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_companion/core/rbac/role.dart';
import 'package:shop_companion/features/ledger/domain/entry_type.dart';
import 'package:shop_companion/features/ledger/domain/models.dart';
import 'package:shop_companion/features/voice/domain/speech_input.dart';
import 'package:shop_companion/features/voice/presentation/voice_entry_store.dart';

import '../../helpers.dart';

void main() {
  test('a sale needs no customer; credit still does', () {
    final store = VoiceEntryStore(
      customers: const [],
      allowedTypes: const [EntryType.credit, EntryType.sale],
    )..setAmountText('300');
    expect(store.canSave.value, isFalse);
    store.setType(EntryType.sale);
    expect(store.needsCustomer.value, isFalse);
    expect(store.canSave.value, isTrue);
  });

  test('a spoken type the person may not record is ignored', () {
    final store = VoiceEntryStore(customers: const [])..applyHeard('400 செலவு');
    expect(store.type.value, EntryType.credit);
    expect(store.amountText.value, '400');
  });

  testWidgets('owner says a sale: read back without a name, saved as cash', (
    tester,
  ) async {
    final app = TestApp();
    app.speech.results.addAll(const [
      HeardSpeech('மூவாயிரம் விற்பனை'),
      HeardSpeech('சரி'),
    ]);
    await app.pump(tester);
    await app.signInUnlocked(tester, Role.owner);
    await tester.tap(find.byIcon(FluentIcons.mic_24_filled).last);
    await tester.pumpAndSettle();

    expect(app.readBack.spoken, ['3000 ரூபா விற்பனை. சரியா?']);
    final entry =
        (await app.ledger.watchDayEntries('fake-shop', clock.now()).first)
            .single;
    expect(entry.type, EntryType.sale);
    expect(entry.amountCents, 300000);
    expect(entry.customerId, isNull);
    expect(entry.method, PaymentMethod.cash);
  });

  testWidgets('helper voice sheet offers sale but not expense', (tester) async {
    final app = TestApp();
    await app.pump(tester);
    await app.signInUnlocked(tester, Role.helper);
    await tester.tap(find.byIcon(FluentIcons.mic_24_filled).last);
    await tester.pumpAndSettle();
    final toggle = find.byKey(const ValueKey('voice-type'));
    expect(
      find.descendant(of: toggle, matching: find.text('விற்பனை')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: toggle, matching: find.text('செலவு')),
      findsNothing,
    );
  });
}
