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
  runApp(
    ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(config)],
      child: const ShopCompanionApp(),
    ),
  );
}
