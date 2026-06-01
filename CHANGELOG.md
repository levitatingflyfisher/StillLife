# Changelog

All notable changes to Still Life are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

---

## [Unreleased]

### Phase 13 — CSV Export
- Export full inventory as a spreadsheet-ready CSV (Settings → Data Management → Export as CSV)
- All fields: name, category, room, container, condition, purchase/current/replacement value, dates, serial, barcode, label ID, notes, insured flag, tags
- RFC 4180 quoting — safe for Excel, Google Sheets, LibreOffice Calc

### Phase 12 — Onboarding
- First-launch welcome screen with two-step walkthrough (Welcome → Features)
- Onboarding completion flag persisted in FlutterSecureStorage
- Subsequent launches skip directly to Dashboard

### Red Team Fixes
- LAN sync authenticated with shared-secret Bearer token (FlutterSecureStorage UUID)
- `isDeleted` soft-delete filter wired into all 9 DAOs (was set but never queried)
- `ItemDao.deleteItem` changed from hard-delete to soft-delete (CRDT tombstones)
- Photo files cleaned up on item deletion via `PhotoStorageService`
- HLC now persisted after every `mergeHlc()` so clock never regresses on restart
- `LanSyncServer`/`LanDiscovery` lifecycle moved to `SyncScreen.initState/dispose`
- JSON export now includes `storageContainers` and `containerId`; import round-trips all tables including receipts and price history
- `LanDiscovery._discovery` field fixed (was shadowed by local variable)
- INTERNET permission added to main `AndroidManifest.xml`; app label fixed to "Still Life"
- Item label screen crash guards on null render objects
- Inventory bulk-move snackbar fixed (`count` captured before set is cleared)
- `flutter_local_notifications` core library desugaring enabled in Gradle

---

## [1.0.0] — 2025

### Phase 11 — QR Labels, Bulk Operations, Value History, Dashboard Upgrades
- **QR labels** — `ItemLabelScreen` generates a printable/shareable PNG label with QR code and human-readable label ID; accessible from item detail screen
- **Human-readable label IDs** — adjective-adjective-noun format (e.g. `oaken-low-rafter`), 1 M unique combinations, derived deterministically from the item UUID
- **Bulk operations** — long-press to enter selection mode in Inventory; select multiple items to move to another room or delete in bulk
- **Value history chart** — `PriceHistoryChart` (fl_chart sparkline) on Item Detail; price entries recorded automatically on create/update
- **Dashboard: Recent Activity** — last 5 modified items widget
- **Dashboard: Items by Month** — 6-month bar chart of items added

### Phase 10 — Global Search, Container Hierarchy, WebDAV Backup
- **Global search** — `SearchScreen` with FTS5 across name, description, notes, serial, barcode; accessible from Dashboard
- **Storage containers** — schema v6: `StorageContainers` table, `containerId` on Items; container chips on Room Detail; container dropdown on Item Edit
- **WebDAV backup** — `WebDavBackupService` with PUT/GET; `WebDavSettingsScreen` for server URL, username, password (FlutterSecureStorage)

### Phase 9 — Notifications, Smart Barcode Flow
- Local notification scheduling for warranty expiry and maintenance due dates
- `BarcodeResultSheet` checks inventory for existing barcode — shows "View Item" if found, "Add to Inventory" if new
- Notification permission requested on launch

### Phase 8 — Privacy-Respecting Barcode Lookup
- Schema v5: `ProductLookupCache` table
- Cache-first lookup; network calls require explicit user opt-in (Settings toggle)
- UPCitemdb fallback when network is enabled; results auto-fill Item Edit form

### Phase 7 — LAN Peer-to-Peer Sync
- Schema v4: `nodeId`, `hlc`, `isDeleted` on all 12 tables
- `CrdtManager` — Hybrid Logical Clock generation and merge
- `MergeEngine` — Last-Write-Wins conflict resolution
- `LanSyncServer` — shelf HTTP server for sync endpoints
- `LanSyncClient` — Dio-based sync client
- `LanDiscovery` — mDNS advertising and discovery via nsd package
- `SyncScreen` — peer list, one-tap sync, manual IP entry

### Phase 6 — Maintenance Tracking
- Schema v3: `MaintenanceLogs` table
- Maintenance log entry with cost, service provider, next due date
- `WarrantyExpiryWidget` — flags items with warranty expiring within 180 days
- `UpcomingMaintenanceWidget` — tasks due within 30 days on Dashboard

### Phase 5 — Insurance Policies
- `PolicyRepository`, `PolicyController`, `PolicyScreen`, `PolicyAddEditScreen`
- Reactive FTS5 search across policies

### Phase 4 — Financial Dashboard, PDF Export
- Dashboard with total household value, depreciation by room and category
- Insurance policy schema (v2)
- PDF inventory report via `pdf` + `printing` packages

### Phase 3 — Store Integration, Barcode & Receipt Scanning
- Barcode scanning via `mobile_scanner`
- Receipt photo capture and OCR via `google_mlkit_text_recognition`
- Amazon / UPC store integration stubs

### Phase 2 — AI Video Analysis
- Video capture pipeline with frame extraction
- 4-tier LLM providers: on-device TFLite, local Ollama, cloud API, hosted
- AI Settings UI

### Phase 1.5 — UX Foundations
- Auto-seeding default categories, property, and rooms on first launch
- Inline category/tag/photo management from Item Edit
- JSON export and import

### Phase 1 — Foundation
- Clean Architecture scaffold (domain/data/presentation)
- Drift ORM, Riverpod state management, GoRouter navigation
- Item CRUD with photos, receipts, serial numbers, purchase details
- Organize by property, room, category, tags
- Financial value tracking per item
