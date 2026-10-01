import 'dart:async';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

import '../../../sync/outbox/outbox_database.dart';
import '../../../sync/outbox/outbox_uploader.dart';
import '../domain/speech_input.dart';

/// Cloud fallback (PRD C1, 10.3 parseVoice) for phones without a Tamil
/// recogniser: records a short AMR-WB clip, sends it through the drift
/// outbox to Cloud Storage, and asks `parseVoice` for the transcript.
/// Online only; the server deletes the clip after transcribing it.
class CloudSpeechInput implements SpeechInput {
  CloudSpeechInput({
    required this.shopId,
    required this.outbox,
    required this.uploader,
    required this.functions,
    required this.isOnline,
    AudioRecorder? recorder,
    this.uploadTimeout = const Duration(seconds: 20),
  }) : _recorder = recorder ?? AudioRecorder();

  final String shopId;
  final OutboxDatabase outbox;
  final OutboxUploader uploader;
  final FirebaseFunctions functions;
  final bool Function() isOnline;
  final Duration uploadTimeout;
  final AudioRecorder _recorder;
  final _uuid = const Uuid();

  Completer<void>? _stopEarly;

  @override
  Future<bool> isAvailable() async => isOnline();

  @override
  Stream<SpeechEvent> listen({
    List<String> phrases = const [],
    Duration maxDuration = const Duration(seconds: 8),
  }) async* {
    if (!isOnline()) {
      yield const SpeechFailed(SpeechFailure.network);
      return;
    }
    if (!await _recorder.hasPermission()) {
      yield const SpeechFailed(SpeechFailure.permission);
      return;
    }
    final id = _uuid.v4();
    final dir = await getTemporaryDirectory();
    final path = p.join(dir.path, 'voice-$id.amr');
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.amrWb,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: path,
    );
    _stopEarly = Completer<void>();
    await Future.any([_stopEarly!.future, Future<void>.delayed(maxDuration)]);
    final recorded = await _recorder.stop();
    if (recorded == null) {
      yield const SpeechFailed(SpeechFailure.noSpeech);
      return;
    }

    yield const PartialSpeech('…');
    final remotePath = 'shops/$shopId/voice/$id.amr';
    try {
      await outbox.enqueue(
        OutboxItemsCompanion.insert(
          id: id,
          kind: OutboxKind.voiceClip,
          shopId: shopId,
          localPath: recorded,
          remotePath: remotePath,
          contentType: 'audio/amr-wb',
          status: OutboxStatus.queued,
          createdAt: clock.now(),
        ),
      );
      unawaited(uploader.kick());
      final uploaded = await outbox
          .watchItem(id)
          .firstWhere(
            (item) =>
                item == null ||
                item.status == OutboxStatus.uploaded ||
                item.status == OutboxStatus.failed,
          )
          .timeout(uploadTimeout);
      if (uploaded?.status != OutboxStatus.uploaded) {
        yield const SpeechFailed(SpeechFailure.network);
        return;
      }
      final result = await functions
          .httpsCallable('parseVoice')
          .call<Map<String, dynamic>>({'shopId': shopId, 'clipId': id});
      final text = result.data['transcript'] as String? ?? '';
      yield text.trim().isEmpty
          ? const SpeechFailed(SpeechFailure.noSpeech)
          : HeardSpeech(
              text,
              alternatives: [
                for (final a in result.data['alternatives'] as List? ?? [])
                  a as String,
              ],
            );
    } on Object {
      yield const SpeechFailed(SpeechFailure.network);
    } finally {
      // A clip is useful for one entry only (PDPA: keep nothing longer).
      await outbox.remove(id);
      final file = File(recorded);
      if (file.existsSync()) await file.delete();
    }
  }

  @override
  Future<void> stop() async {
    if (!(_stopEarly?.isCompleted ?? true)) _stopEarly!.complete();
  }

  @override
  Future<void> cancel() async {
    await stop();
    await _recorder.cancel();
  }
}

/// Picks the engine (PRD 4.3): on-device first, cloud when that can't help
/// and there is signal, otherwise none (the sheet falls back to the keypad).
class VoiceEngine {
  const VoiceEngine({required this.device, this.cloud});

  final SpeechInput device;
  final SpeechInput? cloud;

  Future<SpeechInput?> pick({bool deviceFailed = false}) async {
    if (!deviceFailed && await device.isAvailable()) return device;
    final c = cloud;
    if (c != null && await c.isAvailable()) return c;
    return null;
  }
}
