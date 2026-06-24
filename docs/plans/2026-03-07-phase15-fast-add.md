# Phase 15 — Fast Add Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the bare FAB on all item-bearing screens with a speed dial offering photo-first, voice, and manual add; enhance barcode result sheet with contextual actions; wire photo and voice through the existing LLM tier chain to pre-fill `ItemEditScreen`.

**Architecture:** New `ItemSuggestion` model flows from `ItemPhotoAnalysisService` (wraps `ProviderManager.getBestAvailable()` + `analyzeImage()`) into `ItemEditScreen` via constructor param. `SpeedDialFab` replaces all three bare FABs. `VoiceInputService` uses `speech_to_text` for on-device STT then sends transcript through the same LLM service. `BarcodeResultSheet` gains an action row for existing items.

**Tech Stack:** Flutter, Riverpod, GoRouter, `image_picker` (already in pubspec), `speech_to_text` (new dep), `mobile_scanner` (existing), existing 4-tier `AnalysisProvider` / `ProviderManager` chain.

---

## Codebase orientation

- LLM tiers: `lib/services/ml/analysis_provider.dart` — `AnalysisProvider.analyzeImage({required Uint8List imageBytes})` returns `AnalysisResult`
- LLM management: `lib/services/ml/provider_manager.dart` — `ProviderManager.getBestAvailable()` returns first available tier
- LLM settings providers: `lib/features/settings/presentation/screens/llm_settings_screen.dart` — `llmTierPriorityProvider`, `llmTierEnabledProvider`, `ollamaHostProvider`, `ollamaModelProvider`, `cloudApiTypeProvider`
- `BarcodeResultSheet` lives at bottom of `lib/features/scanning/presentation/screens/barcode_scanner_screen.dart:150`
- `ItemEditScreen` params: `itemId`, `initialRoomId`, `initialContainerId`, `initialBarcode` — add `initialSuggestion`
- Router: `lib/app/router.dart` — `buildAppRouter()` — all named routes defined here
- Riverpod providers: `lib/core/providers/repository_providers.dart`
- Tests: `flutter test` must pass (359 currently)
- After changes to files with `@riverpod`: run `dart run build_runner build --delete-conflicting-outputs`

---

## Task 1: `ItemSuggestion` model

**Files:**
- Create: `lib/features/inventory/domain/entities/item_suggestion.dart`

**Step 1: Write the model**

```dart
// lib/features/inventory/domain/entities/item_suggestion.dart
import 'package:image_picker/image_picker.dart';

/// Structured suggestion returned by photo or voice analysis.
/// All fields nullable — partial suggestions are valid.
class ItemSuggestion {
  final String? name;
  final String? categoryName; // plain name, not ID — matched by name in form
  final double? estimatedValue;
  final String? notes;
  final XFile? photo;

  const ItemSuggestion({
    this.name,
    this.categoryName,
    this.estimatedValue,
    this.notes,
    this.photo,
  });
}
```

**Step 2: Verify no codegen needed** — plain Dart class, no `@freezed` or `@riverpod`. No build_runner run required.

**Step 3: Commit**

```bash
git add lib/features/inventory/domain/entities/item_suggestion.dart
git commit -m "feat: add ItemSuggestion model for photo/voice pre-fill"
```

---

## Task 2: `ItemPhotoAnalysisService`

**Files:**
- Create: `lib/features/inventory/data/services/item_photo_analysis_service.dart`
- Create: `test/unit/features/inventory/services/item_photo_analysis_service_test.dart`

**Step 1: Write failing tests**

