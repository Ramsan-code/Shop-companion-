import 'dart:async';

import 'package:clock/clock.dart';
import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';

import '../../../core/failure.dart';
import '../domain/entry_type.dart';
import '../domain/ledger_math.dart';
import '../domain/ledger_repository.dart';
import '../domain/models.dart';

/// The ledger without Firebase: the `fake` backend and widget tests.
///
/// It plays the server's part too: entries are applied to balances at once
/// unless [autoApply] is false, which leaves them pending, as on a phone
/// with no signal.
class InMemoryLedgerRepository implements LedgerRepository {
  InMemoryLedgerRepository({
    this.uid = 'dev-user',
    this.autoApply = true,
    Iterable<Customer> customers = const [],
  }) {
    for (final c in customers) {
      _customers[c.id] = c;
    }
  }

  /// A small demo shop for the fake backend.
  factory InMemoryLedgerRepository.demo() {
    final repo = InMemoryLedgerRepository(
      customers: const [
        Customer(
          id: 'ravi',
          name: 'Ravi',
          kinship: Kinship.annai,
          village: 'Nedunkerny',
          incomeType: IncomeType.farmer,
        ),
        Customer(
          id: 'selvi',
          name: 'Selvi',
          kinship: Kinship.akka,
          village: 'Cheddikulam',
        ),
        Customer(
          id: 'kumar',
          name: 'Kumar',
          kinship: Kinship.thambi,
          incomeType: IncomeType.dailyWage,
        ),
      ],
    );
    final now = clock.now();
    for (final (customer, type, rupees, daysAgo) in [
      ('ravi', EntryType.credit, 1500, 20),
      ('ravi', EntryType.credit, 750, 6),
      ('ravi', EntryType.payment, 500, 2),
      ('selvi', EntryType.credit, 2400, 9),
      ('kumar', EntryType.credit, 300, 1),
    ]) {
      repo.addEntry(
        'fake-shop',
        EntryDraft(
          type: type,
          amountCents: rupees * 100,
          customerId: customer,
          txnDate: now.subtract(Duration(days: daysAgo)),
          method: type == EntryType.payment ? PaymentMethod.cash : null,
        ),
      );
    }
    return repo;
  }

  final String uid;
  bool autoApply;
  final _customers = <String, Customer>{};
  final _entries = <String, LedgerEntry>{};
  final _changes = StreamController<void>.broadcast();
  final _uuid = const Uuid();

  void _changed() => _changes.add(null);

  Stream<T> _watch<T>(T Function() read) => Stream.multi((controller) {
    controller.add(read());
    final sub = _changes.stream.listen((_) => controller.add(read()));
    // Don't hand back the cancel future: `.first` would wait on it.
    controller.onCancel = () => unawaited(sub.cancel());
  });

  /// Applies every pending entry, like the server's onEntryCreated.
  void applyPending() {
    for (final entry in _entries.values.toList()) {
      final id = entry.customerId;
      final desired = id == null ? 0 : entry.desiredDeltaFor(id);
      final done = entry.applied;
      if (done != null && done.customerId == id && done.deltaCents == desired) {
        continue;
      }
      if (done?.customerId != null) {
        final old = _customers[done!.customerId]!;
        _customers[old.id] = _withBalance(
          old,
          old.balanceCents - done.deltaCents,
        );
      }
      if (id != null && _customers[id] != null) {
        final c = _customers[id]!;
        _customers[id] = _withBalance(c, c.balanceCents + desired);
      }
      _entries[entry.id] = _copyEntry(
        entry,
        applied: Applied(customerId: id, deltaCents: desired),
        createdAt: entry.createdAt ?? clock.now(),
      );
    }
    _changed();
  }

  @override
  Stream<List<Customer>> watchCustomers(String shopId) => _watch(
    () => [
      for (final c in _customers.values)
        c.copyWith(pendingDeltaCents: _pendingFor(c.id)),
    ]..sort(byDuesThenName),
  );

  @override
  Stream<Customer?> watchCustomer(String shopId, String customerId) => _watch(
    () => _customers[customerId]?.copyWith(
      pendingDeltaCents: _pendingFor(customerId),
    ),
  );

  @override
  Stream<List<LedgerEntry>> watchEntries(String shopId, String customerId) =>
      _watch(
        () =>
            _entries.values.where((e) => e.customerId == customerId).toList()
              ..sort(byTxnDateDesc),
      );

  @override
  Stream<PendingSummary> watchPending(String shopId) => _watch(() {
    final pending = _entries.values.where((e) => e.applied == null);
    return PendingSummary(
      count: pending.length,
      oldestAt: pending.isEmpty
          ? null
          : pending
                .map((e) => e.createdAt ?? clock.now())
                .reduce((a, b) => a.isBefore(b) ? a : b),
    );
  });

