/// Domain-level error type. Repositories translate transport errors into this
/// so the UI never deals with Dio/HTTP exceptions directly.
sealed class AppFailure implements Exception {
  final String message;
  const AppFailure(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

class NetworkFailure extends AppFailure {
  const NetworkFailure(super.message);
}

class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure(super.message);
}

class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message);
}

class ConflictFailure extends AppFailure {
  const ConflictFailure(super.message);
}

class NotFoundFailure extends AppFailure {
  const NotFoundFailure(super.message);
}

class UnknownFailure extends AppFailure {
  const UnknownFailure(super.message);
}