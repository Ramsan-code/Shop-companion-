import 'dart:async';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'outbox_database.dart';

/// Moves one local file to Cloud Storage.
abstract interface class FileUploader {
  Future<void> upload({
    required String localPath,
    required String remotePath,
    required String contentType,
  });
}

class FirebaseStorageUploader implements FileUploader {
  FirebaseStorageUploader(this._storage);

  final FirebaseStorage _storage;

  @override
  Future<void> upload({
    required String localPath,
    required String remotePath,
    required String contentType,
  }) async {
    await _storage
        .ref(remotePath)
        .putFile(File(localPath), SettableMetadata(contentType: contentType));
  }
}

/// Drains the outbox whenever the phone is online (PRD 9.2-5): one item at
/// a time, oldest first, retrying with backoff up to [maxAttempts].
class OutboxUploader {
  OutboxUploader(
    this.db,
    this._uploader, {
    required Stream<bool> online,
    this.maxAttempts = 5,
    Duration Function(int attempt)? backoff,
  }) : _onlineChanges = online,
       _backoff =
           backoff ??
           ((attempt) => Duration(seconds: 2 << attempt.clamp(0, 6)));

  final OutboxDatabase db;
  final FileUploader _uploader;
  final Stream<bool> _onlineChanges;
  final int maxAttempts;
  final Duration Function(int attempt) _backoff;

  bool _online = false;
  bool _draining = false;
  StreamSubscription<bool>? _subscription;
  Timer? _retry;

  Future<void> start() async {
    await db.requeueInterrupted();
    _subscription ??= _onlineChanges.listen((online) {
      _online = online;
      if (online) unawaited(drain());
    });
  }

  /// Call after enqueueing so the upload starts at once when online.
  Future<void> kick() => drain();

  Future<void> drain() async {
    if (!_online || _draining) return;
    _draining = true;
    try {
      for (final item in await db.due(maxAttempts: maxAttempts)) {
        if (!_online) break;
        await db.setStatus(item.id, OutboxStatus.uploading);
        try {
          await _uploader.upload(
            localPath: item.localPath,
            remotePath: item.remotePath,
            contentType: item.contentType,
          );
          await db.setStatus(
            item.id,
            OutboxStatus.uploaded,
            uploadedAt: clock.now(),
          );
        } on Object catch (e) {
          final attempts = item.attempts + 1;
          await db.setStatus(
            item.id,
            attempts >= maxAttempts ? OutboxStatus.failed : OutboxStatus.queued,
            error: e.runtimeType.toString(),
            countAttempt: true,
          );
          if (attempts < maxAttempts) _scheduleRetry(attempts);
        }
      }
    } finally {
      _draining = false;
    }
  }

  void _scheduleRetry(int attempt) {
    _retry?.cancel();
    _retry = Timer(_backoff(attempt), () => unawaited(drain()));
  }

  Future<void> dispose() async {
    _retry?.cancel();
    await _subscription?.cancel();
  }
}
