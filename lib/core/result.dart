/// A sealed class representing the result of an operation that can either succeed or fail.
/// This provides a type-safe way to handle errors without throwing exceptions.
sealed class Result<T> {
  const Result();

  /// Creates a successful result with data
  factory Result.success(T data) = Success<T>;

  /// Creates an error result with a message and optional exception
  factory Result.error(String message, [Exception? exception]) = Error<T>;

  /// Returns true if this is a successful result
  bool get isSuccess => this is Success<T>;

  /// Returns true if this is an error result
  bool get isError => this is Error<T>;

  /// Returns the data if successful, null otherwise
  T? get data => switch (this) {
    Success<T> success => success.data,
    Error<T> _ => null,
  };

  /// Returns the error message if failed, null otherwise
  String? get errorMessage => switch (this) {
    Success<T> _ => null,
    Error<T> error => error.message,
  };

  /// Returns the exception if failed, null otherwise
  Exception? get exception => switch (this) {
    Success<T> _ => null,
    Error<T> error => error.exception,
  };

  /// Executes the appropriate callback based on the result type
  R when<R>({
    required R Function(T data) success,
    required R Function(String message, Exception? exception) error,
  }) {
    return switch (this) {
      Success<T> s => success(s.data),
      Error<T> e => error(e.message, e.exception),
    };
  }

  /// Maps the success value to a new type, preserving errors
  Result<R> map<R>(R Function(T) mapper) {
    return switch (this) {
      Success<T> success => Result.success(mapper(success.data)),
      Error<T> error => Result.error(error.message, error.exception),
    };
  }

  /// Chains operations that return Results, flattening nested Results
  Result<R> flatMap<R>(Result<R> Function(T) mapper) {
    return switch (this) {
      Success<T> success => mapper(success.data),
      Error<T> error => Result.error(error.message, error.exception),
    };
  }

  /// Returns the data if successful, or the provided default value if failed
  T getOrElse(T defaultValue) {
    return switch (this) {
      Success<T> success => success.data,
      Error<T> _ => defaultValue,
    };
  }

  /// Returns the data if successful, or throws the exception if failed
  T getOrThrow() {
    return switch (this) {
      Success<T> success => success.data,
      Error<T> error => throw error.exception ?? Exception(error.message),
    };
  }
}

/// Represents a successful result containing data
final class Success<T> extends Result<T> {
  final T data;
  
  const Success(this.data);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> && runtimeType == other.runtimeType && data == other.data;

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'Success($data)';
}

/// Represents a failed result containing an error message and optional exception
final class Error<T> extends Result<T> {
  final String message;
  final Exception? exception;
  
  const Error(this.message, [this.exception]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Error<T> &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          exception == other.exception;

  @override
  int get hashCode => message.hashCode ^ exception.hashCode;

  @override
  String toString() => 'Error($message${exception != null ? ', $exception' : ''})';
}