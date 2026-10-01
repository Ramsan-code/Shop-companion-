import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:redux/redux.dart';

import '../../features/auth/data/fake_auth_repository.dart';
import '../../features/auth/data/firebase_auth_repository.dart';
import '../../features/auth/data/secure_pin_store.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../features/auth/domain/pin_store.dart';
import '../../features/ledger/data/firestore_ledger_repository.dart';
import '../../features/ledger/data/in_memory_ledger_repository.dart';
import '../../features/ledger/domain/ledger_repository.dart';
import '../../features/settings/data/members_repositories.dart';
import '../../features/settings/domain/members_repository.dart';
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
