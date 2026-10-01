import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/failure.dart';

/// One stock line (PRD C6). Quantities can be fractional (2.5 kg).
class StockItem extends Equatable {
  const StockItem({
    required this.id,
    required this.name,
    required this.qty,
    this.unit,
    this.lowStockAt,
    this.costCents,
    this.priceCents,
    this.hasPendingWrites = false,
  });

  final String id;
  final String name;
  final String? unit;
  final num qty;

  /// Alert at or below this quantity; null = no alert.
  final num? lowStockAt;
  final int? costCents;
  final int? priceCents;
  final bool hasPendingWrites;

  bool get isLow => lowStockAt != null && qty <= lowStockAt!;

  @override
  List<Object?> get props => [
    id,
    name,
    unit,
    qty,
    lowStockAt,
    costCents,
    priceCents,
    hasPendingWrites,
  ];
}

class StockItemDraft extends Equatable {
  const StockItemDraft({
    required this.name,
    required this.qty,
    this.unit,
    this.lowStockAt,
    this.costCents,
    this.priceCents,
  });

  final String name;
  final String? unit;
  final num qty;
  final num? lowStockAt;
  final int? costCents;
  final int? priceCents;

  @override
  List<Object?> get props => [
    name,
    unit,
    qty,
    lowStockAt,
    costCents,
    priceCents,
  ];
}

/// Why a quantity changed (`stockMoves.reason`).
enum StockMoveReason { sold, received, adjust, damaged }

/// Items sorted for the stock screen: low stock first, then by name.
int lowFirstThenName(StockItem a, StockItem b) {
  if (a.isLow != b.isLow) return a.isLow ? -1 : 1;
  return a.name.toLowerCase().compareTo(b.name.toLowerCase());
}

/// Stock items (PRD C6). Writes are offline-first, like the ledger.
/// Owner/Partner (`stock:manage`) add and edit items; Helpers
/// (`stock:updateQty`) only change quantities.
abstract interface class StockRepository {
  Stream<List<StockItem>> watchItems(String shopId);

  Result<String> addItem(String shopId, StockItemDraft draft);

  Result<Unit> updateItem(String shopId, String id, StockItemDraft draft);

  /// Adds [delta] (negative to take away) and records why.
  Result<Unit> changeQty(
    String shopId,
    String id,
    num delta,
    StockMoveReason reason,
  );
}
