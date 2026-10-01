import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/failure.dart';
import 'models.dart';

/// Local writes not yet confirmed by the server (feeds the sync store).
class PendingSummary extends Equatable {
  const PendingSummary({this.count = 0, this.oldestAt});

  final int count;

  /// When the oldest still-unsynced entry was made on this phone.
  final DateTime? oldestAt;

  @override
  List<Object?> get props => [count, oldestAt];
}

/// A local write the server refused (for the conflict log).
class WriteRejection extends Equatable {
  const WriteRejection({
    required this.path,
    required this.failure,
    required this.at,
  });

  final String path;
  final Failure failure;
  final DateTime at;

  @override
  List<Object?> get props => [path, failure, at];
}

/// Customers and ledger entries (PRD C2, C3, C8, 9.2).
///
/// Writes are offline-first: they return as soon as the write is in the
/// local Firestore cache, with no network wait. The server confirms later.
/// Edits after 24 hours and deletes are server calls and need a connection.
abstract interface class LedgerRepository {
  Stream<List<Customer>> watchCustomers(String shopId);

  Stream<Customer?> watchCustomer(String shopId, String customerId);

  Stream<List<LedgerEntry>> watchEntries(String shopId, String customerId);

  Stream<PendingSummary> watchPending(String shopId);

  /// Returns the new customer's ID.
  Result<String> addCustomer(String shopId, CustomerDraft draft);

  Result<Unit> updateCustomer(String shopId, String id, CustomerDraft draft);

  /// Returns the entry's clientId (also its document ID).
  Result<String> addEntry(String shopId, EntryDraft draft);

  /// Author's own fix within 24 hours.
  Result<Unit> editOwnEntry(
    String shopId,
    String entryId, {
    required int amountCents,
    String? note,
  });

  /// Owner/Partner: any entry, any age (`editEntry` callable).
  AsyncResult<Unit> editAnyEntry(
    String shopId,
    String entryId, {
    required int amountCents,
    String? note,
  });

  /// Owner/Partner soft delete (`deleteEntry` callable).
  AsyncResult<Unit> deleteEntry(
    String shopId,
    String entryId, {
    String? reason,
  });
}
