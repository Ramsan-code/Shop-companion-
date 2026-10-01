import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_companion/features/customers/presentation/customers_bloc.dart';
import 'package:shop_companion/features/ledger/data/in_memory_ledger_repository.dart';
import 'package:shop_companion/features/ledger/domain/models.dart';

void main() {
  const customers = [
    Customer(
      id: 'r',
      name: 'Ravi',
      village: 'Nedunkerny',
      phone: '+94771234567',
    ),
    Customer(id: 's', name: 'Selvi', village: 'Cheddikulam'),
    Customer(id: 'k', name: 'Kumar'),
  ];

  blocTest<CustomersBloc, CustomersState>(
    'debounces typing and searches name, village and phone',
    build: () =>
        CustomersBloc(InMemoryLedgerRepository(customers: customers), 'shop'),
    act: (bloc) async {
      bloc.add(const CustomersStarted());
      bloc
        ..add(const CustomersSearchChanged('n'))
        ..add(const CustomersSearchChanged('ne'))
        ..add(const CustomersSearchChanged('ned'));
      await Future<void>.delayed(const Duration(milliseconds: 400));
    },
    wait: const Duration(milliseconds: 50),
    expect: () => [
      isA<CustomersState>().having((s) => s.all.length, 'all', 3),
      // Only the last keystroke lands.
      isA<CustomersState>().having(
        (s) => s.visible.map((c) => c.id),
        'visible',
        ['r'],
      ),
    ],
  );

  test('phone search needs 3+ digits', () {
    const state = CustomersState(all: customers, query: '234', loading: false);
    expect(state.visible.map((c) => c.id), ['r']);
    expect(const CustomersState(all: customers, query: '23').visible, isEmpty);
    expect(
      const CustomersState(all: customers, query: 'CHEDDI').visible.single.id,
      's',
    );
  });
}
