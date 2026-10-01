import 'dart:async';

import 'package:fpdart/fpdart.dart';

import '../../../core/failure.dart';
import '../../../core/rbac/role.dart';
import '../domain/auth_repository.dart';
import '../domain/session.dart';

/// In-memory backend for UI work without Firebase (`--dart-define=BACKEND=fake`)
/// and for widget tests. The OTP is always [code].
class FakeAuthRepository implements AuthRepository, DebugSignIn {
  FakeAuthRepository({SessionState initial = const SignedOut()})
    : _current = initial;

  static const code = '123456';

  /// Invite tokens the fake accepts, and the role each grants.
  final invites = <String, Role>{'demo-partner': Role.partner};

  final _controller = StreamController<SessionState>.broadcast();
  SessionState _current;
  String? _pendingPhone;

  void _emit(SessionState state) {
    _current = state;
    _controller.add(state);
  }

  @override
  Stream<SessionState> watchSession() async* {
    yield _current;
    yield* _controller.stream;
  }

  @override
  Stream<PhoneAuthEvent> startPhoneSignIn(
    String e164Phone, {
    int? resendToken,
  }) async* {
    _pendingPhone = e164Phone;
    yield CodeSent('fake-verification', resendToken: (resendToken ?? 0) + 1);
  }

  @override
  AsyncResult<Unit> confirmCode({
    required String verificationId,
    required String smsCode,
  }) => TaskEither(() async {
    final phone = _pendingPhone;
    if (phone == null) return left(const ExpiredFailure('code'));
    if (smsCode != code) return left(const ValidationFailure('code'));
    _emit(SignedIn(AppUser(uid: 'fake-$phone', phone: phone)));
    return right(unit);
  });

  @override
  AsyncResult<Unit> createShop({required String name}) => TaskEither(() async {
    final state = _current;
    if (state is! SignedIn) return left(const PermissionFailure());
    if (state.membership != null) return left(const ConflictFailure());
    if (name.trim().isEmpty) return left(const ValidationFailure('name'));
    _emit(
      SignedIn(
        state.user,
        membership: Membership(
          shopId: 'fake-shop',
          shopName: name.trim(),
          role: Role.owner,
        ),
      ),
    );
    return right(unit);
  });

  @override
  AsyncResult<JoinedShop> acceptInvite(String token) => TaskEither(() async {
    final state = _current;
    if (state is! SignedIn) return left(const PermissionFailure());
    if (state.membership != null) return left(const ConflictFailure());
    final role = invites.remove(token);
    if (role == null) return left(const NotFoundFailure());
    _emit(
      SignedIn(
        state.user,
        membership: Membership(
          shopId: 'fake-shop',
          shopName: 'Selvarasa Stores',
          role: role,
        ),
      ),
    );
    return right(JoinedShop(shopId: 'fake-shop', role: role));
  });

  @override
  AsyncResult<Unit> markPinSet() => TaskEither.of(unit);

  @override
  AsyncResult<Unit> signOut() => TaskEither(() async {
    _emit(const SignedOut());
    return right(unit);
  });

  @override
  AsyncResult<Unit> debugSignInAs(Role role) => TaskEither(() async {
    _emit(
      SignedIn(
        const AppUser(uid: 'dev-user', phone: '+94770000000'),
        membership: Membership(
          shopId: 'fake-shop',
          shopName: 'Selvarasa Stores',
          role: role,
        ),
      ),
    );
    return right(unit);
  });

  Future<void> dispose() => _controller.close();
}
