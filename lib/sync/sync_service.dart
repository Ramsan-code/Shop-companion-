import 'dart:async';

import 'package:clock/clock.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:redux/redux.dart';

import '../features/ledger/domain/ledger_repository.dart';
import 'outbox/outbox_database.dart';
import 'sync_state.dart';

/// Feeds the sync store from connectivity and the ledger's pending writes.
/// The only code that dispatches to [store].
///
/// Firestore itself queues and uploads ledger writes (PRD 9.2); this service
/// only observes. Files (voice clips, photos) go through the drift outbox,
/// whose size this service also reports.
class SyncService {
  SyncService(this.store, {Stream<bool>? connectivity})
    : _connectivity = connectivity ?? _deviceConnectivity();

  final Store<SyncState> store;
  final Stream<bool> _connectivity;
  StreamSubscription<bool>? _online;
  StreamSubscription<PendingSummary>? _pending;
  StreamSubscription<int>? _outbox;

  static Stream<bool> _deviceConnectivity() async* {
    final c = Connectivity();
    bool isOnline(List<ConnectivityResult> r) =>
        r.any((x) => x != ConnectivityResult.none);
    yield isOnline(await c.checkConnectivity());
    yield* c.onConnectivityChanged.map(isOnline);
  }

  void start() {
    _online ??= _connectivity.distinct().listen(
      (online) => store.dispatch(ConnectivityChanged(online: online)),
    );
  }

  /// Follow one shop's pending writes; null stops (signed out / no shop).
  void watchShop(LedgerRepository? ledger, String? shopId) {
    unawaited(_pending?.cancel());
    _pending = null;
    if (ledger == null || shopId == null) {
      store.dispatch(PendingChanged(const PendingSummary(), at: clock.now()));
      return;
    }
    _pending = ledger
        .watchPending(shopId)
        .listen((s) => store.dispatch(PendingChanged(s, at: clock.now())));
  }

  void watchOutbox(OutboxDatabase db) {
    _outbox ??= db.watchPendingCount().listen(
      (n) => store.dispatch(OutboxChanged(n)),
    );
  }

  void reportRejection(WriteRejection rejection) =>
      store.dispatch(WriteRejected(rejection));

  Future<void> dispose() async {
    await _online?.cancel();
    await _pending?.cancel();
    await _outbox?.cancel();
  }
}
