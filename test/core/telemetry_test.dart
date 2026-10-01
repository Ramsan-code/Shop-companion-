import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_companion/core/rbac/role.dart';
import 'package:shop_companion/core/telemetry.dart';
import 'package:shop_companion/features/voice/domain/speech_input.dart';

import '../helpers.dart';

void main() {
  test('counts are bucketed', () {
    expect([0, 3, 12, 150, 600, 5000].map(countBucket), [
      '0',
      '1-9',
      '10-49',
      '50-199',
      '200-999',
      '1000+',
    ]);
  });

  testWidgets('events carry no names, phones or amounts (PRD 11)', (
    tester,
  ) async {
    final app = TestApp();
    await app.pump(tester);
    await app.signInUnlocked(tester, Role.helper);
    // A voice sale, a cash count and simple mode: every event type a
    // helper can cause.
    app.speech.results.addAll(const [
      HeardSpeech('Ravi annai 1500 விற்பனை'),
      HeardSpeech('சரி'),
    ]);
    await tester.tap(find.text('பதிவைச் சொல்லுங்கள் அல்லது எழுதுங்கள்'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('நாள் முடிவு').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('count-amount')), '4321');
    await tester.tap(find.byKey(const ValueKey('count-save')));
    await tester.pumpAndSettle();

    expect(app.telemetry.events.map((e) => e.$1), ['voice_entry', 'close_day']);
    for (final (_, params) in app.telemetry.events) {
      for (final value in params.values) {
        expect('$value', isNot(contains('Ravi')));
        expect('$value', isNot(matches(RegExp(r'\d{3,}'))));
      }
    }
  });
}