```dart
// test/unit/features/inventory/services/item_photo_analysis_service_test.dart
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:image_picker/image_picker.dart';
import 'package:still_life/features/inventory/data/services/item_photo_analysis_service.dart';
import 'package:still_life/services/ml/analysis_provider.dart';
import 'package:still_life/services/ml/provider_manager.dart';

class MockProviderManager extends Mock implements ProviderManager {}
class MockAnalysisProvider extends Mock implements AnalysisProvider {}

void main() {
  late MockProviderManager mockManager;
  late MockAnalysisProvider mockProvider;
  late ItemPhotoAnalysisService service;

  setUp(() {
    mockManager = MockProviderManager();
    mockProvider = MockAnalysisProvider();
    service = ItemPhotoAnalysisService(mockManager);
  });

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  test('returns ItemSuggestion when LLM succeeds', () async {
    when(() => mockManager.getBestAvailable())
        .thenAnswer((_) async => mockProvider);
    when(() => mockProvider.analyzeImage(imageBytes: any(named: 'imageBytes')))
        .thenAnswer((_) async => const AnalysisResult(
              itemName: 'Drill',
              description: 'A power drill',
              category: 'Tools',
              estimatedPrice: 89.0,
              confidence: 0.9,
            ));

    final result = await service.analyzePhoto(Uint8List(1));

    expect(result, isNotNull);
    expect(result!.name, 'Drill');
    expect(result.categoryName, 'Tools');
    expect(result.estimatedValue, 89.0);
  });

  test('returns null when no LLM provider available', () async {
    when(() => mockManager.getBestAvailable()).thenAnswer((_) async => null);

    final result = await service.analyzePhoto(Uint8List(1));

    expect(result, isNull);
  });

  test('returns null when LLM call throws', () async {
    when(() => mockManager.getBestAvailable())
        .thenAnswer((_) async => mockProvider);
    when(() => mockProvider.analyzeImage(imageBytes: any(named: 'imageBytes')))
        .thenThrow(Exception('network error'));

    final result = await service.analyzePhoto(Uint8List(1));

    expect(result, isNull);
  });

  test('parseVoiceTranscript returns suggestion from structured text', () async {
    when(() => mockManager.getBestAvailable())
        .thenAnswer((_) async => mockProvider);
    when(() => mockProvider.analyzeImage(imageBytes: any(named: 'imageBytes')))
        .thenAnswer((_) async => const AnalysisResult(
              itemName: 'Bosch Drill',
              description: 'power tool',
              category: 'Tools',
              estimatedPrice: 120.0,
              confidence: 0.8,
            ));

    // Voice path re-uses analyzeImage with a text-only prompt image
    final result = await service.analyzeVoice('Bosch drill paid 120 dollars kitchen');
    expect(result, isNotNull);
    expect(result!.name, 'Bosch Drill');
  });
}
```

**Step 2: Run tests to verify they fail**

```bash
flutter test test/unit/features/inventory/services/item_photo_analysis_service_test.dart
```
Expected: FAIL with "Target of URI doesn't exist"

**Step 3: Implement `ItemPhotoAnalysisService`**

```dart
// lib/features/inventory/data/services/item_photo_analysis_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:still_life/features/inventory/domain/entities/item_suggestion.dart';
import 'package:still_life/services/ml/provider_manager.dart';

class ItemPhotoAnalysisService {
  final ProviderManager _manager;

  ItemPhotoAnalysisService(this._manager);

  /// Analyze a photo (raw bytes) and return a suggestion, or null if
  /// no LLM is configured or the call fails.
  Future<ItemSuggestion?> analyzePhoto(Uint8List imageBytes) async {
    try {
      final provider = await _manager.getBestAvailable();
      if (provider == null) return null;
      final result = await provider.analyzeImage(imageBytes: imageBytes);
      return ItemSuggestion(
        name: result.itemName.isEmpty ? null : result.itemName,
        categoryName: result.category.isEmpty ? null : result.category,
        estimatedValue: result.estimatedPrice,
        notes: result.description.isEmpty ? null : result.description,
      );
    } catch (_) {
      return null;
    }
  }

  /// Encode a voice transcript as a minimal PNG-like payload and send through
  /// the same LLM chain with an extraction prompt baked into existingLabel.
  /// Returns null if no provider or call fails.
  Future<ItemSuggestion?> analyzeVoice(String transcript) async {
    try {
      final provider = await _manager.getBestAvailable();
      if (provider == null) return null;
      // Send a 1×1 transparent PNG; the real content is in existingLabel prompt.
      final result = await provider.analyzeImage(
        imageBytes: _minimalPng(),
        existingLabel:
            'Extract item name, category (one of: Electronics, Furniture, '
            'Appliances, Clothing, Tools, Sports, Books, Kitchenware, Other), '
            'and estimated value in USD from this spoken description. '
            'Description: "$transcript"',
      );
      return ItemSuggestion(
        name: result.itemName.isEmpty ? null : result.itemName,
        categoryName: result.category.isEmpty ? null : result.category,
        estimatedValue: result.estimatedPrice,
        notes: result.description.isEmpty ? null : result.description,
      );
    } catch (_) {
      return null;
    }
  }

  // Minimal 1×1 transparent PNG (68 bytes) — avoids image_picker dependency
  // in the service layer while satisfying the analyzeImage bytes parameter.
  static Uint8List _minimalPng() {
    const b64 =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';
    return base64Decode(b64);
  }
}
```

**Step 4: Run tests**

```bash
flutter test test/unit/features/inventory/services/item_photo_analysis_service_test.dart
```
Expected: PASS (4 tests)

**Step 5: Commit**

```bash
git add lib/features/inventory/data/services/item_photo_analysis_service.dart \
        test/unit/features/inventory/services/item_photo_analysis_service_test.dart
git commit -m "feat: ItemPhotoAnalysisService wraps LLM tier chain for photo/voice"
```

---

## Task 3: `providerManagerProvider` + `itemPhotoAnalysisServiceProvider`

**Files:**
- Modify: `lib/core/providers/repository_providers.dart`
- Modify: `lib/features/settings/presentation/screens/llm_settings_screen.dart` (just reads providers, no change needed if manager built in repo providers)

**Step 1: Add providers to `repository_providers.dart`**

