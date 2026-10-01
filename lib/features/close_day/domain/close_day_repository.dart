import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/failure.dart';

/// What `onCashCounted` recorded for a day (`dayClosings/{date}`).
/// Holds profit, so only Owner/Partner can read it.
class DayClosing extends Equatable {
  const DayClosing({
    required this.expectedCashCents,
    required this.profitEstimateCents,
    this.countedCashCents,
    this.differenceCents,
    this.countedBy,
    this.closedAt,
  });

  final int expectedCashCents;
  final int profitEstimateCents;
  final int? countedCashCents;
  final int? differenceCents;
  final String? countedBy;
  final DateTime? closedAt;

  @override
  List<Object?> get props => [
    expectedCashCents,
    profitEstimateCents,
    countedCashCents,
    differenceCents,
    countedBy,
    closedAt,
  ];
}

/// Cash counts and the server's day closings (PRD C5).
abstract interface class CloseDayRepository {
  /// This user's count for [date] (`yyyy-mm-dd`). Offline-first: the
  /// server records the closing when it syncs.
  Result<Unit> saveCount(String shopId, String date, int countedCashCents);

  /// This user's saved count, null if none yet.
  Stream<int?> watchMyCount(String shopId, String date);

  /// The server's closing for [date]; null until recorded. Owner/Partner.
  Stream<DayClosing?> watchClosing(String shopId, String date);

  /// The drawer at the start of [date]: the last counted cash in the week
  /// before, else the shop's opening float, else zero. Same as the server.
  Future<int> openingCash(String shopId, String date);
}
