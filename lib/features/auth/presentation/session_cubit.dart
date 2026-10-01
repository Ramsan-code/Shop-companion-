import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/rbac/role.dart';
import '../domain/auth_repository.dart';
import '../domain/session.dart';

/// App-wide session. The router listens to it for redirects.
class SessionCubit extends Cubit<SessionState> {
  SessionCubit(this._repository) : super(const SessionUnknown()) {
    _subscription = _repository.watchSession().listen(emit);
  }

  final AuthRepository _repository;
  late final StreamSubscription<SessionState> _subscription;

  Future<void> signIn(String phone) => _repository.signIn(phone).run();

  Future<void> createShop(String name) =>
      _repository.createShop(name: name).run();

  Future<void> signOut() => _repository.signOut().run();

  Future<void> debugSignInAs(Role role) =>
      _repository.debugSignInAs(role).run();

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
