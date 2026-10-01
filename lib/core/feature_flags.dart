import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Switches that change without an app update (PRD 3: Remote Config holds
/// templates, calendars and flags). Every flag has a safe default, so the
/// app behaves the same offline or before the first fetch.
abstract interface class FeatureFlags {
  /// Send unclear speech to the cloud recogniser (costs money per minute).
  bool get cloudVoiceFallback;

  /// Show switch-in import.
  bool get importEnabled;
}

class DefaultFeatureFlags implements FeatureFlags {
  const DefaultFeatureFlags({
    this.cloudVoiceFallback = true,
    this.importEnabled = true,
  });

  @override
  final bool cloudVoiceFallback;

  @override
  final bool importEnabled;
}

class RemoteFeatureFlags implements FeatureFlags {
  RemoteFeatureFlags(this._config) {
    unawaited(_start());
  }

  final FirebaseRemoteConfig _config;

  static const _defaults = {
    'cloud_voice_fallback': true,
    'import_enabled': true,
  };

  Future<void> _start() async {
    try {
      await _config.setDefaults(_defaults);
      await _config.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          // Rural data is expensive: twice a day is plenty.
          minimumFetchInterval: const Duration(hours: 12),
        ),
      );
      await _config.fetchAndActivate();
    } on Object {
      // Offline or throttled: defaults or the last fetched values stay.
    }
  }

  @override
  bool get cloudVoiceFallback => _config.getBool('cloud_voice_fallback');

  @override
  bool get importEnabled => _config.getBool('import_enabled');
}
