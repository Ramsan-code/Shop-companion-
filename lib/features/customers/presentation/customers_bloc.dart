import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rxdart/rxdart.dart';

import '../../ledger/domain/ledger_repository.dart';
import '../../ledger/domain/models.dart';

sealed class CustomersEvent {
  const CustomersEvent();
}

final class CustomersStarted extends CustomersEvent {
  const CustomersStarted();
}

final class CustomersSearchChanged extends CustomersEvent {
  const CustomersSearchChanged(this.query);

  final String query;
}

class CustomersState extends Equatable {
  const CustomersState({
    this.all = const [],
    this.query = '',
    this.loading = true,
  });

  final List<Customer> all;
  final String query;
  final bool loading;

  /// Matches name, village or phone digits; highest dues first.
  List<Customer> get visible {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;
    final digits = q.replaceAll(RegExp(r'\D'), '');
    return [
      for (final c in all)
        if (c.name.toLowerCase().contains(q) ||
            (c.village?.toLowerCase().contains(q) ?? false) ||
            (digits.length >= 3 &&
                (c.phone?.replaceAll(RegExp(r'\D'), '').contains(digits) ??
                    false)))
          c,
    ];
  }

  @override
  List<Object?> get props => [all, query, loading];
}

/// Customer list with search (PRD C2). Voice search joins in Phase 3.
class CustomersBloc extends Bloc<CustomersEvent, CustomersState> {
  CustomersBloc(this._repository, this._shopId)
    : super(const CustomersState()) {
    on<CustomersStarted>(
      (_, emit) => emit.forEach(
        _repository.watchCustomers(_shopId),
        onData: (customers) =>
            CustomersState(all: customers, query: state.query, loading: false),
      ),
    );
    // PRD 8.2: rxdart debounces search inside blocs.
    on<CustomersSearchChanged>(
      (event, emit) => emit(
        CustomersState(
          all: state.all,
          query: event.query,
          loading: state.loading,
        ),
      ),
      transformer: (events, mapper) => events
          .debounceTime(const Duration(milliseconds: 250))
          .switchMap(mapper),
    );
  }

  final LedgerRepository _repository;
  final String _shopId;
}
