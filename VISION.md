# Vision

> The north star for Still Life. If you (person or agent) are about to change
> something load-bearing, read this first — it says what must stay true and why.
> For *how it's built*, see [docs/architecture/OVERVIEW.md](docs/architecture/OVERVIEW.md);
> for *why each decision was made*, [docs/adr/](docs/adr/).

## The one idea

**A catalogue of everything you own — that you actually own.** Know what's in your
home, where it lives, and what it's worth, so that the worst day (a fire, a flood, a
burglary, a claim) starts from a list instead of from memory. The catalogue lives on
your device, works with no account and no internet, and never phones home. It is a
still life of your household: your possessions, held still, so you can see them.

The move that makes this different from every cloud inventory app is the default:

> **Nothing leaves your device unless you turn it on — and every switch that lets
> something leave is named, gated, and off to begin with.**

An insurance inventory is a map of your most valuable, most private possessions.
Handing that to someone else's server is the thing to avoid, not the price of
admission. So the product *is* the offline app; sync, AI, and backup are bonuses you
opt into, one consent at a time.

## What this is

A **local-first home-inventory app** built with Flutter (Android today; desktop and
web build in CI; iOS is on the roadmap). Photograph your belongings, record what they
cost and what they're worth, organise them room-by-container-by-item, and produce an
insurance-ready report. On-device SQLite via Drift; no server required to use any core
feature.

```
   your home                 Still Life (on device)              opt-in edges
  ───────────            ───────────────────────────          ─────────────────
  rooms, boxes,          catalogue · value · depreciation      LAN sync (your Wi-Fi)
  items, receipts  ──▶   photos · receipts · policies    ──▶   WebDAV backup (your server)
  warranties, loans      search (FTS5) · QR labels · PDF        AI cataloguing (your choice)
```

## Design commitments (the invariants — do not break these)

These are the load-bearing beliefs Still Life shares with every OpenHearth app, in
this app's voice. Breaking one is a design regression, not a feature.

1. **No account, ever, for core functionality.** There is no sign-up, no login, no
   identity. The app is fully usable the second it opens. ([ADR-0002](docs/adr/0002-local-first-no-account.md))
2. **Local-first, not local-only.** On-device storage and full offline operation are
   the default. Sync and backup exist, but they are opt-in and travel to destinations
   *you* control — a device on your own Wi-Fi, or your own WebDAV server.
3. **Every egress is named and off by default.** Barcode lookup, WebDAV backup, cloud
   or hosted AI — each is a switch in Settings, each says what it sends, each starts
   off. If nothing is enabled, nothing leaves. ([privacy model](docs/privacy-model.md))
4. **No ads, no tracking, no data sales.** There is no analytics SDK, no crash
   reporter, no telemetry in the dependency set. This is enforced by what *isn't*
   there, not just promised.
5. **Your data is portable.** JSON backup and CSV export in open formats mean you can
   leave at any time. The code is AGPL — a recipe worth sharing.
6. **Fail safe on the user's data.** The database is the family's memory of their
   possessions; a boot glitch, a bad import, or a stale sync peer must never brick it
   or silently destroy it. ([ADR-0005](docs/adr/0005-boot-resilience.md),
   [ADR-0006](docs/adr/0006-import-db-safety.md))
7. **Genuine craft.** Clean Architecture (domain / data / presentation), Riverpod,
   Drift, high test coverage. Warm, not sterile — home-cooked software.

## Honest scorecard — built vs. aspirational

A guiding light has to tell the truth about where the light reaches. Every line of
this codebase and every comment in it was written by an AI assistant; treat them as
**an accurate record of what currently exists, offered with gratitude and a grain of
salt** — not as a specification, and not as guaranteed-correct. Verify a claim (read
the code, run the test) before you rely on it. As of schema v14:

**Real, tested, load-bearing:**
- The inventory core: Property → Room → Container → Item, with categories, tags,
  photos, receipts, purchase/current/replacement value, condition, serial, barcode,
  brand/model/ASIN, warranty, and notes. Drift schema v14, 17 tables, FTS5 full-text
  search. ~162 test files across unit / widget / visual.
