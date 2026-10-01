import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';

/// A salted PBKDF2-HMAC-SHA256 hash of the 4-digit app PIN (PRD C10).
///
/// The hash lives only in flutter_secure_storage (Android Keystore), never in
/// Firestore. A 4-digit PIN has only 10,000 values, so the hash alone is not
/// the protection: the Keystore-encrypted storage and the 5-attempt limit in
/// AppLockCubit are.
class PinHash {
  const PinHash({
    required this.salt,
    required this.hash,
    required this.iterations,
  });

  factory PinHash.fromJson(Map<String, dynamic> json) => PinHash(
    salt: json['salt'] as String,
    hash: json['hash'] as String,
    iterations: json['iterations'] as int,
  );

  final String salt;
  final String hash;
  final int iterations;

  Map<String, dynamic> toJson() => {
    'salt': salt,
    'hash': hash,
    'iterations': iterations,
  };
}

abstract final class PinHasher {
  /// Tuned to stay well under 100 ms on a 2 GB Android Go phone.
  static const defaultIterations = 20000;

  static final _pin = RegExp(r'^\d{4}$');

  static bool isValidPin(String pin) => _pin.hasMatch(pin);

  static PinHash create(
    String pin, {
    int iterations = defaultIterations,
    Random? random,
  }) {
    if (!isValidPin(pin)) throw ArgumentError.value(pin, 'pin', '4 digits');
    final rng = random ?? Random.secure();
    final salt = Uint8List.fromList(
      List<int>.generate(16, (_) => rng.nextInt(256)),
    );
    return PinHash(
      salt: base64Encode(salt),
      hash: base64Encode(pbkdf2(utf8.encode(pin), salt, iterations)),
      iterations: iterations,
    );
  }

  static bool verify(String pin, PinHash stored) {
    if (!isValidPin(pin)) return false;
    final candidate = pbkdf2(
      utf8.encode(pin),
      base64Decode(stored.salt),
      stored.iterations,
    );
    final expected = base64Decode(stored.hash);
    if (candidate.length != expected.length) return false;
    // Constant-time comparison.
    var diff = 0;
    for (var i = 0; i < candidate.length; i++) {
      diff |= candidate[i] ^ expected[i];
    }
    return diff == 0;
  }

  /// PBKDF2 with a single 32-byte block (RFC 8018).
  @visibleForTesting
  static List<int> pbkdf2(List<int> password, List<int> salt, int rounds) {
    final hmac = Hmac(sha256, password);
    var u = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
    final out = List<int>.from(u);
    for (var i = 1; i < rounds; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < out.length; j++) {
        out[j] ^= u[j];
      }
    }
    return out;
  }
}
