import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_companion/features/auth/data/secure_pin_store.dart';
import 'package:shop_companion/features/auth/domain/pin_hasher.dart';
import 'package:shop_companion/features/auth/domain/pin_store.dart';
import 'package:shop_companion/features/auth/presentation/app_lock_cubit.dart';

class _Biometric implements BiometricAuth {
  bool available = true;
  bool succeed = true;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate(String reason) async => succeed;
}

void main() {
  late InMemoryPinStore store;
  late _Biometric biometric;
  late int wipes;
  late int pinSets;

  AppLockCubit build() => AppLockCubit(
    store: store,
    biometrics: biometric,
    onWipe: () async => wipes++,
    onPinSet: () async => pinSets++,
  );

  setUp(() {
    store = InMemoryPinStore();
    biometric = _Biometric();
    wipes = 0;
    pinSets = 0;
  });

  test(
    'first sign-in asks for a PIN, then unlocks and records pinSet',
    () async {
      final lock = build();
      await lock.userChanged('u1');
      expect(lock.state.status, LockStatus.needsPin);
      await lock.setPin('2468');
      expect(lock.state.status, LockStatus.unlocked);
      expect(await store.read('u1'), isNotNull);
      expect(pinSets, 1);
      await lock.close();
    },
  );

  test('a returning user starts locked; right PIN unlocks', () async {
    await store.write('u1', PinHasher.create('2468', iterations: 100));
    final lock = build();
    await lock.userChanged('u1');
    expect(lock.state.status, LockStatus.locked);
    expect(lock.state.biometricAvailable, isTrue);
    expect(await lock.unlockWithPin('1111'), isFalse);
    expect(lock.state.attemptsLeft, 4);
    expect(await lock.unlockWithPin('2468'), isTrue);
    expect(lock.state.status, LockStatus.unlocked);
    expect(lock.state.failedAttempts, 0);
    await lock.close();
  });

  test('fingerprint unlocks when available', () async {
    await store.write('u1', PinHasher.create('2468', iterations: 100));
    final lock = build();
    await lock.userChanged('u1');
    biometric.succeed = false;
    await lock.unlockWithBiometric('why');
    expect(lock.state.status, LockStatus.locked);
    biometric.succeed = true;
    await lock.unlockWithBiometric('why');
    expect(lock.state.status, LockStatus.unlocked);
    await lock.close();
  });

  test('five wrong PINs wipe the PIN and sign out', () async {
    await store.write('u1', PinHasher.create('2468', iterations: 100));
    final lock = build();
    await lock.userChanged('u1');
    for (var i = 0; i < AppLockCubit.maxAttempts; i++) {
      await lock.unlockWithPin('0000');
    }
    expect(wipes, 1);
    expect(await store.read('u1'), isNull);
    await lock.close();
  });

  test('a different user on the phone needs their own PIN', () async {
    await store.write('u1', PinHasher.create('2468', iterations: 100));
    final lock = build();
    await lock.userChanged('u2');
    expect(lock.state.status, LockStatus.needsPin);
    await lock.userChanged(null);
    expect(lock.state.status, LockStatus.inactive);
    await lock.close();
  });

  test('auto-locks after 5 idle minutes; activity keeps it open', () {
    fakeAsync((async) {
      final lock = build();
      withClock(async.getClock(DateTime(2026, 10, 1, 9)), () {
        lock.userChanged('u1');
        async.flushMicrotasks();
        lock.setPin('2468');
        async.flushMicrotasks();
        expect(lock.state.status, LockStatus.unlocked);

        async.elapse(const Duration(minutes: 4));
        lock.userActivity();
        async.elapse(const Duration(minutes: 4));
        expect(lock.state.status, LockStatus.unlocked);

        async.elapse(const Duration(minutes: 1, seconds: 15));
        expect(lock.state.status, LockStatus.locked);
      });
      lock.close();
      async.flushMicrotasks();
    });
  });

  test('locks on return from 5+ minutes in the background', () {
    fakeAsync((async) {
      final lock = build();
      withClock(async.getClock(DateTime(2026, 10, 1, 9)), () {
        lock.userChanged('u1');
        async.flushMicrotasks();
        lock.setPin('2468');
        async.flushMicrotasks();
        lock.appPaused();
        async.elapse(const Duration(minutes: 2));
        lock.appResumed();
        expect(lock.state.status, LockStatus.unlocked);
        lock.appPaused();
        async.elapse(const Duration(minutes: 5));
        lock.appResumed();
        expect(lock.state.status, LockStatus.locked);
      });
      lock.close();
      async.flushMicrotasks();
    });
  });
}
