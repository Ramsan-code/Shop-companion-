import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/failure.dart';
import '../../../core/rbac/role.dart';
import '../domain/members_repository.dart';

class MembersState extends Equatable {
  const MembersState({
    this.members = const [],
    this.loading = true,
    this.busy = false,
    this.failure,
  });

  final List<Member> members;
  final bool loading;

  /// An invite or removal is in flight.
  final bool busy;
  final Failure? failure;

  MembersState copyWith({
    List<Member>? members,
    bool? loading,
    bool? busy,
    Failure? failure,
  }) => MembersState(
    members: members ?? this.members,
    loading: loading ?? this.loading,
    busy: busy ?? this.busy,
    failure: failure,
  );

  @override
  List<Object?> get props => [members, loading, busy, failure];
}

class MembersCubit extends Cubit<MembersState> {
  MembersCubit(this._repository, this.shopId) : super(const MembersState()) {
    _subscription = _repository
        .watchActiveMembers(shopId)
        .listen(
          (members) => emit(state.copyWith(members: members, loading: false)),
          onError: (Object _) => emit(
            state.copyWith(loading: false, failure: const PermissionFailure()),
          ),
        );
  }

  final MembersRepository _repository;
  final String shopId;
  late final StreamSubscription<List<Member>> _subscription;

  /// Returns the link to share, or null (the failure is in the state).
  Future<InviteLink?> invite(String phone, Role role) async {
    emit(state.copyWith(busy: true));
    final result = await _repository
        .invite(shopId: shopId, phone: phone, role: role)
        .run();
    return result.match(
      (failure) {
        emit(state.copyWith(busy: false, failure: failure));
        return null;
      },
      (link) {
        emit(state.copyWith(busy: false));
        return link;
      },
    );
  }

  Future<void> remove(String uid) async {
    emit(state.copyWith(busy: true));
    final result = await _repository.remove(shopId: shopId, uid: uid).run();
    emit(state.copyWith(busy: false, failure: result.getLeft().toNullable()));
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
