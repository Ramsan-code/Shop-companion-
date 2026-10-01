import 'package:equatable/equatable.dart';

import '../../../core/rbac/role.dart';

/// The signed-in user's link to one shop (`shops/{shopId}/members/{uid}`).
class Membership extends Equatable {
  const Membership({
    required this.shopId,
    required this.shopName,
    required this.role,
  });

  final String shopId;
  final String shopName;
  final Role role;

  @override
  List<Object?> get props => [shopId, shopName, role];
}

class AppUser extends Equatable {
  const AppUser({required this.uid, required this.phone});

  final String uid;
  final String phone;

  @override
  List<Object?> get props => [uid, phone];
}

/// What the router needs to pick a screen: signed out, signed in without a
/// shop (go to setup), or signed in with a shop (role picks the shell).
sealed class SessionState extends Equatable {
  const SessionState();

  @override
  List<Object?> get props => [];
}

final class SessionUnknown extends SessionState {
  const SessionUnknown();
}

final class SignedOut extends SessionState {
  const SignedOut();
}

final class SignedIn extends SessionState {
  const SignedIn(this.user, {this.membership});

  final AppUser user;
  final Membership? membership;

  @override
  List<Object?> get props => [user, membership];
}
