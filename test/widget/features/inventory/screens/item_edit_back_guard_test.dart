import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:still_life/core/providers/database_provider.dart';
import 'package:still_life/core/providers/profile_providers.dart';
import 'package:still_life/features/inventory/presentation/screens/item_edit_screen.dart';
import 'package:still_life/features/inventory/domain/entities/item_suggestion.dart';
import 'dart:typed_data';
import 'package:still_life/features/profiles/domain/entities/profile.dart'
    as domain;
import 'package:still_life/services/database/database.dart';

import '../../../../test_setup.dart';
import 'package:still_life/core/providers/sync_providers.dart';
import 'package:still_life/core/sync/sync_stamp.dart';

class _NoProfile extends ActiveProfileNotifier {
  @override
  Future<domain.Profile?> build() async => null;
}

/// about-face-07: Back on Add Item used to throw away everything typed,
/// silently. Typed work now asks before it goes; an untouched form leaves
/// at once.
void main() {
  ensureSqlite3();
  late AppDatabase db;
  setUp(() => db = AppDatabase.memory());
  tearDown(() => db.close());

  Future<void> open(
    WidgetTester tester, {
    Widget screen = const ItemEditScreen(),
  }) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: ElevatedButton(
              onPressed: () => context.push('/add'),
              child: const Text('open'),
            ),
          ),
        ),
        GoRoute(path: '/add', builder: (_, _) => screen),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          // No keystore in widget tests: writes go unstamped.
          syncStampProvider.overrideWithValue(SyncStamp.none),
          activeProfileProvider.overrideWith(_NoProfile.new),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> back(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump(const Duration(milliseconds: 20));
  }

  testWidgets('Back with typed work asks, and Keep editing keeps it', (
    tester,
  ) async {
    await open(tester);
    await tester.enterText(find.byType(TextFormField).first, 'Walnut desk');
    await back(tester);

    expect(find.text('Discard item'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Walnut desk'), findsOneWidget);

    await back(tester);
    await tester.tap(find.text('Discard item'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('open'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('Back on an untouched form leaves without asking', (
    tester,
  ) async {
    await open(tester);
    await back(tester);
    expect(find.text('Discard item'), findsNothing);
    expect(find.text('open'), findsOneWidget);
    await unmount(tester);
  });

  // mind-in-mind-08: Create was a live button on an empty field and did
  // nothing when pressed. It is now off until there is a name.
  testWidgets('New room: Create is off until a name is typed', (tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('New room'));
    await tester.pump(const Duration(milliseconds: 400));

    FilledButton create() => tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Create'),
    );
    expect(create().onPressed, isNull);

    await tester.enterText(find.widgetWithText(TextField, 'Room name'), '  ');
    await tester.pump();
    expect(create().onPressed, isNull, reason: 'blank is still no name');

    await tester.enterText(
      find.widgetWithText(TextField, 'Room name'),
      'Attic',
    );
    await tester.pump();
    expect(create().onPressed, isNotNull);

    await tester.tap(find.text('Cancel'));
    await tester.pump(const Duration(milliseconds: 400));
    await unmount(tester);
  });

  // A photo or voice add fills the form before the person types anything.
  // Back must not throw away the photo and the AI suggestion silently.
  testWidgets('Back after a photo add asks, and names the photo', (
    tester,
  ) async {
    await open(
      tester,
      screen: ItemEditScreen(
        initialSuggestion: ItemSuggestion(
          name: 'Reading lamp',
          photoBytes: Uint8List.fromList(List<int>.filled(16, 1)),
        ),
      ),
    );
    await back(tester);

    expect(find.text('Discard item'), findsOneWidget);
    expect(find.textContaining('photo'), findsWidgets);
    await tester.tap(find.text('Keep editing'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Reading lamp'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('Back after a voice add (no photo) asks too', (tester) async {
    await open(
      tester,
      screen: const ItemEditScreen(
        initialSuggestion: ItemSuggestion(name: 'Walnut desk'),
      ),
    );
    await back(tester);
    expect(find.text('Discard item'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pump(const Duration(milliseconds: 400));
    await unmount(tester);
  });
}