Add these imports at the top:
```dart
import '../../services/ml/analysis_provider.dart';
import '../../services/ml/on_device_provider.dart';
import '../../services/ml/ollama_provider.dart';
import '../../services/ml/cloud_api_provider.dart';
import '../../services/ml/hosted_provider.dart';
import '../../services/ml/provider_manager.dart';
import '../../features/inventory/data/services/item_photo_analysis_service.dart';
import '../../features/settings/presentation/screens/llm_settings_screen.dart';
```

Add providers at the bottom of the file:
```dart
final providerManagerProvider = Provider<ProviderManager>((ref) {
  final priority = ref.watch(llmTierPriorityProvider);
  final enabled = ref.watch(llmTierEnabledProvider);
  final ollamaHost = ref.watch(ollamaHostProvider);
  final ollamaPort = ref.watch(ollamaPortProvider);
  final ollamaModel = ref.watch(ollamaModelProvider);

  final providers = <AnalysisProvider>[
    OnDeviceProvider(),
    OllamaProvider(host: ollamaHost, port: ollamaPort, model: ollamaModel),
    CloudApiProvider(),
    HostedProvider(),
  ].where((p) => enabled[p.tier] ?? true).toList();

  return ProviderManager(
    providers: providers,
    priorityOrder: priority.where((t) => enabled[t] ?? true).toList(),
  );
});

final itemPhotoAnalysisServiceProvider =
    Provider<ItemPhotoAnalysisService>((ref) {
  return ItemPhotoAnalysisService(ref.watch(providerManagerProvider));
});
```

**Step 2: Check existing provider constructors**

Read `lib/services/ml/on_device_provider.dart`, `ollama_provider.dart`, `cloud_api_provider.dart`, `hosted_provider.dart` to verify constructor signatures match what's used above. Adjust if signatures differ (e.g., OllamaProvider may need `baseUrl` instead of `host`+`port`).

**Step 3: Run analyze to find any issues**

```bash
flutter analyze lib/core/providers/repository_providers.dart
```
Fix any reported errors.

**Step 4: Run all tests**

```bash
flutter test
```
Expected: 359 passing (no regressions)

**Step 5: Commit**

```bash
git add lib/core/providers/repository_providers.dart
git commit -m "feat: providerManagerProvider + itemPhotoAnalysisServiceProvider"
```

---

## Task 4: Update `ItemEditScreen` to accept `ItemSuggestion?`

**Files:**
- Modify: `lib/features/inventory/presentation/screens/item_edit_screen.dart`
- Modify: `lib/app/router.dart` (pass suggestion through `GoRouterState.extra`)

**Step 1: Write failing widget tests**

```dart
// test/widget/features/inventory/screens/item_edit_suggestion_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:still_life/core/providers/repository_providers.dart';
import 'package:still_life/features/inventory/domain/entities/item_suggestion.dart';
import 'package:still_life/features/inventory/domain/repositories/item_repository.dart';
import 'package:still_life/features/inventory/presentation/screens/item_edit_screen.dart';
import 'package:still_life/features/locations/domain/repositories/room_repository.dart';

class MockItemRepository extends Mock implements ItemRepository {}
class MockRoomRepository extends Mock implements RoomRepository {}

void main() {
  // Set tall viewport so all form fields are in the tree.
  setUp(() {
    // no-op; set in each test
  });

  testWidgets('pre-fills name from ItemSuggestion', (tester) async {
    tester.view.physicalSize = const Size(800, 5000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final suggestion = const ItemSuggestion(name: 'Bosch Drill');

    await tester.pumpWidget(ProviderScope(
      overrides: [/* minimal overrides */],
      child: MaterialApp(
        home: ItemEditScreen(initialSuggestion: suggestion),
      ),
    ));
    await tester.pump();

    expect(
      find.byWidgetPredicate(
        (w) => w is EditableText && w.controller.text == 'Bosch Drill',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows AI banner when suggestion is null', (tester) async {
    tester.view.physicalSize = const Size(800, 5000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(ProviderScope(
      overrides: [],
      child: MaterialApp(
        home: const ItemEditScreen(showAiBanner: true),
      ),
    ));
    await tester.pump();

    expect(find.textContaining('Set up AI analysis'), findsOneWidget);
  });
}
```

**Step 2: Run to confirm failure**

```bash
flutter test test/widget/features/inventory/screens/item_edit_suggestion_test.dart
```
Expected: FAIL — `initialSuggestion` and `showAiBanner` params don't exist yet.

**Step 3: Add params to `ItemEditScreen`**

In `item_edit_screen.dart`, add two params:

```dart
class ItemEditScreen extends ConsumerStatefulWidget {
  final String? itemId;
  final String? initialRoomId;
  final String? initialContainerId;
  final String? initialBarcode;
  final ItemSuggestion? initialSuggestion; // NEW
  final bool showAiBanner;                 // NEW

  const ItemEditScreen({
    super.key,
    this.itemId,
    this.initialRoomId,
    this.initialContainerId,
    this.initialBarcode,
    this.initialSuggestion,               // NEW
    this.showAiBanner = false,            // NEW
  });
  // ...
}
```

