import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart' hide Result;
import 'package:fpdart/fpdart.dart';
import 'package:rxdart/rxdart.dart';

import '../../../core/failure.dart';
import '../../auth/data/firebase_errors.dart';
import '../../ledger/domain/models.dart';
import '../domain/collections.dart';

class FirestoreCollectionsRepository implements CollectionsRepository {
  FirestoreCollectionsRepository({
    required this._db,
    required this._functions,
    required this._currentUid,
  });

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;
  final String Function() _currentUid;

  @override
  Stream<TrustInfo?> watchTrust(String shopId, String customerId) => _db
      .doc('shops/$shopId/customers/$customerId/private/score')
      .snapshots()
      .map((doc) => doc.exists ? trustFromMap(doc.data()!) : null)
      // Helpers get permission-denied by design: no trust info for them.
      .onErrorReturn(null);

  @override
  Stream<WhoToAsk?> watchWhoToAsk(String shopId, String date) => _db
      .doc('shops/$shopId/insights/$date')
      .snapshots()
      .map((doc) => doc.exists ? whoToAskFromMap(doc.data()!) : null)
      .onErrorReturn(null);

  @override
  Result<Unit> recordAction(
    String shopId,
    String customerId,
    CollectAction action, {
    DateTime? snoozeUntil,
  }) {
    unawaited(
      _db
          .doc('shops/$shopId/collectState/$customerId')
          .set({
            'lastAction': action.name,
            'lastActionAt': FieldValue.serverTimestamp(),
            if (snoozeUntil != null)
              'snoozedUntil': Timestamp.fromDate(snoozeUntil),
            'updatedBy': _currentUid(),
          }, SetOptions(merge: true))
          .catchError((Object _) {}),
    );
    return right(unit);
  }

  @override
  AsyncResult<int?> overrideLimit(
    String shopId,
    String customerId,
    int? limitCents,
  ) => TaskEither.tryCatch(() async {
    final result = await _functions
        .httpsCallable('overrideLimit')
        .call<Map<String, dynamic>>({
          'shopId': shopId,
          'customerId': customerId,
          'limitCents': limitCents,
        });
    return result.data['creditLimitCents'] as int?;
  }, (e, _) => failureFromFirebase(e));
}

TrustReason _reason(Object? raw) {
  final m = raw! as Map<String, dynamic>;
  return TrustReason(m['code'] as String, m['value'] as int?);
}

TrustInfo trustFromMap(Map<String, dynamic> d) => TrustInfo(
  score: d['trustScore'] as int? ?? 0,
  band: TrustBand.values.byWire(d['trustBand']) ?? TrustBand.watch,
  reasons: [for (final r in d['reasons'] as List? ?? const []) _reason(r)],
  creditLimitCents: d['creditLimitCents'] as int?,
  computedLimitCents: d['computedLimitCents'] as int?,
  overrideLimitCents: d['overrideLimitCents'] as int?,
);

WhoToAsk whoToAskFromMap(Map<String, dynamic> d) => WhoToAsk(
  date: d['date'] as String? ?? '',
  totalDueCents: d['totalDueCents'] as int? ?? 0,
  items: [
    for (final raw in d['whoToAsk'] as List? ?? const [])
      if (raw case final Map<String, dynamic> m)
        WhoToAskItem(
          customerId: m['customerId'] as String,
          name: m['name'] as String? ?? '',
          kinship: Kinship.values.byWire(m['kinship']),
          balanceCents: m['balanceCents'] as int? ?? 0,
          band: TrustBand.values.byWire(m['band']),
          reason: m['reason'] == null ? null : _reason(m['reason']),
        ),
  ],
);

/// Fake backend and tests: fixed trust per customer, no morning list until
/// one is set (the screen then shows its highest-dues fallback).
class InMemoryCollectionsRepository implements CollectionsRepository {
  InMemoryCollectionsRepository({Map<String, TrustInfo>? trust, this.whoToAsk})
    : trust = {...?trust};

  /// Demo trust for the fake backend's demo customers.
  factory InMemoryCollectionsRepository.demo() => InMemoryCollectionsRepository(
    trust: const {
      'ravi': TrustInfo(
        score: 45,
        band: TrustBand.watch,
        reasons: [TrustReason('overdue', 20), TrustReason('paysLittle', 22)],
        creditLimitCents: 200000,
        computedLimitCents: 200000,
      ),
      'selvi': TrustInfo(
        score: 70,
        band: TrustBand.good,
        reasons: [TrustReason('newCustomer')],
        creditLimitCents: 300000,
        computedLimitCents: 300000,
      ),
      'kumar': TrustInfo(
        score: 85,
        band: TrustBand.excellent,
        reasons: [TrustReason('regularPayer', 4)],
        creditLimitCents: 500000,
        computedLimitCents: 500000,
      ),
    },
  );

  final Map<String, TrustInfo> trust;
  WhoToAsk? whoToAsk;
  final actions = <(String, CollectAction, DateTime?)>[];
  final _changes = StreamController<void>.broadcast();

  Stream<T> _watch<T>(T Function() read) => Stream.multi((controller) {
    controller.add(read());
    final sub = _changes.stream.listen((_) => controller.add(read()));
    // Don't hand back the cancel future: `.first` would wait on it.
    controller.onCancel = () => unawaited(sub.cancel());
  });

  @override
  Stream<TrustInfo?> watchTrust(String shopId, String customerId) =>
      _watch(() => trust[customerId]);

  @override
  Stream<WhoToAsk?> watchWhoToAsk(String shopId, String date) =>
      _watch(() => whoToAsk?.date == date ? whoToAsk : null);

  @override
  Result<Unit> recordAction(
    String shopId,
    String customerId,
    CollectAction action, {
    DateTime? snoozeUntil,
  }) {
    actions.add((customerId, action, snoozeUntil));
    return right(unit);
  }

  @override
  AsyncResult<int?> overrideLimit(
    String shopId,
    String customerId,
    int? limitCents,
  ) => TaskEither(() async {
    final current = trust[customerId];
    if (current == null) return left(const NotFoundFailure());
    final effective = limitCents ?? current.computedLimitCents;
    trust[customerId] = TrustInfo(
      score: current.score,
      band: current.band,
      reasons: current.reasons,
      creditLimitCents: effective,
      computedLimitCents: current.computedLimitCents,
      overrideLimitCents: limitCents,
    );
    _changes.add(null);
    return right(effective);
  });

  void setWhoToAsk(WhoToAsk? value) {
    whoToAsk = value;
    _changes.add(null);
  }

  Future<void> dispose() => _changes.close();
}
