# Phase 15 — Fast Add: Design

**Date:** 2026-03-07
**Status:** Approved
**Scope:** Three sub-features shipped as one atomic phase — photo-first flow, quick actions after scan, voice add

---

## Problem

Adding an item currently requires navigating to a form, typing every field, and optionally attaching a photo as an afterthought. The FAB on every screen leads to the same blank form. Users default to skipping photos and filling in minimal data, leading to an inventory with poor documentation over time.

**Goal:** Make the best-documented path the fastest path. Nudge users toward photos without removing the manual escape hatch.

---

## Non-Goals

- Loan tracking (Phase 17)
- Appraiser / market price estimation (Phase 23)
- Batch import via CSV/email (Phase 20)
- Quantity / consumables (Phase 18)

---

## Architecture

### New files

| File | Purpose |
|------|---------|
| `lib/features/inventory/data/services/item_photo_analysis_service.dart` | Wraps existing LLM tier chain; takes `XFile`, returns `ItemSuggestion` |
| `lib/features/inventory/presentation/widgets/speed_dial_fab.dart` | Replaces bare `FloatingActionButton` on item-bearing screens |
| `lib/services/voice/voice_input_service.dart` | On-device STT via `speech_to_text` package; returns transcript string |

### Modified files

| File | Change |
|------|--------|
| `lib/features/scanning/presentation/screens/barcode_result_sheet.dart` | Promote "Add to Inventory" to primary CTA; add contextual action row for existing items |
| `lib/features/inventory/presentation/screens/inventory_screen.dart` | Replace FAB with `SpeedDialFab` |
| `lib/features/locations/presentation/screens/room_detail_screen.dart` | Replace FAB with `SpeedDialFab` |
| `lib/features/locations/presentation/screens/container_detail_screen.dart` | Replace FAB with `SpeedDialFab` |
| `lib/features/inventory/presentation/screens/item_edit_screen.dart` | Accept `ItemSuggestion?` param; pre-fill fields; show AI banner if suggestion absent |

---

## Sub-feature 1: Speed Dial FAB

`SpeedDialFab` is a stateful widget wrapping Flutter's `FloatingActionButton` with an animated expansion overlay showing child options.

**Options (in order, top to bottom when expanded):**

| Icon | Label | Action |
|------|-------|--------|
| `camera_alt` | Take photo | Photo-first flow |
| `mic` | Describe it | Voice add flow |
| `edit` | Enter manually | Existing form, no changes |

Tapping the main FAB when collapsed opens the speed dial. Tapping outside collapses it. Each option passes the contextual `roomId` / `containerId` (from the enclosing screen) through to whichever flow it launches, exactly as the current bare FAB does.

The manual option is always visible — never hidden behind a second interaction.

---

## Sub-feature 2: Photo-First Flow

### Happy path

1. User taps camera option in speed dial
2. `image_picker` opens in camera mode (`ImageSource.camera`)
3. On photo captured → `ItemPhotoAnalysisService.analyze(XFile file, {String? roomContext})` called
4. Service sends image + prompt to the LLM provider chain (existing 4-tier: on-device → Ollama → cloud API → hosted)
5. LLM returns JSON: `{name, category, estimatedValue, notes}`
6. `ItemEditScreen` opened with pre-filled `ItemSuggestion` and photo pre-attached

### LLM prompt

```
You are a home inventory assistant. Look at this photo and return ONLY valid JSON with these fields:
{
  "name": "short descriptive item name",
  "category": "one of: Electronics, Furniture, Appliances, Clothing, Tools, Sports, Books, Kitchenware, Other",
  "estimatedValue": 0.00,
  "notes": "brief condition or identifying notes, or empty string"
}
Be concise. If unsure of value, use 0.
```

### Fallback (LLM not configured or call fails)

- Open `ItemEditScreen` with photo pre-attached, all fields empty
- Show a non-blocking `MaterialBanner` at top of form:
  *"Set up AI analysis for automatic suggestions"* with an "Set Up" action → navigates to `llmSettings` route
