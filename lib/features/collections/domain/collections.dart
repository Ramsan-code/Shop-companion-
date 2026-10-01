import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/failure.dart';
import '../../ledger/domain/models.dart';

/// Trust Score bands (PRD D1).
enum TrustBand { excellent, good, watch, risky }

/// A plain-language reason, from functions/src/collections/scoring.ts.
class TrustReason extends Equatable {
  const TrustReason(this.code, [this.value]);

  /// newCustomer, overdue, regularPayer, noRecentPayment, paysMost,
  /// paysLittle, highBalance, longCustomer, settled, payDay
  final String code;
  final int? value;

  @override
  List<Object?> get props => [code, value];
}

/// customers/{id}/private/score: Owner and Partner only (PRD 6).
class TrustInfo extends Equatable {
  const TrustInfo({
    required this.score,
    required this.band,
    this.reasons = const [],
    this.creditLimitCents,
    this.computedLimitCents,
    this.overrideLimitCents,
  });

  final int score;
  final TrustBand band;
  final List<TrustReason> reasons;

  /// The Safe Credit Limit in force: the owner's override, else computed.
  final int? creditLimitCents;
  final int? computedLimitCents;
  final int? overrideLimitCents;

  bool get isOverridden => overrideLimitCents != null;

  @override
  List<Object?> get props => [
    score,
    band,
    reasons,
    creditLimitCents,
    computedLimitCents,
    overrideLimitCents,
  ];
}

class WhoToAskItem extends Equatable {
  const WhoToAskItem({
    required this.customerId,
    required this.name,
    required this.balanceCents,
    this.kinship,
    this.band,
    this.reason,
  });

  final String customerId;
  final String name;
  final Kinship? kinship;

  /// As at 06:00; the screen shows the live balance.
  final int balanceCents;
  final TrustBand? band;
  final TrustReason? reason;

  @override
  List<Object?> get props => [
    customerId,
    name,
    kinship,
    balanceCents,
    band,
    reason,
  ];
}

/// insights/{yyyy-mm-dd}, built at 06:00 Colombo time (PRD D5).
class WhoToAsk extends Equatable {
  const WhoToAsk({
    required this.date,
    required this.items,
    required this.totalDueCents,
  });

  final String date;
  final List<WhoToAskItem> items;
  final int totalDueCents;

  @override
  List<Object?> get props => [date, items, totalDueCents];
}

enum CollectAction { call, whatsapp, snooze }

/// The over-limit warning before saving credit (PRD D2, US4).
class LimitWarning extends Equatable {
  const LimitWarning({
    required this.limitCents,
    required this.balanceAfterCents,
  });

  final int limitCents;
  final int balanceAfterCents;

  @override
  List<Object?> get props => [limitCents, balanceAfterCents];
}

/// Null when within the limit or no limit is known (Helpers can't see it).
LimitWarning? checkCreditLimit({
  required TrustInfo? trust,
  required int balanceCents,
  required int creditCents,
}) {
  final limit = trust?.creditLimitCents;
  if (limit == null) return null;
  final after = balanceCents + creditCents;
  return after > limit
      ? LimitWarning(limitCents: limit, balanceAfterCents: after)
      : null;
}

/// Today's date in Sri Lanka (UTC+05:30), the insights document ID.
String colomboDate(DateTime now) => now
    .toUtc()
    .add(const Duration(hours: 5, minutes: 30))
    .toIso8601String()
    .substring(0, 10);

abstract interface class CollectionsRepository {
  Stream<TrustInfo?> watchTrust(String shopId, String customerId);

  Stream<WhoToAsk?> watchWhoToAsk(String shopId, String date);

  /// Local write (works offline): tomorrow's list skips them.
  Result<Unit> recordAction(
    String shopId,
    String customerId,
    CollectAction action, {
    DateTime? snoozeUntil,
  });

  /// `overrideLimit` callable; null clears the override. Returns the limit
  /// now in force.
  AsyncResult<int?> overrideLimit(
    String shopId,
    String customerId,
    int? limitCents,
  );
}
