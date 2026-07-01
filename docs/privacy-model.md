# Privacy model

Still Life's core promise is simple: **your inventory stays on your device unless you
turn on a feature that moves it, and every such feature is named here and off by
default.** This document is the concrete accounting — the threat model, exactly what
can leave, and how you can check that nothing does.

*The code behind these claims was written by an AI assistant. Treat this as the current,
verifiable behaviour — the "how to verify" section tells you how to confirm it yourself
rather than take it on faith.*

## What you're protecting

A home inventory is a list of your most valuable and most private possessions, with
photos, serial numbers, values, and receipts. The adversaries worth naming: a company
that would monetise that list; a breach of a server that holds it; a network snooper;
and lock-in that makes leaving costly. The design answer to all four is the same — keep
the data local, make every exit explicit, and use open, portable formats.

## The default: nothing leaves

With a fresh install and no settings changed, Still Life makes **no network calls at
all** for its core function. Specifically:

- **No account, no login, no server-side identity.** There is nothing to sign up for.
- **No telemetry, no analytics, no crash reporting.** There is no Firebase, Sentry,
  analytics, or telemetry SDK anywhere in the dependency set — verified by grep, not
  just policy. Uncaught errors are printed locally, never uploaded.
- **No ads, no trackers.** None are present to disable.

The `INTERNET` permission the Android app requests exists solely so the *opt-in*
features below can work; nothing uses it until you turn one on.

## Exactly what can leave, and when

Every row below is **off by default** and requires an explicit action in Settings (or a
deliberate in-app choice) to activate.

| Feature | What leaves | Where it goes | Notes |
|---|---|---|---|
| **Barcode product lookup** | Only the **barcode number** | Open Food Facts, then UPCitemdb (fallback) | Cache-first: a barcode is fetched at most once, then stored locally. `allowNetwork` is `false` until you opt in. No item data, no photos — just the UPC. |
| **WebDAV backup** | The full **JSON export** (all your catalogue *metadata*; **no image files**) | **Your own** WebDAV server (Nextcloud, ownCloud, …) | You supply the URL + credentials. **HTTPS is enforced** — a non-`https://` URL is refused before any request, so Basic-Auth credentials can't leak. |
| **LAN sync** | The full database **state** (metadata; **no image files**) | **Another of your devices on the same Wi-Fi** | mDNS discovery + HTTP on port 8420. Authenticated by a shared secret Bearer token (≥ 16 chars) you copy between devices. **Never the internet — no cloud relay.** Plaintext on the LAN (not TLS). |
| **AI — Tier 1, on-device (Android)** | **Nothing at analysis time.** The optional VLM model download (only after you tap Download and confirm) fetches the chosen SmolVLM2 files | huggingface.co — first-party ggml-org repos, commit-pinned URLs, download only | Photos analyzed on-device never leave the phone. Downloads are sha256-verified fail-closed; the bundled labeler needs no download at all. Gemini Nano provisioning goes through Google Play's AICore system service, and only after an explicit Set-up tap. |
| **AI — Tier 2, local LLM** | The **images / text** each flow sends (exact map below) | **Your own machine** running Ollama on the LAN (host and port you set) | Stays on your network, as plaintext HTTP. **Explicit opt-in, off by default** — the app never probes an unconfigured localhost port with your photos. |
| **AI — Tier 3, cloud API (your key)** | The same **images / text + prompts** | **Anthropic, or any OpenAI-compatible endpoint you configure** (a major provider, or your own llamafile / LM Studio / vLLM server), using **your own API key** | You bring the key and the relationship; Still Life is just the client. Keyless self-hosted endpoints work. |
| **AI — Tier 4, hosted proxy** | The **image / prompt** | A **first-party hosted proxy** (`server/hosted-llm/`), authenticated by a bearer token | A future paid ("Pro") tier. **Disabled in default builds**: the base URL defaults to empty and the code fails closed — no request is ever attempted unless an operator compiles one in. |
| **Pro checkout** | Purchase details | A web checkout page + payment processor | Only if you choose to buy Pro. The checkout URL is also empty in default builds — the upgrade button is hidden; fail-closed like the hosted tier. |