In `_ItemEditScreenState._prefillFromWidget()` (or wherever `initialRoomId` / `initialBarcode` are applied), add:

```dart
// Apply suggestion fields only when creating (not editing).
if (!widget.isEditing && widget.initialSuggestion != null) {
  final s = widget.initialSuggestion!;
  if (s.name != null) _nameController.text = s.name!;
  if (s.notes != null) _notesController.text = s.notes!;
  if (s.estimatedValue != null) {
    _currentValueController.text = s.estimatedValue!.toStringAsFixed(2);
  }
  // Category: match by name against loaded categories (done after categories load)
  _pendingCategoryName = s.categoryName;
}
```

Add `String? _pendingCategoryName;` to state, then in the build/watch where categories load:
```dart
// After categories are loaded, match pending category name.
if (_pendingCategoryName != null) {
  final match = categories.firstWhereOrNull(
    (c) => c.name.toLowerCase() == _pendingCategoryName!.toLowerCase(),
  );
  if (match != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() { _selectedCategoryId = match.id; _pendingCategoryName = null; });
    });
  }
}
```

Add AI banner in `build()` — wrap the form body in a `Column` with `MaterialBanner` at top when `widget.showAiBanner`:

```dart
// In build(), before the form body:
if (widget.showAiBanner)
  MaterialBanner(
    content: const Text('Set up AI analysis for automatic suggestions'),
    actions: [
      TextButton(
        onPressed: () => context.pushNamed('llmSettings'),
        child: const Text('Set Up'),
      ),
      TextButton(
        onPressed: () => setState(() => _bannerDismissed = true),
        child: const Text('Dismiss'),
      ),
    ],
  ),
```

Add `bool _bannerDismissed = false;` to state and gate the banner on `!_bannerDismissed`.

**Step 4: Run tests**

```bash
flutter test test/widget/features/inventory/screens/item_edit_suggestion_test.dart
```
Expected: PASS (2 tests). If Riverpod provider overrides are missing in test, add fake implementations for repositories that the screen reads.

**Step 5: Run full suite**

```bash
flutter test
```
Expected: 361+ passing.

**Step 6: Commit**

```bash
git add lib/features/inventory/presentation/screens/item_edit_screen.dart \
        lib/features/inventory/domain/entities/item_suggestion.dart \
        test/widget/features/inventory/screens/item_edit_suggestion_test.dart
git commit -m "feat: ItemEditScreen accepts ItemSuggestion pre-fill + AI banner"
```

---

## Task 5: `SpeedDialFab` widget

**Files:**
- Create: `lib/features/inventory/presentation/widgets/speed_dial_fab.dart`
- Create: `test/widget/features/inventory/widgets/speed_dial_fab_test.dart`

**Step 1: Write failing widget test**

```dart
// test/widget/features/inventory/widgets/speed_dial_fab_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/inventory/presentation/widgets/speed_dial_fab.dart';

void main() {
  testWidgets('shows only main FAB when collapsed', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        floatingActionButton: SpeedDialFab(
          onPhoto: () {},
          onVoice: () {},
          onManual: () {},
        ),
      ),
    ));

    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byIcon(Icons.camera_alt), findsNothing);
  });

  testWidgets('shows three options when expanded', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        floatingActionButton: SpeedDialFab(
          onPhoto: () {},
          onVoice: () {},
          onManual: () {},
        ),
      ),
    ));

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    expect(find.byIcon(Icons.mic), findsOneWidget);
    expect(find.byIcon(Icons.edit), findsOneWidget);
  });

  testWidgets('calls onPhoto when camera option tapped', (tester) async {
    bool called = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        floatingActionButton: SpeedDialFab(
          onPhoto: () => called = true,
          onVoice: () {},
          onManual: () {},
        ),
      ),
    ));

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.camera_alt));
    await tester.pumpAndSettle();

    expect(called, isTrue);
  });

  testWidgets('collapses when tapped outside', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: const SizedBox.expand(),
        floatingActionButton: SpeedDialFab(
          onPhoto: () {},
          onVoice: () {},
          onManual: () {},
        ),
      ),
    ));

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.camera_alt), findsOneWidget);

    await tester.tapAt(const Offset(100, 100)); // tap away
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.camera_alt), findsNothing);
  });
}
```

**Step 2: Run to confirm failure**

```bash
flutter test test/widget/features/inventory/widgets/speed_dial_fab_test.dart
```
Expected: FAIL.

**Step 3: Implement `SpeedDialFab`**

