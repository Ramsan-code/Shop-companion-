import 'dart:async';

import 'package:clock/clock.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/failure.dart';
import '../../auth/data/firebase_errors.dart';
import '../../ledger/domain/ledger_repository.dart';
import '../domain/close_day_repository.dart';
import '../domain/day_totals.dart';

/// The [n] calendar days before [date], newest first.
List<String> previousDays(String date, int n) {
  final d = DateTime.parse(date);
  return [
    for (var i = 1; i <= n; i++) dayKey(DateTime(d.year, d.month, d.day - i)),
  ];
}

class FirestoreCloseDayRepository implements CloseDayRepository {
  FirestoreCloseDayRepository({
    required this._db,
    required this._currentUid,
    required this._onRejected,
  });

  final FirebaseFirestore _db;
  final String Function() _currentUid;
  final void Function(WriteRejection) _onRejected;

  DocumentReference<Map<String, dynamic>> _closing(String shopId, String d) =>
      _db.doc('shops/$shopId/dayClosings/$d');

  @override
  Result<Unit> saveCount(String shopId, String date, int countedCashCents) {
    if (countedCashCents < 0) return left(const ValidationFailure('amount'));
    final path = 'dayClosings/$date/counts/${_currentUid()}';
    unawaited(
      _closing(shopId, date)
          .collection('counts')
          .doc(_currentUid())
          .set({
            'countedCashCents': countedCashCents,
            'at': FieldValue.serverTimestamp(),
          })
          .catchError((Object e) {
            _onRejected(
              WriteRejection(
                path: path,
                failure: failureFromFirebase(e),
                at: clock.now(),
              ),
            );
          }),
    );
    return right(unit);
  }

  @override
  Stream<int?> watchMyCount(String shopId, String date) =>
      _closing(shopId, date)
          .collection('counts')
          .doc(_currentUid())
          .snapshots()
          .map((doc) => doc.data()?['countedCashCents'] as int?);

  @override
  Stream<DayClosing?> watchClosing(String shopId, String date) =>
      _closing(shopId, date).snapshots().map((doc) {
        final d = doc.data();
        if (d == null) return null;
        return DayClosing(
          expectedCashCents: d['expectedCashCents'] as int? ?? 0,
          profitEstimateCents: d['profitEstimateCents'] as int? ?? 0,
          countedCashCents: d['countedCashCents'] as int?,
          differenceCents: d['differenceCents'] as int?,
          countedBy: d['countedBy'] as String?,
          closedAt: (d['closedAt'] as Timestamp?)?.toDate(),
        );
      });

  @override
  Future<int> openingCash(String shopId, String date) async {
    try {
      for (final day in previousDays(date, 7)) {
        final doc = await _closing(shopId, day).get();
        final counted = doc.data()?['countedCashCents'];
        if (counted is int) return counted;
      }
      final shop = await _db.doc('shops/$shopId').get();
      final settings = shop.data()?['settings'] as Map<String, dynamic>?;
      return settings?['openingFloatCents'] as int? ?? 0;
    } on FirebaseException {
      // Offline with nothing cached: start from zero; the server's closing
      // has the real opening once the count syncs.
      return 0;
    }
  }
}

/// Close Day without Firebase. It also plays the server: saving a count
/// records the closing with the totals [totalsFor] gives.
class InMemoryCloseDayRepository implements CloseDayRepository {
  InMemoryCloseDayRepository({
    this.uid = 'dev-user',
    this.openingFloatCents = 0,
    this.totalsFor,
  });

  final String uid;
  final int openingFloatCents;

  /// Supplies the day's totals when a count is saved; none = no closing.
  Future<DayTotals> Function(String shopId, String date)? totalsFor;

  final _counts = <String, Map<String, ({int cents, DateTime at})>>{};
  final _closings = <String, DayClosing>{};
  final _changes = StreamController<void>.broadcast();

  Stream<T> _watch<T>(T Function() read) => Stream.multi((controller) {
    controller.add(read());
    final sub = _changes.stream.listen((_) => controller.add(read()));
    controller.onCancel = () => unawaited(sub.cancel());
  });

  @override
  Result<Unit> saveCount(String shopId, String date, int countedCashCents) {
    if (countedCashCents < 0) return left(const ValidationFailure('amount'));
    (_counts[date] ??= {})[uid] = (cents: countedCashCents, at: clock.now());
    _changes.add(null);
    final totals = totalsFor;
    if (totals != null) {
      unawaited(
        totals(shopId, date).then((t) {
          _closings[date] = DayClosing(
            expectedCashCents: t.expectedCashCents,
            profitEstimateCents: t.profitEstimateCents,
            countedCashCents: countedCashCents,
            differenceCents: countedCashCents - t.expectedCashCents,
            countedBy: uid,
            closedAt: clock.now(),
          );
          if (!_changes.isClosed) _changes.add(null);
        }),
      );
    }
    return right(unit);
  }

  @override
  Stream<int?> watchMyCount(String shopId, String date) =>
      _watch(() => _counts[date]?[uid]?.cents);

  @override
  Stream<DayClosing?> watchClosing(String shopId, String date) =>
      _watch(() => _closings[date]);

  @override
  Future<int> openingCash(String shopId, String date) async {
    for (final day in previousDays(date, 7)) {
      final counted = _closings[day]?.countedCashCents;
      if (counted != null) return counted;
    }
    return openingFloatCents;
  }

  Future<void> dispose() => _changes.close();
}
