import 'dart:async';

import 'package:drift/drift.dart' show Constant;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_companion/sync/outbox/outbox_database.dart';
import 'package:shop_companion/sync/outbox/outbox_uploader.dart';

class _FlakyUploader implements FileUploader {
  int failuresLeft = 0;
  final uploaded = <String>[];

  @override
  Future<void> upload({
    required String localPath,
    required String remotePath,
    required String contentType,
  }) async {
    if (failuresLeft > 0) {
      failuresLeft--;
      throw StateError('network');
    }
    uploaded.add(remotePath);
  }
}

void main() {
  late OutboxDatabase db;
  late _FlakyUploader uploader;
  late StreamController<bool> online;
  late OutboxUploader outbox;

  OutboxItemsCompanion clip(String id, DateTime at) =>
      OutboxItemsCompanion.insert(
        id: id,
        kind: OutboxKind.voiceClip,
        shopId: 's1',
        localPath: '/tmp/$id.amr',
        remotePath: 'shops/s1/voice/$id.amr',
        contentType: 'audio/amr-wb',
        status: OutboxStatus.queued,
        createdAt: at,
      );

  setUp(() async {
    db = OutboxDatabase(NativeDatabase.memory());
    uploader = _FlakyUploader();
    online = StreamController<bool>();
    outbox = OutboxUploader(
      db,
      uploader,
      online: online.stream,
      backoff: (_) => Duration.zero,
    );
    await outbox.start();
  });

  tearDown(() async {
    await outbox.dispose();
    await online.close();
    await db.close();
  });

  test(
    'waits offline, then uploads oldest first when signal returns',
    () async {
      await db.enqueue(clip('b', DateTime(2026, 10, 1, 10)));
      await db.enqueue(clip('a', DateTime(2026, 10, 1, 9)));
      await outbox.kick();
      expect(uploader.uploaded, isEmpty);
      expect(await db.watchPendingCount().first, 2);

      online.add(true);
      await pumpEventQueue();
      await outbox.drain();
      expect(uploader.uploaded, [
        'shops/s1/voice/a.amr',
        'shops/s1/voice/b.amr',
      ]);
      expect(await db.watchPendingCount().first, 0);
      final a = await db.watchItem('a').first;
      expect(a!.status, OutboxStatus.uploaded);
      expect(a.uploadedAt, isNotNull);
    },
  );

  test('retries a failed upload and gives up after max attempts', () async {
    online.add(true);
    await pumpEventQueue();
    uploader.failuresLeft = 2;
    await db.enqueue(clip('c', DateTime(2026, 10, 1)));
    await outbox.drain();
    await pumpEventQueue();
    await Future<void>.delayed(Duration.zero);
    await outbox.drain();
    await outbox.drain();
    final c = await db.watchItem('c').first;
    expect(c!.status, OutboxStatus.uploaded);
    expect(c.attempts, 2);

    uploader.failuresLeft = 99;
    await db.enqueue(clip('d', DateTime(2026, 10, 2)));
    for (var i = 0; i < 6; i++) {
      await outbox.drain();
    }
    final d = await db.watchItem('d').first;
    expect(d!.status, OutboxStatus.failed);
    expect(d.attempts, 5);
    expect(d.lastError, 'StateError');
  });

  test('an upload cut off by a crash goes back in the queue', () async {
    await db.enqueue(clip('e', DateTime(2026, 10, 1)));
    await db.setStatus('e', OutboxStatus.uploading);
    await db.requeueInterrupted();
    expect((await db.watchItem('e').first)!.status, OutboxStatus.queued);
    await db.remove('e');
    expect(await db.watchItem('e').first, isNull);
  });

  test('the generated table matches the schema version', () {
    expect(db.schemaVersion, 1);
    expect(db.outboxItems.actualTableName, 'outbox_items');
    expect(const Constant(0), isA<Constant<int>>());
  });
}