```dart
// lib/features/inventory/presentation/widgets/speed_dial_fab.dart
import 'package:flutter/material.dart';

class SpeedDialFab extends StatefulWidget {
  final VoidCallback onPhoto;
  final VoidCallback onVoice;
  final VoidCallback onManual;

  const SpeedDialFab({
    super.key,
    required this.onPhoto,
    required this.onVoice,
    required this.onManual,
  });

  @override
  State<SpeedDialFab> createState() => _SpeedDialFabState();
}

class _SpeedDialFabState extends State<SpeedDialFab>
    with SingleTickerProviderStateMixin {
  bool _open = false;
  late final AnimationController _controller;
  late final Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _expandAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    _open ? _controller.forward() : _controller.reverse();
  }

  void _close() {
    if (!_open) return;
    setState(() => _open = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      clipBehavior: Clip.none,
      children: [
        // Scrim — dismiss on tap outside
        if (_open)
          Positioned.fill(
            child: GestureDetector(
              onTap: _close,
              behavior: HitTestBehavior.translucent,
              child: Container(
                color: Colors.black.withAlpha(30),
              ),
            ),
          ),

        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Options (visible when open)
            ScaleTransition(
              scale: _expandAnim,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _DialOption(
                    icon: Icons.camera_alt,
                    label: 'Take photo',
                    onTap: () { _close(); widget.onPhoto(); },
                  ),
                  const SizedBox(height: 8),
                  _DialOption(
                    icon: Icons.mic,
                    label: 'Describe it',
                    onTap: () { _close(); widget.onVoice(); },
                  ),
                  const SizedBox(height: 8),
                  _DialOption(
                    icon: Icons.edit,
                    label: 'Enter manually',
                    onTap: () { _close(); widget.onManual(); },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            // Main FAB
            FloatingActionButton(
              heroTag: 'speedDialMain',
              onPressed: _toggle,
              child: AnimatedRotation(
                turns: _open ? 0.125 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.add),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DialOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DialOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(8),
          color: theme.colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(label, style: theme.textTheme.labelMedium),
          ),
        ),
        const SizedBox(width: 8),
        FloatingActionButton.small(
          heroTag: label,
          onPressed: onTap,
          child: Icon(icon),
        ),
      ],
    );
  }
}
```

**Step 4: Run tests**

```bash
flutter test test/widget/features/inventory/widgets/speed_dial_fab_test.dart
```
Expected: PASS (4 tests). Note: the scrim overlay may interfere with "tap outside" — if the test fails, adjust the `GestureDetector` placement in the widget.

**Step 5: Commit**

```bash
git add lib/features/inventory/presentation/widgets/speed_dial_fab.dart \
        test/widget/features/inventory/widgets/speed_dial_fab_test.dart
git commit -m "feat: SpeedDialFab — photo/voice/manual options with animation"
```

---

## Task 6: Wire photo-first flow + wire `SpeedDialFab` into screens

**Files:**
- Modify: `lib/features/inventory/presentation/screens/inventory_screen.dart`
- Modify: `lib/features/locations/presentation/screens/room_detail_screen.dart`
- Modify: `lib/features/locations/presentation/screens/container_detail_screen.dart`

For each screen, replace:
```dart
floatingActionButton: FloatingActionButton(
  onPressed: () => context.pushNamed('addItem', ...),
  child: const Icon(Icons.add),
),
```

With:
```dart
floatingActionButton: SpeedDialFab(
  onPhoto: () => _onPhotoAdd(context, ref),
  onVoice: () => _onVoiceAdd(context, ref),
  onManual: () => context.pushNamed('addItem', queryParameters: {
    if (roomId != null) 'roomId': roomId!,
    if (containerId != null) 'containerId': containerId!,
  }),
),
```

