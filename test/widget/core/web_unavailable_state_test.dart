import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/core/widgets/web_unavailable_state.dart';

void main() {
  testWidgets('names the feature and explains the alternative honestly', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WebUnavailableState(
            icon: Icons.wifi_tethering_off_outlined,
            featureName: 'Wi-Fi sync',
            explanation: 'Use the Android app to pair devices.',
          ),
        ),
      ),
    );

    expect(find.text("Wi-Fi sync isn't available on web"), findsOneWidget);
    expect(find.text('Use the Android app to pair devices.'), findsOneWidget);
    expect(find.byIcon(Icons.wifi_tethering_off_outlined), findsOneWidget);
  });
}
