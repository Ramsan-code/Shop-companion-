import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';
import 'core/config/firebase_bootstrap.dart';
import 'core/di/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
  await initializeFirebase(config);
  if (config.backend == Backend.firebase) await _startCrashReporting(config);
  runApp(
    ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(config)],
      child: const ShopCompanionApp(),
    ),
  );
}

/// Crashlytics catches Flutter and async errors (PRD 11: crash-free
/// sessions 99.5%+). Collection is on for staging and prod builds only.
Future<void> _startCrashReporting(AppConfig config) async {
  final crashlytics = FirebaseCrashlytics.instance;
  final collect = config.flavor != Flavor.dev && !kDebugMode;
  await crashlytics.setCrashlyticsCollectionEnabled(collect);
  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(collect);
  FlutterError.onError = crashlytics.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    unawaited(crashlytics.recordError(error, stack, fatal: true));
    return true;
  };
}
