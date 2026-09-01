import 'dart:convert';

import 'package:crdt/crdt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/core/widgets/old_file_import_warning.dart';

/// Decision 5: an explicit import still takes a pre-stamp file, but only
/// after saying plainly that its records replace the device's own.
void main() {
  String file(List<String> stamps) => json.encode({
        'app': 'still_life',
        'version': '1.0',
        'data': {
          'categories': [
            for (var i = 0; i < stamps.length; i++)
              {'id': 'c$i', 'name': 'n', 'hlc': stamps[i]},
          ],
        },
      });
  final stamped = Hlc(DateTime.utc(2026, 9), 0, 'n').toString();

  Future<bool?> run(WidgetTester tester, String json,
      {String? tap}) async {
    bool? answer;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async =>
              answer = await confirmOldFileImport(context, json),
          child: const Text('go'),
        ),
      ),
    ));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    if (tap != null) {
      await tester.tap(find.text(tap));
      await tester.pumpAndSettle();
    }
    return answer;
  }

  testWidgets('a fully stamped file imports without asking', (tester) async {
    expect(await run(tester, file([stamped])), isTrue);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('an old file warns, and Cancel stops the import',
      (tester) async {
    bool? answer;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => answer =
              await confirmOldFileImport(context, file(['', '', stamped])),
          child: const Text('go'),
        ),
      ),
    ));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining('2 records'), findsOneWidget);
    expect(find.textContaining('even where yours are newer'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(answer, isFalse);
  });

  testWidgets('an old file imports once the user accepts', (tester) async {
    expect(await run(tester, file(['']), tap: 'Import anyway'), isTrue);
  });
}
