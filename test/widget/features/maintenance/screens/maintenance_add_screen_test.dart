import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/maintenance/domain/entities/maintenance_log.dart';
import 'package:still_life/features/maintenance/presentation/screens/maintenance_add_screen.dart';
import 'package:still_life/core/errors/result.dart';
import 'package:still_life/core/providers/repository_providers.dart';
import 'package:still_life/features/maintenance/domain/repositories/maintenance_repository.dart';

class _FakeRepo implements MaintenanceRepository {
  @override
  Future<Result<MaintenanceLog>> create(MaintenanceLog log) async =>
      Success(log);
  @override
  Future<Result<void>> delete(String id) async => const Success(null);
  @override
  Future<Result<List<MaintenanceLog>>> getUpcoming() async => const Success([]);
  @override
  Future<Result<MaintenanceLog>> update(MaintenanceLog log) async =>
      Success(log);
  @override
  Stream<List<MaintenanceLog>> watchAll() => const Stream.empty();
  @override
  Stream<List<MaintenanceLog>> watchByItem(String itemId) =>
      const Stream.empty();
}

void main() {
  Widget buildSubject({MaintenanceLog? existing}) {
    return ProviderScope(
      overrides: [maintenanceRepositoryProvider.overrideWithValue(_FakeRepo())],
      child: MaterialApp(home: MaintenanceAddScreen(existing: existing)),
    );
  }

  group('MaintenanceAddScreen', () {
    testWidgets('shows "Log Maintenance" title in add mode', (tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Log Maintenance'), findsWidgets);
    });

    testWidgets('shows "Edit Entry" title in edit mode', (tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final now = DateTime(2025, 6, 1);
      final existing = MaintenanceLog(
        id: 'log1',
        title: 'Old Title',
        performedAt: now,
        createdAt: now,
        modifiedAt: now,
      );

      await tester.pumpWidget(buildSubject(existing: existing));
      await tester.pumpAndSettle();

      expect(find.text('Edit Entry'), findsWidgets);
    });

    testWidgets('title field is present', (tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsWidgets);
      expect(find.text('Title'), findsOneWidget);
    });

    testWidgets('title validation shows error on empty save', (tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Tap save without entering title
      // Find the FilledButton specifically
      final filledBtn = find.widgetWithText(FilledButton, 'Log Maintenance');
      await tester.tap(filledBtn);
      await tester.pumpAndSettle();

      expect(find.text('Title is required'), findsOneWidget);
    });

    testWidgets('save button present', (tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(FilledButton), findsOneWidget);
    });
  });
}
