import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/failure.dart';

/// Maps Firebase exceptions to [Failure]s so nothing raw crosses layers.
Failure failureFromFirebase(Object error) => switch (error) {
  FirebaseAuthException(:final code) => switch (code) {
    'invalid-phone-number' => const ValidationFailure('phone'),
    'invalid-verification-code' ||
    'invalid-verification-id' => const ValidationFailure('code'),
    'session-expired' || 'code-expired' => const ExpiredFailure('code'),
    'too-many-requests' || 'quota-exceeded' => const RateLimitFailure(),
    'network-request-failed' => const NetworkFailure(),
    _ => UnexpectedFailure('auth/$code'),
  },
  FirebaseFunctionsException(:final code) => switch (code) {
    'invalid-argument' => const ValidationFailure('argument'),
    'not-found' => const NotFoundFailure(),
    'deadline-exceeded' => const ExpiredFailure(),
    'already-exists' => const ConflictFailure(),
    'permission-denied' ||
    'unauthenticated' ||
    'failed-precondition' => PermissionFailure(code),
    'unavailable' || 'internal' => const NetworkFailure(),
    _ => UnexpectedFailure('functions/$code'),
  },
  FirebaseException(:final code) => switch (code) {
    'permission-denied' => const PermissionFailure(),
    'unavailable' => const NetworkFailure(),
    _ => UnexpectedFailure('firebase/$code'),
  },
  _ => UnexpectedFailure(error.runtimeType.toString()),
};
