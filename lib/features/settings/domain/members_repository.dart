import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/failure.dart';
import '../../../core/rbac/role.dart';

class Member extends Equatable {
  const Member({required this.uid, required this.phone, required this.role});

  final String uid;
  final String phone;
  final Role role;

  @override
  List<Object?> get props => [uid, phone, role];
}

class InviteLink extends Equatable {
  const InviteLink({required this.link, required this.expiresAt});

  final String link;
  final DateTime expiresAt;

  @override
  List<Object?> get props => [link, expiresAt];
}

/// Shop members (PRD 6, US9). Reads come from Firestore (owner-only by
/// Security Rules); changes go through the member callables.
abstract interface class MembersRepository {
  Stream<List<Member>> watchActiveMembers(String shopId);

  AsyncResult<InviteLink> invite({
    required String shopId,
    required String phone,
    required Role role,
  });

  AsyncResult<Unit> remove({required String shopId, required String uid});
}