  int _pendingFor(String customerId) => _entries.values.fold(
    0,
    (total, e) => total + e.pendingDeltaFor(customerId),
  );

  @override
  Result<String> addCustomer(String shopId, CustomerDraft draft) {
    if (draft.name.trim().isEmpty) return left(const ValidationFailure('name'));
    final id = _uuid.v4();
    _customers[id] = Customer(
      id: id,
      name: draft.name.trim(),
      phone: draft.phone,
      kinship: draft.kinship,
      village: draft.village,
      incomeType: draft.incomeType,
      payDay: draft.payDay,
      reminderConsent: draft.reminderConsent,
      reminderTone: draft.reminderTone,
      reminderLang: draft.reminderLang,
    );
    _changed();
    return right(id);
  }

  @override
  Result<Unit> updateCustomer(String shopId, String id, CustomerDraft draft) {
    final old = _customers[id];
    if (old == null) return left(const NotFoundFailure());
    _customers[id] = Customer(
      id: id,
      name: draft.name.trim(),
      phone: draft.phone,
      kinship: draft.kinship,
      village: draft.village,
      incomeType: draft.incomeType,
      payDay: draft.payDay,
      balanceCents: old.balanceCents,
      oldestUnpaidAt: old.oldestUnpaidAt,
      reminderConsent: draft.reminderConsent,
      reminderTone: draft.reminderTone,
      reminderLang: draft.reminderLang,
      optedOut: old.optedOut,
      disputeOpen: old.disputeOpen,
    );
    _changed();
    return right(unit);
  }

  @override
  Result<String> addEntry(String shopId, EntryDraft draft) {
    if (affectsCustomer(draft.type) && draft.customerId == null) {
      return left(const ValidationFailure('customer'));
    }
    final id = _uuid.v4();
    _entries[id] = LedgerEntry(
      id: id,
      type: draft.type,
      amountCents: draft.amountCents,
      txnDate: draft.txnDate,
      createdBy: uid,
      customerId: draft.customerId,
      method: draft.method,
      note: draft.note,
      createdAt: clock.now(),
    );
    autoApply ? applyPending() : _changed();
    return right(id);
  }

  @override
  Result<Unit> editOwnEntry(
    String shopId,
    String entryId, {
    required int amountCents,
    String? note,
  }) {
    final e = _entries[entryId];
    if (e == null) return left(const NotFoundFailure());
    if (!e.canEditDirectly(uid, clock.now())) {
      return left(const PermissionFailure());
    }
    _entries[entryId] = _copyEntry(e, amountCents: amountCents, note: note);
    autoApply ? applyPending() : _changed();
    return right(unit);
  }

  @override
  AsyncResult<Unit> editAnyEntry(
    String shopId,
    String entryId, {
    required int amountCents,
    String? note,
  }) => TaskEither(() async {
    final e = _entries[entryId];
    if (e == null) return left(const NotFoundFailure());
    _entries[entryId] = _copyEntry(e, amountCents: amountCents, note: note);
    applyPending();
    return right(unit);
  });

  @override
  AsyncResult<Unit> deleteEntry(
    String shopId,
    String entryId, {
    String? reason,
  }) => TaskEither(() async {
    final e = _entries[entryId];
    if (e == null) return left(const NotFoundFailure());
    _entries[entryId] = _copyEntry(e, deletedAt: clock.now());
    applyPending();
    return right(unit);
  });

  static Customer _withBalance(Customer c, int balanceCents) => Customer(
    id: c.id,
    name: c.name,
    phone: c.phone,
    kinship: c.kinship,
    village: c.village,
    incomeType: c.incomeType,
    payDay: c.payDay,
    balanceCents: balanceCents,
    oldestUnpaidAt: c.oldestUnpaidAt,
    reminderConsent: c.reminderConsent,
    reminderTone: c.reminderTone,
    reminderLang: c.reminderLang,
    optedOut: c.optedOut,
    disputeOpen: c.disputeOpen,
  );

  static LedgerEntry _copyEntry(
    LedgerEntry e, {
    int? amountCents,
    String? note,
    DateTime? deletedAt,
    Applied? applied,
    DateTime? createdAt,
  }) => LedgerEntry(
    id: e.id,
    type: e.type,
    amountCents: amountCents ?? e.amountCents,
    txnDate: e.txnDate,
    createdBy: e.createdBy,
    customerId: e.customerId,
    method: e.method,
    note: note ?? e.note,
    createdAt: createdAt ?? e.createdAt,
    deletedAt: deletedAt ?? e.deletedAt,
    applied: applied ?? e.applied,
  );

  Future<void> dispose() => _changes.close();
}
