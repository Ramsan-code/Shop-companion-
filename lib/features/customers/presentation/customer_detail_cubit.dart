import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:rxdart/rxdart.dart';

import '../../../core/failure.dart';
import '../../ledger/domain/ledger_repository.dart';
import '../../ledger/domain/models.dart';

class CustomerDetailState extends Equatable {
  const CustomerDetailState({
    this.customer,
    this.entries = const [],
    this.loading = true,
    this.busy = false,
    this.failure,
  });

  final Customer? customer;

  /// Newest first by transaction date.
  final List<LedgerEntry> entries;
  final bool loading;
  final bool busy;
  final Failure? failure;

  /// Balance right after each entry (PRD C2 running balance), oldest-first
  /// arithmetic shown newest first. Deleted entries don't move it.
  Map<String, int> get runningBalances {
    final c = customer;
    if (c == null) return const {};
    final result = <String, int>{};
    var balance = 0;
    for (final e in entries.reversed) {
      balance += e.desiredDeltaFor(c.id);
      result[e.id] = balance;
    }
    return result;
  }

  CustomerDetailState copyWith({
    Customer? customer,
    List<LedgerEntry>? entries,
    bool? loading,
    bool? busy,
    Failure? failure,
  }) => CustomerDetailState(
    customer: customer ?? this.customer,
    entries: entries ?? this.entries,
    loading: loading ?? this.loading,
    busy: busy ?? this.busy,
    failure: failure,
  );

  @override
  List<Object?> get props => [customer, entries, loading, busy, failure];
}

class CustomerDetailCubit extends Cubit<CustomerDetailState> {
  CustomerDetailCubit(this._repository, this.shopId, this.customerId)
    : super(const CustomerDetailState()) {
    _subscription =
        Rx.combineLatest2(
          _repository.watchCustomer(shopId, customerId),
          _repository.watchEntries(shopId, customerId),
          (Customer? c, List<LedgerEntry> e) => (c, e),
        ).listen(
          (data) => emit(
            state.copyWith(customer: data.$1, entries: data.$2, loading: false),
          ),
        );
  }

  final LedgerRepository _repository;
  final String shopId;
  final String customerId;
  late final StreamSubscription<(Customer?, List<LedgerEntry>)> _subscription;

  /// Own entry within 24 hours: a local write. Otherwise the editEntry call.
  Future<bool> editEntry(
    LedgerEntry entry, {
    required int amountCents,
    String? note,
    required bool direct,
  }) async {
    if (direct) {
      final result = _repository.editOwnEntry(
        shopId,
        entry.id,
        amountCents: amountCents,
        note: note,
      );
      return result.match((f) {
        emit(state.copyWith(failure: f));
        return false;
      }, (_) => true);
    }
    return _remote(
      _repository
          .editAnyEntry(shopId, entry.id, amountCents: amountCents, note: note)
          .run(),
    );
  }

  Future<bool> deleteEntry(LedgerEntry entry) =>
      _remote(_repository.deleteEntry(shopId, entry.id).run());

  Future<bool> _remote(Future<Either<Failure, Unit>> call) async {
    emit(state.copyWith(busy: true));
    final failure = (await call).getLeft().toNullable();
    emit(state.copyWith(busy: false, failure: failure));
    return failure == null;
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
