import 'dart:async';

import 'package:clock/clock.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

import '../../ledger/domain/ledger_repository.dart';
import '../../ledger/domain/models.dart';
import '../domain/collections.dart';

class WhoToAskRow extends Equatable {
  const WhoToAskRow({required this.customer, this.band, this.reason});

  /// Live customer: today's balance, not the 06:00 one.
  final Customer customer;
  final TrustBand? band;
  final TrustReason? reason;

  bool get paidSinceMorning => customer.balance.cents <= 0;

  @override
  List<Object?> get props => [customer, band, reason];
}

class WhoToAskState extends Equatable {
  const WhoToAskState({
    this.rows = const [],
    this.fallback = false,
    this.loading = true,
  });

  final List<WhoToAskRow> rows;

  /// No 06:00 list yet (new shop, before 6 AM, or offline): highest dues.
  final bool fallback;
  final bool loading;

  int get totalDueCents => rows.fold(
    0,
    (sum, r) => sum + (r.paidSinceMorning ? 0 : r.customer.balance.cents),
  );

  int get stillToAsk => rows.where((r) => !r.paidSinceMorning).length;

  @override
  List<Object?> get props => [rows, fallback, loading];
}

/// Who To Ask Today (PRD D5, US2, flow 7.1-3).
class WhoToAskCubit extends Cubit<WhoToAskState> {
  WhoToAskCubit({
    required this._collections,
    required this._ledger,
    required this.shopId,
  }) : super(const WhoToAskState()) {
    _subscription = Rx.combineLatest2(
      _collections.watchWhoToAsk(shopId, colomboDate(clock.now())),
      _ledger.watchCustomers(shopId),
      _rows,
    ).listen(emit);
  }

  final CollectionsRepository _collections;
  final LedgerRepository _ledger;
  final String shopId;
  final _snoozedToday = <String>{};
  WhoToAsk? _lastInsight;
  List<Customer> _lastCustomers = const [];
  late final StreamSubscription<WhoToAskState> _subscription;

  WhoToAskState _rows(WhoToAsk? insight, List<Customer> customers) {
    _lastInsight = insight;
    _lastCustomers = customers;
    final byId = {for (final c in customers) c.id: c};
    if (insight != null) {
      return WhoToAskState(
        loading: false,
        rows: [
          for (final item in insight.items)
            if (byId[item.customerId] case final c?
                when !_snoozedToday.contains(c.id))
              WhoToAskRow(customer: c, band: item.band, reason: item.reason),
        ],
      );
    }
    final now = clock.now();
    return WhoToAskState(
      loading: false,
      fallback: true,
      rows: [
        for (final c
            in customers
                .where(
                  (c) => c.balance.cents > 0 && !_snoozedToday.contains(c.id),
                )
                .take(10))
          WhoToAskRow(
            customer: c,
            reason: c.oldestUnpaidAt == null
                ? null
                : TrustReason(
                    'overdue',
                    now.difference(c.oldestUnpaidAt!).inDays,
                  ),
          ),
      ],
    );
  }

  void contacted(String customerId, CollectAction action) =>
      _collections.recordAction(shopId, customerId, action);

  void snooze(String customerId, DateTime until) {
    _collections.recordAction(
      shopId,
      customerId,
      CollectAction.snooze,
      snoozeUntil: until,
    );
    _snoozedToday.add(customerId);
    emit(_rows(_lastInsight, _lastCustomers));
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}

/// The next time [payDay] comes round (this month or next), at 06:00.
DateTime nextPayDay(int payDay, DateTime now) {
  DateTime at(int year, int month) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, payDay > lastDay ? lastDay : payDay, 6);
  }

  final thisMonth = at(now.year, now.month);
  return thisMonth.isAfter(now) ? thisMonth : at(now.year, now.month + 1);
}
