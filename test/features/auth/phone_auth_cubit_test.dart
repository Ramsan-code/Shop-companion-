import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_companion/core/failure.dart';
import 'package:shop_companion/core/phone.dart';
import 'package:shop_companion/features/auth/data/fake_auth_repository.dart';
import 'package:shop_companion/features/auth/domain/session.dart';
import 'package:shop_companion/features/auth/presentation/phone_auth_cubit.dart';

void main() {
  group('normalizeLkMobile (mirrors functions/src/phone.ts)', () {
    test('accepts local and international forms', () {
      for (final input in [
        '0771234567',
        '771234567',
        '94771234567',
        '+94 77 123 4567',
        '077-123-4567',
      ]) {
        expect(normalizeLkMobile(input), '+94771234567', reason: input);
      }
    });

    test('rejects landlines, foreign and short numbers', () {
      for (final input in ['0241234567', '+919876543210', '07712345', '']) {
        expect(normalizeLkMobile(input), isNull, reason: input);
      }
    });
  });

  late FakeAuthRepository repo;
  setUp(() => repo = FakeAuthRepository());
  tearDown(() => repo.dispose());

  blocTest<PhoneAuthCubit, PhoneAuthState>(
    'rejects a bad number without calling Firebase',
    build: () => PhoneAuthCubit(repo),
    act: (c) => c.sendCode('12345'),
    expect: () => [const EnterPhone(failure: ValidationFailure('phone'))],
  );

  blocTest<PhoneAuthCubit, PhoneAuthState>(
    'phone → code → signed in',
    build: () => PhoneAuthCubit(repo),
    act: (c) async {
      await c.sendCode('077 123 4567');
      await Future<void>.delayed(Duration.zero);
      await c.confirm(FakeAuthRepository.code);
    },
    expect: () => [
      const SendingCode(),
      isA<EnterCode>().having((s) => s.phone, 'phone', '+94771234567'),
      isA<EnterCode>().having((s) => s.verifying, 'verifying', true),
      const PhoneVerified(),
    ],
    verify: (_) async {
      expect(await repo.watchSession().first, isA<SignedIn>());
    },
  );

  blocTest<PhoneAuthCubit, PhoneAuthState>(
    'a wrong code stays on the code step with an error',
    build: () => PhoneAuthCubit(repo),
    act: (c) async {
      await c.sendCode('0771234567');
      await Future<void>.delayed(Duration.zero);
      await c.confirm('000000');
    },
    skip: 3,
    expect: () => [
      isA<EnterCode>()
          .having((s) => s.verifying, 'verifying', false)
          .having((s) => s.failure, 'failure', const ValidationFailure('code')),
    ],
  );

  blocTest<PhoneAuthCubit, PhoneAuthState>(
    'a code that is not 6 digits is refused locally',
    build: () => PhoneAuthCubit(repo),
    act: (c) async {
      await c.sendCode('0771234567');
      await Future<void>.delayed(Duration.zero);
      await c.confirm('12');
    },
    skip: 2,
    expect: () => [
      isA<EnterCode>().having(
        (s) => s.failure,
        'failure',
        const ValidationFailure('code'),
      ),
    ],
  );
}
