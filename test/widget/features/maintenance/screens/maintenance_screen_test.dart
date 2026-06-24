import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/maintenance/domain/entities/maintenance_log.dart';
import 'package:still_life/features/maintenance/presentation/controllers/maintenance_controller.dart';
import 'package:still_life/features/maintenance/presentation/screens/maintenance_screen.dart';

void main() {
  final now = DateTime(2025, 6, 1);
  final future = DateTime(2030, 1, 1);

  Widget buildSubject({List<MaintenanceLog> logs = const []}) {
    return ProviderScope(
      overrides: [
        maintenanceLogsProvider.overrideWith((_) => Stream.value(logs)),
      ],
      child: const MaterialApp(home: MaintenanceScreen()),
    );
  }

  group('MaintenanceScreen', () {
    testWidgets('shows empty state when no logs', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('No maintenance logs yet.'), findsOneWidget);
    });

    testWidgets('shows FAB in all states', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('shows log titles', (tester) async {
      final logs = [
        MaintenanceLog(
          id: 'log1',
          title: 'AC Filter',
          performedAt: now,
          createdAt: now,
          modifiedAt: now,
        ),
        MaintenanceLog(
          id: 'log2',
          title: 'Boiler Check',
          performedAt: now,
          createdAt: now,
          modifiedAt: now,
        ),
      ];
      await tester.pumpWidget(buildSubject(logs: logs));
      await tester.pumpAndSettle();

      expect(find.text('AC Filter'), findsOneWidget);
      expect(find.text('Boiler Check'), findsOneWidget);
      expect(find.text('No maintenance logs yet.'), findsNothing);
    });

    testWidgets('shows upcoming section for logs with future nextDueAt', (
      tester,
    ) async {
      final logs = [
        MaintenanceLog(
          id: 'log1',
          title: 'Upcoming Task',
          performedAt: now,
          nextDueAt: future,
          createdAt: now,
          modifiedAt: now,
        ),
      ];
      await tester.pumpWidget(buildSubject(logs: logs));
      await tester.pumpAndSettle();

      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('Upcoming Task'), findsOneWidget);
    });

    testWidgets('shows loading indicator while loading', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            maintenanceLogsProvider.overrideWith(
              (_) => const Stream<List<MaintenanceLog>>.empty(),
            ),
          ],
          child: const MaterialApp(home: MaintenanceScreen()),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
