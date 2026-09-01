import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// House style for words on screen: no spaced em dashes, and typographic
/// apostrophes and quotes (’ “ ”) rather than typewriter ones (' ").
/// A source scan over string literals in lib/: comments, imports and log
/// lines are ignored. (Same scan as Sundial's and Furrow's; the fleet has
/// no shared home for it yet.) Files whose literals never reach the screen
/// are exempt: model prompts and JSON schemas (the model reads them),
/// ffmpeg arguments, CSV quoting, a DAO guard, and generated l10n.
const _exempt = {
  'lib/features/inventory/data/services/item_photo_analysis_service.dart',
  'lib/features/video_analysis/data/services/frame_extractor_io.dart',
  'lib/services/ml/multi_item_parser.dart',
  'lib/services/import/receipt_structuring_parser.dart',
  'lib/services/chat/item_chat_service.dart',
  'lib/services/ml/hosted_provider.dart',
  'lib/services/ml/cloud_api_provider.dart',
  'lib/services/ml/ollama_provider.dart',
  'lib/services/ml/on_device/nano_engine.dart',
  'lib/services/ml/on_device/smolvlm_engine.dart',
  'lib/services/export/csv_export_service.dart',
  'lib/services/database/daos/appraisal_dao.dart',
  'lib/l10n/arb/app_localizations.dart',
};
void main() {
  final literal = RegExp(r'"([^"\\]|\\.)*"' "|" r"'([^'\\]|\\.)*'");

  Iterable<(String, int, String)> literals() sync* {
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'))
        .where((f) => !_exempt.contains(f.path));
    for (final f in files) {
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final t = line.trimLeft();
        if (t.startsWith('//') || line.contains('debugPrint(')) continue;
        if (t.startsWith('import ') || t.startsWith('export ')) continue;
        if (t.startsWith('part ')) continue;
        for (final m in literal.allMatches(line)) {
          yield (f.path, i + 1, m.group(0)!);
        }
      }
    }
  }

  test('no spaced em dash in on-screen copy', () {
    final hits = [
      for (final (path, line, lit) in literals())
        if (lit.contains(' — ') || lit.endsWith(" —'") || lit.endsWith(' —"'))
          '$path:$line $lit',
    ];
    expect(hits, isEmpty);
  });

  test('no typewriter apostrophe or quote inside on-screen copy', () {
    final apostrophe = RegExp(r"[A-Za-z]'[A-Za-z]");
    final escaped = RegExp(r"[A-Za-z}]\\'[A-Za-z]");
    final hits = [
      for (final (path, line, lit) in literals())
        if ((lit.startsWith('"') &&
                apostrophe.hasMatch(lit.substring(1, lit.length - 1))) ||
            (lit.startsWith("'") &&
                (lit.substring(1, lit.length - 1).contains('"') ||
                    escaped.hasMatch(lit))))
          '$path:$line $lit',
    ];
    expect(hits, isEmpty);
  });
}
