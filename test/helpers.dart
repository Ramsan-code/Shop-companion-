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
import 'package:shop_companion/features/voice/data/cloud_speech_input.dart';
import 'package:shop_companion/features/voice/domain/speech_input.dart';

/// The whole app on the fake backend, with test doubles the test can poke.
class TestApp {
  TestApp({InMemoryLedgerRepository? ledger, SpeechInput? cloud})
    : ledger = ledger ?? InMemoryLedgerRepository(uid: 'dev-user'),
      cloudSpeech = cloud;

  final auth = FakeAuthRepository();
  final pins = InMemoryPinStore();
  final InMemoryLedgerRepository ledger;
  final speech = FakeSpeechInput();
  final SpeechInput? cloudSpeech;
  final readBack = RecordingReadBack();

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
          readBackProvider.overrideWithValue(readBack),
          voiceEngineProvider.overrideWith(
            (ref, shopId) => VoiceEngine(device: speech, cloud: cloudSpeech),
          ),
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

/// A scripted recogniser: each listen() delivers the next queued result.
class FakeSpeechInput implements SpeechInput {
  FakeSpeechInput({this.available = true});

  bool available;
  final results = <SpeechEvent>[];
  int listens = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Stream<SpeechEvent> listen({
    List<String> phrases = const [],
    Duration maxDuration = const Duration(seconds: 8),
  }) async* {
    listens++;
    if (results.isEmpty) {
      yield const SpeechFailed(SpeechFailure.noSpeech);
      return;
    }
    yield results.removeAt(0);
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> cancel() async {}
}

class RecordingReadBack implements ReadBack {
  final spoken = <String>[];

  @override
  Future<void> speak(String text, {required String languageCode}) async =>
      spoken.add(text);

  @override
  Future<void> stop() async {}
}
