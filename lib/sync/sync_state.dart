import 'package:equatable/equatable.dart';
import 'package:redux/redux.dart';

import '../features/ledger/domain/ledger_repository.dart';

/// The sync engine's single store (PRD 9.1: redux, dispatched to only by
/// lib/sync). Screens read it for the pending badge and warnings.
class SyncState extends Equatable {
  const SyncState({
    this.online = true,
    this.pending = 0,
    this.oldestPendingAt,
    this.lastSyncedAt,
    this.conflicts = const [],
  });

  final bool online;

  /// Local writes the server hasn't received yet.
  final int pending;
  final DateTime? oldestPendingAt;

  /// Last moment the pending count dropped to zero while online.
  final DateTime? lastSyncedAt;

  /// Writes the server refused (shown so nothing disappears silently).
  final List<WriteRejection> conflicts;

  SyncState copyWith({
    bool? online,
    int? pending,
    DateTime? Function()? oldestPendingAt,
    DateTime? lastSyncedAt,
    List<WriteRejection>? conflicts,
  }) => SyncState(
    online: online ?? this.online,
    pending: pending ?? this.pending,
    oldestPendingAt: oldestPendingAt == null
        ? this.oldestPendingAt
        : oldestPendingAt(),
    lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    conflicts: conflicts ?? this.conflicts,
  );

  @override
  List<Object?> get props => [
    online,
    pending,
    oldestPendingAt,
    lastSyncedAt,
    conflicts,
  ];
}

sealed class SyncAction {
  const SyncAction();
}

final class ConnectivityChanged extends SyncAction {
  const ConnectivityChanged({required this.online});

  final bool online;
}

final class PendingChanged extends SyncAction {
  const PendingChanged(this.summary, {required this.at});

  final PendingSummary summary;
  final DateTime at;
}

final class WriteRejected extends SyncAction {
  const WriteRejected(this.rejection);

  final WriteRejection rejection;
}

final class ConflictsCleared extends SyncAction {
  const ConflictsCleared();
}

/// Keeps the conflict log bounded on a phone that is offline for weeks.
const maxConflicts = 50;

SyncState syncReducer(SyncState state, dynamic action) => switch (action) {
  ConnectivityChanged(:final online) => state.copyWith(online: online),
  PendingChanged(:final summary, :final at) => state.copyWith(
    pending: summary.count,
    oldestPendingAt: () => summary.count == 0 ? null : summary.oldestAt,
    lastSyncedAt: summary.count == 0 && state.online ? at : null,
  ),
  WriteRejected(:final rejection) => state.copyWith(
    conflicts: [
      ...state.conflicts,
      rejection,
    ].reversed.take(maxConflicts).toList().reversed.toList(),
  ),
  ConflictsCleared() => state.copyWith(conflicts: const []),
  _ => state,
};

Store<SyncState> createSyncStore() =>
    Store<SyncState>(syncReducer, initialState: const SyncState());

/// PRD 9.2-6: warn when anything has stayed unsynced for more than 24 hours.
const staleAfter = Duration(hours: 24);

bool isStale(SyncState state, DateTime now) {
  final oldest = state.oldestPendingAt;
  return state.pending > 0 &&
      oldest != null &&
      now.difference(oldest) > staleAfter;
}
