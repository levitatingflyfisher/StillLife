import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/core/errors/failures.dart';
import 'package:still_life/core/errors/result.dart';

void main() {
  group('Result', () {
    test('Success holds data', () {
      const result = Success(42);
      expect(result.isSuccess, true);
      expect(result.isFailure, false);
      expect(result.value, 42);
    });

    test('Err holds failure', () {
      const result = Err<int>(DatabaseFailure('test error'));
      expect(result.isSuccess, false);
      expect(result.isFailure, true);
      expect(result.failure.message, 'test error');
    });

    test('when dispatches to correct branch', () {
      const success = Success<int>(42);
      final successResult = success.when(
        success: (data) => 'got $data',
        failure: (f) => 'failed: ${f.message}',
      );
      expect(successResult, 'got 42');

      const err = Err<int>(ValidationFailure('bad input'));
      final errResult = err.when(
        success: (data) => 'got $data',
        failure: (f) => 'failed: ${f.message}',
      );
      expect(errResult, 'failed: bad input');
    });

    test('Success with null value', () {
      const result = Success<void>(null);
      expect(result.isSuccess, true);
    });
  });

  group('Failure types', () {
    test('DatabaseFailure equality', () {
      const f1 = DatabaseFailure('error');
      const f2 = DatabaseFailure('error');
      expect(f1, equals(f2));
    });

    test('different failure types are not equal', () {
      const f1 = DatabaseFailure('error');
      const f2 = ValidationFailure('error');
      expect(f1, isNot(equals(f2)));
    });

    test('all failure types hold message', () {
      expect(const DatabaseFailure('a').message, 'a');
      expect(const ValidationFailure('b').message, 'b');
      expect(const StorageFailure('c').message, 'c');
      expect(const NetworkFailure('d').message, 'd');
      expect(const ExportFailure('e').message, 'e');
      expect(const ImportFailure('f').message, 'f');
      expect(const AnalysisFailure('g').message, 'g');
    });
  });
}
