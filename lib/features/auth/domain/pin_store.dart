import 'pin_hasher.dart';

/// Where the PIN hash lives, per user (a new phone number means a new PIN).
abstract interface class PinStore {
  Future<PinHash?> read(String uid);

  Future<void> write(String uid, PinHash hash);

  Future<void> clear(String uid);
}

/// Fingerprint / face unlock (PRD C10).
abstract interface class BiometricAuth {
  Future<bool> isAvailable();

  Future<bool> authenticate(String reason);
}