Add the `_onPhotoAdd` helper (add to each screen's widget/state class or as a top-level function shared across screens — prefer a shared mixin or static function in `speed_dial_fab.dart` to avoid duplication):

```dart
Future<void> _onPhotoAdd(BuildContext context, WidgetRef ref, {
  String? roomId,
  String? containerId,
}) async {
  final picker = ImagePicker();
  final photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
  if (photo == null || !context.mounted) return;

  final bytes = await photo.readAsBytes();
  final service = ref.read(itemPhotoAnalysisServiceProvider);
  final suggestion = await service.analyzePhoto(bytes);
  if (!context.mounted) return;

  context.pushNamed('addItem', queryParameters: {
    if (roomId != null) 'roomId': roomId!,
    if (containerId != null) 'containerId': containerId!,
  }, extra: (suggestion ?? const ItemSuggestion()).copyWith(photo: photo));
}
```

**Note on `extra` in GoRouter:** The router's `addItem` route builder must read `state.extra as ItemSuggestion?` and pass it to `ItemEditScreen(initialSuggestion: ..., showAiBanner: suggestion == null)`.

Update `lib/app/router.dart` — find the `addItem` GoRoute and update its builder:

```dart
GoRoute(
  path: 'add',
  name: 'addItem',
  builder: (context, state) {
    final roomId = state.uri.queryParameters['roomId'];
    final containerId = state.uri.queryParameters['containerId'];
    final barcode = state.uri.queryParameters['barcode'];
    final suggestion = state.extra as ItemSuggestion?;
    return ItemEditScreen(
      initialRoomId: roomId,
      initialContainerId: containerId,
      initialBarcode: barcode,
      initialSuggestion: suggestion,
      showAiBanner: suggestion == null && barcode == null,
    );
  },
),
```

Add import at top of `router.dart`:
```dart
import '../features/inventory/domain/entities/item_suggestion.dart';
```

**Step 1: Make the changes to all three screens and router.dart**

**Step 2: Run analyze**

```bash
flutter analyze
```
Fix any errors.

**Step 3: Run all tests**

```bash
flutter test
```
Expected: 361+ passing.

**Step 4: Commit**

```bash
git add lib/features/inventory/presentation/screens/inventory_screen.dart \
        lib/features/locations/presentation/screens/room_detail_screen.dart \
        lib/features/locations/presentation/screens/container_detail_screen.dart \
        lib/app/router.dart
git commit -m "feat: wire SpeedDialFab + photo-first flow into item-bearing screens"
```

---

## Task 7: Enhance `BarcodeResultSheet` for existing items

**Files:**
- Modify: `lib/features/scanning/presentation/screens/barcode_scanner_screen.dart`
- Modify: `test/widget/features/scanning/` (new test file)

**Step 1: Write failing test**

```dart
// test/widget/features/scanning/barcode_result_sheet_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:still_life/features/inventory/domain/entities/item.dart';
import 'package:still_life/features/scanning/presentation/screens/barcode_scanner_screen.dart';

Item _item() => Item(
      id: 'i1',
      name: 'Bosch Drill',
      description: '',
      categoryId: 'c1',
      roomId: 'r1',
      createdAt: DateTime(2025),
      modifiedAt: DateTime(2025),
    );

Barcode _barcode() => const Barcode(rawValue: '0123456789');

Widget _sheet({Item? existingItem}) {
  return MaterialApp(
    home: Scaffold(
      body: BarcodeResultSheet(
        barcode: _barcode(),
        existingItem: existingItem,
        onScanAgain: () {},
        onAddToInventory: existingItem == null ? () {} : null,
        onViewItem: existingItem != null ? () {} : null,
        onEditItem: existingItem != null ? () {} : null,
        onMoveItem: existingItem != null ? () {} : null,
        onLogMaintenance: existingItem != null ? () {} : null,
      ),
    ),
  );
}

void main() {
  testWidgets('shows Add to Inventory as FilledButton for new item', (tester) async {
    await tester.pumpWidget(_sheet());
    expect(find.text('Add to Inventory'), findsOneWidget);
    // Verify it's a FilledButton (rendered with filled style)
    expect(find.byType(FilledButton), findsWidgets);
  });

  testWidgets('shows action row for existing item', (tester) async {
    await tester.pumpWidget(_sheet(existingItem: _item()));
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.byIcon(Icons.drive_file_move_outlined), findsOneWidget);
    expect(find.byIcon(Icons.build_outlined), findsOneWidget);
  });

  testWidgets('calls onEditItem when edit tapped', (tester) async {
    bool called = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BarcodeResultSheet(
          barcode: _barcode(),
          existingItem: _item(),
          onScanAgain: () {},
          onViewItem: () {},
          onEditItem: () => called = true,
          onMoveItem: () {},
          onLogMaintenance: () {},
        ),
      ),
    ));
    await tester.tap(find.byIcon(Icons.edit_outlined));
    expect(called, isTrue);
  });
}
```

**Step 2: Run to confirm failure**

```bash
flutter test test/widget/features/scanning/barcode_result_sheet_test.dart
```
Expected: FAIL — `onEditItem`, `onMoveItem`, `onLogMaintenance` params missing.

**Step 3: Update `BarcodeResultSheet`**

Add three new optional params:
```dart
class BarcodeResultSheet extends StatelessWidget {
  // ... existing params ...
  final VoidCallback? onEditItem;
  final VoidCallback? onMoveItem;
  final VoidCallback? onLogMaintenance;

  const BarcodeResultSheet({
    // ... existing ...
    this.onEditItem,
    this.onMoveItem,
    this.onLogMaintenance,
  });
```

Replace the existing `if (existingItem != null) FilledButton.icon(...)` block with:

```dart
if (existingItem != null) ...[
  FilledButton.icon(
    onPressed: onViewItem,
    icon: const Icon(Icons.open_in_new),
    label: const Text('View Item'),
  ),
  const SizedBox(height: 8),
  Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      _ActionButton(
        icon: Icons.edit_outlined,
        label: 'Edit',
        onTap: onEditItem,
      ),
      _ActionButton(
        icon: Icons.drive_file_move_outlined,
        label: 'Move',
        onTap: onMoveItem,
      ),
      _ActionButton(
        icon: Icons.build_outlined,
        label: 'Maintenance',
        onTap: onLogMaintenance,
      ),
    ],
  ),
] else
  FilledButton.icon(
    onPressed: onAddToInventory,
    icon: const Icon(Icons.add),
    label: const Text('Add to Inventory'),
  ),
```

Add a private `_ActionButton` widget at the bottom of the file:
```dart
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionButton({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}
```

Update the `_showResultSheet()` call site in `_BarcodeScannerScreenState` to pass the three new callbacks:
```dart
BarcodeResultSheet(
  barcode: barcode,
  existingItem: found,
  onScanAgain: ...,
  onAddToInventory: ...,
  onViewItem: ...,
  onEditItem: found != null
    ? () {
        Navigator.of(ctx).pop();
        context.pushNamed('editItem', pathParameters: {'itemId': found.id});
      }
    : null,
  onMoveItem: found != null
    ? () {
        Navigator.of(ctx).pop();
        _showMoveItemSheet(context, ref, found.id);
      }
    : null,
  onLogMaintenance: found != null
    ? () {
        Navigator.of(ctx).pop();
        context.pushNamed('addMaintenance',
            queryParameters: {'itemId': found.id});
      }
    : null,
)
```

For `_showMoveItemSheet`: implement a simple `showModalBottomSheet` that lists rooms/containers and calls `itemRepository.updateItem(item.copyWith(roomId: selected))`. Keep it minimal — just a list of room names, no container picker in Phase 15.

**Step 4: Run tests**

```bash
flutter test test/widget/features/scanning/barcode_result_sheet_test.dart
flutter test
```
Expected: all passing.

**Step 5: Commit**

```bash
git add lib/features/scanning/presentation/screens/barcode_scanner_screen.dart \
        test/widget/features/scanning/barcode_result_sheet_test.dart
git commit -m "feat: BarcodeResultSheet — action row (Edit/Move/Log) for existing items"
```

---

## Task 8: `VoiceInputService` + `speech_to_text` dependency

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/services/voice/voice_input_service.dart`
- Modify: `android/app/src/main/AndroidManifest.xml`

**Step 1: Add `speech_to_text` to pubspec.yaml**

In `pubspec.yaml` under `dependencies:`, add:
```yaml
  speech_to_text: ^7.0.0
```

Run:
```bash
flutter pub get
```

**Step 2: Add microphone permission to Android manifest**

In `android/app/src/main/AndroidManifest.xml`, before `<application`:
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
```

**Step 3: Implement `VoiceInputService`**

```dart
// lib/services/voice/voice_input_service.dart
import 'package:speech_to_text/speech_to_text.dart';

/// Wrapper around speech_to_text for on-device STT.
/// Returns the final transcript, or null if unavailable / cancelled.
class VoiceInputService {
  final SpeechToText _stt = SpeechToText();
  bool _initialized = false;

  /// Initialize the speech recognizer. Must be called before [listen].
  Future<bool> initialize() async {
    if (_initialized) return true;
    _initialized = await _stt.initialize(onError: (_) {});
    return _initialized;
  }

  /// Start listening and return the final transcript when the user stops.
  /// Returns null if not initialized or if the user cancels.
  Future<String?> listen({
    void Function(String partial)? onPartial,
  }) async {
    if (!await initialize()) return null;

    String? finalResult;
    await _stt.listen(
      onResult: (r) {
        if (r.finalResult) {
          finalResult = r.recognizedWords;
        } else {
          onPartial?.call(r.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_US',
    );

    // Wait for final result (listen() returns after pause timeout)
    await Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 100));
      return _stt.isListening;
    });

    await _stt.stop();
    return finalResult;
  }

  bool get isListening => _stt.isListening;

  Future<void> stop() => _stt.stop();
}
```

**Step 4: Add `voiceInputServiceProvider` to `repository_providers.dart`**

```dart
import '../../services/voice/voice_input_service.dart';

// At bottom of repository_providers.dart:
final voiceInputServiceProvider = Provider<VoiceInputService>((ref) {
  return VoiceInputService();
});
```

**Step 5: Run analyze**

```bash
flutter analyze
```
Fix any issues.

**Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock \
        lib/services/voice/voice_input_service.dart \
        lib/core/providers/repository_providers.dart \
        android/app/src/main/AndroidManifest.xml
git commit -m "feat: VoiceInputService + speech_to_text dep + mic permission"
```

---

## Task 9: Wire voice add into `SpeedDialFab`

**Files:**
- The `onVoice` callbacks in inventory/room/container screens

Add `_onVoiceAdd` helper alongside `_onPhotoAdd`:

```dart
Future<void> _onVoiceAdd(BuildContext context, WidgetRef ref, {
  String? roomId,
  String? containerId,
}) async {
  final voiceService = ref.read(voiceInputServiceProvider);
  final ok = await voiceService.initialize();
  if (!ok) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Microphone permission required for voice add.')),
    );
    return;
  }

  // Navigate to item edit screen immediately with a listening indicator
  // We pass a null suggestion + showAiBanner=false + showVoiceBanner=true
  // The voice result comes back via a Completer<ItemSuggestion?>.
  // Simpler: collect transcript first (up to 30s), then navigate.
  if (!context.mounted) return;
  final transcript = await _collectVoiceWithDialog(context, voiceService);
  if (transcript == null || !context.mounted) return;

  final service = ref.read(itemPhotoAnalysisServiceProvider);
  final suggestion = await service.analyzeVoice(transcript);
  if (!context.mounted) return;

  context.pushNamed('addItem', queryParameters: {
    if (roomId != null) 'roomId': roomId!,
    if (containerId != null) 'containerId': containerId!,
  }, extra: suggestion);
}

