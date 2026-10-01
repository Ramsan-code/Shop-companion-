import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/failure.dart';
import '../../../core/phone.dart';
import '../../../core/rbac/role.dart';
import '../../auth/data/firebase_errors.dart';
import '../domain/members_repository.dart';

class FirebaseMembersRepository implements MembersRepository {
  FirebaseMembersRepository({
    required FirebaseFirestore firestore,
    required this._functions,
  }) : _db = firestore;

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  @override
  Stream<List<Member>> watchActiveMembers(String shopId) => _db
      .collection('shops/$shopId/members')
      .where('status', isEqualTo: 'active')
      .snapshots()
      .map(
        (snap) => [
          for (final doc in snap.docs)
            if (Role.fromWire(doc.data()['role'] as String? ?? '')
                case final role?)
              Member(
                uid: doc.id,
                phone: doc.data()['phone'] as String? ?? '',
                role: role,
              ),
        ]..sort(_byRoleThenPhone),
      );

  @override
  AsyncResult<InviteLink> invite({
    required String shopId,
    required String phone,
    required Role role,
  }) => TaskEither.tryCatch(() async {
    final result = await _functions
        .httpsCallable('inviteMember')
        .call<Map<String, dynamic>>({
          'shopId': shopId,
          'phone': phone,
          'role': role.name,
        });
    return InviteLink(
      link: result.data['link'] as String,
      expiresAt: DateTime.parse(result.data['expiresAt'] as String),
    );
  }, (e, _) => failureFromFirebase(e));

  @override
  AsyncResult<Unit> remove({required String shopId, required String uid}) =>
      TaskEither.tryCatch(() async {
        await _functions.httpsCallable('removeMember').call<Object?>({
          'shopId': shopId,
          'uid': uid,
        });
        return unit;
      }, (e, _) => failureFromFirebase(e));
}

int _byRoleThenPhone(Member a, Member b) {
  final byRole = a.role.index.compareTo(b.role.index);
  return byRole != 0 ? byRole : a.phone.compareTo(b.phone);
}

class FakeMembersRepository implements MembersRepository {
  FakeMembersRepository({List<Member>? members})
    : _members =
          members ??
          [
            const Member(
              uid: 'dev-user',
              phone: '+94770000000',
              role: Role.owner,
            ),
          ];

  final List<Member> _members;
  final _changes = StreamController<void>.broadcast();

  @override
  Stream<List<Member>> watchActiveMembers(String shopId) =>
      Stream.multi((controller) {
        controller.add(List.unmodifiable(_members));
        final sub = _changes.stream.listen(
          (_) => controller.add(List.unmodifiable(_members)),
        );
        controller.onCancel = sub.cancel;
      });

  @override
  AsyncResult<InviteLink> invite({
    required String shopId,
    required String phone,
    required Role role,
  }) => TaskEither(() async {
    final normalized = normalizeLkMobile(phone);
    if (normalized == null || role == Role.owner || role == Role.admin) {
      return left(const ValidationFailure('argument'));
    }
    return right(
      InviteLink(
        link: 'https://shop-companion-dev.web.app/invite/demo-${role.name}',
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      ),
    );
  });

  @override
  AsyncResult<Unit> remove({required String shopId, required String uid}) =>
      TaskEither(() async {
        final index = _members.indexWhere((m) => m.uid == uid);
        if (index < 0) return left(const NotFoundFailure());
        if (_members[index].role == Role.owner) {
          return left(const PermissionFailure('failed-precondition'));
        }
        _members.removeAt(index);
        _changes.add(null);
        return right(unit);
      });
}
