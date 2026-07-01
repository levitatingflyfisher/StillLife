# Reference: data model

The on-device schema, precisely. Source of truth: `lib/services/database/tables.dart`
and `lib/services/database/database.dart` (`schemaVersion => 11`). This is a lookup
reference; for the *ideas*, read [concepts.md](../concepts.md).

## Tables (17)

Declared on `AppDatabase` (`@DriftDatabase`), accessed through 13 DAOs.

| Table | Holds | Key relationships |
|---|---|---|
| `Properties` | A home | root of the place hierarchy |
| `Rooms` | A room in a property | → `Properties`; self-nesting via `parentId` |
| `StorageContainers` | A shelf/box/drawer in a room | → `Rooms` |
| `Categories` | Item category (a tree) | self-nesting via `parentId` |
| `Tags` | Flat labels | many-to-many with items via `ItemTags` |
| `Items` | A single possession | → `Categories`, `Rooms`, optional `StorageContainers`, optional creator/owner `Profiles` |
| `ItemTags` | Item↔tag join | composite PK (`itemId`,`tagId`) |
| `Photos` | Item image (file path + metadata) | → `Items`; one `isPrimary` |
| `Receipts` | Receipt image + OCR (store/date/total) | → `Items` (optional) |
| `PriceHistoryEntries` | Value over time | → `Items` |
| `Policies` | Insurance policy | → `Properties` |
| `MaintenanceLogs` | Service record / warranty task | → `Items` or `Properties` |
| `Loans` | Item lent out (borrower, due date) | → `Items` |
| `Profiles` | A household member | referenced by `Items` (creator/owner) |
| `Appraisals` | LLM valuation (mode, value, sources, TTL) | → `Items` |
| `VideoAnalyses` | AI video-walkthrough results | → `Items` |
| `ProductLookupCache` | Cached barcode → product | local cache only (not synced) |

## The place hierarchy

```
Properties ──1:N── Rooms ──1:N── StorageContainers
                     │                   │
                     └────────1:N────────┴──1:N── Items ──1:N── Photos
                                                    │           Receipts
                                                    │           PriceHistoryEntries
                                                    │           Loans / Appraisals / VideoAnalyses
                                                    └── N:M (ItemTags) ── Tags
Properties ──1:N── Policies          Categories ──1:N── Items
```

## The CRDT stamp columns

Every **syncable** table carries three extra columns, defaulted so pre-sync rows are
valid:

| Column | Type | Meaning |
|---|---|---|
| `nodeId` | `text` default `''` | device that last wrote the row |
| `hlc` | `text` default `''` | Hybrid Logical Clock timestamp (sorts lexicographically) |
| `isDeleted` | `bool` default `false` | soft-delete tombstone; all reads filter it out |

These drive last-writer-wins sync ([yellow paper](../spec/yellow-paper.md)). Twelve core
tables participate in HLC-LWW conflict *filtering* during a merge (properties, rooms,
storage containers, categories, tags, items, photos, receipts, price history, policies,
maintenance logs, loans). `ItemTags` (composite key) is intentionally excluded and
upserted idempotently. `VideoAnalyses` and `ProductLookupCache` are not synced; a couple
of later tables (`Profiles`, `Appraisals`) carry the stamp and export/import but
currently fall *outside* the LWW filter — see the yellow paper's honesty note.

## Identity & value fields worth knowing

- **IDs are string UUIDs** (`uuid` v4), assigned client-side — which is what lets two
  offline devices create rows that never collide, and what the `adjective-adjective-noun`
  QR label ID is derived from (`lib/core/utils/label_id.dart`).
- **`Items`** carries three money fields — `purchasePrice`, `currentValue`,
  `replacementCost` — plus `quantity` / `quantityUnit` / `lowStockThreshold` for
  consumables, and `warrantyExpiration`, `serialNumber`, `barcode`, `condition`,
  `isInsured`.
- **Timestamps:** most tables carry `createdAt` / `modifiedAt` (wall clock, for display
  and sorting). Note conflict resolution uses **`hlc`**, not `modifiedAt`.

## Full-text search

`items_fts` is an SQLite **FTS5** virtual table over `name`, `description`, `notes`,
`serial_number`, `barcode`, created in the `onCreate` migration and kept current by
`AFTER INSERT/UPDATE/DELETE` triggers on `items`.

## Migrations

`schemaVersion` is **11**; the `onUpgrade` ladder in `database.dart` is explicit and
testable. Notable steps: v4 added the `isDeleted` tombstone to every table and
`nodeId`/`hlc` to maintenance logs; v6 added storage containers; v7 loans; v8 quantity
fields; v9 profiles; v10 appraisals; v11 backfilled nullable `nodeId`/`hlc` on
appraisals. **A new syncable table must add the three stamp columns and a migration
step**, and be wired into the import round-trip.