- The financial layer: dashboard totals, depreciation, per-item value history,
  insurance policies with coverage-gap detection, CSV export (RFC 4180, with
  formula-injection neutralised), JSON backup, and a PDF report.
- **LAN sync**: HLC last-writer-wins merge, soft-delete tombstones, shared-secret
  Bearer auth, mDNS discovery, a 20 MB body cap — real and tested. The
  [yellow paper](docs/spec/yellow-paper.md) specifies its semantics.
- **Data safety**: import runs in one transaction behind a path-sandbox guard (a
  crafted backup can't point a file path at the database and delete it); boot survives
  a transient documents-directory failure instead of caching it forever.
- QR labels (memorable `adjective-adjective-noun` IDs), barcode scan with cache-first
  opt-in product lookup, receipt OCR, loan tracking, maintenance/warranty reminders,
  WebDAV backup (HTTPS-enforced).

**Aspirational — documented or scaffolded, not shipped:**
- **On-device AI is built (Android) but not yet device-proven.** Tier 1 now has
  three real engines — Gemini Nano on AICore flagships, an opt-in downloaded
  SmolVLM2 over llama.cpp, and the bundled ML Kit labeler that works with zero
  setup — so single-photo recognition finally has a "no bytes leave home" path
  that doesn't require self-hosting Ollama. Honest residue: coarse labels from
  the labeler floor, unverified real-device latency/quality for the VLM rung,
  and shelf/video multi-item analysis still needs a networked tier. Scorecard
  moves from "does not exist" to "built, awaiting device verification".
- **The hosted AI tier and billing are scaffolding** for a future paid tier (a small
  Cloudflare-Worker proxy in `server/hosted-llm`, plus Stripe plumbing), not a shipped
  product — and they **fail closed**: the hosted base URL and checkout URL default to
  empty, so default builds never attempt the requests. The valuation "appraiser" is a
  real LLM-backed call (via a Messages-style transport, with an explicit
  apply-to-item write-back), *not* the marketplace-scraping the roadmap describes.
- **Sync moves rows, not media.** LAN sync transfers database records; the photo and
  receipt image *files* are not carried across devices yet. Sync is also a full-
  snapshot exchange (bandwidth grows with the library) and per-*row* last-writer-wins.
  The wire itself is encrypted end to end (ADR-0007) and fails closed. See
  [limitations](docs/limitations.md).
- **iOS is not shipped.** Android is the live target; desktop/web build in CI. Cloud
  (encrypted off-site) backup is roadmap only.

The offline catalogue is real and trustworthy, and AI recognition is real once you
point it at a tier you configure. *On-device* recognition, the *paid tier*, and
*cross-device photos* are still hopes. Keep that line bright.

## Horizons (problems, not a feature list)

Framed as problems on purpose — a dated feature list self-destructs, but the open
problems endure.

- **Near — move the media, not just the metadata.** Sync's missing half: how do photos
  and receipts travel between two devices with no cloud in the middle? Solve this and
  LAN sync becomes whole.
- **Mid — prove on-device recognition on real phones, and make sync scale.** The
  on-device tier is built (bundled labeler + downloadable SmolVLM2 + Gemini Nano);
  what remains is device verification, latency/quality tuning, and extending it to
  multi-item shelf photos. Move sync from full-snapshot to delta so a large library
  doesn't re-ship on every merge.
- **Far — trust beyond the LAN without becoming a cloud account.** Encrypt sync on the
  wire; let two homes reconcile over the internet through a dumb, zero-knowledge relay
  — never a server that can read the inventory. The hard, worth-naming problem: sharing
  a household catalogue across places while keeping the "nobody else can see it"
  guarantee intact.

## The name

**Still life** — the genre of painting that depicts ordinary, inanimate household
things (a bowl of fruit, a jug, the objects of a home) arranged and observed at rest.
An inventory is exactly that: your possessions, held still long enough to be seen,
counted, and remembered. The pun is intentional — the *stuff* of your life, kept
*still*, so that when life moves suddenly you already have the picture.
