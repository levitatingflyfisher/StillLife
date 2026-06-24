# Still Life — Roadmap

This document captures the full phasing plan beyond Phase 14. Each phase is sized to be shippable independently. Phases within a tier can be reordered based on user feedback.

---

## Completed (Phases 1–14)

| Phase | Summary |
|-------|---------|
| 1 | Foundation: Flutter project, Drift schema v1, basic inventory CRUD |
| 1.5 | UX polish: auto-seeding, inline create, category/tag/photo management, export |
| 2 | AI cataloguing: video analysis pipeline, 4-tier LLM (on-device / Ollama / cloud / hosted) |
| 3 | Store integration: barcode scanning, receipt OCR |
| 4 | Financial dashboards: depreciation, value by room/category, insurance policies |
| 5 | Policy repository, policy screens, reactive FTS5 search |
| 6 | Maintenance logs, warranty expiry reminders, upcoming maintenance widget |
| 7 | LAN P2P sync: CRDT/HLC conflict resolution, shelf server, mDNS discovery |
| 8 | Privacy-first barcode lookup: cache-first, opt-in network, consent dialog |
| 9 | Notifications, smart scan flow (BarcodeResultSheet, findByBarcode) |
| 10 | Global search, container hierarchy (shelf/box/drawer), WebDAV backup |
| 11 | QR labels, bulk operations, value history charts |
| 12 | Onboarding flow (2-page welcome) |
| 13 | CSV export (18 columns, RFC 4180) |
| 14 | Bug blitz + container features: soft-delete filters, reactive dashboard, async settings providers, camera barcode in item edit, price-field filter, container detail + label screens, llmSettings route, rooms crash fix |

---

## Tier A — UX Gaps (Phases 15–17)
*Fix the most common "I gave up" moments. Ship before marketing push.*

### Phase 15 — Fast Add
**Goal:** Reduce item-add friction from ~12 taps to 2.

- **Photo-first flow:** FAB opens camera immediately; AI suggests name/category/value after photo capture; user confirms or edits
- **Quick Actions after scan:** After barcode scan → "Add to inventory" as primary CTA (currently secondary to "View Details")
- **Voice add:** Hold mic button, say "Add a Bosch drill, paid $120, Kitchen drawer" → pre-filled form; uses on-device speech-to-text (no cloud)
- **Inline create everywhere:** Typing a new tag, category, room, or container in any form field creates it without leaving the screen
- **Duplicate detection:** On item save, warn if barcode or name+room already exists

### Phase 16 — Natural Language Search + Smart Filters
**Goal:** Match what people actually type ("expensive stuff in the garage").

- Natural language query parser: extract room, category, price range, date range from free text
- "Where is my…" mode: type item name → app shows room + container path
- Saved searches / smart lists (e.g. "Items worth over $500 with no photo")
- Filter improvements: date added range, has-photo / has-receipt / has-barcode toggles

### Phase 17 — Loan Tracking
**Goal:** Stop losing things to friends.

- "Lend" action on any item: captures borrower name + optional return date
- Loaned items shown with a distinct badge in inventory list
- Reminder notification when return date approaches
- Loan history log on item detail page

---

## Tier B — Household & Collaboration (Phases 18–20)

### Phase 18 — Quantities & Consumables
**Goal:** Track pantry, supplies, and stock levels.

- `quantity` field on items (integer or decimal)
- `lowStockThreshold` field: notification when quantity drops below threshold
- Quick decrement from item list tile (tap "−1" without opening detail)
- Consumable category template with common items pre-seeded on first use
- "Shopping list" export: all items below threshold

### Phase 19 — Family Sharing / Multi-User
**Goal:** Let households share one inventory without a cloud account.

- Multiple named profiles within one app instance ("shared household")
- Per-profile "my items" filter (created by me / assigned to me)
- LAN sync promotes one device to primary; others subscribe — no account required
- Optional: invite via QR code (LAN only) or WebDAV-synced shared vault

