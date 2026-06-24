import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/core/providers/database_provider.dart';
import 'package:still_life/features/dashboard/presentation/widgets/recent_activity_widget.dart';
import 'package:still_life/services/database/database.dart';

import '../../../../test_setup.dart';

Widget buildSubject(AppDatabase db) {
  return ProviderScope(
    overrides: [databaseProvider.overrideWithValue(db)],
    child: const MaterialApp(home: Scaffold(body: RecentActivityWidget())),
  );
}

void main() {
  ensureSqlite3();

  late AppDatabase db;
  final now = DateTime(2025, 1, 1);

  setUp(() async {
    db = AppDatabase.memory();
    await db
        .into(db.properties)
        .insert(
          PropertiesCompanion.insert(
            id: 'p1',
            name: 'Home',
            createdAt: now,
            modifiedAt: now,
          ),
        );
    await db
        .into(db.rooms)
        .insert(
          RoomsCompanion.insert(
            id: 'r1',
            propertyId: 'p1',
            name: 'Living Room',
            createdAt: now,
            modifiedAt: now,
          ),
        );
    await db
        .into(db.categories)
        .insert(
          CategoriesCompanion.insert(
            id: 'c1',
            name: 'Electronics',
            createdAt: now,
            modifiedAt: now,
          ),
        );
  });

  tearDown(() => db.close());

  group('RecentActivityWidget', () {
    testWidgets('shows nothing when no items', (tester) async {
      await tester.pumpWidget(buildSubject(db));
      await tester.pumpAndSettle();

      expect(find.text('Recent Activity'), findsNothing);
    });

    testWidgets('shows recently modified items', (tester) async {
      final modified = DateTime(2025, 6, 1, 12);
      await db.itemDao.insertItem(
        ItemsCompanion.insert(
          id: 'i1',
          name: 'Samsung TV',
          categoryId: 'c1',
          roomId: 'r1',
          createdAt: modified,
          modifiedAt: modified,
        ),
      );

      await tester.pumpWidget(buildSubject(db));
      await tester.pumpAndSettle();

      expect(find.text('Recent Activity'), findsOneWidget);
      expect(find.text('Samsung TV'), findsOneWidget);
    });

    testWidgets('shows at most 5 items', (tester) async {
      for (int i = 1; i <= 7; i++) {
        await db.itemDao.insertItem(
          ItemsCompanion.insert(
            id: 'i$i',
            name: 'Item $i',
            categoryId: 'c1',
            roomId: 'r1',
            createdAt: DateTime(2025, i, 1),
            modifiedAt: DateTime(2025, i, 1),
          ),
        );
      }

      await tester.pumpWidget(buildSubject(db));
      await tester.pumpAndSettle();

      // 5 ListTiles, not 7
      expect(find.byType(ListTile), findsNWidgets(5));
    });
  });
}
