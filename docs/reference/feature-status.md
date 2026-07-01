# Reference: feature status

The honest, per-area picture of what's real. Legend: **Shipped** = built, tested,
load-bearing · **Partial** = works but with a real caveat · **Scaffolded** = code
exists, not a finished/shipped capability · **Roadmap** = not built.

*Written against schema v14. The code was AI-authored; verify against the tests before
relying on any row.*

## Inventory & organisation

| Feature | Status | Notes |
|---|---|---|
| Item catalogue (photos, value, serial, barcode, brand/model/ASIN, warranty, notes) | Shipped | The core. Brand/model/ASIN landed in schema v13. |
| Property → Room → Container → Item hierarchy | Shipped | Container nesting is a differentiator. |
| Categories (tree) + Tags (many-to-many) | Shipped | |
| Full-text search (FTS5) | Shipped | name/description/notes/serial/barcode. |
| Natural-language search + saved searches | Shipped | Free-text query parsing. |
| QR labels (`adj-adj-noun` IDs) | Shipped | Scan-to-find; deterministic from UUID. |
| Bulk select / move / delete | Shipped | |
| Quantities & consumables (low-stock) | Shipped | Shopping-list export included. |
| Loans (lend / due / overdue) | Shipped | With reminders. |
| Maintenance logs + warranty reminders | Shipped | |
| Profiles (shared household) | Partial | Attribution only; no auth, and outside the sync LWW filter. |

## Financial & reporting

| Feature | Status | Notes |
|---|---|---|
| Dashboard (totals, by-room, by-category, depreciation, trend) | Shipped | Reactive off Drift streams. |
| Per-item value history + chart | Shipped | |
| Insurance policies + coverage-gap ("what to insure") | Shipped | |
| PDF insurance report | Shipped | Grouped by room/category. |
| CSV export (RFC 4180, formula-injection-safe) | Shipped | |
| JSON backup / restore | Shipped | Metadata only — **no image files**. |

## Sync & backup

| Feature | Status | Notes |
|---|---|---|
| LAN sync (HLC last-writer-wins, tombstones) | Shipped | Rows only; see caveats below. |
| mDNS peer discovery + shared-secret auth | Shipped | Port 8420; Bearer token ≥ 16 chars. |
| Media (photo/receipt files) sync | Roadmap | Sync moves metadata, not image files. |
| Delta / incremental sync | Roadmap | Today it's a full-snapshot exchange. |
| Per-field conflict merge | Roadmap | Today it's per-row last-writer-wins. |
| Encrypted / beyond-LAN sync | Roadmap | LAN transport is plaintext. |
| WebDAV backup (HTTPS-enforced) | Shipped | To your own server. |
| Cloud (off-site, encrypted) backup | Roadmap | |

## Scanning & import

| Feature | Status | Notes |
|---|---|---|
| Barcode scanning | Shipped | |
| Product lookup (cache-first, opt-in) | Shipped | Open Food Facts → UPCitemdb; barcode only. |
| Receipt scan (camera/gallery/share) | Shipped | OCR on-device (MLKit); with an AI tier configured the **text** (never the image) is LLM-structured into line items with brand/model; otherwise a deterministic pattern-matcher extracts store/date/total. Receipts persist as rows (schema v14) and items link back to them. Still review it. |
| CSV / bank-statement / Amazon import | Partial | Column-mapping + parsers exist; coverage varies. Amazon: current Privacy Central `Retail.OrderHistory` exports parse (the legacy report format died in 2023 but is still accepted). |

## AI cataloguing & valuation

Most AI flows below need a **configured tier** to do real work — your own Ollama
(opt-in) or a cloud key you bring. On Android, single-photo add also has an
**on-device floor** (coarse labels from the bundled recognizer, richer if you
download a model) that works with zero configuration. With no tier available, each
flow says so honestly and degrades to the manual path; nothing is fabricated.

