import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/fake_auth_repository.dart';
import '../../features/auth/domain/auth_repository.dart';

/// Service wiring only (PRD 9.1): Firebase instances, repositories, adapters
/// and config live here. Screen state belongs in blocs, never in riverpod.
///
/// Phase 1 replaces the fake with `FirebaseAuthRepository`.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final repository = FakeAuthRepository();
  ref.onDispose(repository.dispose);
  return repository;
});
