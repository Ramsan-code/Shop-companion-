import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shop_companion/features/auth/domain/pin_hasher.dart';

void main() {
  test('verifies the right PIN and rejects others', () {
    final hash = PinHasher.create('4821', iterations: 1000);
    expect(PinHasher.verify('4821', hash), isTrue);
    expect(PinHasher.verify('4820', hash), isFalse);
    expect(PinHasher.verify('48210', hash), isFalse);
  });

  test('salts each hash', () {
    final a = PinHasher.create('1111', iterations: 1000);
    final b = PinHasher.create('1111', iterations: 1000);
    expect(a.salt, isNot(b.salt));
    expect(a.hash, isNot(b.hash));
  });

  test('round-trips through JSON', () {
    final hash = PinHasher.create('0007', iterations: 1000, random: Random(1));
    final restored = PinHash.fromJson(hash.toJson());
    expect(PinHasher.verify('0007', restored), isTrue);
  });

  test('PBKDF2-HMAC-SHA256 matches the published test vectors', () {
    String hex(List<int> b) =>
        b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    final password = utf8.encode('password');
    final salt = utf8.encode('salt');
    expect(
      hex(PinHasher.pbkdf2(password, salt, 1)),
      '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b',
    );
    expect(
      hex(PinHasher.pbkdf2(password, salt, 4096)),
      'c5e478d59288c841aa530db6845c4c8d962893a001ce4e11a4963873aa98134a',
    );
  });

  test('only 4-digit PINs', () {
    expect(PinHasher.isValidPin('1234'), isTrue);
    expect(PinHasher.isValidPin('12a4'), isFalse);
    expect(() => PinHasher.create('123'), throwsArgumentError);
  });
}
