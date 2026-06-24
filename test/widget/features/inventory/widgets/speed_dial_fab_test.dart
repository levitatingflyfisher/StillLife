import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/inventory/presentation/widgets/speed_dial_fab.dart';

void main() {
  testWidgets('shows only main FAB when collapsed', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          floatingActionButton: SpeedDialFab(
            onPhoto: () {},
            onVoice: () {},
            onManual: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byIcon(Icons.camera_alt), findsNothing);
    expect(find.byIcon(Icons.mic), findsNothing);
    expect(find.byIcon(Icons.edit), findsNothing);
  });

  testWidgets('shows three option icons when expanded', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          floatingActionButton: SpeedDialFab(
            onPhoto: () {},
            onVoice: () {},
            onManual: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    expect(find.byIcon(Icons.mic), findsOneWidget);
    expect(find.byIcon(Icons.edit), findsOneWidget);
  });

  testWidgets('calls onPhoto when camera option tapped', (tester) async {
    bool called = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          floatingActionButton: SpeedDialFab(
            onPhoto: () => called = true,
            onVoice: () {},
            onManual: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.camera_alt));
    await tester.pumpAndSettle();

    expect(called, isTrue);
  });

  testWidgets('collapses when barrier tapped', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: const SizedBox.expand(),
          floatingActionButton: SpeedDialFab(
            onPhoto: () {},
            onVoice: () {},
            onManual: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.camera_alt), findsOneWidget);

    // Tap top-left corner (away from FAB)
    await tester.tapAt(const Offset(50, 50));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.camera_alt), findsNothing);
  });
}
