import 'dart:async';

import 'package:clock/clock.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';

import '../../../core/failure.dart';
import '../../auth/data/firebase_errors.dart';
import '../../ledger/domain/ledger_repository.dart';
import '../domain/stock.dart';

class FirestoreStockRepository implements StockRepository {
  FirestoreStockRepository({
    required this._db,
    required this._currentUid,
    required this._onRejected,
    this._uuid = const Uuid(),
  });

  final FirebaseFirestore _db;
  final String Function() _currentUid;
  final void Function(WriteRejection) _onRejected;
  final Uuid _uuid;

  CollectionReference<Map<String, dynamic>> _items(String shopId) =>
      _db.collection('shops/$shopId/items');

  @override
  Stream<List<StockItem>> watchItems(String shopId) =>
      _items(shopId)
          .snapshots(includeMetadataChanges: true)
          .map(
            (snap) => [
              for (final doc in snap.docs)
                StockItem(
                  id: doc.id,
                  name: doc.data()['name'] as String? ?? '',
                  unit: doc.data()['unit'] as String?,
                  qty: doc.data()['qty'] as num? ?? 0,
                  lowStockAt: doc.data()['lowStockAt'] as num?,
                  costCents: doc.data()['costCents'] as int?,
                  priceCents: doc.data()['priceCents'] as int?,
                  hasPendingWrites: doc.metadata.hasPendingWrites,
                ),
            ]..sort(lowFirstThenName),
          );

  static Map<String, Object?> _fields(StockItemDraft d) => {
    'name': d.name.trim(),
    'unit': d.unit,
    'qty': d.qty,
    'lowStockAt': d.lowStockAt,
    'costCents': d.costCents,
    'priceCents': d.priceCents,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  @override
  Result<String> addItem(String shopId, StockItemDraft draft) {
    if (draft.name.trim().isEmpty) return left(const ValidationFailure('name'));
    final id = _uuid.v4();
    _track(
      _items(shopId).doc(id).set({
        ..._fields(draft),
        'createdBy': _currentUid(),
        'createdAt': FieldValue.serverTimestamp(),
      }),
      'items/$id',
    );
    return right(id);
  }

  @override
  Result<Unit> updateItem(String shopId, String id, StockItemDraft draft) {
    if (draft.name.trim().isEmpty) return left(const ValidationFailure('name'));
    _track(_items(shopId).doc(id).update(_fields(draft)), 'items/$id');
    return right(unit);
  }

  @override
  Result<Unit> changeQty(
    String shopId,
    String id,
    num delta,
    StockMoveReason reason,
  ) {
    if (delta == 0) return right(unit);
    // An increment, so two phones changing it offline both count.
    _track(
      _items(shopId).doc(id).update({
        'qty': FieldValue.increment(delta),
        'updatedAt': FieldValue.serverTimestamp(),
      }),
      'items/$id',
    );
    final moveId = _uuid.v4();
    _track(
      _db.doc('shops/$shopId/stockMoves/$moveId').set({
        'itemId': id,
        'deltaQty': delta,
        'reason': reason.name,
        'createdBy': _currentUid(),
        'createdAt': FieldValue.serverTimestamp(),
      }),
      'stockMoves/$moveId',
    );
    return right(unit);
  }

  /// Not awaited on purpose (offline-first); a later refusal is logged.
  void _track(Future<void> write, String path) => unawaited(
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

/// Stock without Firebase: the `fake` backend and widget tests.
class InMemoryStockRepository implements StockRepository {
  InMemoryStockRepository({Iterable<StockItem> items = const []}) {
    for (final i in items) {
      _items[i.id] = i;
    }
  }

  factory InMemoryStockRepository.demo() => InMemoryStockRepository(
    items: const [
      StockItem(
        id: 'rice',
        name: 'அரிசி',
        unit: 'kg',
        qty: 42,
        lowStockAt: 10,
        costCents: 22000,
        priceCents: 26000,
      ),
      StockItem(
        id: 'sugar',
        name: 'சீனி',
        unit: 'kg',
        qty: 3,
        lowStockAt: 5,
        costCents: 26000,
        priceCents: 30000,
      ),
      StockItem(
        id: 'dhal',
        name: 'பருப்பு',
        unit: 'kg',
        qty: 12,
        lowStockAt: 4,
        costCents: 30000,
        priceCents: 36000,
      ),
      StockItem(id: 'soap', name: 'சவர்க்காரம்', qty: 20),
    ],
  );

  final _items = <String, StockItem>{};
  final moves = <({String itemId, num delta, StockMoveReason reason})>[];
  final _changes = StreamController<void>.broadcast();
  final _uuid = const Uuid();

  @override
  Stream<List<StockItem>> watchItems(String shopId) =>
      Stream.multi((controller) {
        List<StockItem> read() =>
            _items.values.toList()..sort(lowFirstThenName);
        controller.add(read());
        final sub = _changes.stream.listen((_) => controller.add(read()));
        controller.onCancel = () => unawaited(sub.cancel());
      });

  StockItem _item(String id, StockItemDraft d) => StockItem(
    id: id,
    name: d.name.trim(),
    unit: d.unit,
    qty: d.qty,
    lowStockAt: d.lowStockAt,
    costCents: d.costCents,
    priceCents: d.priceCents,
  );

  @override
  Result<String> addItem(String shopId, StockItemDraft draft) {
    if (draft.name.trim().isEmpty) return left(const ValidationFailure('name'));
    final id = _uuid.v4();
    _items[id] = _item(id, draft);
    _changes.add(null);
    return right(id);
  }

  @override
  Result<Unit> updateItem(String shopId, String id, StockItemDraft draft) {
    if (!_items.containsKey(id)) return left(const NotFoundFailure());
    if (draft.name.trim().isEmpty) return left(const ValidationFailure('name'));
    _items[id] = _item(id, draft);
    _changes.add(null);
    return right(unit);
  }

  @override
  Result<Unit> changeQty(
    String shopId,
    String id,
    num delta,
    StockMoveReason reason,
  ) {
    final i = _items[id];
    if (i == null) return left(const NotFoundFailure());
    _items[id] = StockItem(
      id: i.id,
      name: i.name,
      unit: i.unit,
      qty: i.qty + delta,
      lowStockAt: i.lowStockAt,
      costCents: i.costCents,
      priceCents: i.priceCents,
    );
    moves.add((itemId: id, delta: delta, reason: reason));
    _changes.add(null);
    return right(unit);
  }

  Future<void> dispose() => _changes.close();
}
