import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_companion/core/failure.dart';
import 'package:shop_companion/features/customers/presentation/customer_detail_cubit.dart';
import 'package:shop_companion/features/ledger/data/in_memory_ledger_repository.dart';
import 'package:shop_companion/features/ledger/domain/entry_type.dart';
import 'package:shop_companion/features/ledger/domain/ledger_math.dart';
import 'package:shop_companion/features/ledger/domain/models.dart';

void main() {
  final day = DateTime(2026, 10, 1, 12);

  test('balanceDelta mirrors functions/src/ledger/balance.ts', () {
    expect(balanceDelta(EntryType.credit, 500), 500);
    expect(balanceDelta(EntryType.payment, 500), -500);
    expect(balanceDelta(EntryType.discount, 500), -500);
    for (final t in [EntryType.sale, EntryType.expense, EntryType.purchase]) {
      expect(balanceDelta(t, 500), 0);
      expect(affectsCustomer(t), isFalse);
    }
  });

  group('LedgerEntry', () {
    LedgerEntry entry({
      Applied? applied,
      int amount = 500,
      DateTime? deleted,
    }) => LedgerEntry(
      id: 'e',
      type: EntryType.credit,
      amountCents: amount,
      txnDate: day,
      createdBy: 'u1',
      customerId: 'ravi',
      createdAt: day,
      applied: applied,
      deletedAt: deleted,
    );

    test('pending delta = what the server has not applied yet', () {
      expect(entry().pendingDeltaFor('ravi'), 500);
      expect(entry().isPending, isTrue);
      final done = entry(
        applied: const Applied(customerId: 'ravi', deltaCents: 500),
      );
      expect(done.pendingDeltaFor('ravi'), 0);
      expect(done.isPending, isFalse);
      // Edited to 700 locally; server applied 500 so far.
      expect(
        entry(
          amount: 700,
          applied: const Applied(customerId: 'ravi', deltaCents: 500),
        ).pendingDeltaFor('ravi'),
        200,
      );
      // Deleted locally: reverse what was applied.
      expect(
        entry(
          deleted: day,
          applied: const Applied(customerId: 'ravi', deltaCents: 500),
        ).pendingDeltaFor('ravi'),
        -500,
      );
    });

    test('the author edits directly for 24 hours only', () {
      final e = entry();
      expect(
        e.canEditDirectly('u1', day.add(const Duration(hours: 23))),
        isTrue,
      );
      expect(
        e.canEditDirectly('u1', day.add(const Duration(hours: 25))),
        isFalse,
      );
      expect(e.canEditDirectly('u2', day), isFalse);
    });
  });

  test('customers sort by highest dues, then name', () {
    const a = Customer(id: 'a', name: 'Arun', balanceCents: 100);
    const b = Customer(id: 'b', name: 'bala', balanceCents: 900);
    const c = Customer(id: 'c', name: 'Chitra', balanceCents: 100);
    expect(([c, a, b]..sort(byDuesThenName)).map((x) => x.id), ['b', 'a', 'c']);
  });

  group('offline behaviour (US6)', () {
    late InMemoryLedgerRepository repo;
    setUp(
      () => repo = InMemoryLedgerRepository(
        autoApply: false,
        customers: const [Customer(id: 'ravi', name: 'Ravi')],
      ),
    );
    tearDown(() => repo.dispose());

    test('balance shows at once as pending, then is confirmed without double-counting', () async {
      repo.addEntry(
        's',
        EntryDraft(
          type: EntryType.credit,
          amountCents: 50000,
          customerId: 'ravi',
          txnDate: day,
        ),
      );
      repo.addEntry(
        's',
        EntryDraft(
          type: EntryType.payment,
          amountCents: 20000,
          customerId: 'ravi',
          txnDate: day,
        ),
      );
      var ravi = (await repo.watchCustomers('s').first).single;
      expect(ravi.balance.cents, 30000);
      expect(ravi.balanceCents, 0);
      expect(ravi.isPending, isTrue);
      expect((await repo.watchPending('s').first).count, 2);

      repo.applyPending();
      repo.applyPending(); // a retried trigger
      ravi = (await repo.watchCustomers('s').first).single;
      expect(ravi.balanceCents, 30000);
      expect(ravi.balance.cents, 30000);
      expect(ravi.isPending, isFalse);
      expect((await repo.watchPending('s').first).count, 0);
    });

    test('credit without a customer is refused before saving', () {
      final result = repo.addEntry(
        's',
        EntryDraft(type: EntryType.credit, amountCents: 1, txnDate: day),
      );
      expect(
        result.getLeft().toNullable(),
        const ValidationFailure('customer'),
      );
      expect(
        repo
            .addEntry(
              's',
              EntryDraft(type: EntryType.sale, amountCents: 1, txnDate: day),
            )
            .isRight(),
        isTrue,
      );
    });
  });

  test(
    'detail cubit: running balance, owner delete, helper limited to 24 hours',
    () async {
      final repo = InMemoryLedgerRepository(
        customers: const [Customer(id: 'ravi', name: 'Ravi')],
      );
      await withClock(Clock.fixed(day), () async {
        repo.addEntry(
          's',
          EntryDraft(
            type: EntryType.credit,
            amountCents: 50000,
            customerId: 'ravi',
            txnDate: day.subtract(const Duration(days: 3)),
          ),
        );
        repo.addEntry(
          's',
          EntryDraft(
            type: EntryType.credit,
            amountCents: 20000,
            customerId: 'ravi',
            txnDate: day.subtract(const Duration(days: 2)),
          ),
        );
        repo.addEntry(
          's',
          EntryDraft(
            type: EntryType.payment,
            amountCents: 10000,
            customerId: 'ravi',
            txnDate: day,
          ),
        );
      });
      final cubit = CustomerDetailCubit(repo, 's', 'ravi');
      await pumpEventQueue();
      final entries = cubit.state.entries;
      expect(entries.map((e) => e.type), [
        EntryType.payment,
        EntryType.credit,
        EntryType.credit,
      ]);
      final running = cubit.state.runningBalances;
      expect(entries.map((e) => running[e.id]), [60000, 70000, 50000]);

      expect(await cubit.deleteEntry(entries[1]), isTrue);
      await pumpEventQueue();
      expect(cubit.state.customer!.balance.cents, 40000);
      expect(cubit.state.runningBalances[entries.first.id], 40000);
      await cubit.close();
      await repo.dispose();
    },
  );
}
