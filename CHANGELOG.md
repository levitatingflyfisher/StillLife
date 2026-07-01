# Changelog

All notable changes to Still Life are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

---

## [Unreleased]

### Money correctness
- **Money is now stored as integer cents (schema v15).** Every monetary
  column moves from floating-point dollars to exact integer cents via a
  guarded, re-entry-safe table rebuild; all totals and sums are exact
  arithmetic. Nothing changes on any wire: backups, CSV exports, and LAN
  sync still speak decimal dollars, so old backups restore, new backups
  restore on the old app, and cross-version sync stays correct
- **Policy and maintenance costs now obey the rounding law.** Both forms
  parsed raw text into unrounded floats; they now use the same
  locale-tolerant parser as item prices, straight to whole cents
- **Sync now refuses a payload from a newer app version.** The changeset
  carries a payload schema version (older peers' changesets remain
  accepted); a future semantic change fails closed with an actionable
  message instead of silently corrupting an older install

### Backup & restore integrity
- **The pre-restore safety snapshot now always opens with this device's
  own recovery words.** Restoring a backup made with a different set of
  words used to seal the safety snapshot under the incoming backup's key —
  so the promised rollback could not be opened with the device's
  credentials. The snapshot (and its read-back verification) is now sealed
  under the device's stored key whenever one exists; only a keyless fresh
  install seals under the typed phrase, which that same restore then
  adopts as the device identity — either way the rollback is openable by
  the post-restore device identity
- **Fresh-install photo restores now adopt the typed recovery words as the
  device identity.** Restoring a photos-included backup on a keyless
  device derived a key from the typed phrase but never stored the phrase —
  the device stayed keyless, so the safety snapshot the restore just
  vaulted (and every future backup step) was unreachable. Typing the words
  to restore is proof of possession: the phrase is now written to the
  keystore (never overwriting an existing identity) and acknowledged,
  matching the metadata restore flow
- **"Verified by read-back" now authenticates every entry of the safety
  snapshot.** Verification used to length-compare the stored snapshot and
  decrypt only its metadata entry; a photo or receipt entry corrupted in
  storage still passed, certifying a rollback that could never restore its
  images. Every entry's encryption tag is now decrypt-authenticated (one
  at a time, nothing buffered) before the restore is allowed to proceed
- **A damaged backup no longer blames your recovery words.** When the
  words already opened the backup's records but a photo entry inside it
  failed to decrypt, the flow showed "made with a different set of words"
  — sending the user hunting for a phrase that cannot exist. That case is
  now reported honestly: "This backup file is damaged and could not be
  restored. Nothing on this device was changed."
- **Restoring a photo snapshot asks once, honestly.** The snapshot list's
  confirm dialog claimed the restore "rolls back" (it is an upsert-merge:
  items added since the snapshot survive) and was then followed by a
  second, contradicting confirm from the file-restore flow. The copy now
  says what a merge does, and one action gets exactly one dialog
- **The restore confirm no longer promises a photos-included snapshot it
  cannot take.** Restoring a records-only .ohbk file through "Restore
  with photos" showed the same "photos included" snapshot promise as a
  full .ohbkz — but a bare-records restore gets a records-only snapshot.
  The dialog now sniffs the file first and describes the snapshot that
  will actually be taken

### Fleet standardization
- **Fleet conformance suite adopted.** `test/fleet_conformance_test.dart`
  runs the shared `oh_fleet_conformance` checks (canonical design package,
  backup adoption, size budgets, exact Android permission surface, harness
  canon) with StillLife's posture recorded in one place: merge-semantics
  restore, tighter analysis options, and the longer design-package hop
- **Size budgets recorded.** `budgets.json` pins the web JS payload
  (gzipped `main.dart.js`) and arm64 APK at measured baseline +5%, so size
  regressions fail CI instead of accumulating silently
- **CI clones the conformance package** alongside the other sibling path
  dependencies in every Flutter job

### Money correctness
- **A bad price can no longer slip past Save by being scrolled
  off-screen.** The edit form is a lazy list, so an unfocused money field
  scrolled out of view was unmounted and its validator silently dropped
  out of the Form — Save then passed and stored the item with no price.
  Save now checks the three money fields' text directly regardless of
  what is on screen, shows which field was rejected, and scrolls the
  Valuation section back into view with the inline error visible
- **Ambiguous "1,234"-style amounts are refused instead of silently
  misread 1000x.** A single separator followed by exactly three digits
  ("1,234" / "1.234") is one thousand to a US user and one-point-something
  to a comma-decimal user; the old parser silently picked the decimal
  reading, so a $1,234 purchase price saved as $1.23. The field now shows
  "Ambiguous amount — use 1234 or 1,234.00" and blocks the save — a
  deterministic, locale-independent refusal to guess. Unambiguous forms
  ("12,50", "1,234.56", "1.234,56", "1,234,567") keep working
- **The rounding law: money rounds to whole cents at every write
  boundary.** One shared `roundToCents` (decimal half-up: 1.005 → 1.01,
  0.1+0.2 → 0.30) now guards every money write — item edit save, LLM
  suggestion batch, appraisal save, and appraisal apply-to-item — so no
  fractional cent or floating-point artifact ever lands in the database.
  Display math is unchanged
- **Comma-decimal prices no longer vanish on save.** The item form and the
  price filter now parse money through a locale-tolerant parser: "12,50"
  means 12.50, "1.234,56" and "1,234.56" both mean 1234.56, currency
  symbols and grouping spaces are ignored. Input the parser cannot read
  shows "Enter a valid amount" on the field and blocks the save/apply —
  before, `double.tryParse` quietly turned any such price into "no price"
