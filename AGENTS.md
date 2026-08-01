# AGENTS.md

Guidance for AI coding agents (and humans) working in this repo. This is the
top-level map; dense subsystems may carry their own notes — the closest guidance to
the file you're editing wins.

**Read these three, in order, before non-trivial work:**
1. [VISION.md](VISION.md) — what must stay true and why (the invariants).
2. [docs/architecture/OVERVIEW.md](docs/architecture/OVERVIEW.md) — how it fits together, with diagrams.
3. [docs/adr/](docs/adr/) — why each load-bearing decision was made.

## Take the code as current-state, not gospel

Every line of source and every comment here was written by an AI assistant. Treat it
as **an accurate record of what currently exists, offered with gratitude and a grain
of salt** — not as a specification and not as guaranteed-correct. A comment claiming
an invariant is a *hypothesis to verify*, not a proof. If a comment and the tests
disagree, the tests win; if the tests and reality disagree, reality wins. When you
rely on a claim, confirm it (read the code, run the test) first. (Concrete example: a
class comment in `hosted_messages_client.dart` still says "Stub client" even though
its request paths are fully implemented — while the on-device ML provider, which
*sounds* real, honestly reports itself unavailable because no model ships. Read
before believing.)

## What this is

A **local-first home-inventory app** (Flutter). Catalogue belongings room-by-item,
record value and condition, photograph items and receipts, and produce an insurance
report — entirely on-device, with no account. Optional, off-by-default edges add LAN
sync, WebDAV backup, and tiered AI cataloguing. Clean Architecture (domain / data /
presentation), Riverpod for state, Drift for storage. Schema v14, 17 tables, ~162 test
files.

## Non-negotiables (breaking one is a regression, not a feature)

- **No account, no mandatory cloud.** Core features must work fully offline with zero
  server contact. Never add a sign-up gate, a required login, or a hard dependency on
  a remote service to any core path.
- **Every egress stays opt-in and named.** Any code that sends data off the device
  (AI tiers, product lookup, WebDAV, LAN sync, hosted proxy) must be behind an explicit
  user setting that is **off by default**, and must be reflected in
  [docs/privacy-model.md](docs/privacy-model.md). Adding a new network call means
  updating that doc in the same change.
- **One stamp, one position.** Every HLC `CrdtManager` hands out is a position in
  a total order, and last-writer-wins has no way to choose between two rows that
  share one. Its clock mutations are serialized and its identity mint is memoized
  as a FUTURE, not a value — read-await-write across three steps is exactly how
  twenty concurrent stamps once came back identical, and how eight callers once
  minted three node identities. If you touch that class, the concurrency group in
  `test/unit/services/sync/crdt_manager_test.dart` is the contract, and a test
  that calls one method at a time cannot see the bug.
- **No telemetry, no analytics, no crash-reporter SDKs.** The dependency set is clean
  of them by design (verified by grep). Don't add Firebase/Sentry/analytics/etc.
- **Don't let user data get bricked or wiped.** The database is the family's memory.
  Preserve the boot-resilience retry ([ADR-0005](docs/adr/0005-boot-resilience.md))
  and the import path-sandbox guard
  ([ADR-0006](docs/adr/0006-import-db-safety.md)). A sync merge must stay
  fail-safe: LWW by HLC, never a blind clobber (see the
  [yellow paper](docs/spec/yellow-paper.md)).
- **Money is integer cents in storage and domain; every wire speaks decimal
  dollars.** Schema v15 stores monetary columns as `*_cents INTEGER`, and domain
  fields are named `*Cents` precisely so the compiler flushes any code that would
  misread the unit — never reuse a dollar-era name for a cent value. Backup JSON,
  CSV, and LAN sync serialize decimal dollars under the original keys; the only
  crossings are `centsFromDollars`/`dollarsFromCents`
  (`lib/core/utils/money.dart`). Changing sync payload *semantics* must bump
  `SyncChangeset.currentPayloadSchemaVersion` so an older peer fails closed.
  Drift migrations are NOT transactional here: a migration that rebuilds a table
  must be guarded for re-entry (see the v15 `stillDollars` guards), and any
  rebuild of `items` must recreate the FTS triggers and rebuild the index.
- **TDD, always.** Reproduce → failing test → fix → `flutter test` green → commit.
  Every bugfix ships with a regression test. Security fixes especially (see the
  path-traversal and CSV-injection tests).
- **Atomic commits, one concern each.** Commit messages state the *why* and the failure
  mode fixed. **No AI-attribution trailers** in commit messages — deliberate project
  policy; keep authorship to the project's existing neutral persona.
