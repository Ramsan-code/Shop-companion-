import 'dart:async';

import 'package:clock/clock.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

import '../../ledger/domain/ledger_repository.dart';
import '../../stock/domain/stock.dart';
import '../domain/close_day_repository.dart';
import '../domain/day_totals.dart';

class CloseDayState extends Equatable {
  const CloseDayState({
    required this.date,
    this.totals = const DayTotals(),
    this.lowStock = const [],
    this.myCountCents,
    this.closing,
    this.loading = true,
  });

  /// `yyyy-mm-dd` of the day being closed.
  final String date;

  /// Worked out on this phone from today's entries; matches the server.
  final DayTotals totals;
  final List<StockItem> lowStock;
  final int? myCountCents;

  /// What the server recorded once the count synced (Owner/Partner only).
  final DayClosing? closing;
  final bool loading;

  /// The latest count: the server's (anyone's) or this phone's.
  int? get countedCents => closing?.countedCashCents ?? myCountCents;

  /// Counted minus expected; null until counted.
  int? get differenceCents {
    final counted = countedCents;
    return counted == null ? null : counted - totals.expectedCashCents;
  }

  CloseDayState copyWith({
    DayTotals? totals,
    List<StockItem>? lowStock,
    int? myCountCents,
    DayClosing? closing,
    bool? loading,
  }) => CloseDayState(
    date: date,
    totals: totals ?? this.totals,
    lowStock: lowStock ?? this.lowStock,
    myCountCents: myCountCents ?? this.myCountCents,
    closing: closing ?? this.closing,
    loading: loading ?? this.loading,
  );

  @override
  List<Object?> get props => [
    date,
    totals,
    lowStock,
    myCountCents,
    closing,
    loading,
  ];
}

/// Close Day (PRD C5, flow 7.1-5). Owner/Partner see the day's totals and
/// Profit Mirror; a Helper only enters the count ([withTotals] false), since
/// the totals hold profit.
class CloseDayCubit extends Cubit<CloseDayState> {
  CloseDayCubit({
    required this._ledger,
    required this._stock,
    required this._closeDay,
    required this._shopId,
    required bool withTotals,
  }) : super(CloseDayState(date: dayKey(clock.now()))) {
    final date = state.date;
    _subs.add(
      _closeDay
          .watchMyCount(_shopId, date)
          .listen(
            (c) => emit(
              CloseDayState(
                date: date,
                totals: state.totals,
                lowStock: state.lowStock,
                myCountCents: c,
                closing: state.closing,
                loading: withTotals && state.loading,
              ),
            ),
          ),
    );
    if (!withTotals) return;
    _subs
      ..add(
        Rx.combineLatest3(
          _ledger.watchDayEntries(_shopId, clock.now()),
          _stock.watchItems(_shopId),
          Stream.fromFuture(_closeDay.openingCash(_shopId, date)),
          (entries, items, int opening) => (
            totals: DayTotals.of(
              entries,
              openingCashCents: opening,
              marginPercent: averageMarginPercent([
                for (final i in items)
                  (costCents: i.costCents, priceCents: i.priceCents),
              ]),
            ),
            low: items.where((i) => i.isLow).toList(),
          ),
        ).listen(
          (r) => emit(
            state.copyWith(totals: r.totals, lowStock: r.low, loading: false),
          ),
        ),
      )
      ..add(
        _closeDay
            .watchClosing(_shopId, date)
            .listen((c) => emit(state.copyWith(closing: c))),
      );
  }

  final LedgerRepository _ledger;
  final StockRepository _stock;
  final CloseDayRepository _closeDay;
  final String _shopId;
  final _subs = <StreamSubscription<Object?>>[];

  bool saveCount(int cents) =>
      _closeDay.saveCount(_shopId, state.date, cents).isRight();

  @override
  Future<void> close() async {
    for (final s in _subs) {
      await s.cancel();
    }
    return super.close();
  }
}
