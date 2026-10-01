import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app_config.dart';

/// Region of the callable functions (functions/src/index.ts).
const functionsRegion = 'asia-south1';

/// Starts Firebase for [config]; does nothing for the fake backend.
Future<void> initializeFirebase(AppConfig config) async {
  final options = config.firebaseOptions;
  if (options == null) return;
  await Firebase.initializeApp(options: options);

  if (config.backend == Backend.emulator) {
    final host = config.emulatorHost;
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    FirebaseFunctions.instanceFor(region: functionsRegion)
        .useFunctionsEmulator(host, 5001);
    return;
  }

  // PRD 11: offline persistence is the default on Android; set it
  // explicitly with an unlimited cache so a month offline never evicts data.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  await FirebaseAppCheck.instance.activate(
    providerAndroid: config.flavor == Flavor.prod
        ? const AndroidPlayIntegrityProvider()
        : const AndroidDebugProvider(),
  );
}