| Feature | Status | Notes |
|---|---|---|
| 4-tier provider cascade + config | Shipped | Default order is **quality-first**: local → cloud → hosted → on-device. Configuring a tier is an explicit quality choice, so the always-available on-device floor answers only when nothing better is configured; drag it to the top in settings for privacy-first. Fully reorderable, persisted. |
| Tier 1 — on-device | Built (Android; device-unverified) | **Three engines**, best available wins: Gemini Nano via AICore (flagships only, explicit Set-up), a downloaded SmolVLM2 GGUF over llama.cpp (opt-in 1.7 GB / 546 MB download, sha256-verified, Apache-2.0), and the always-ready bundled ML Kit labeler (~400 coarse labels, zero download). **Single-photo only** — shelf/video multi-item still needs a networked tier. Web build: unsupported, tier honestly unavailable. Native paths not yet exercised on a real device. |
| Tier 2 — local Ollama | Shipped | Your own machine on the LAN. **Explicit opt-in, off by default** — the app never probes an unconfigured localhost port with your photos. |
| Tier 3 — cloud API (your key) | Shipped | Anthropic, or **any OpenAI-compatible endpoint** (llamafile / LM Studio / vLLM; keyless self-hosted servers work). You bring the key + the provider relationship. |
| Tier 4 — hosted proxy | Not deployed | **Fail-closed**: the base URL is empty in default builds, the settings toggle is pinned off, and no HTTP is ever attempted. Worker code exists in `server/hosted-llm/` for a future paid tier. |
| Photo add (single item) | Shipped | Suggests name/brand/model/category/value; captured photo attaches to the item. On Android the on-device floor answers even with nothing configured (coarse labels, or a downloaded model); otherwise no tier → honest snackbar + manual form keeps the photo. |
| Shelf photo (one photo → many items) | Shipped | Multi-item VLM parse → review screen (accept, fix, batch-home); the shelf frame attaches to every created item. |
| Voice add | Shipped | Speech-to-text runs on-device; the transcript is LLM-structured on your tier. No tier → transcript preserved as item notes. |
| Receipt LLM structuring | Shipped | OCR text (never the image) becomes line items with brand/model; any failure falls back byte-for-byte to the deterministic parser. |
| Video-walkthrough analysis | Shipped (Android) | Record/import → ffmpeg frames → quality gate (top-12 by default) → per-frame VLM on your configured tier → cross-frame merge → review → batch save with source-frame photos. Call-count cost disclosure before analysis; honest no-AI/failure/cancel states. |
| Appraiser (resale / replace-new / replace-equivalent) | Partial | LLM estimate + web search with TTL cache — **not** marketplace scraping. Needs an **Anthropic key or Pro** specifically (the OpenAI-compat tier can't run it). Write-back is an explicit "Apply to item", never automatic. |
| Per-item chat | Partial | Same Anthropic-or-Pro transport as the appraiser. |
| Billing / Pro (Stripe) | Scaffolded | Plumbing exists; not a shipped product. **Fail-closed** — checkout URL empty by default, upgrade CTA hidden. |

## Platform

| Target | Status | Notes |
|---|---|---|
| Android | Shipped | The live target. |
| Linux / Web | Partial | Build in CI; not the primary experience. |
| iOS | Roadmap | Camera/permissions/share work outstanding. |

## Robustness (the safety net)

| Property | Status | Notes |
|---|---|---|
| Boot survives transient DB-open failure | Shipped | Bounded retry; onboarding never traps. [ADR-0005](../adr/0005-boot-resilience.md) |
| Import sandboxed + transactional | Shipped | Can't wipe the DB. [ADR-0006](../adr/0006-import-db-safety.md) |
| Sync merge fails safe (LWW, no clobber) | Shipped | [Yellow paper](../spec/yellow-paper.md) |
| No telemetry / analytics / crash SDK | Shipped | Verified by absence. |
| Test suite | Shipped | ~162 test files (unit / widget / visual). |
