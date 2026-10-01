import 'package:drift/drift.dart';

part 'outbox_database.g.dart';

enum OutboxKind { voiceClip, notebookPhoto }

enum OutboxStatus { queued, uploading, uploaded, failed }

/// Files waiting to reach Cloud Storage (PRD 9.2-5). Ledger writes don't
/// pass through here: Firestore queues those itself.
@DataClassName('OutboxItem')
class OutboxItems extends Table {
  TextColumn get id => text()();
  TextColumn get kind => textEnum<OutboxKind>()();
  TextColumn get shopId => text()();
  TextColumn get localPath => text()();

  /// Destination in Cloud Storage, e.g. shops/{shopId}/voice/{id}.amr
  TextColumn get remotePath => text()();
  TextColumn get contentType => text()();
  TextColumn get status => textEnum<OutboxStatus>()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get uploadedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [OutboxItems])
class OutboxDatabase extends _$OutboxDatabase {
  OutboxDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  Future<void> enqueue(OutboxItemsCompanion item) =>
      into(outboxItems).insert(item);

  /// Queued and failed-but-retryable items, oldest first.
  Future<List<OutboxItem>> due({int maxAttempts = 5}) =>
      (select(outboxItems)
            ..where(
              (t) =>
                  t.status.equalsValue(OutboxStatus.queued) &
                  t.attempts.isSmallerThanValue(maxAttempts),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();

  Stream<OutboxItem?> watchItem(String id) =>
      (select(outboxItems)..where((t) => t.id.equals(id))).watchSingleOrNull();

  /// Items not yet uploaded (for the sync badge).
  Stream<int> watchPendingCount() {
    final count = outboxItems.id.count();
    final query = selectOnly(outboxItems)
      ..addColumns([count])
      ..where(
        outboxItems.status.isInValues([
          OutboxStatus.queued,
          OutboxStatus.uploading,
        ]),
      );
    return query.map((row) => row.read(count) ?? 0).watchSingle();
  }

  Future<void> setStatus(
    String id,
    OutboxStatus status, {
    String? error,
    bool countAttempt = false,
    DateTime? uploadedAt,
  }) async {
    await transaction(() async {
      final item = await (select(
        outboxItems,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
      if (item == null) return;
      await (update(outboxItems)..where((t) => t.id.equals(id))).write(
        OutboxItemsCompanion(
          status: Value(status),
          lastError: Value(error),
          attempts: Value(item.attempts + (countAttempt ? 1 : 0)),
          uploadedAt: Value(uploadedAt ?? item.uploadedAt),
        ),
      );
    });
  }

  Future<void> remove(String id) =>
      (delete(outboxItems)..where((t) => t.id.equals(id))).go();

  /// After a crash mid-upload, put interrupted items back in the queue.
  Future<void> requeueInterrupted() =>
      (update(
        outboxItems,
      )..where((t) => t.status.equalsValue(OutboxStatus.uploading))).write(
        const OutboxItemsCompanion(status: Value(OutboxStatus.queued)),
      );
}
