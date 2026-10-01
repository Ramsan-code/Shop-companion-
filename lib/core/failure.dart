import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

/// Errors that cross layer boundaries (PRD 9.1: no raw exceptions).
sealed class Failure extends Equatable {
  const Failure(this.message);

  /// Developer-facing detail. Never shown to users and never logged with
  /// customer names, phones or amounts.
  final String message;

  @override
  List<Object?> get props => [runtimeType, message];
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'network']);
}

final class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'permission-denied']);
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'not-found']);
}

/// The thing already exists (already a member, already has a shop).
final class ConflictFailure extends Failure {
  const ConflictFailure([super.message = 'already-exists']);
}

/// A time-limited thing (invite, OTP) is past its expiry.
final class ExpiredFailure extends Failure {
  const ExpiredFailure([super.message = 'expired']);
}

/// Too many attempts; try again later.
final class RateLimitFailure extends Failure {
  const RateLimitFailure([super.message = 'too-many-requests']);
}

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message);
}

typedef Result<T> = Either<Failure, T>;
typedef AsyncResult<T> = TaskEither<Failure, T>;
