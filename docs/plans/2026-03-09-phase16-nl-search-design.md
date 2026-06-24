# Phase 16 — Natural Language Search + Smart Filters: Design Doc

**Date:** 2026-03-09
**Status:** Approved

---

## Goal

Let users search in plain English ("expensive stuff in the garage", "where is my camera") and get
precise, filtered results — without learning filter UI. All four ROADMAP items are in scope.

---

## Approach

**Shared NL parser service (Approach B).** A pure-Dart `NlQueryParser` class extracts structured
`ItemQuery` fields from free text. Both `SearchScreen` and `InventoryScreen` route through it. If
only a bare name is extracted, the existing FTS5 path (`searchItems()`) is used. If structured
fields are extracted, `watchItems(ItemQuery)` is used. LLM fallback fires only when the parser
extracts nothing useful from a non-trivial input, gated behind existing `llmTierEnabledProvider`.

---

## Architecture

### 1. `NlQueryParser`

**Location:** `lib/features/search/domain/services/nl_query_parser.dart`

Pure Dart class, no async, no external deps.

```dart
ParseResult parse(String input, {
  required List<Room> rooms,
  required List<Category> categories,
  required List<StorageContainer> containers,
})
```

**`ParseResult`:**
```dart
class ParseResult {
  final ItemQuery query;
  final bool hasStructuredFilters; // true if any field beyond searchText was set
  final String residualText;       // input with recognised tokens stripped
  final bool needsLlmFallback;     // !hasStructuredFilters && residualText.length > 3
}
```

**Extraction table (applied in order, case-insensitive):**

| Input pattern | Field set |
|---|---|
| Room name (fuzzy match) | `roomId` |
| Category name (fuzzy match) | `categoryId` |
| Container name (fuzzy match) | `containerId` |
| `over $X` / `more than $X` / `above $X` | `minValue` |
| `under $X` / `less than $X` / `below $X` | `maxValue` |
| `expensive` / `valuable` | `minValue = 500` |
| `cheap` / `inexpensive` | `maxValue = 100` |
| `recent` / `last month` / `this year` | `addedAfter` |
| `new` / `like new` (as condition, not article) | `condition = ItemCondition.newItem` |
| `with photo` / `has photo` | `hasPhoto = true` |
| `with receipt` / `has receipt` | `hasReceipt = true` |
| `with barcode` / `has barcode` | `hasBarcode = true` |
| `most valuable` / `by value` | `sortBy = currentValue, ascending = false` |
| `newest` / `recently added` | `sortBy = createdAt, ascending = false` |
| `where is` / `find my` / `where's` prefix | stripped; residual drives name search |

Fuzzy room/category/container matching: lowercase, strip common words ("the", "my"), then
`String.contains()` in both directions (input contains name, or name contains input token).

**`nlQueryParserProvider`** (`lib/features/search/presentation/controllers/search_controller.dart`):
A Riverpod `Provider` that watches `roomsProvider`, `categoriesStreamProvider`, and
`containersProvider`. Exposes a bound `ParseResult Function(String)` so callers pass only the
raw string.

**LLM fallback:** When `needsLlmFallback = true` and an LLM tier is configured, the caller
passes the query to `itemPhotoAnalysisService.analyzeVoice(input)` (reuses the existing voice
extraction path — it already returns an `ItemSuggestion` with name/category). This is optional
and gracefully degrades to plain FTS if no LLM is available.

---

### 2. SearchScreen Enhancements

**NL routing:**
`onChanged` runs input through `nlQueryParserProvider`. Routes to:
- `watchItems(ItemQuery)` if `hasStructuredFilters == true`
- `searchItems(residualText)` if only a bare name remains (existing FTS path)
- Empty state if both are empty

**"Where is my…" card:**
Displayed above the results list when the raw query matches the prefix pattern
(`where is` / `find my` / `where's`). Shows for each matched item:
```
📦  Sony A7 IV
    Living Room  ›  Camera Shelf
```
Tapping navigates to item detail. If multiple matches, all shown in the card before the full
list. No new DB queries — data comes from the same result stream.

**Saved searches chip row:**
Shown in the empty state (no query typed yet) as a horizontally scrollable `FilterChip` row.
- Tapping a chip fills the search bar and runs the query immediately.
- A bookmark `IconButton` appears in the app bar whenever the current query returns results.
- Tapping bookmark calls `SavedSearchService.save(label: query, query: query)`.
- Maximum 20 saved searches (LRU eviction — oldest dropped when over limit).

---

### 3. SavedSearchService

**Location:** `lib/features/search/data/services/saved_search_service.dart`

Stores a JSON-encoded `List<SavedSearch>` in `FlutterSecureStorage` under key `'saved_searches_v1'`.

```dart
class SavedSearch {
  final String label;  // display text (= raw query string)
  final String query;  // raw query string passed to NL parser
}
```

No new DB table — FlutterSecureStorage is sufficient for ≤20 short strings.