- **Never commit local agent artifacts** — the per-repo agent-instructions file, the
  agent tool's local state directory, and `docs/superpowers/` are all gitignored (see
  `.gitignore`). This repo ships `AGENTS.md` as its committed agent guide.

## Where things are (progressive disclosure)

The full map with diagrams is in
[OVERVIEW.md § Module map](docs/architecture/OVERVIEW.md#module-map-where-to-look).
The short version, by concern:

| You're touching… | Go to |
|---|---|
| **The data model / schema / migrations** | `lib/services/database/tables.dart`, `database.dart` (+ `daos/`). Run codegen after edits. |
| **An item / room / container / photo feature** | `lib/features/inventory/`, `lib/features/locations/` (`{domain,data,presentation}`) |
| **Money: value, depreciation, dashboard, policies** | `lib/features/dashboard/`, `lib/features/insurance/`, `lib/features/reports/` |
| **LAN sync + the merge** | `lib/services/sync/` (`crdt_manager`, `merge_engine`, `lan_sync_server`, `lan_sync_client`, `changeset`), `lib/services/network/lan_discovery.dart` |
| **Backup / export / import** | `lib/services/export/` (`json_export_service`, `csv_export_service`, `import_service`), `lib/services/backup/webdav_backup_service.dart`, `lib/features/reports/data/services/pdf_report_generator.dart` |
| **AI cataloguing / appraisal / chat** | `lib/services/ml/` (`provider_manager` + the four `*_provider`s), `lib/services/appraisal/`, `lib/services/chat/`; the video-walkthrough pipeline (frame gate, merger, orchestrator) is `lib/features/video_analysis/`; the paid tier's backend is `server/hosted-llm/` (TypeScript, separate) |
| **Scanning & import: barcode, receipts, Amazon, product lookup** | `lib/features/scanning/`, `lib/services/product_lookup/`, `lib/services/import/` (`receipt_parser`, `receipt_structuring_parser`, `import_receipt_ocr_service`, `amazon_import_service`) |
| **Boot / DB open / onboarding trap** | `lib/main.dart`, `lib/app/boot.dart`, `lib/services/database/database.dart` (`resolveAppDocumentsDir`), `lib/features/onboarding/` |
| **On-device model downloads** | `lib/services/ml/on_device/`. The transfer itself is NOT ours — it delegates to `domovoi`'s `resumableDownload` (sibling package, `../DomovoiDiscernment`). Byte-range resume, `.part` handling and 416/Range recovery all live there; what stays here is the multi-file loop, the pinned-size/sha256 verification in `promote`, and the aggregate progress fraction. |
| **DI wiring** | `lib/core/providers/` (Riverpod providers), `lib/core/config/feature_flags.dart` |
| **QR labels** | `lib/features/labels/`, `lib/core/utils/label_id.dart` (adj-adj-noun IDs) |

Docs are organised [Diátaxis](https://diataxis.fr/)-style — see
[docs/README.md](docs/README.md) for the tutorials / how-to / reference / explanation
split.

## How to work here

```bash
flutter pub get                                            # deps
dart run build_runner build --delete-conflicting-outputs   # regenerate Drift + Riverpod + Freezed codegen
flutter analyze                                            # lint — must pass (config in analysis_options.yaml)
flutter test                                               # the suite — must be green before you commit
flutter build apk --debug                                  # Android build sanity
```

- **Codegen is mandatory** after any change to `tables.dart`, `database.dart`, or a
  file with a `@riverpod` / `@freezed` / `@DriftDatabase` / `@DriftAccessor`
  annotation. Generated `*.g.dart` / `*.freezed.dart` are excluded from analysis.
- **A schema change is a migration.** Bump `schemaVersion` in `database.dart` and add
  an `onUpgrade` step; a new table needs its CRDT stamp columns (`nodeId`, `hlc`,
  `isDeleted`) if it should sync, and a row in the import round-trip
  ([ADR-0004](docs/adr/0004-lan-sync-hlc-lww.md)). A synced table that forgets its HLC
  silently opts out of last-writer-wins.
- **CI** (`.github/workflows/ci.yml`) runs analyze → test (with coverage) → build
  Android / Linux / Web, plus a separate Node job for `server/hosted-llm`. Note its
  triggers are `main`/`develop`; the live branch is `master`.
- The custom design system comes from a sibling package
  (`../ohStyle/openhearth_design`) referenced by a path dependency.

## When you're unsure

Prefer failing safe on user data to a clever shortcut. Prefer a failing test to a
plausible fix. Prefer matching the surrounding Clean-Architecture layering to
introducing a new pattern. If a change would send anything off the device, stop and
check it's opt-in, named, and documented. When in doubt about a decision's rationale,
grep [docs/adr/](docs/adr/) before reopening it — you may be re-litigating a settled
trade-off.
