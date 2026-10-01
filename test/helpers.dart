import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_companion/app/app.dart';
import 'package:shop_companion/core/di/providers.dart';
import 'package:shop_companion/core/rbac/role.dart';
import 'package:shop_companion/features/auth/data/fake_auth_repository.dart';
import 'package:shop_companion/features/auth/data/secure_pin_store.dart';
import 'package:shop_companion/features/auth/domain/pin_hasher.dart';
import 'package:shop_companion/features/ledger/data/in_memory_ledger_repository.dart';
import 'package:shop_companion/features/settings/data/members_repositories.dart';

/// The whole app on the fake backend, with test doubles the test can poke.
class TestApp {
  TestApp({InMemoryLedgerRepository? ledger})
    : ledger = ledger ?? InMemoryLedgerRepository(uid: 'dev-user');

  final auth = FakeAuthRepository();
  final pins = InMemoryPinStore();
  final InMemoryLedgerRepository ledger;

  Future<void> pump(WidgetTester tester) async {
    // A typical Android phone (1080×2340 at 2.625x ≈ 411×891 dp).
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          pinStoreProvider.overrideWithValue(pins),
          biometricAuthProvider.overrideWithValue(const NoBiometricAuth()),
          membersRepositoryProvider.overrideWithValue(FakeMembersRepository()),
          ledgerRepositoryProvider.overrideWithValue(ledger),
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
}
