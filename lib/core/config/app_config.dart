import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart' show appFlavor;

/// Build flavor (PRD 11.1: separate Firebase projects for dev, staging, prod).
enum Flavor { dev, staging, prod }

/// Which backend the app talks to.
enum Backend {
  /// In-memory fakes: UI work with no Firebase at all.
  fake,

  /// Local Firebase Emulator Suite with the `demo-shop-companion` project.
  emulator,

  /// A real Firebase project, configured by `--dart-define-from-file`.
  firebase,
}

/// Everything comes from compile-time defines, so no project config or keys
/// live in the repository. See `config/*.example.json`.
class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.backend,
    this.emulatorHost = '10.0.2.2',
    this.firebaseOptions,
  });

  factory AppConfig.fromEnvironment() {
    final flavor = Flavor.values.asNameMap()[appFlavor] ?? Flavor.dev;
    const backendName = String.fromEnvironment('BACKEND');
    final backend =
        Backend.values.asNameMap()[backendName] ??
        (flavor == Flavor.dev ? Backend.fake : Backend.firebase);
    return AppConfig(
      flavor: flavor,
      backend: backend,
      emulatorHost: const String.fromEnvironment(
        'EMULATOR_HOST',
        // The Android emulator reaches the host machine on 10.0.2.2.
        defaultValue: '10.0.2.2',
      ),
      firebaseOptions: switch (backend) {
        Backend.fake => null,
        Backend.emulator => demoOptions,
        Backend.firebase => _optionsFromDefines(),
      },
    );
  }

  final Flavor flavor;
  final Backend backend;
  final String emulatorHost;
  final FirebaseOptions? firebaseOptions;

  /// `demo-*` projects work only against the emulators; the values are dummies.
  static const demoOptions = FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: '1:000000000000:android:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'demo-shop-companion',
    storageBucket: 'demo-shop-companion.appspot.com',
  );

  static FirebaseOptions _optionsFromDefines() {
    const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
    const appId = String.fromEnvironment('FIREBASE_APP_ID');
    const senderId = String.fromEnvironment('FIREBASE_SENDER_ID');
    const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
    const bucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
    if ([apiKey, appId, senderId, projectId].any((v) => v.isEmpty)) {
      throw StateError(
        'Missing Firebase config. Build with '
        '--dart-define-from-file=config/<flavor>.json (see config/README.md).',
      );
    }
    return const FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: senderId,
      projectId: projectId,
      storageBucket: bucket,
    );
  }
}
