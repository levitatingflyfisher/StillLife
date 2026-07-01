import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/services/database/connection/native.dart';

/// drift's LazyDatabase caches the FIRST open error for the whole session, so a
/// single transient path_provider channel failure would permanently break every
/// database write (e.g. first-run onboarding). resolveAppDocumentsDir() guards
/// against that with a short bounded retry.
void main() {
  test('returns immediately when the directory resolves on the first try',
      () async {
    var calls = 0;
    final dir = await resolveAppDocumentsDir(
      resolve: () async {
        calls++;
        return Directory('/tmp/docs');
      },
      sleep: (_) async {},
    );
    expect(dir.path, '/tmp/docs');
    expect(calls, 1, reason: 'happy path must not retry');
  });

  test('retries a transient channel failure, then succeeds', () async {
    var calls = 0;
    final dir = await resolveAppDocumentsDir(
      resolve: () async {
        calls++;
        if (calls < 3) {
          throw Exception('Unable to establish connection on channel');
        }
        return Directory('/tmp/ready');
      },
      sleep: (_) async {},
    );
    expect(dir.path, '/tmp/ready');
    expect(calls, 3);
  });

  test('gives up after the final attempt and throws with the real cause',
      () async {
    var calls = 0;
    await expectLater(
      () => resolveAppDocumentsDir(
        resolve: () async {
          calls++;
          throw Exception('channel permanently dead');
        },
        attempts: 4,
        sleep: (_) async {},
      ),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('channel permanently dead'),
        ),
      ),
    );
    expect(calls, 4);
  });
}
