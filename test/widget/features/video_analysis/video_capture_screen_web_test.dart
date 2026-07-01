import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/core/widgets/web_unavailable_state.dart';
import 'package:still_life/features/video_analysis/presentation/screens/video_capture_screen.dart';

void main() {
  testWidgets('on web the capture screen is an honest unavailable state, '
      'not a crash', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: VideoCaptureScreen(isWeb: true)),
      ),
    );
    await tester.pump();

    expect(find.byType(WebUnavailableState), findsOneWidget);
    expect(find.textContaining('Android app'), findsOneWidget);
    // No camera init was attempted — nothing spins, nothing throws.
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
