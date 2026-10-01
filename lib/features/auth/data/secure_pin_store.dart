import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import '../domain/pin_hasher.dart';
import '../domain/pin_store.dart';

/// PIN hash in Android Keystore-backed storage.
class SecurePinStore implements PinStore {
  SecurePinStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static String _key(String uid) => 'pin.$uid';

  @override
  Future<PinHash?> read(String uid) async {
    final raw = await _storage.read(key: _key(uid));
    if (raw == null) return null;
    return PinHash.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> write(String uid, PinHash hash) =>
      _storage.write(key: _key(uid), value: jsonEncode(hash.toJson()));

  @override
  Future<void> clear(String uid) => _storage.delete(key: _key(uid));
}

class InMemoryPinStore implements PinStore {
  final _hashes = <String, PinHash>{};

  @override
  Future<PinHash?> read(String uid) async => _hashes[uid];

  @override
  Future<void> write(String uid, PinHash hash) async => _hashes[uid] = hash;

  @override
  Future<void> clear(String uid) async => _hashes.remove(uid);
}

class LocalBiometricAuth implements BiometricAuth {
  LocalBiometricAuth([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported() &&
          (await _auth.getAvailableBiometrics()).isNotEmpty;
    } on Exception {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } on Exception {
      return false;
    }
  }
}

class NoBiometricAuth implements BiometricAuth {
  const NoBiometricAuth();

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<bool> authenticate(String reason) async => false;
}
