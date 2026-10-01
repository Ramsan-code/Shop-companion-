import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../domain/speech_input.dart';

/// Android's own recogniser (PRD 4.3: on-device speech first). Offline when
/// the phone has the Tamil language pack; otherwise it uses the network.
class DeviceSpeechInput implements SpeechInput {
  DeviceSpeechInput([SpeechToText? speech])
    : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;
  StreamController<SpeechEvent>? _events;
  String? _localeId;
  bool _initialised = false;

  /// Sri Lankan Tamil if offered, then any Tamil.
  static String? pickTamilLocale(Iterable<String> localeIds) {
    final ids = localeIds.map((id) => id.replaceAll('-', '_')).toList();
    for (final preferred in ['ta_LK', 'ta_IN']) {
      if (ids.contains(preferred)) return preferred;
    }
    for (final id in ids) {
      if (id.toLowerCase().startsWith('ta')) return id;
    }
    return null;
  }

  Future<bool> _init() async {
    if (_initialised) return _localeId != null;
    _initialised = true;
    final ok = await _speech.initialize(onError: _onError, onStatus: _onStatus);
    if (!ok) return false;
    _localeId = pickTamilLocale(
      (await _speech.locales()).map((l) => l.localeId),
    );
    return _localeId != null;
  }

  @override
  Future<bool> isAvailable() async {
    try {
      return await _init();
    } on Exception {
      return false;
    }
  }

  @override
  Stream<SpeechEvent> listen({
    List<String> phrases = const [],
    Duration maxDuration = const Duration(seconds: 8),
  }) {
    final events = StreamController<SpeechEvent>();
    _events = events;
    events.onListen = () async {
      if (!await isAvailable()) {
        _finish(const SpeechFailed(SpeechFailure.unavailable));
        return;
      }
      await _speech.listen(
        onResult: _onResult,
        listenOptions: SpeechListenOptions(
          localeId: _localeId,
          partialResults: true,
          cancelOnError: true,
          listenFor: maxDuration,
          pauseFor: const Duration(seconds: 2),
          contextualPhrases: phrases.take(100).toList(),
        ),
      );
    };
    return events.stream;
  }

  void _onResult(SpeechRecognitionResult result) {
    if (result.finalResult) {
      _finish(
        result.recognizedWords.trim().isEmpty
            ? const SpeechFailed(SpeechFailure.noSpeech)
            : HeardSpeech(
                result.recognizedWords,
                alternatives: [
                  for (final a in result.alternates.skip(1)) a.recognizedWords,
                ],
              ),
      );
    } else {
      _events?.add(PartialSpeech(result.recognizedWords));
    }
  }

  void _onError(SpeechRecognitionError error) {
    final reason = switch (error.errorMsg) {
      'error_permission' ||
      'error_insufficient_permissions' => SpeechFailure.permission,
      'error_no_match' || 'error_speech_timeout' => SpeechFailure.noSpeech,
      'error_network' ||
      'error_network_timeout' ||
      'error_server' ||
      'error_server_disconnected' ||
      'error_language_unavailable' ||
      'error_language_not_supported' => SpeechFailure.network,
      _ => SpeechFailure.unavailable,
    };
    _finish(SpeechFailed(reason));
  }

  void _onStatus(String status) {
    // "done" without a final result means silence.
    if (status == SpeechToText.doneStatus && _events != null) {
      _finish(const SpeechFailed(SpeechFailure.noSpeech));
    }
  }

  void _finish(SpeechEvent event) {
    final events = _events;
    if (events == null) return;
    _events = null;
    events.add(event);
    unawaited(events.close());
  }

  @override
  Future<void> stop() => _speech.stop();

  @override
  Future<void> cancel() async {
    unawaited(_events?.close());
    _events = null;
    await _speech.cancel();
  }
}

/// Text-to-speech read-back with the phone's Tamil voice.
class TtsReadBack implements ReadBack {
  TtsReadBack([FlutterTts? tts]) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;

  @override
  Future<void> speak(String text, {required String languageCode}) async {
    try {
      final language = languageCode == 'ta' ? 'ta-IN' : 'en-IN';
      if (await _tts.isLanguageAvailable(language) != true) return;
      await _tts.setLanguage(language);
      await _tts.setSpeechRate(0.45);
      await _tts.awaitSpeakCompletion(true);
      await _tts.speak(text);
    } on Exception {
      // No voice: the read-back is still on screen.
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } on Exception {
      // Nothing playing.
    }
  }
}

class SilentReadBack implements ReadBack {
  const SilentReadBack();

  @override
  Future<void> speak(String text, {required String languageCode}) async {}

  @override
  Future<void> stop() async {}
}
