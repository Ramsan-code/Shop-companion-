import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_companion/app/app.dart';
import 'package:shop_companion/core/di/providers.dart';
import 'package:shop_companion/core/rbac/role.dart';
import 'package:shop_companion/features/auth/data/fake_auth_repository.dart';

void main() {
  Future<FakeAuthRepository> pumpApp(WidgetTester tester) async {
    final auth = FakeAuthRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(auth)],
        child: const ShopCompanionApp(),
      ),
    );
    await tester.pumpAndSettle();
    return auth;
  }

  testWidgets('starts on Tamil login', (tester) async {
    await pumpApp(tester);
    expect(find.text('உங்கள் தொலைபேசி இலக்கம்'), findsOneWidget);
  });

  testWidgets('owner gets five tabs and the mic opens the voice sheet', (
    tester,
  ) async {
    final auth = await pumpApp(tester);
    await auth.debugSignInAs(Role.owner).run();
    await tester.pumpAndSettle();

    for (final tab in ['முகப்பு', 'வாடிக்கையாளர்', 'சரக்கு', 'மேலும்']) {
      expect(find.text(tab), findsWidgets, reason: tab);
    }

    // The raised centre button is icon-only.
    await tester.tap(find.byIcon(FluentIcons.mic_24_filled));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Ravi annai 500 kadan');
    await tester.pump();
    expect(find.text('Ravi annai'), findsOneWidget);
    expect(find.text('Rs. 500.00'), findsOneWidget);
  });

  testWidgets('helper gets the three-tab shell without Stock or More', (
    tester,
  ) async {
    final auth = await pumpApp(tester);
    await auth.debugSignInAs(Role.helper).run();
    await tester.pumpAndSettle();

    expect(find.text('நாள் முடிவு'), findsWidgets);
    expect(find.text('சரக்கு'), findsNothing);
    expect(find.text('மேலும்'), findsNothing);
  });

  testWidgets('language switch changes the UI to English', (tester) async {
    final auth = await pumpApp(tester);
    await auth.debugSignInAs(Role.owner).run();
    await tester.pumpAndSettle();
    await tester.tap(find.text('மேலும்'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Language'), findsOneWidget);
  });
}
