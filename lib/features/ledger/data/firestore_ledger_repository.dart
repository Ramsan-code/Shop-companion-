import 'dart:async';

import 'package:clock/clock.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart' hide Result;
import 'package:fpdart/fpdart.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

import '../../../core/failure.dart';
import '../../auth/data/firebase_errors.dart';
import '../domain/entry_type.dart';
import '../domain/ledger_math.dart';
import '../domain/ledger_repository.dart';
import '../domain/models.dart';

/// Firestore-backed ledger (PRD 9.2).
///
/// Every write uses a UUID made on the phone as its document ID and is not
/// awaited: Firestore stores it locally at once and uploads it when signal
/// returns. Re-sending the same ID can't create a duplicate. If the server
/// later refuses a write, [onRejected] puts it in the sync conflict log.
class FirestoreLedgerRepository implements LedgerRepository {
  FirestoreLedgerRepository({
    required this._db,
    required this._functions,
    required this._currentUid,
    required this._onRejected,
    this._uuid = const Uuid(),
  });

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;
  final String Function() _currentUid;
  final void Function(WriteRejection) _onRejected;
  final Uuid _uuid;

  CollectionReference<Map<String, dynamic>> _customers(String shopId) =>
      _db.collection('shops/$shopId/customers');

  CollectionReference<Map<String, dynamic>> _entries(String shopId) =>
      _db.collection('shops/$shopId/entries');

  /// Entries the server hasn't applied yet: written here and not uploaded,
  /// or uploaded and waiting for onEntryCreated. Normally a handful.
  Stream<QuerySnapshot<Map<String, dynamic>>> _unapplied(String shopId) =>
      _entries(shopId)
          .where('applied', isNull: true)
          .snapshots(includeMetadataChanges: true);

  @override
  Stream<List<Customer>> watchCustomers(String shopId) => Rx.combineLatest2(
    _customers(shopId).snapshots(includeMetadataChanges: true),
    _unapplied(shopId),
    (customers, pending) {
      final pendingByCustomer = <String, int>{};
      for (final doc in pending.docs) {
        final entry = _entry(doc);
        final id = entry.customerId;
        if (id == null || entry.isDeleted) continue;
        pendingByCustomer[id] =
            (pendingByCustomer[id] ?? 0) +
            balanceDelta(entry.type, entry.amountCents);
      }
      return [
        for (final doc in customers.docs)
          _customer(doc).copyWith(pendingDeltaCents: pendingByCustomer[doc.id]),
      ]..sort(byDuesThenName);
    },
  );

  @override
  Stream<Customer?> watchCustomer(String shopId, String customerId) =>
      Rx.combineLatest2(
        _customers(shopId)
            .doc(customerId)
            .snapshots(includeMetadataChanges: true),
        watchEntries(shopId, customerId),
        (doc, entries) {
          if (!doc.exists) return null;
          final pending = entries.fold<int>(
            0,
            (total, e) => total + e.pendingDeltaFor(customerId),
          );
          return _customer(doc).copyWith(pendingDeltaCents: pending);
        },
      );

  @override
  Stream<List<LedgerEntry>> watchEntries(String shopId, String customerId) =>
      _entries(shopId)
          .where('customerId', isEqualTo: customerId)
          .orderBy('txnDate', descending: true)
          .limit(500)
          .snapshots(includeMetadataChanges: true)
          .map((snap) => snap.docs.map(_entry).toList()..sort(byTxnDateDesc));

  @override
  Stream<PendingSummary> watchPending(String shopId) => Rx.combineLatest2(
    _unapplied(shopId),
    _customers(shopId).snapshots(includeMetadataChanges: true),
    (entries, customers) {
      final pendingEntries = entries.docs.where(
        (d) => d.metadata.hasPendingWrites,
      );
      DateTime? oldest;
      for (final doc in pendingEntries) {
        final at = (doc.data()['deviceAt'] as Timestamp?)?.toDate();
        if (at != null && (oldest == null || at.isBefore(oldest))) {
          oldest = at;
        }
      }
      final pendingCustomers = customers.docs
          .where((d) => d.metadata.hasPendingWrites)
          .length;
      return PendingSummary(
        count: pendingEntries.length + pendingCustomers,
        oldestAt: oldest,
      );
    },
  ).distinct();

  @override
  Result<String> addCustomer(String shopId, CustomerDraft draft) => _write(() {
    final id = _uuid.v4();
    _track(
      _customers(shopId).doc(id).set({
        ..._customerFields(draft),
        'reminderConsent': false,
        'createdBy': _currentUid(),
        'createdAt': FieldValue.serverTimestamp(),
      }),
      'customers/$id',
    );
    return id;
  });

