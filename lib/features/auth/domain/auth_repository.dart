import 'package:fpdart/fpdart.dart';

import '../../../core/failure.dart';
import '../../../core/rbac/role.dart';
import 'session.dart';

/// Phase 0 contract. Phase 1 implements it with Firebase phone OTP,
/// the `createShop` callable and the membership snapshot.
abstract interface class AuthRepository {
  Stream<SessionState> watchSession();

  AsyncResult<AppUser> signIn(String phone);

  AsyncResult<Membership> createShop({required String name});

  AsyncResult<Unit> signOut();

  /// Development only: jump straight into a role's shell.
  AsyncResult<Unit> debugSignInAs(Role role);
}
