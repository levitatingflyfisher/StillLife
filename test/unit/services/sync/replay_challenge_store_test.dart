import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/services/sync/replay_challenge_store.dart';

void main() {
  group('ReplayChallengeStore', () {
    test('issues a fresh 16-byte base64 token each time', () {
      final store = ReplayChallengeStore();
      final a = store.issue();
      final b = store.issue();
      expect(a, isNot(equals(b)));
      expect(base64.decode(a).length, 16);
      expect(store.outstandingCount, 2);
    });

    test('consume returns the raw bytes for an outstanding token', () {
      final store = ReplayChallengeStore();
      final token = store.issue();
      final bytes = store.consume(token);
      expect(bytes, isNotNull);
      expect(bytes, base64.decode(token));
    });

    test('a token is single-use: the second consume is rejected', () {
      final store = ReplayChallengeStore();
      final token = store.issue();
      expect(store.consume(token), isNotNull);
      // Replay of the same token → rejected (this is the replay defence).
      expect(store.consume(token), isNull);
    });

    test('an unknown token is rejected', () {
      final store = ReplayChallengeStore();
      expect(store.consume(base64.encode(List.filled(16, 9))), isNull);
    });

    test('an expired token is rejected', () {
      var now = DateTime(2026, 1, 1, 12, 0, 0);
      final store = ReplayChallengeStore(
        ttl: const Duration(minutes: 5),
        clock: () => now,
      );
      final token = store.issue();
      now = now.add(const Duration(minutes: 6));
      expect(store.consume(token), isNull);
    });

    test('outstanding challenges are bounded by maxOutstanding', () {
      final store = ReplayChallengeStore(maxOutstanding: 8);
      for (var i = 0; i < 100; i++) {
        store.issue();
      }
      expect(store.outstandingCount, lessThanOrEqualTo(8));
    });
  });
}
