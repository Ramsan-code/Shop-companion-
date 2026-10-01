/// Speech recognition as a stream of events, whichever engine is behind it.
sealed class SpeechEvent {
  const SpeechEvent();
}

/// Words so far, while the person is still speaking.
final class PartialSpeech extends SpeechEvent {
  const PartialSpeech(this.text);

  final String text;
}

/// The final result. The stream ends after this or [SpeechFailed].
final class HeardSpeech extends SpeechEvent {
  const HeardSpeech(this.text, {this.alternatives = const []});

  final String text;
  final List<String> alternatives;
}

final class SpeechFailed extends SpeechEvent {
  const SpeechFailed(this.reason);

  final SpeechFailure reason;
}

enum SpeechFailure {
  /// Microphone permission refused.
  permission,

  /// Nothing was said.
  noSpeech,

  /// The recogniser needs the network (no offline Tamil pack) or the cloud
  /// call failed.
  network,

  /// No Tamil recogniser on this phone.
  unavailable,
}

abstract interface class SpeechInput {
  /// Whether this engine can listen right now.
  Future<bool> isAvailable();

  /// Listens once. [phrases] are this shop's customer names, used to bias
  /// recognition where the engine supports it.
  Stream<SpeechEvent> listen({
    List<String> phrases = const [],
    Duration maxDuration = const Duration(seconds: 8),
  });

  /// Finish now and deliver what was heard.
  Future<void> stop();

  Future<void> cancel();
}

/// Speaks the read-back (PRD C1: "spoken and visual read-back").
abstract interface class ReadBack {
  /// Completes when speaking ends. Silently does nothing when the phone has
  /// no voice for [languageCode]; the read-back is on screen anyway.
  Future<void> speak(String text, {required String languageCode});

  Future<void> stop();
}
