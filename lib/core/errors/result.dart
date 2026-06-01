import 'failures.dart';

/// A simple Result type for operations that can fail.
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Err<T>;

  T get value => (this as Success<T>).data;
  Failure get failure => (this as Err<T>).error;

  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) failure,
  }) {
    return switch (this) {
      Success(:final data) => success(data),
      Err(:final error) => failure(error),
    };
  }
}

final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

final class Err<T> extends Result<T> {
  final Failure error;
  const Err(this.error);
}
