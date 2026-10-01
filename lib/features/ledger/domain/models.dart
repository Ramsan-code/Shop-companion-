import 'package:equatable/equatable.dart';

import '../../../core/money.dart';
import 'entry_type.dart';
import 'ledger_math.dart';

enum PaymentMethod { cash, bank, lankaqr, wallet }

enum IncomeType { farmer, dailyWage, salaried, business, other }

/// Kinship terms used in respectful reminders (PRD D3).
enum Kinship { annai, akka, aiya, amma, thambi, thangachi, maama }

extension EnumWire<T extends Enum> on Iterable<T> {
  T? byWire(Object? value) => value is String ? asNameMap()[value] : null;
}

class Customer extends Equatable {
  const Customer({
    required this.id,
    required this.name,
    this.phone,
    this.kinship,
    this.village,
    this.incomeType,
    this.payDay,
    this.balanceCents = 0,
    this.pendingDeltaCents = 0,
    this.oldestUnpaidAt,
    this.hasPendingWrites = false,
  });

  final String id;
  final String name;
  final String? phone;
  final Kinship? kinship;
  final String? village;
  final IncomeType? incomeType;

  /// Day of the month this customer is usually paid, if known.
  final int? payDay;

  /// Confirmed by the server (`balanceCents`, written only by functions).
  final int balanceCents;

  /// Entries saved on this phone that the server hasn't applied yet.
  final int pendingDeltaCents;
  final DateTime? oldestUnpaidAt;

  /// The customer document itself hasn't reached the server yet.
  final bool hasPendingWrites;

  /// What the shopkeeper sees: confirmed plus pending (PRD 9.2 step 2).
  Money get balance => Money(balanceCents + pendingDeltaCents);

  bool get isPending => hasPendingWrites || pendingDeltaCents != 0;

  String get displayName => kinship == null ? name : '$name ${kinship!.name}';

  Customer copyWith({int? pendingDeltaCents}) => Customer(
    id: id,
    name: name,
    phone: phone,
    kinship: kinship,
    village: village,
    incomeType: incomeType,
    payDay: payDay,
    balanceCents: balanceCents,
    pendingDeltaCents: pendingDeltaCents ?? this.pendingDeltaCents,
    oldestUnpaidAt: oldestUnpaidAt,
    hasPendingWrites: hasPendingWrites,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    phone,
    kinship,
    village,
    incomeType,
    payDay,
    balanceCents,
    pendingDeltaCents,
    oldestUnpaidAt,
    hasPendingWrites,
  ];
}

/// What the server already applied for an entry (`entries.applied`).
class Applied extends Equatable {
  const Applied({required this.customerId, required this.deltaCents});

  final String? customerId;
  final int deltaCents;

  @override
  List<Object?> get props => [customerId, deltaCents];
}

class LedgerEntry extends Equatable {
  const LedgerEntry({
    required this.id,
    required this.type,
    required this.amountCents,
    required this.txnDate,
    required this.createdBy,
    this.customerId,
    this.method,
    this.note,
    this.createdAt,
    this.deletedAt,
    this.applied,
    this.hasPendingWrites = false,
  });

  final String id;
  final EntryType type;
  final int amountCents;
  final DateTime txnDate;
  final String createdBy;
  final String? customerId;
  final PaymentMethod? method;
  final String? note;

  /// Server time; null until the entry reaches the server.
  final DateTime? createdAt;
  final DateTime? deletedAt;
  final Applied? applied;
  final bool hasPendingWrites;

  bool get isDeleted => deletedAt != null;

  Money get amount => Money(amountCents);

  /// The balance change this entry should make for [forCustomer].
  int desiredDeltaFor(String forCustomer) =>
      isDeleted || customerId != forCustomer
      ? 0
      : balanceDelta(type, amountCents);

  /// The part of that change the server hasn't applied yet.
  int pendingDeltaFor(String forCustomer) {
    final done = applied?.customerId == forCustomer ? applied!.deltaCents : 0;
    return desiredDeltaFor(forCustomer) - done;
  }

  /// Shown with a "waiting to sync" marker until the server has applied it.
  bool get isPending =>
      hasPendingWrites ||
      applied == null ||
      (customerId != null && pendingDeltaFor(customerId!) != 0);

  /// The author may fix their own entry for 24 hours (PRD 6); after that,
  /// or for someone else's entry, it takes Owner/Partner and a server call.
  bool canEditDirectly(String uid, DateTime now) =>
      !isDeleted &&
      createdBy == uid &&
      now.difference(createdAt ?? now) < const Duration(hours: 24);

  @override
  List<Object?> get props => [
    id,
    type,
    amountCents,
    txnDate,
    createdBy,
    customerId,
    method,
    note,
    createdAt,
    deletedAt,
    applied,
    hasPendingWrites,
  ];
}

class CustomerDraft extends Equatable {
  const CustomerDraft({
    required this.name,
    this.phone,
    this.kinship,
    this.village,
    this.incomeType,
    this.payDay,
  });

  final String name;
  final String? phone;
  final Kinship? kinship;
  final String? village;
  final IncomeType? incomeType;
  final int? payDay;

  @override
  List<Object?> get props => [
    name,
    phone,
    kinship,
    village,
    incomeType,
    payDay,
  ];
}

class EntryDraft extends Equatable {
  const EntryDraft({
    required this.type,
    required this.amountCents,
    required this.txnDate,
    this.customerId,
    this.method,
    this.note,
    this.source = 'text',
  });

  final EntryType type;
  final int amountCents;
  final DateTime txnDate;
  final String? customerId;
  final PaymentMethod? method;
  final String? note;

  /// voice, text, import or ocr (PRD 10.1).
  final String source;

  @override
  List<Object?> get props => [
    type,
    amountCents,
    txnDate,
    customerId,
    method,
    note,
    source,
  ];
}

/// Customer-list order: highest dues first (PRD C2), then by name.
int byDuesThenName(Customer a, Customer b) {
  final dues = b.balance.cents.compareTo(a.balance.cents);
  return dues != 0
      ? dues
      : a.name.toLowerCase().compareTo(b.name.toLowerCase());
}

/// Entries newest first by transaction date, so back-dated entries land in
/// the right place (PRD C2), then by creation time.
int byTxnDateDesc(LedgerEntry a, LedgerEntry b) {
  final byDate = b.txnDate.compareTo(a.txnDate);
  if (byDate != 0) return byDate;
  return (b.createdAt ?? DateTime(9999)).compareTo(
    a.createdAt ?? DateTime(9999),
  );
}
