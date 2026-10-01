import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';

/// Product metrics and crash reports (PRD 8.1 Quality, 11 Observability).
///
/// Only these typed events exist, and none takes a name, phone number,
/// amount or free text: the funnel needs what happened, never to whom or
/// for how much. No user ID is set either.
abstract interface class Telemetry {
  /// type: credit/payment/sale/expense/…; source: voice/text/import.
  void entrySaved({required String type, required String source});

  /// From opening the voice sheet to saving (NFR: under 10 s offline).
  void voiceEntrySaved({required Duration took, required bool cloud});

  void closeDayDone({required bool helper});

  void importDone(int customers);

  void exportDone();

  void simpleModeChanged(bool on);

  void recordError(Object error, StackTrace stack, {bool fatal = false});
}

/// Bucketed so a count can't single out a shop.
String countBucket(int n) => switch (n) {
  0 => '0',
  < 10 => '1-9',
  < 50 => '10-49',
  < 200 => '50-199',
  < 1000 => '200-999',
  _ => '1000+',
};

class FirebaseTelemetry implements Telemetry {
  FirebaseTelemetry(this._analytics, this._crashlytics, this._performance);

  final FirebaseAnalytics _analytics;
  final FirebaseCrashlytics _crashlytics;
  final FirebasePerformance _performance;

  void _log(String name, [Map<String, Object> params = const {}]) =>
      unawaited(_analytics.logEvent(name: name, parameters: params));

  @override
  void entrySaved({required String type, required String source}) =>
      _log('entry_saved', {'type': type, 'source': source});

  @override
  void voiceEntrySaved({required Duration took, required bool cloud}) {
    _log('voice_entry', {
      'engine': cloud ? 'cloud' : 'device',
      'under_10s': took.inSeconds < 10 ? 1 : 0,
    });
    unawaited(() async {
      final trace = _performance.newTrace('voice_entry');
      await trace.start();
      trace
        ..putAttribute('engine', cloud ? 'cloud' : 'device')
        ..setMetric('ms', took.inMilliseconds);
      await trace.stop();
    }());
  }

  @override
  void closeDayDone({required bool helper}) =>
      _log('close_day', {'by': helper ? 'helper' : 'owner'});

  @override
  void importDone(int customers) =>
      _log('import_done', {'customers': countBucket(customers)});

  @override
  void exportDone() => _log('export_done');

  @override
  void simpleModeChanged(bool on) => _log('simple_mode', {'on': on ? 1 : 0});

  @override
  void recordError(Object error, StackTrace stack, {bool fatal = false}) =>
      unawaited(_crashlytics.recordError(error, stack, fatal: fatal));
}

/// The fake backend and tests: remembers events as plain maps.
class RecordingTelemetry implements Telemetry {
  final events = <(String, Map<String, Object>)>[];

  @override
  void entrySaved({required String type, required String source}) =>
      events.add(('entry_saved', {'type': type, 'source': source}));

  @override
  void voiceEntrySaved({required Duration took, required bool cloud}) =>
      events.add(('voice_entry', {'engine': cloud ? 'cloud' : 'device'}));

  @override
  void closeDayDone({required bool helper}) =>
      events.add(('close_day', {'by': helper ? 'helper' : 'owner'}));

  @override
  void importDone(int customers) =>
      events.add(('import_done', {'customers': countBucket(customers)}));

  @override
  void exportDone() => events.add(('export_done', const {}));

  @override
  void simpleModeChanged(bool on) =>
      events.add(('simple_mode', {'on': on ? 1 : 0}));

  @override
  void recordError(Object error, StackTrace stack, {bool fatal = false}) =>
      events.add(('error', {'fatal': fatal ? 1 : 0}));
}
