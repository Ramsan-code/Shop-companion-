import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shop_companion/core/failure.dart';
import 'package:shop_companion/features/ledger/data/in_memory_ledger_repository.dart';
import 'package:shop_companion/features/ledger/domain/entry_type.dart';
import 'package:shop_companion/features/ledger/domain/ledger_repository.dart';
import 'package:shop_companion/features/ledger/domain/models.dart';
import 'package:shop_companion/sync/sync_service.dart';
import 'package:shop_companion/sync/sync_state.dart';

void main() {
  final t0 = DateTime(2026, 10, 1, 9);

  group('syncReducer', () {
    test('tracks pending writes and the last full sync', () {
      var s = const SyncState();
      s = syncReducer(
        s,
        PendingChanged(PendingSummary(count: 3, oldestAt: t0), at: t0),
      );
      expect(s.pending, 3);
      expect(s.oldestPendingAt, t0);
      expect(s.lastSyncedAt, isNull);

      final later = t0.add(const Duration(minutes: 5));
      s = syncReducer(s, PendingChanged(const PendingSummary(), at: later));
      expect(s.pending, 0);
      expect(s.oldestPendingAt, isNull);
      expect(s.lastSyncedAt, later);
    });

    test('offline with nothing pending is not a sync', () {
      var s = syncReducer(
        const SyncState(),
        const ConnectivityChanged(online: false),
      );
      s = syncReducer(s, PendingChanged(const PendingSummary(), at: t0));
      expect(s.online, isFalse);
      expect(s.lastSyncedAt, isNull);
    });

    test('keeps at most $maxConflicts refused writes, newest last', () {
      var s = const SyncState();
      for (var i = 0; i < maxConflicts + 5; i++) {
        s = syncReducer(
          s,
          WriteRejected(
            WriteRejection(
              path: 'entries/$i',
              failure: const PermissionFailure(),
              at: t0,
            ),
          ),
        );
      }
      expect(s.conflicts, hasLength(maxConflicts));
      expect(s.conflicts.last.path, 'entries/${maxConflicts + 4}');
      expect(syncReducer(s, const ConflictsCleared()).conflicts, isEmpty);
    });

    test('outbox uploads count towards what is waiting', () {
      var s = syncReducer(const SyncState(pending: 2), const OutboxChanged(3));
      expect(s.waiting, 5);
      s = syncReducer(s, const OutboxChanged(0));
      expect(s.waiting, 2);
    });

    test('warns after 24 hours unsynced (PRD 9.2-6)', () {
      final s = SyncState(pending: 1, oldestPendingAt: t0);
      expect(isStale(s, t0.add(const Duration(hours: 23))), isFalse);
      expect(isStale(s, t0.add(const Duration(hours: 25))), isTrue);
      expect(
        isStale(const SyncState(), t0.add(const Duration(days: 9))),
        isFalse,
      );
    });
  });

  test(
    'SyncService feeds connectivity and pending writes into the store',
    () async {
      final online = StreamController<bool>();
      final store = createSyncStore();
      final service = SyncService(store, connectivity: online.stream)..start();
      final repo = InMemoryLedgerRepository(
        autoApply: false,
        customers: const [Customer(id: 'ravi', name: 'Ravi')],
      );
      service.watchShop(repo, 'shop');

      online.add(false);
      repo.addEntry(
        'shop',
        EntryDraft(
          type: EntryType.credit,
          amountCents: 500,
          customerId: 'ravi',
          txnDate: t0,
        ),
      );
      await pumpEventQueue();
      expect(store.state.online, isFalse);
      expect(store.state.pending, 1);

      online.add(true);
      repo.applyPending();
      await pumpEventQueue();
      expect(store.state.online, isTrue);
      expect(store.state.pending, 0);
      expect(store.state.lastSyncedAt, isNotNull);

      service.watchShop(null, null);
      await service.dispose();
      await online.close();
      await repo.dispose();
    },
  );
}
