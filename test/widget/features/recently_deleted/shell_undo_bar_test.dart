import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/recently_deleted/presentation/shell_undo_bar.dart';
import 'package:still_life/features/recently_deleted/presentation/undo_providers.dart';

void main() {
  testWidgets('shell Undo sits flush on the nav bar and restores on tap', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    var undone = false;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: MediaQuery(
            // A phone with a 48 px gesture bar.
            data: const MediaQueryData(
              size: Size(360, 740),
              padding: EdgeInsets.only(bottom: 48),
              viewPadding: EdgeInsets.only(bottom: 48),
            ),
            child: Scaffold(
              body: const SizedBox.expand(),
              bottomNavigationBar: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ShellUndoBar(),
                  NavigationBar(
                    destinations: const [
                      NavigationDestination(icon: Icon(Icons.home), label: 'A'),
                      NavigationDestination(icon: Icon(Icons.list), label: 'B'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Undo'), findsNothing);

    container
        .read(shellUndoControllerProvider)
        .show(message: 'Deleted TV', onUndo: () async => undone = true);
    await tester.pump();

    expect(find.text('Deleted TV'), findsOneWidget);
    final bar = tester.getRect(find.byType(ShellUndoBar));
    // 48 dp Undo button plus its vertical padding; no gesture-bar band.
    expect(bar.height, lessThan(80));

    await tester.tap(find.text('Undo'));
    await tester.pump();
    expect(undone, isTrue);
    expect(find.text('Deleted TV'), findsNothing);
  });
}
