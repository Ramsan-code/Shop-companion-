import 'dart:async';

import 'package:clock/clock.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/pin_hasher.dart';
import '../domain/pin_store.dart';

enum LockStatus {
  /// No signed-in user, nothing to lock.
  inactive,

  /// Reading the PIN store.
  checking,

  /// Signed in on this phone for the first time: choose a PIN.
  needsPin,
  locked,
  unlocked,
}

class LockState extends Equatable {
  const LockState(
    this.status, {
    this.failedAttempts = 0,
    this.biometricAvailable = false,
  });

  final LockStatus status;
  final int failedAttempts;
  final bool biometricAvailable;

  int get attemptsLeft => AppLockCubit.maxAttempts - failedAttempts;

  LockState copyWith({LockStatus? status, int? failedAttempts}) => LockState(
    status ?? this.status,
    failedAttempts: failedAttempts ?? this.failedAttempts,
    biometricAvailable: biometricAvailable,
  );

  @override
  List<Object?> get props => [status, failedAttempts, biometricAvailable];
}

/// PIN and fingerprint app lock with auto-lock after 5 idle minutes (PRD C10).
///
/// After [maxAttempts] wrong PINs the stored PIN is wiped and [onWipe] signs
/// the user out, so getting back in needs a fresh phone OTP.
class AppLockCubit extends Cubit<LockState> {
  AppLockCubit({
    required this._store,
    required this._biometrics,
    required this._onWipe,
    this._onPinSet,
    this.idleTimeout = const Duration(minutes: 5),
  }) : super(const LockState(LockStatus.inactive));

  static const maxAttempts = 5;

  final PinStore _store;
  final BiometricAuth _biometrics;
  final Future<void> Function() _onWipe;
  final Future<void> Function()? _onPinSet;
  final Duration idleTimeout;

  String? _uid;
  DateTime _lastActivity = clock.now();
  Timer? _idleCheck;

  /// Called whenever the signed-in user changes (null when signed out).
  Future<void> userChanged(String? uid) async {
    if (uid == _uid) return;
    _uid = uid;
    _stopIdleCheck();
    if (uid == null) {
      emit(const LockState(LockStatus.inactive));
      return;
    }
    emit(const LockState(LockStatus.checking));
    final hash = await _store.read(uid);
    final biometric = hash != null && await _biometrics.isAvailable();
    if (_uid != uid) return; // changed again while reading
    // Every cold start or new sign-in starts locked.
    emit(
      LockState(
        hash == null ? LockStatus.needsPin : LockStatus.locked,
        biometricAvailable: biometric,
      ),
    );
  }

  Future<void> setPin(String pin) async {
    final uid = _uid;
    if (uid == null || state.status != LockStatus.needsPin) return;
    await _store.write(uid, PinHasher.create(pin));
    await _onPinSet?.call();
    _unlock();
  }

  /// Returns false for a wrong PIN.
  Future<bool> unlockWithPin(String pin) async {
    final uid = _uid;
    if (uid == null || state.status != LockStatus.locked) return false;
    final hash = await _store.read(uid);
    if (hash != null && PinHasher.verify(pin, hash)) {
      _unlock();
      return true;
    }
    final failed = state.failedAttempts + 1;
    if (failed >= maxAttempts) {
      await _store.clear(uid);
      emit(state.copyWith(failedAttempts: failed));
      await _onWipe();
      return false;
    }
    emit(state.copyWith(failedAttempts: failed));
    return false;
  }

  Future<void> unlockWithBiometric(String reason) async {
    if (state.status != LockStatus.locked || !state.biometricAvailable) return;
    if (await _biometrics.authenticate(reason)) _unlock();
  }

  /// Any touch on the screen.
  void userActivity() => _lastActivity = clock.now();

  /// App went to the background.
  void appPaused() => _lastActivity = clock.now();

  /// Back from the background: lock if away for [idleTimeout] or longer.
  void appResumed() => _checkIdle();

  void lockNow() {
    if (state.status == LockStatus.unlocked) {
      _stopIdleCheck();
      emit(state.copyWith(status: LockStatus.locked, failedAttempts: 0));
    }
  }

  void _unlock() {
    _lastActivity = clock.now();
    emit(state.copyWith(status: LockStatus.unlocked, failedAttempts: 0));
    _stopIdleCheck();
    _idleCheck = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _checkIdle(),
    );
  }

  void _checkIdle() {
    if (state.status != LockStatus.unlocked) return;
    if (clock.now().difference(_lastActivity) >= idleTimeout) lockNow();
  }

  void _stopIdleCheck() {
    _idleCheck?.cancel();
    _idleCheck = null;
  }

  @override
  Future<void> close() {
    _stopIdleCheck();
    return super.close();
  }
}
