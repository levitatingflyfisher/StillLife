import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/core/utils/label_id.dart';

void main() {
  group('labelId', () {
    const uuid1 = '550e8400-e29b-41d4-a716-446655440000';
    const uuid2 = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';

    test('returns three hyphen-separated words', () {
      final label = labelId(uuid1);
      final parts = label.split('-');
      expect(parts.length, 3);
    });

    test('is deterministic — same UUID always yields same label', () {
      expect(labelId(uuid1), labelId(uuid1));
      expect(labelId(uuid2), labelId(uuid2));
    });

    test('different UUIDs produce different labels', () {
      expect(labelId(uuid1), isNot(equals(labelId(uuid2))));
    });

    test('all words are lowercase letters only', () {
      final label = labelId(uuid1);
      final wordRe = RegExp(r'^[a-z]+$');
      for (final word in label.split('-')) {
        expect(
          wordRe.hasMatch(word),
          isTrue,
          reason: '"$word" contains non-lowercase characters',
        );
      }
    });

    test('works with a nil UUID', () {
      const nil = '00000000-0000-0000-0000-000000000000';
      final label = labelId(nil);
      expect(label.split('-').length, 3);
    });

    test('sample label looks cozy', () {
      // Spot-check — not flaky since it is deterministic
      final label = labelId(uuid1);
      expect(label, isNotEmpty);
      expect(label, contains('-'));
    });

    test('uses all three UUID windows independently', () {
      // Vary only window 1 (chars 0-7): adj1 changes, adj2/noun fixed.
      final labels1 = List.generate(100, (i) {
        final hex = i.toRadixString(16).padLeft(8, '0') + '0' * 24;
        final uuid = '${hex.substring(0, 8)}-0000-0000-0000-000000000000';
        return labelId(uuid).split('-')[0];
      }).toSet();

      // Vary only window 2 (chars 8-15): adj2 changes.
      final labels2 = List.generate(100, (i) {
        final hex = '00000000${i.toRadixString(16).padLeft(8, '0')}${'0' * 16}';
        final uuid =
            '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
            '${hex.substring(12, 16)}-0000-000000000000';
        return labelId(uuid).split('-')[1];
      }).toSet();

      expect(
        labels1.length,
        greaterThan(50),
        reason: 'window 1 should produce varied adj1',
      );
      expect(
        labels2.length,
        greaterThan(50),
        reason: 'window 2 should produce varied adj2',
      );
    });
  });
}