- **AI appraisals can no longer fabricate a $0.00 value.** An LLM reply
  that omits or garbles the `value`, `currency`, or `confidence` field now
  fails validation ("Could not parse appraiser response") instead of being
  coerced to `0.0`/`USD` and persisted as a real appraisal the model never
  made. An explicit `{"value": 0, "confidence": 0.0}` reply — the prompt's
  honest "cannot find comparable listings" contract — still saves

### Backup retention — sanctuary_backup_ui 0.2.0 adoption
- **Photo restores are no longer a one-way door.** Before any `.ohbkz`
  (photos-included) restore, Still Life now takes a mandatory photo-ful
  snapshot of the current data into a dedicated photo vault (keep-2,
  auto-pinned, verified by read-back) — and refuses to restore if the
  snapshot can't be saved, with an honest "nothing was changed" dialog.
  Bare `.ohbk` restores through the same tile get a metadata snapshot into
  the main vault. The restore dialog's "This cannot be undone." is gone
  because it stopped being true
- **New "Previous photo backups" list** in Settings: restore or delete photo
  snapshots; restoring one routes through the same guarded flow and takes
  its own counter-snapshot first
- **Merge-honest restore confirmation** for encrypted `.ohbk` restores:
  "Merge backup into this device?" / "Merge backup" instead of the package's
  destructive-replace defaults ("Replace all data?") that contradicted
  Still Life's upsert-merge restore
- **Preview-before-restore** now reflects Still Life's real validation:
  the serializer implements the app-level dry-run parse (shared gate with
  restore, so preview and restore can never drift) and the backup envelope
  additively gains `createdAt` (UTC) + integer `schemaVersion` — all legacy
  keys kept, so old backups still restore and new backups restore on old
  installs (tested both ways)
- **Silent freshness snapshot on app open** when the newest vault snapshot
  is over 7 days old — no nag, no badge, it just happens

### On-Device Tier — rungs 1, 1.5, 2 (Android)
- **The empty Tier-1 seam is now a three-engine cascade** — best available
  engine wins per photo: Gemini Nano > downloaded SmolVLM2 > bundled labeler.
  Single-photo analysis only; image-only capabilities keep text and multi-item
  calls routed to other tiers
- **Rung 1: bundled ML Kit labeler** — ~400 coarse labels, zero download,
  works offline from first launch; honest results (top label + category +
  confidence, brand/model never guessed) with all labels kept for enrich-later
- **Rung 1.5: SmolVLM2 over llama.cpp** — opt-in download of first-party
  Apache-2.0 GGUFs (2.2B recommended ≈ 1.7 GB, 500M lite ≈ 546 MB) with
  commit-pinned URLs and fail-closed sha256 verification; runs the same JSON
  prompt as the cloud tiers, fully offline; photos downscaled to 768px before
  inference
- **Rung 2: Gemini Nano via AICore** — free on-device inference on supported
  flagships; provisioning is an explicit settings action, never a side effect
- **Settings: live On-Device section** — engine states, informed-consent model
  downloads with progress/cancel/delete, Nano Set-up
- **Default tier priority is now quality-first** (local → cloud → hosted →
  on-device): the always-available floor never silently replaces a tier you
  configured; drag on-device to the top for privacy-first. Persisted orders
  unchanged
- **Shared single-item prompt/parser** extracted (`single_item_parser.dart`) —
  the byte-identical per-provider prompt copies are gone
- *Not yet device-verified*: native labeler/Nano/llama.cpp paths need a real
  Android build + phone; multi-item stays networked-tier-only

### Intelligence Campaign — AI cataloguing made real (schema v13–v14)
- **Honest tiers** — on-device tier reports itself unavailable instead of fabricating results; dead TFLite path and `tflite_flutter` dependency removed (no model ever shipped); hosted tier and Pro checkout fail closed on empty build-time URLs; local Ollama tier is an explicit opt-in, never a probed default
- **Cloud tier revived** — stored keys actually reach the provider; speaks Anthropic or any OpenAI-compatible endpoint (keyless self-hosted servers work); both Test Connection buttons really test the connection
- **Photo & voice add** — captured photo attaches to the created item; voice transcript rides a text-only LLM path (no more prompt-smuggling hack); typed "no AI configured" outcome with an honest snackbar and no dropped data
- **Shelf photos** — one photo → many items via `analyzeImageMulti` on every tier; review screen with per-item accept/edit and batch room/container assignment
- **Receipts** — three near-duplicate parsers consolidated into one; OCR text (never the image) LLM-structured into line items with brand/model, deterministic fallback on any failure; receipts persisted as rows with items linking back (schema v14); receipt camera in the import flow; item detail shows its source receipt
- **Brand / model / ASIN** — new Items columns (schema v13) carried through AI suggestions, imports, barcode lookup, backup, and CSV export
- **Amazon import** — current Privacy Central `Retail.OrderHistory` exports parse (the legacy order report died in 2023); help dialog explains how to request the file
- **Appraiser** — estimates write back via an explicit "Apply to item" (price history records `llm_estimate` provenance); the Anthropic model is a setting; prompt-injection hardening and a URL scheme allowlist on cited sources
- **Video walkthrough (Android)** — record/import → on-device ffmpeg frame extraction → blur/duplicate quality gate (top-12 default) → per-frame VLM on the configured tier → cross-frame merge → review → batch save with each item's source frame as its photo; call-count cost disclosure before the calls run; honest no-AI, failure, and cancellation states
- **Removed** — YOLO/MobileNet scaffolding, the `store_integration` feature, the orphaned receipt demo screen

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