- Banner dismissed on tap or when user starts typing

### `ItemSuggestion` model

```dart
class ItemSuggestion {
  final String? name;
  final String? category;
  final double? estimatedValue;
  final String? notes;
  final XFile? photo; // pre-attached
}
```

---

## Sub-feature 3: Quick Actions after Scan

### New item (barcode not in inventory)

Current: "Add to Inventory" is a secondary `TextButton`.
New: "Add to Inventory" is the **primary `FilledButton`** — full width, at the bottom. Product info (name, brand, image from lookup cache) pre-fills `ItemEditScreen` as it does today, but the button is impossible to miss.

### Existing item (barcode already in inventory)

Current: single "View Item" button.
New: contextual action row below the item summary card:

| Action | Icon | Behaviour |
|--------|------|-----------|
| Edit | `edit_outlined` | `context.pushNamed('editItem', pathParameters: {'itemId': id})` |
| Move | `drive_file_move_outlined` | Bottom sheet with room/container picker |
| Log Maintenance | `build_outlined` | `context.pushNamed('addMaintenance', queryParameters: {'itemId': id})` |

"Lend" action reserved for Phase 17.

---

## Sub-feature 4: Voice Add

### Flow

1. User taps mic option in speed dial
2. `VoiceInputService.listen()` → starts `SpeechRecognizer` (on-device; `speech_to_text` package)
3. `ItemEditScreen` opens immediately with a listening banner at top — user sees the form being filled as they speak
4. On final transcript → sent to LLM with extraction prompt (same provider chain)
5. LLM returns same `ItemSuggestion` JSON as photo-first
6. Fields filled; listening banner dismissed

### LLM prompt (voice)

```
Extract item details from this spoken description and return ONLY valid JSON:
{
  "name": "item name",
  "category": "...",
  "estimatedValue": 0.00,
  "roomHint": "room name mentioned, or empty",
  "notes": "any other details mentioned"
}
Description: "{transcript}"
```

`roomHint` used to auto-select the room dropdown if it matches an existing room name (fuzzy match).

### Fallback

Same AI banner as photo-first. If `speech_to_text` permission denied, show a `SnackBar`: *"Microphone permission required for voice add."*

---

## Data Flow

```
SpeedDialFab
  ├─ camera → image_picker → ItemPhotoAnalysisService → ItemSuggestion → ItemEditScreen
  ├─ mic    → VoiceInputService → transcript → ItemPhotoAnalysisService → ItemSuggestion → ItemEditScreen
  └─ edit   → ItemEditScreen (no suggestion)

BarcodeResultSheet
  ├─ new item  → FilledButton "Add to Inventory" → ItemEditScreen (pre-filled from product cache)
  └─ existing  → action row (Edit / Move / Log Maintenance)
```

---

## Testing

| Test | Type | File |
|------|------|------|
| `ItemPhotoAnalysisService` returns suggestion on LLM success | unit | `test/unit/features/inventory/services/item_photo_analysis_service_test.dart` |
| `ItemPhotoAnalysisService` returns null suggestion on LLM failure | unit | same |
| `SpeedDialFab` shows three options when expanded | widget | `test/widget/features/inventory/widgets/speed_dial_fab_test.dart` |
| `BarcodeResultSheet` shows FilledButton for new item | widget | `test/widget/features/scanning/barcode_result_sheet_test.dart` |
| `BarcodeResultSheet` shows action row for existing item | widget | same |
| `ItemEditScreen` pre-fills fields from `ItemSuggestion` | widget | `test/widget/features/inventory/screens/item_edit_screen_test.dart` |
| `ItemEditScreen` shows AI banner when suggestion is null | widget | same |

---

## Open Questions / Deferred

- `speech_to_text` package version compatibility with current Flutter SDK — check before implementation
- On-device LLM tier response quality for the photo prompt — may need prompt tuning after first test
- Move action in `BarcodeResultSheet` shares UI with future bulk-move (Phase 18) — keep it simple for now (full bottom sheet, no optimisation)