**API:** `load()`, `save(SavedSearch)`, `delete(String label)`, `clear()`.
Provider: `savedSearchServiceProvider` in `repository_providers.dart`.

---

### 4. ItemQuery Extensions

Three new optional fields added to `ItemQuery`:

```dart
final bool? hasPhoto;     // null = no filter, true = ≥1 photo record exists
final bool? hasReceipt;   // null = no filter, true = ≥1 receipt record exists
final bool? hasBarcode;   // null = no filter, true = barcode non-null and non-empty
```

`FilterResult` gains the same three fields plus the existing `addedAfter`/`addedBefore`
(date-range UI was missing; fields were already in `ItemQuery`).

---

### 5. ItemDao Additions

`watchAllItems()` gains three new WHERE clauses (applied only when the param is `true`):

- `hasPhoto`: `EXISTS (SELECT 1 FROM photos WHERE photos.item_id = items.id)`
- `hasReceipt`: `EXISTS (SELECT 1 FROM receipts WHERE receipts.item_id = items.id)`
- `hasBarcode`: `items.barcode IS NOT NULL AND items.barcode != ''`

Implemented as Drift `customExpression` subqueries.

---

### 6. FilterDialog Enhancements

Two new sections added below the existing price range slider:

**Presence filters** — `Wrap` of three `FilterChip`s:
`Has Photo` · `Has Receipt` · `Has Barcode`

**Date added range** — two `ListTile`s with calendar icon opening `showDatePicker()`:
`Added after: [pick date]` · `Added before: [pick date]`

These feed directly into `FilterResult` → `ItemQuery.addedAfter` / `addedBefore` (already
supported in the DAO — only the UI was missing).

---

## Data Flow

```
User types "expensive stuff in the garage"
  → nlQueryParserProvider.parse(input)
  → ParseResult {
      query: ItemQuery(roomId: 'garage-id', minValue: 500),
      hasStructuredFilters: true,
      residualText: "stuff",
    }
  → watchItems(ItemQuery(roomId: 'garage-id', minValue: 500, searchText: 'stuff'))
  → Stream<List<Item>> → ResultsList

User types "where is my sony camera"
  → ParseResult { residualText: "sony camera", hasStructuredFilters: false }
  → searchItems("sony camera") → Stream<List<Item>>
  → "where is my" card above results showing room + container
```

---

## Files Modified / Created

| File | Action |
|---|---|
| `lib/features/search/domain/services/nl_query_parser.dart` | NEW |
| `lib/features/search/data/services/saved_search_service.dart` | NEW |
| `lib/features/search/presentation/controllers/search_controller.dart` | NEW (nlQueryParserProvider, savedSearchesProvider) |
| `lib/features/search/presentation/screens/search_screen.dart` | MODIFY (NL routing, where-is card, saved chips) |
| `lib/features/inventory/domain/repositories/item_repository.dart` | MODIFY (3 new ItemQuery fields) |
| `lib/features/inventory/presentation/widgets/filter_dialog.dart` | MODIFY (presence chips, date pickers) |
| `lib/services/database/daos/item_dao.dart` | MODIFY (hasPhoto/hasReceipt/hasBarcode WHERE) |
| `lib/features/inventory/data/repositories/item_repository_impl.dart` | MODIFY (pass new fields through) |
| `lib/core/providers/repository_providers.dart` | MODIFY (savedSearchServiceProvider) |

---

## Testing

### Unit tests
- `test/unit/features/search/services/nl_query_parser_test.dart` (~15 cases)
  - price keywords, room matching, date keywords, presence flags
  - `"where is my"` prefix stripped
  - LLM fallback flag set when no structured result
  - empty input → empty `ItemQuery`
- `test/unit/features/search/services/saved_search_service_test.dart`
  - save/load/delete round-trips
  - cap at 20 (LRU eviction)

### Widget tests
- `test/widget/features/search/screens/search_screen_nl_test.dart`
  - NL query routes to `watchItems` when structured filters extracted
  - FTS path used when only bare text
  - "where is my" card appears for matching prefix
  - bookmark icon saves query; chip row shows saved queries; tapping chip fills bar
- `test/widget/features/inventory/widgets/filter_dialog_test.dart` (extend existing)
  - has-photo chip toggle sets `FilterResult.hasPhoto`
  - date pickers produce correct `addedAfter`/`addedBefore`

### DAO integration test
- `test/unit/services/database/daos/item_dao_presence_test.dart`
  - `hasPhoto: true` returns only items with photo records
  - `hasBarcode: true` excludes null/empty barcode items

---

## Out of Scope (Phase 16)

- Merging `searchItems()` into `watchItems()` (clean-up, Phase 16.5 if desired)
- NL search in `InventoryScreen` inline bar gets the parser silently but no saved-search UI
- Voice-driven search (user can already use voice add from Phase 15; NL search via mic is Phase 17+)
