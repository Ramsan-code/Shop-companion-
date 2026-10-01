import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_companion/app/app.dart';
import 'package:shop_companion/core/di/providers.dart';
import 'package:shop_companion/core/rbac/role.dart';
import 'package:shop_companion/features/auth/data/fake_auth_repository.dart';
import 'package:shop_companion/features/auth/data/secure_pin_store.dart';
import 'package:shop_companion/features/auth/domain/pin_hasher.dart';
import 'package:shop_companion/features/settings/data/members_repositories.dart';

void main() {
  late FakeAuthRepository auth;
  late InMemoryPinStore pins;

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          pinStoreProvider.overrideWithValue(pins),
          biometricAuthProvider.overrideWithValue(const NoBiometricAuth()),
          membersRepositoryProvider.overrideWithValue(FakeMembersRepository()),
        ],
        child: const ShopCompanionApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> typePin(WidgetTester tester, String pin) async {
    for (final digit in pin.split('')) {
      await tester.tap(find.text(digit).last);
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  /// Signs in as [role] on a phone that already has PIN 2468.
  Future<void> signInUnlocked(WidgetTester tester, Role role) async {
    await pins.write('dev-user', PinHasher.create('2468', iterations: 100));
    await auth.debugSignInAs(role).run();
    await tester.pumpAndSettle();
    await typePin(tester, '2468');
  }

  setUp(() {
    auth = FakeAuthRepository();
    pins = InMemoryPinStore();
  });

  testWidgets('first-time setup: OTP → PIN twice → shop name → home', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.text('உங்கள் தொலைபேசி இலக்கம்'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('phone-field')),
      '0771234567',
    );
    await tester.tap(find.text('தொடரவும்'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('otp-field')),
      FakeAuthRepository.code,
    );
    await tester.tap(find.text('உறுதிப்படுத்து'));
    await tester.pumpAndSettle();

    expect(find.text('4 இலக்க PIN ஒன்றைத் தெரிவு செய்யுங்கள்'), findsOneWidget);
    await typePin(tester, '1357');
    expect(find.text('அதே PIN ஐ மீண்டும் உள்ளிடுங்கள்'), findsOneWidget);
    await typePin(tester, '1357');

    expect(find.text('உங்கள் கடையின் பெயர் என்ன?'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Selvarasa Stores');
    await tester.tap(find.text('கடையைத் தொடங்கு'));
    await tester.pumpAndSettle();

    expect(find.text('முகப்பு'), findsWidgets);
  });

  testWidgets('mismatched PIN confirmation starts again', (tester) async {
    await pumpApp(tester);
    await auth.debugSignInAs(Role.owner).run();
    await tester.pumpAndSettle();
    await typePin(tester, '1111');
    await typePin(tester, '2222');
    expect(
      find.text('PIN கள் பொருந்தவில்லை. மீண்டும் தெரிவு செய்யுங்கள்.'),
      findsOneWidget,
    );
  });

  testWidgets('a wrong PIN shows attempts left; the right one unlocks', (
    tester,
  ) async {
    await pumpApp(tester);
    await pins.write('dev-user', PinHasher.create('2468', iterations: 100));
    await auth.debugSignInAs(Role.owner).run();
    await tester.pumpAndSettle();
    expect(find.text('உங்கள் PIN ஐ உள்ளிடுங்கள்'), findsOneWidget);
    await typePin(tester, '0000');
    expect(find.text('PIN தவறு. இன்னும் 4 முயற்சிகள் உள்ளன.'), findsOneWidget);
    await typePin(tester, '2468');
    expect(find.text('முகப்பு'), findsWidgets);
  });

  testWidgets('owner gets five tabs and the mic opens the voice sheet', (
    tester,
  ) async {
    await pumpApp(tester);
    await signInUnlocked(tester, Role.owner);

    for (final tab in ['முகப்பு', 'வாடிக்கையாளர்', 'சரக்கு', 'மேலும்']) {
      expect(find.text(tab), findsWidgets, reason: tab);
    }
    await tester.tap(find.byIcon(FluentIcons.mic_24_filled));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Ravi annai 500 kadan');
    await tester.pump();
    expect(find.text('Ravi annai'), findsOneWidget);
    expect(find.text('Rs. 500.00'), findsOneWidget);
  });

  testWidgets('helper gets the three-tab shell and no Members', (tester) async {
    await pumpApp(tester);
    await signInUnlocked(tester, Role.helper);
    expect(find.text('நாள் முடிவு'), findsWidgets);
    expect(find.text('சரக்கு'), findsNothing);
    expect(find.text('மேலும்'), findsNothing);
  });

  testWidgets('owner opens Members from More; partner does not see it', (
    tester,
  ) async {
    await pumpApp(tester);
    await signInUnlocked(tester, Role.owner);
    await tester.tap(find.text('மேலும்'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('உறுப்பினர்கள்'));
    await tester.pumpAndSettle();
    expect(find.text('+94770000000'), findsOneWidget);
    expect(find.text('அழை'), findsOneWidget);
  });

  testWidgets('partner has no Members entry', (tester) async {
    await pumpApp(tester);
    await signInUnlocked(tester, Role.partner);
    await tester.tap(find.text('மேலும்'));
    await tester.pumpAndSettle();
    expect(find.text('உறுப்பினர்கள்'), findsNothing);
  });

  testWidgets('language switch changes the UI to English', (tester) async {
    await pumpApp(tester);
    await signInUnlocked(tester, Role.owner);
    await tester.tap(find.text('மேலும்'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Language'), findsOneWidget);
  });
}
