import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:redux/redux.dart';
import 'package:rxdart/rxdart.dart';

import '../../features/auth/data/fake_auth_repository.dart';
import '../../features/auth/data/firebase_auth_repository.dart';
import '../../features/auth/data/secure_pin_store.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../features/auth/domain/pin_store.dart';
import '../../features/collections/data/collections_repositories.dart';
import '../../features/collections/data/push_registration.dart';
import '../../features/collections/domain/collections.dart';
import '../../features/ledger/data/firestore_ledger_repository.dart';
import '../../features/ledger/data/in_memory_ledger_repository.dart';
import '../../features/ledger/domain/ledger_repository.dart';
import '../../features/reminders/data/reminders_repositories.dart';
import '../../features/reminders/domain/reminders.dart';
import '../../features/settings/data/members_repositories.dart';
import '../../features/settings/domain/members_repository.dart';
import '../../features/voice/data/cloud_speech_input.dart';
import '../../features/voice/data/device_speech_input.dart';
import '../../features/voice/domain/speech_input.dart';
import '../../sync/outbox/outbox_database.dart';
import '../../sync/outbox/outbox_uploader.dart';
import '../../sync/sync_service.dart';
import '../../sync/sync_state.dart';
import '../config/app_config.dart';
import '../config/firebase_bootstrap.dart';

/// Service wiring only (PRD 9.1): Firebase instances, repositories, adapters
/// and config live here. Screen state belongs in blocs, never in riverpod.

/// Overridden in main() with the real config.
final appConfigProvider = Provider<AppConfig>(
  (ref) => const AppConfig(flavor: Flavor.dev, backend: Backend.fake),
);

bool _isFake(Ref ref) => ref.watch(appConfigProvider).backend == Backend.fake;

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (_isFake(ref)) {
    final repository = FakeAuthRepository();
    ref.onDispose(repository.dispose);
    return repository;
  }
  return FirebaseAuthRepository(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
    functions: FirebaseFunctions.instanceFor(region: functionsRegion),
  );
});

final membersRepositoryProvider = Provider<MembersRepository>((ref) {
  if (_isFake(ref)) return FakeMembersRepository();
  return FirebaseMembersRepository(
    firestore: FirebaseFirestore.instance,
    functions: FirebaseFunctions.instanceFor(region: functionsRegion),
  );
});

final pinStoreProvider = Provider<PinStore>(
  (ref) => _isFake(ref) ? InMemoryPinStore() : SecurePinStore(),
);

final biometricAuthProvider = Provider<BiometricAuth>(
  (ref) => _isFake(ref) ? const NoBiometricAuth() : LocalBiometricAuth(),
);

/// The sync engine's redux store (PRD 9.1). Only [SyncService] dispatches.
final syncStoreProvider = Provider<Store<SyncState>>(
  (ref) => createSyncStore(),
);

final syncServiceProvider = Provider<SyncService>((ref) {
  final service = SyncService(
    ref.watch(syncStoreProvider),
    // The fake backend has no network to watch.
    connectivity: _isFake(ref) ? Stream.value(true) : null,
  )..start();
  ref.onDispose(service.dispose);
  return service;
});

final ledgerRepositoryProvider = Provider<LedgerRepository>((ref) {
  if (_isFake(ref)) {
    final repository = InMemoryLedgerRepository.demo();
    ref.onDispose(repository.dispose);
    return repository;
  }
  final sync = ref.watch(syncServiceProvider);
  return FirestoreLedgerRepository(
    db: FirebaseFirestore.instance,
    functions: FirebaseFunctions.instanceFor(region: functionsRegion),
    currentUid: () => FirebaseAuth.instance.currentUser?.uid ?? '',
    onRejected: sync.reportRejection,
  );
});

/// Local queue for files (voice clips; notebook photos in Release 2).
/// None with the fake backend, which has nowhere to upload to.
final outboxDatabaseProvider = Provider<OutboxDatabase?>((ref) {
  if (_isFake(ref)) return null;
  final db = OutboxDatabase(driftDatabase(name: 'outbox'));
  ref.onDispose(db.close);
  return db;
});

final outboxUploaderProvider = Provider<OutboxUploader?>((ref) {
  final db = ref.watch(outboxDatabaseProvider);
  if (db == null) return null;
  final store = ref.watch(syncStoreProvider);
  final uploader = OutboxUploader(
    db,
    FirebaseStorageUploader(FirebaseStorage.instance),
    online: store.onChange
        .map((s) => s.online)
        .startWith(store.state.online)
        .distinct(),
  );
  ref.onDispose(uploader.dispose);
  return uploader;
});

final readBackProvider = Provider<ReadBack>((ref) => TtsReadBack());

/// On-device recogniser first, cloud fallback for [shopId] when online.
final voiceEngineProvider = Provider.family<VoiceEngine, String>((ref, shopId) {
  final db = ref.watch(outboxDatabaseProvider);
  final uploader = ref.watch(outboxUploaderProvider);
  final store = ref.watch(syncStoreProvider);
  return VoiceEngine(
    device: DeviceSpeechInput(),
    cloud: db == null || uploader == null
        ? null
        : CloudSpeechInput(
            shopId: shopId,
            outbox: db,
            uploader: uploader,
            functions: FirebaseFunctions.instanceFor(region: functionsRegion),
            isOnline: () => store.state.online,
          ),
  );
});

/// Trust Scores, Safe Credit Limits and Who To Ask Today (PRD D1, D2, D5).
final collectionsRepositoryProvider = Provider<CollectionsRepository>((ref) {
  if (_isFake(ref)) {
    final repository = InMemoryCollectionsRepository.demo();
    ref.onDispose(repository.dispose);
    return repository;
  }
  return FirestoreCollectionsRepository(
    db: FirebaseFirestore.instance,
    functions: FirebaseFunctions.instanceFor(region: functionsRegion),
    currentUid: () => FirebaseAuth.instance.currentUser?.uid ?? '',
  );
});

final pushRegistrationProvider = Provider<PushRegistration>((ref) {
  if (_isFake(ref)) return const NoPushRegistration();
  final push = FirebasePushRegistration(
    FirebaseMessaging.instance,
    FirebaseFirestore.instance,
  );
  ref.onDispose(push.dispose);
  return push;
});

/// Reminders, statement links and shop reminder settings (PRD C7, D3, N8).
final remindersRepositoryProvider = Provider<RemindersRepository>((ref) {
  if (_isFake(ref)) {
    final repository = InMemoryRemindersRepository();
    ref.onDispose(repository.dispose);
    return repository;
  }
  return FirestoreRemindersRepository(
    db: FirebaseFirestore.instance,
    functions: FirebaseFunctions.instanceFor(region: functionsRegion),
  );
});