  @override
  Result<Unit> updateCustomer(String shopId, String id, CustomerDraft draft) =>
      _write(() {
        _track(
          _customers(shopId).doc(id).update({
            ..._customerFields(draft),
            'updatedAt': FieldValue.serverTimestamp(),
          }),
          'customers/$id',
        );
        return unit;
      });

  @override
  Result<String> addEntry(String shopId, EntryDraft draft) => _write(() {
    if (affectsCustomer(draft.type) && draft.customerId == null) {
      throw const _Invalid('customer');
    }
    final clientId = _uuid.v4();
    _track(
      _entries(shopId).doc(clientId).set({
        'clientId': clientId,
        'shopId': shopId,
        'type': draft.type.name,
        'amountCents': draft.amountCents,
        if (draft.customerId != null) 'customerId': draft.customerId,
        if (draft.method != null) 'method': draft.method!.name,
        if (draft.note != null && draft.note!.isNotEmpty) 'note': draft.note,
        'txnDate': Timestamp.fromDate(draft.txnDate),
        'deviceAt': Timestamp.fromDate(clock.now()),
        'source': draft.source,
        'createdBy': _currentUid(),
        'createdAt': FieldValue.serverTimestamp(),
        'applied': null,
      }),
      'entries/$clientId',
    );
    return clientId;
  });

  @override
  Result<Unit> editOwnEntry(
    String shopId,
    String entryId, {
    required int amountCents,
    String? note,
  }) => _write(() {
    _track(
      _entries(shopId).doc(entryId).update({
        'amountCents': amountCents,
        'note': ?note,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _currentUid(),
      }),
      'entries/$entryId',
    );
    return unit;
  });

  @override
  AsyncResult<Unit> editAnyEntry(
    String shopId,
    String entryId, {
    required int amountCents,
    String? note,
  }) => _call('editEntry', {
    'shopId': shopId,
    'entryId': entryId,
    'amountCents': amountCents,
    'note': ?note,
  });

  @override
  AsyncResult<Unit> deleteEntry(
    String shopId,
    String entryId, {
    String? reason,
  }) => _call('deleteEntry', {
    'shopId': shopId,
    'entryId': entryId,
    'reason': ?reason,
  });

  AsyncResult<Unit> _call(String name, Map<String, Object?> data) =>
      TaskEither.tryCatch(() async {
        await _functions.httpsCallable(name).call<Object?>(data);
        return unit;
      }, (e, _) => failureFromFirebase(e));

  /// Not awaited on purpose (offline-first); a later refusal is logged.
  void _track(Future<void> write, String path) {
    unawaited(
      write.catchError((Object e) {
        _onRejected(
          WriteRejection(
            path: path,
            failure: failureFromFirebase(e),
            at: clock.now(),
          ),
        );
      }),
    );
  }

  Result<T> _write<T>(T Function() body) {
    try {
      return right(body());
    } on _Invalid catch (e) {
      return left(ValidationFailure(e.field));
    }
  }

  static Map<String, Object?> _customerFields(CustomerDraft d) => {
    'name': d.name.trim(),
    'phone': d.phone,
    'kinshipTerm': d.kinship?.name,
    'village': d.village?.trim(),
    'incomeType': d.incomeType?.name,
    'payDay': d.payDay,
  };

  static Customer _customer(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return Customer(
      id: doc.id,
      name: d['name'] as String? ?? '',
      phone: d['phone'] as String?,
      kinship: Kinship.values.byWire(d['kinshipTerm']),
      village: d['village'] as String?,
      incomeType: IncomeType.values.byWire(d['incomeType']),
      payDay: d['payDay'] as int?,
      balanceCents: d['balanceCents'] as int? ?? 0,
      oldestUnpaidAt: (d['oldestUnpaidAt'] as Timestamp?)?.toDate(),
      hasPendingWrites: doc.metadata.hasPendingWrites,
    );
  }

  static LedgerEntry _entry(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    final applied = d['applied'] as Map<String, dynamic>?;
    return LedgerEntry(
      id: doc.id,
      type: EntryType.fromWire(d['type'] as String? ?? '') ?? EntryType.sale,
      amountCents: d['amountCents'] as int? ?? 0,
      txnDate:
          (d['txnDate'] as Timestamp?)?.toDate() ??
          (d['deviceAt'] as Timestamp?)?.toDate() ??
          clock.now(),
      createdBy: d['createdBy'] as String? ?? '',
      customerId: d['customerId'] as String?,
      method: PaymentMethod.values.byWire(d['method']),
      note: d['note'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      deletedAt: (d['deletedAt'] as Timestamp?)?.toDate(),
      applied: applied == null
          ? null
          : Applied(
              customerId: applied['customerId'] as String?,
              deltaCents: applied['deltaCents'] as int? ?? 0,
            ),
      hasPendingWrites: doc.metadata.hasPendingWrites,
    );
  }
}

class _Invalid implements Exception {
  const _Invalid(this.field);

  final String field;
}
