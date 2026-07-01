# Concepts

The ideas and the domain model behind Still Life, in prose. For the exact tables and
columns, see [reference/data-model.md](reference/data-model.md); for the merge
semantics, the [yellow paper](spec/yellow-paper.md).

## The catalogue is a place hierarchy

Still Life models a home the way you'd actually search it — *where is the thing?* — not
as a flat list:

```
Property (your home)
  └─ Room (Kitchen, Garage, Attic…)
       └─ Storage container (a shelf, box, drawer, cabinet)   ← optional
            └─ Item (the drill, the painting, the ski boots)
```

- A **Property** is a home. Most users have one; the model allows several (a house and
  a rental).
- A **Room** groups items by where they live. Rooms can nest (a `parentId`).
- A **Storage container** is a shelf/box/drawer *within* a room — the difference between
  "it's in the garage" and "it's in the blue bin on the top shelf of the garage."
  Competitors show flat lists; the container hierarchy is where Still Life earns its
  keep.
- An **Item** is a single possession, filed under exactly one room (and optionally one
  container).

Cross-cutting the hierarchy, **categories** (a tree) and **tags** (flat, many-to-many)
let you slice the catalogue by *kind* rather than *place* — "all electronics", "things
tagged fragile."

## An item is a small dossier

Each item carries what an insurance claim or a resale would need: name, description,
category, room/container, condition, serial number, barcode, warranty expiry, store
URL, notes, quantity (for consumables), and a low-stock threshold. Attached to it:

- **Photos** — image files (camera or import) with one marked primary.
- **Receipts** — a photo plus OCR-extracted store, date, and total.
- **Price history** — a time series of values, so every item detail page can chart how
  its worth has moved.

## Value, depreciation, and insurance

Three distinct money figures live on an item, because insurance policies care about the
difference:

- **Purchase price** — what you paid.
- **Current value** — what it's worth now (depreciated).
- **Replacement cost** — what it would cost to replace.

The **dashboard** aggregates these into household totals, value-by-room, value-by-
category, a depreciation view, and a 6-month acquisition trend. **Insurance policies**
record provider, coverage amount, deductible, premium, and expiry; a **coverage-gap**
service surfaces high-value items with no policy attached ("what should I insure?").
The **appraiser** can estimate a current or replacement value via an LLM (see below).

## The CRDT stamp (how a row learns to sync)

Every table that participates in sync carries three extra columns:

- **`nodeId`** — which device last wrote the row.
- **`hlc`** — a Hybrid Logical Clock timestamp: a monotonic, causally-ordered clock
  (from the `crdt` package) that survives clock skew between devices. HLC strings sort
  lexicographically, which is what makes last-writer-wins deterministic.
- **`isDeleted`** — a soft-delete tombstone. Deleting an item flips this flag rather
  than removing the row, so the *deletion* can propagate across devices and win like any
  other edit. All read queries filter tombstones out.

Together these turn an ordinary row into a syncable one: two devices can reconcile by
keeping, per row, the version with the greater HLC. See
[ADR-0004](adr/0004-lan-sync-hlc-lww.md).

## QR labels: memorable IDs

Any item or container can mint a printable **QR label** whose payload is a
human-readable ID in **`adjective-adjective-noun`** form (e.g. `oaken-low-rafter`),
derived deterministically from the row's UUID (~1M unique combinations). Stick the
label on the box; later, scan it to jump straight to the detail screen. The point is
recall: `oaken-low-rafter` is something a person can read aloud and find, where a raw
UUID is not.

## Search

Full-text search runs against an SQLite **FTS5** virtual table (`items_fts`) kept in
sync by triggers, covering name, description, notes, serial number, and barcode.
Layered on top is a natural-language query parser (extract room / category / price
range / date range from free text) and saved searches.

## The four AI tiers

AI cataloguing (identify an item from a photo, or estimate its value) is a **cascade of
four provider tiers**, tried in a user-configurable order that defaults to most-private
first:

1. **On-device** — no network. *Not implemented yet:* the provider reports itself
   unavailable and the cascade skips it — no model ships and nothing is returned,
   placeholder or otherwise (see [limitations](limitations.md)).
2. **Local LLM** (Ollama) — talks to a model running on your own machine on the LAN.
3. **Cloud API (your own key)** — calls a major third-party model API directly, using
   an API key *you* supply. Your image/prompt goes to the provider you chose.
4. **Hosted proxy** — a first-party paid tier that proxies requests so you don't need
   your own key (opt-in, off by default; the backend lives in `server/hosted-llm/`).

The **appraiser** (resale value / replace-new / replace-equivalent) and the per-item
**chat** ride the same transports — an LLM call, cached with a TTL, *not* live
marketplace scraping. Tiers 3 and 4 are the only ones that send your data off the
device, and only when you enable them; see the [privacy model](privacy-model.md).

## Profiles (a shared household)

Multiple named **profiles** can live in one app instance so a household can attribute
items to who created or owns them, without anyone creating an account. Profiles are
just rows; they carry no authentication and no cloud identity.
