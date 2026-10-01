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

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message);
}

typedef Result<T> = Either<Failure, T>;
typedef AsyncResult<T> = TaskEither<Failure, T>;