Future<String?> _collectVoiceWithDialog(
  BuildContext context,
  VoiceInputService service,
) async {
  String partial = '';
  String? result;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSt) => AlertDialog(
        title: const Text('Listening...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(partial.isEmpty ? 'Speak now' : partial),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await service.stop();
              Navigator.of(ctx).pop();
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    ),
  );

  // Actually start listening (dialog is just UI feedback; real listen runs concurrently)
  // Better approach: use a Completer
  final completer = Completer<String?>();
  service.listen(
    onPartial: (p) => partial = p,
  ).then((r) {
    result = r;
    completer.complete(r);
  });
  await completer.future;
  return result;
}
```

Note: The exact approach to showing a "listening" dialog while also collecting the transcript may need refinement. The plan above shows the intent — adjust the async sequencing as needed during implementation.

**Step 1: Wire `onVoice` in each screen** (same screens as Task 6).

**Step 2: Run analyze + tests**

```bash
flutter analyze
flutter test
```

**Step 3: Commit**

```bash
git add lib/features/inventory/presentation/screens/inventory_screen.dart \
        lib/features/locations/presentation/screens/room_detail_screen.dart \
        lib/features/locations/presentation/screens/container_detail_screen.dart
git commit -m "feat: voice add — STT transcript → LLM extraction → pre-filled form"
```

---

## Task 10: Final integration pass

**Step 1: Run full test suite**

```bash
flutter test
```
Expected: 367+ passing (8 new tests: 4 service unit, 4 widget). Fix any failures before continuing.

**Step 2: Run analyzer**

```bash
flutter analyze
```
Expected: 0 issues.

**Step 3: Build debug APK**

```bash
flutter build apk --debug
```
Expected: clean build. If `speech_to_text` has a Kotlin/Gradle version conflict, check the package's README for the required compileSdkVersion and update `android/app/build.gradle.kts` accordingly.

**Step 4: Manual smoke test checklist**

- [ ] Inventory screen FAB → opens speed dial with 3 options
- [ ] "Take photo" → camera opens → photo taken → form opens with fields pre-filled (if LLM configured)
- [ ] "Take photo" with no LLM configured → form opens with photo attached + AI banner
- [ ] "Enter manually" → existing empty form behaviour unchanged
- [ ] "Describe it" → microphone dialog → says item name → form pre-filled
- [ ] Barcode scan → item not in inventory → "Add to Inventory" is prominent FilledButton
- [ ] Barcode scan → item already in inventory → Edit / Move / Maintenance action row visible
- [ ] Room detail and Container detail FABs also show speed dial

**Step 5: Final commit**

```bash
git add .
git commit -m "Phase 15 Fast Add: SpeedDialFab, photo-first, voice add, quick actions after scan"
```

---

## Reference: all new/modified files

| File | Status |
|------|--------|
| `lib/features/inventory/domain/entities/item_suggestion.dart` | NEW |
| `lib/features/inventory/data/services/item_photo_analysis_service.dart` | NEW |
| `lib/features/inventory/presentation/widgets/speed_dial_fab.dart` | NEW |
| `lib/services/voice/voice_input_service.dart` | NEW |
| `lib/features/inventory/presentation/screens/item_edit_screen.dart` | MODIFIED |
| `lib/features/scanning/presentation/screens/barcode_scanner_screen.dart` | MODIFIED |
| `lib/features/inventory/presentation/screens/inventory_screen.dart` | MODIFIED |
| `lib/features/locations/presentation/screens/room_detail_screen.dart` | MODIFIED |
| `lib/features/locations/presentation/screens/container_detail_screen.dart` | MODIFIED |
| `lib/app/router.dart` | MODIFIED |
| `lib/core/providers/repository_providers.dart` | MODIFIED |
| `android/app/src/main/AndroidManifest.xml` | MODIFIED |
| `pubspec.yaml` | MODIFIED |
| `test/unit/features/inventory/services/item_photo_analysis_service_test.dart` | NEW |
| `test/widget/features/inventory/widgets/speed_dial_fab_test.dart` | NEW |
| `test/widget/features/inventory/screens/item_edit_suggestion_test.dart` | NEW |
| `test/widget/features/scanning/barcode_result_sheet_test.dart` | NEW |
