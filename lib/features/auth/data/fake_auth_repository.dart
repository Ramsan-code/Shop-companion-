import 'dart:async';

import 'package:fpdart/fpdart.dart';

import '../../../core/failure.dart';
import '../../../core/rbac/role.dart';
import '../domain/auth_repository.dart';
import '../domain/session.dart';

/// In-memory auth used until Phase 1 wires Firebase Authentication.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({SessionState initial = const SignedOut()})
    : _current = initial;

  final _controller = StreamController<SessionState>.broadcast();
  SessionState _current;

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
  AsyncResult<AppUser> signIn(String phone) => TaskEither(() async {
    final normalized = phone.replaceAll(RegExp(r'\D'), '');
    if (normalized.length < 9) {
      return left(const ValidationFailure('phone'));
    }
    final user = AppUser(uid: 'dev-$normalized', phone: '+94$normalized');
    _emit(SignedIn(user));
    return right(user);
  });

  @override
  AsyncResult<Membership> createShop({required String name}) =>
      TaskEither(() async {
        final state = _current;
        if (state is! SignedIn) return left(const PermissionFailure());
        if (name.trim().isEmpty) return left(const ValidationFailure('name'));
        final membership = Membership(
          shopId: 'dev-shop',
          shopName: name.trim(),
          role: Role.owner,
        );
        _emit(SignedIn(state.user, membership: membership));
        return right(membership);
      });

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
          shopId: 'dev-shop',
          shopName: 'Selvarasa Stores',
          role: role,
        ),
      ),
    );
    return right(unit);
  });

  Future<void> dispose() => _controller.close();
}
