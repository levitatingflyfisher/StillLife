import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:still_life/features/maintenance/presentation/screens/maintenance_add_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Every screen caps its content with OhPage (fleet ruling: no phone
/// layout stretched across a tablet or a browser). This is the check that
/// fails when a new screen forgets. Full-bleed screens are exempt, each
/// with its reason.
const _exempt = {
  'lib/app/shell_screen.dart':
      'hosts the tab screens, which carry their own OhPage',
  'lib/features/inventory/presentation/screens/photo_viewer_screen.dart':
      'full-bleed zoomable photo',
  'lib/features/inventory/presentation/screens/receipt_viewer_screen.dart':
      'full-bleed receipt image',
  'lib/features/scanning/presentation/screens/barcode_scanner_screen.dart':
      'full-bleed camera preview',
  'lib/features/video_analysis/presentation/screens/video_capture_screen.dart':
      'full-bleed camera preview',
};

void main() {
  test('every Scaffold body is an OhPage, or the screen is exempt', () {
    final misses = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      if (_exempt.containsKey(f.path)) continue;
      final src = f.readAsStringSync();
      final scaffolds = RegExp(r'\bScaffold\(').allMatches(src).length;
      final capped = RegExp(
        r'body:\s*(const\s+)?OhPage\(',
      ).allMatches(src).length;
      if (scaffolds > capped) misses.add('${f.path} ($capped/$scaffolds)');
    }
    expect(misses, isEmpty);
  });

  test('the old app-wide 760 clamp is gone', () {
    expect(File('lib/app/app.dart').readAsStringSync(), isNot(contains('760')));
  });

  testWidgets('a pushed screen is capped and centred at 1024 wide', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: MaintenanceAddScreen())),
    );
    await tester.pump();
    final field = tester.getRect(find.byType(TextFormField).first);
    expect(field.width, lessThanOrEqualTo(OhPage.phoneMaxWidth));
    expect(field.center.dx, closeTo(512, 1));
  });
}