### Phase 20 — Receipt Forwarding & Import
**Goal:** Add items from email receipts and Amazon orders without typing.

- Email parser (local): user forwards receipt to local inbox hook; app extracts item, price, date
- Amazon order import: paste order confirmation URL; app scrapes item list (offline-friendly via saved HTML)
- CSV import: match columns to Still Life fields; deduplicate by barcode
- Google Shopping history import (for users who want to migrate from other apps)

---

## Tier C — Platform Expansion (Phases 21–22)

### Phase 21 — iOS Build + App Store
**Goal:** Ship on iOS without breaking Android.

- Resolve iOS-specific build issues (camera permissions, share_plus, path_provider)
- App Store Connect setup, screenshots, privacy nutrition label
- TestFlight beta
- Ensure LAN sync works across Android ↔ iOS on same network

### Phase 22 — Hosted LLM + Cloud Backup (Revenue)
**Goal:** First paying customers.

- **Hosted LLM tier:** Anthropic/OpenAI token arbitrage — user pays a fixed monthly fee; app proxies requests through our endpoint (no API key needed)
- **Cloud backup tier:** Encrypted S3 backup; restore on new device by logging in with a code phrase (no email required — code phrase IS the identity)
- Stripe payment integration (in-app purchase on iOS, Stripe web on Android to avoid 30% cut)
- Pro badge in app; feature gate hosted LLM + cloud backup behind Pro

---

## Tier D — Intelligence & B2B (Phases 23–24)

### Phase 23 — AI Item Intelligence + Appraiser
**Goal:** Per-item Q&A, proactive value alerts, and automatic market-price estimation.

- "Ask about this item": chat interface on item detail page; answers from item data + web knowledge (LLM)
- **Appraiser — current value:** scrape or query Facebook Marketplace / eBay / Craigslist completed listings for the item's make/model → suggest a realistic resale/liquidation value ("what you'd get selling it today")
- **Appraiser — replacement cost:** two distinct modes the user can pick:
  - *Buy new:* pull current retail price from Amazon / Google Shopping (buy the same thing new)
  - *Buy equivalent:* LLM estimates cost to replace with an item of similar age and condition (more relevant for insurance "actual cash value" vs "replacement cost value" policy types)
  - App surfaces which definition is in use so the user knows what they're comparing to their policy
- Replacement value alerts: notify user if market price for their item model has shifted >15% since last estimate
- Batch re-value: run an appraiser pass over all items older than 12 months, surface suggested updates for user approval
- "What should I insure?" summary: top N items by value with no policy attached

### Phase 24 — B2B / Insurance Integration
**Goal:** Unlock B2B revenue channel.

- Insurance company API: export inventory in standard ACORD or carrier-specific format
- Adjuster mode: read-only shareable link (or PDF) for a claim; no account required for adjuster
- Property manager mode: track fixtures, appliances, and white goods across multiple units
- Bulk import from property management software (CSV or API)
- White-label build option (commercial license customers)

---

## Competitive Differentiators to Protect

These are the features that make Still Life defensible. Every phase should strengthen at least one.

1. **Local-first / no account required** — never compromise this; it's the core promise
2. **LAN sync without cloud** — unique in the market; expand to more protocols (Bluetooth, AirDrop)
3. **Container hierarchy (room → container → item)** — competitors show flat lists; we show where things actually are
4. **Human-readable QR labels** — memorable adj-adj-noun IDs; scan-to-find in seconds
5. **Privacy-respecting AI** — on-device first, user-controlled API keys; never train on user data
6. **Open source** — trust through transparency; community contributions accelerate the roadmap

---

## UX Principles for All Phases

- **5 ways to add an item** (target): photo, barcode scan, voice, manual form, receipt/import
- **Zero dead ends:** every empty state has a primary action
- **Offline always works:** no feature should degrade to a spinner when there's no internet
- **Scan is the primary interaction:** the camera should feel faster than typing every time
