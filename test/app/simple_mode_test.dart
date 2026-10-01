import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_companion/core/rbac/role.dart';

import '../helpers.dart';

void main() {
  testWidgets('simple mode: big tiles that say what they do', (tester) async {
    final app = TestApp();
    await app.pump(tester);
    await app.signInUnlocked(tester, Role.owner);
    expect(find.byTooltip('கேளுங்கள்'), findsNothing);

    await tester.tap(find.text('மேலும்').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('simple-mode')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('முகப்பு').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('கேளுங்கள்').first);
    await tester.pump();
    expect(app.readBack.spoken.single, startsWith('பேசு:'));

    // The sale tile opens the quick sale sheet.
    await tester.tap(find.text('விற்பனை'));
    await tester.pumpAndSettle();
    expect(find.text('விற்பனை பதிவு'), findsOneWidget);
  });

  testWidgets('helper switches simple mode from the entry screen', (
    tester,
  ) async {
    final app = TestApp();
    await app.pump(tester);
    await app.signInUnlocked(tester, Role.helper);
    await tester.tap(find.byKey(const ValueKey('simple-mode')));
    await tester.pumpAndSettle();
    expect(find.byTooltip('கேளுங்கள்'), findsWidgets);
    expect(find.text('செலவு'), findsNothing, reason: 'no expense for helpers');
  });
}
