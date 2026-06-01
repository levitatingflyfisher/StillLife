import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/dashboard/presentation/widgets/upcoming_maintenance_widget.dart';
import 'package:still_life/features/maintenance/domain/entities/maintenance_log.dart';
import 'package:still_life/features/maintenance/presentation/controllers/maintenance_controller.dart';

void main() {
  final now = DateTime(2025, 6, 1);

  MaintenanceLog makeLog({
    String id = 'log1',
    String title = 'AC Filter',
    DateTime? nextDueAt,
  }) {
    return MaintenanceLog(
      id: id,
      title: title,
      performedAt: now,
      nextDueAt: nextDueAt,
      createdAt: now,
      modifiedAt: now,
    );
  }

  Widget buildSubject({List<MaintenanceLog> logs = const []}) {
    return ProviderScope(
      overrides: [upcomingMaintenanceProvider.overrideWith((_) async => logs)],
      child: const MaterialApp(
        home: Scaffold(body: UpcomingMaintenanceWidget()),
      ),
    );
  }

  group('UpcomingMaintenanceWidget', () {
    testWidgets('shows empty state message when no logs', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('No upcoming maintenance.'), findsOneWidget);
    });

    testWidgets('shows "Add Entry" button in empty state', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Add Entry'), findsOneWidget);
    });

    testWidgets('shows card header', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Upcoming Maintenance'), findsOneWidget);
    });

    testWidgets('shows log title when logs present', (tester) async {
      final due = DateTime.now().add(const Duration(days: 5));
      await tester.pumpWidget(
        buildSubject(
          logs: [makeLog(title: 'Boiler Service', nextDueAt: due)],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Boiler Service'), findsOneWidget);
    });

    testWidgets('shows "Log Maintenance" button when logs present', (
      tester,
    ) async {
      final due = DateTime.now().add(const Duration(days: 5));
      await tester.pumpWidget(buildSubject(logs: [makeLog(nextDueAt: due)]));
      await tester.pumpAndSettle();

      expect(find.text('Log Maintenance'), findsOneWidget);
    });

    testWidgets('shows overdue badge for past due logs', (tester) async {
      // Logs passed to upcoming widget have future nextDueAt normally,
      // but we simulate overdue by passing a past date
      final pastDue = DateTime.now().subtract(const Duration(days: 1));
      await tester.pumpWidget(
        buildSubject(
          logs: [makeLog(title: 'Overdue Task', nextDueAt: pastDue)],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Overdue'), findsOneWidget);
    });
  });
}
