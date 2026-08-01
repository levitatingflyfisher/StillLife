# Limitations

Read this before adopting Still Life or building on it. It is the honest companion to
the [feature list](../README.md#features) — what the app does *not* do, or does only
partway. The [VISION scorecard](../VISION.md#honest-scorecard--built-vs-aspirational)
is the short version; this is the detail.

*The code and comments here were written by an AI assistant; this document reflects the
current implementation, which you should verify against the tests before relying on.*

## AI cataloguing

- **The on-device tier is real on Android now — with honest limits.** Three engines
  serve it, best-available first: Gemini Nano (AICore flagships only, Beta API with
  no SLA), a user-downloaded SmolVLM2 GGUF over llama.cpp, and the bundled ML Kit
  labeler. The limits, plainly: the labeler is **coarse** — "Chair", a category, a
  confidence; never a brand, model, or value (re-analyze on a richer tier to enrich).
  SmolVLM2's real-world latency, RAM behaviour, and brand-reading quality on phones
  are **unverified** — no published benchmarks exist, and the llama.cpp runtime ships
  from a prerelease binding that has not yet been exercised on a physical device.
  The tier is **single-photo only**: shelf photos and video walkthroughs still
  require a networked tier. The web build has no on-device tier at all. And the
  default cascade order is quality-first, so a *configured* tier wins over the
  on-device floor unless you reorder.
- **AI suggestions are LLM output — review them.** Vision models hallucinate brands
  and model numbers that merely look plausible; that risk is why every AI path ends in
  a review screen (shelf review, video review, import review) instead of writing
  straight to the database. Accuracy drops on casual photos — blur, distance, clutter,
  partial views — and the confidence figure shown is the model's self-assessment, not
  a measurement.
- **The video walkthrough costs one AI call per analyzed frame.** Android only (web
  shows an honest unavailable state). ffmpeg extracts frames on-device and a quality
  gate keeps at most 12 (configurable); each survivor goes to your configured tier —
  the call count is disclosed before anything runs. Cross-frame merging is by name or
  brand+model, so the same couch can still appear twice and small background items can
  be missed. Cancelling keeps the partial results.
- **The appraiser is an LLM estimate, not a market quote.** Despite roadmap language
  about scraping eBay/Facebook Marketplace, valuations come from an LLM call with web
  search (cached with a 7- or 30-day TTL). Treat the number as an informed guess with
  cited sources, not a live listing price. It also specifically needs an Anthropic
  (Claude) key or Pro — the OpenAI-compatible tier cannot run the appraiser — and an
  estimate only changes the item when you explicitly tap "Apply to item".
- **The hosted tier and billing are scaffolding — and fail closed.** A first-party
  proxy (`server/hosted-llm/`, a Cloudflare Worker) and Stripe plumbing exist in the
  tree, but no backend is deployed: the hosted base URL and the Pro checkout URL
  default to empty, the hosted toggle is pinned off, and the code refuses without
  attempting a request. This is a future paid tier, not a shipped product.

## Sync

- **Sync moves rows, not media.** LAN sync transfers database records; the actual photo
  and receipt *image files* are not carried to the other device (the JSON export marks
  `photosIncluded: false`). After a sync, the second device knows an item *has* a photo
  but doesn't have the file. Moving the media is an open problem.
- **It's LAN-only.** Sync works only between devices on the same local network (mDNS
  discovery + HTTP on port 8420). There is no sync beyond the LAN and no cloud relay.
  The transport *is* end-to-end encrypted — bodies are AEAD frames keyed by your
  household secret, there is no plaintext fallback path, and a frame that will not
  open is refused before it reaches the database (ADR-0007). It is not TLS, which
  matters only in that a network observer still sees that two devices are talking,
  and how much.
- **It's a full-snapshot exchange.** Each sync ships the entire database state, so
  bandwidth and time grow with the size of your inventory. There is no delta/incremental
  sync yet.
- **Conflict resolution is per-row, not per-field.** If two devices edit *different*
  fields of the same item while apart, the row with the newer HLC wins *wholesale* — the
  older device's field edit is lost, not merged. Last-writer-wins is deterministic and
  safe against clobbering newer data, but it is not a three-way field merge.

## Backup

- **WebDAV/JSON backup does not include image files either** — it's the same
  metadata-only JSON export. A restore rebuilds the catalogue but not the photos unless
  those files are already present on the device.
- **Cloud (off-site, encrypted) backup is roadmap only.** Today your off-device backup
  options are your own WebDAV server (HTTPS-enforced) or a local file you manage.

## Platform

- **iOS is not shipped.** Android is the live target. Desktop (Linux) and Web build in
  CI but are not the primary experience. iOS-specific work (camera permissions,
  `share_plus`, `path_provider`) is on the roadmap.
- **CI branch mismatch.** The CI workflow triggers on `main`/`develop`, while the live
  branch is `master`; pushes to `master` don't currently run CI automatically. Run
  `flutter analyze` and `flutter test` locally before you push.

## Data & scope

- **Product barcode lookup is best-effort and third-party.** When you opt in, lookups
  hit Open Food Facts then UPCitemdb (a free trial tier, ~100 requests/day, no key).
  Coverage is uneven, especially for non-grocery items, and rate limits apply.
- **Receipt scanning is two-stage — and still needs review.** OCR runs on-device;
  when an AI tier is configured the recognized *text* (never the image) is
  LLM-structured into line items with brand/model. Without a provider — or on any LLM
  failure — it falls back to a deterministic pattern-matcher that extracts only
  store/date/total and per-line prices, no brand or model. Both stages misread
  sometimes; review what it fills in.
- **No multi-user permissions.** Profiles attribute items to people but carry no
  authentication — anyone with the app (and, for sync, the shared code) can edit
  everything. It's a shared household model, not an access-control model.