The AI tier is a cascade (`provider_manager.dart`) tried in a user-configurable
order. The default is **quality-first** (local → cloud → hosted → on-device):
configuring a tier is an explicit choice, so the always-available on-device floor
answers only when nothing better is set up. **Drag on-device to the top of the
priority list for a privacy-first order** — analysis then never leaves the phone.
Tier 1 (on-device, Android) sends **nothing at analysis time**; its only network
activity is the optional, user-initiated model download from Hugging Face
(commit-pinned URLs, sha256-verified — see the row above). Only Tiers 3 and 4 send
data off *your* network — Tier 3 only once you store a key, Tier 4 only in builds
where an operator compiled in a base URL.

### What each AI flow sends (once a tier is enabled)

Every flow goes to the single tier the cascade selects — nothing is sent anywhere by
default.

| Flow | What leaves | What never leaves |
|---|---|---|
| **Photo add** (single item) | The captured photo | — |
| **Shelf photo** (one photo → many items) | The shelf photo | — |
| **Video walkthrough** | Only the **selected frames** — at most 12 (default) downscaled JPEG frames chosen by an on-device quality gate, sent one call per frame | The **video file** itself, and every rejected frame |
| **Voice add** | The **transcript text** only | The **audio** — speech-to-text runs on the device's built-in recognizer |
| **Receipt scan** | The **recognized text** only (OCR runs on-device via MLKit) | The **receipt image** |
| **Appraiser** | The item's **text fields** (name, brand, model, description, notes, serial, condition, purchase year); the model is permitted to run **web searches** on them | The item's **photos** |
| **Per-item chat** | The item's descriptive text + your messages | The item's **photos** |

The appraiser and per-item chat use an Anthropic Messages transport, so they run only
against **your Anthropic key** (or the hosted proxy, where compiled in) — never against
the Ollama or OpenAI-compatible tiers.

## Data safety at the edges (defense in depth)

Being local isn't enough if a bad input can corrupt the local store, so the ingest
paths are hardened:

- **Imports are sandboxed and transactional.** A restored backup or an incoming sync
  changeset can only reference files inside the sanctioned media directories, and the
  whole import runs in one transaction. A crafted payload cannot point a file path at
  the database and wipe it. See [ADR-0006](adr/0006-import-db-safety.md).
- **Sync merges fail safe.** A stale or malicious LAN peer cannot clobber a newer local
  edit or resurrect a deleted item — last-writer-wins by HLC only ever accepts strictly
  newer rows. See the [yellow paper](spec/yellow-paper.md).
- **The sync server never logs secrets.** Its request logger (debug builds only) records
  method + path, never headers (which carry the Bearer secret) or bodies.
- **Exports are safe to open elsewhere.** CSV export neutralises spreadsheet formula
  injection (a leading `=`/`+`/`-`/`@` is escaped) so opening your inventory in Excel or
  Sheets can't execute a payload.

## How to verify (don't take our word for it)

- **Airplane mode.** Turn off Wi-Fi and mobile data. Every core feature — add, edit,
  search, dashboard, export to file, PDF report — still works. Nothing degrades to a
  spinner. That's the local-first guarantee, observable directly.
- **Read the switches.** Settings names every egress feature (AI Analysis, Barcode
  Lookup, Sync & Backup, WebDAV) and states "No telemetry. No ads. Your data stays on
  your device."
- **Read the source.** Network calls are confined to a handful of files —
  `lib/services/ml/` (the tier providers + `hosted_messages_client.dart`),
  `lib/services/appraisal/messages_transport_adapter.dart` (appraiser/chat),
  `lib/services/product_lookup/`, `lib/services/backup/webdav_backup_service.dart`,
  `lib/services/sync/` and `lib/services/network/` (LAN sync + LAN mDNS discovery),
  `lib/features/settings/data/llm_connection_tester.dart` (only when you press Test
  Connection), and `lib/features/billing/` (Pro — fail-closed by default). Grep for
  `Dio`/`http` and you will find no other egress, and no analytics endpoints at all.
- **Watch the network.** Point a LAN proxy at the device; with all opt-in features off,
  you'll see no outbound traffic.

## What this model does *not* claim

- It does **not** encrypt sync on the wire — LAN sync trusts your local network.
- It does **not** hide metadata from a WebDAV server *you* configure — your server sees
  your backup (that's the point; you chose it).
- Tiers 3 and 4 send data to third parties **you** enable; their handling is governed by
  *their* policies, not this app's. Choose them knowingly.
