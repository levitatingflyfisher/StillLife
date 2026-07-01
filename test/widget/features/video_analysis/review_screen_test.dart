import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:still_life/core/providers/database_provider.dart';
import 'package:still_life/core/providers/profile_providers.dart';
import 'package:still_life/features/profiles/domain/entities/profile.dart'
    as domain;
import 'package:still_life/features/video_analysis/domain/entities/analysis_session.dart';
import 'package:still_life/features/video_analysis/domain/entities/detected_object.dart';
import 'package:still_life/features/video_analysis/presentation/controllers/video_analysis_controller.dart';
import 'package:still_life/features/video_analysis/presentation/screens/review_screen.dart';
import 'package:still_life/services/database/database.dart';

import '../../../test_setup.dart';

/// Review-save tests: a real in-memory database behind the real
/// repositories, so what the review screen claims to save is what lands in
/// columns — and each item's SOURCE FRAME really attaches as its photo.
class _FakeActiveProfileNotifier extends ActiveProfileNotifier {
  @override
  Future<domain.Profile?> build() async => null;
}

class _StubVideoController extends VideoAnalysisController {
  _StubVideoController(super.ref, AnalysisSession? initial) {
    state = initial;
  }
}

final _frameA = Uint8List.fromList([10, 11, 12]);
final _frameB = Uint8List.fromList([20, 21, 22]);

AnalysisSession _reviewSession() => AnalysisSession(
  id: 'vs-1',
  videoPath: '/tmp/walk.mp4',
  status: AnalysisStatus.reviewing,
  startedAt: DateTime(2026),
  detectedObjects: [
    DetectedObject(
      id: 'vs-1-0',
      label: 'Sony TV',
      confidence: 0.9,
      frameImage: _frameA,
      frameIndex: 3,
      brand: 'Sony',
      model: 'X90L',
      estimatedPrice: 899.999,
      category: 'Electronics',
    ),
    DetectedObject(
      id: 'vs-1-1',
      label: 'Floor lamp',
      confidence: 0.7,
      frameImage: _frameB,
      frameIndex: 8,
    ),
  ],
);

void main() {
  ensureSqlite3();

  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.memory();
    final now = DateTime(2026);
    await db.into(db.properties).insert(PropertiesCompanion.insert(
        id: 'prop-1', name: 'Home', createdAt: now, modifiedAt: now));
    await db.into(db.rooms).insert(RoomsCompanion.insert(
        id: 'room-1',
        propertyId: 'prop-1',
        name: 'Den',
        createdAt: now,
        modifiedAt: now));
    await db.into(db.categories).insert(CategoriesCompanion.insert(
        id: 'cat-elec',
        name: 'Electronics',
        createdAt: now,
        modifiedAt: now));
  });

  tearDown(() => db.close());

  Future<void> pumpReviewScreen(
    WidgetTester tester,
    AnalysisSession? session,
  ) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/video/review',
      routes: [
        GoRoute(
          path: '/video/review',
          builder: (_, _) => const ReviewScreen(),
        ),
        GoRoute(
          path: '/video/capture',
          builder: (_, _) => const Scaffold(body: Text('capture-screen')),
        ),
        GoRoute(
          path: '/inventory',
          builder: (_, _) => const Scaffold(body: Text('inventory-screen')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          activeProfileProvider.overrideWith(_FakeActiveProfileNotifier.new),
          videoAnalysisControllerProvider.overrideWith(
            (ref) => _StubVideoController(ref, session),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    // Bounded pumps, not pumpAndSettle: drift watch streams keep
    // scheduling work that never fully settles under fake async.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  /// Must be the last line of every test body: disposes the ProviderScope
  /// (closing drift query streams) and flushes their zero-duration close
  /// timers.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump(const Duration(milliseconds: 20));
  }

  Future<void> saveAndSettle(WidgetTester tester) async {
    await tester.tap(find.text('Save to Inventory'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets(
      'saves accepted items with brand/model/cents and their source frames',
      (tester) async {
    await pumpReviewScreen(tester, _reviewSession());

    await saveAndSettle(tester);

    final items = await db.select(db.items).get();
    expect(items, hasLength(2));

    final tv = items.firstWhere((i) => i.name == 'Sony TV');
    expect(tv.brand, 'Sony');
    expect(tv.model, 'X90L');
    expect(tv.currentValueCents, 90000); // 899.999 rounded to cents
    expect(tv.categoryId, 'cat-elec'); // hint resolved by name

    final photos = await db.select(db.photos).get();
    expect(photos, hasLength(2));
    for (final photo in photos) {
      expect(photo.source, 'videoFrame');
    }
    // Each item carries ITS OWN source frame, not a shared image.
    final tvPhoto = photos.firstWhere((p) => p.itemId == tv.id);
    expect(tvPhoto.bytes, _frameA);
    final lamp = items.firstWhere((i) => i.name == 'Floor lamp');
    final lampPhoto = photos.firstWhere((p) => p.itemId == lamp.id);
    expect(lampPhoto.bytes, _frameB);

    // Save hands off to the inventory.
    expect(find.text('inventory-screen'), findsOneWidget);

    await unmount(tester);
  });

  testWidgets('unchecked suggestions are not saved', (tester) async {
    await pumpReviewScreen(tester, _reviewSession());

    // Uncheck the lamp row.
    await tester.tap(find.byType(Checkbox).last);
    await tester.pump();

    await saveAndSettle(tester);

    final items = await db.select(db.items).get();
    expect(items, hasLength(1));
    expect(items.single.name, 'Sony TV');

    final photos = await db.select(db.photos).get();
    expect(photos, hasLength(1));
    expect(photos.single.bytes, _frameA);

    await unmount(tester);
  });

  testWidgets('an edited name is what gets saved', (tester) async {
    await pumpReviewScreen(tester, _reviewSession());

    await tester.enterText(
      find.widgetWithText(TextField, 'Sony TV'),
      'Living-room TV',
    );
    await saveAndSettle(tester);

    final items = await db.select(db.items).get();
    expect(items.map((i) => i.name), contains('Living-room TV'));

    await unmount(tester);
  });

  testWidgets('empty session still points back to capture', (tester) async {
    await pumpReviewScreen(tester, null);

    expect(find.text('No items to review'), findsOneWidget);
    expect(find.text('Scan a Room'), findsOneWidget);

    await unmount(tester);
  });
}
