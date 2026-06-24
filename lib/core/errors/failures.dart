import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

final class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

final class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

final class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

final class ExportFailure extends Failure {
  const ExportFailure(super.message);
}

final class ImportFailure extends Failure {
  const ImportFailure(super.message);
}

final class AnalysisFailure extends Failure {
  const AnalysisFailure(super.message);
}

/// Raised when an operation is refused because it would violate a security
/// invariant (e.g. sending credentials over plaintext HTTP, writing outside
/// the app sandbox).
final class SecurityFailure extends Failure {
  const SecurityFailure(super.message);
}

/// Hosted-LLM proxy returned 429 — the caller exceeded the monthly token
/// cap. Not retryable; UI should surface UpgradeCta / "try again next
/// month" rather than a generic error.
final class QuotaExceededFailure extends Failure {
  const QuotaExceededFailure() : super('Quota exceeded');
}

/// Hosted-LLM proxy returned 401 — the bearer is missing, invalid, or
/// revoked. The auth layer should clear the stored bearer and show the
/// upgrade flow.
final class UnauthenticatedFailure extends Failure {
  const UnauthenticatedFailure() : super('Unauthenticated');
}
