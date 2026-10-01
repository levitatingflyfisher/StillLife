# Still Life — Yellow Paper

*A formal specification of the synchronisation core: the changeset wire format, the
HLC last-writer-wins merge, and the import data-safety invariants.*

**Register.** "Yellow paper" is the convention for a rigorous formal specification
(after Wood's *Ethereum Yellow Paper*). This document plays that role for Still Life's
sync and import core. It is precise about *intent and current behaviour*; it is **not** a
machine-checked proof. Where a property is tested-and-intended rather than mechanically
verified, it says so. The code it describes was authored by an AI assistant — treat it
as the current implementation to be checked against this spec, not as an oracle.

For the intuition, read [architecture/OVERVIEW.md](../architecture/OVERVIEW.md) and
[concepts.md](../concepts.md) first; for *why*, [ADR-0004](../adr/0004-lan-sync-hlc-lww.md)
and [ADR-0006](../adr/0006-import-db-safety.md).

> **Addendum (2026-07-12) — the sync wire is now encrypted.** This paper specifies the
> *changeset semantics and merge* (unchanged). The transport it rides on is no longer
> plaintext HTTP + Bearer: `/sync/export` and `/sync/import` bodies are now binary AEAD
> frames (ChaCha20-Poly1305) under a key derived from the shared code, `/sync/status`
> negotiates a `proto`/challenge, and old plaintext peers are refused. The wire format,
> the single-use replay challenge, and the honest scorecard (no forward secrecy;
> `/sync/export` possession accepted) are in
> [ADR-0007](../adr/0007-sync-and-backup-encryption.md). The plaintext-body §§ below
> describe the *pre-encryption* changeset that is sealed into each frame.

---

## 1. Notation

We write `≻` for the strict last-writer-wins order on stamps, `⊤`/`⊥` for the
accept/reject outcome of a per-row decision, and `∅` for "no local row." `⊕` denotes the
per-row merge join. Hybrid-Logical-Clock values are compared as strings under
lexicographic order `<ₗₑₓ`; the encoding (zero-padded `wall.counter.nodeId`) is chosen so
that lexicographic order coincides with causal-then-tiebreak order. All decision
procedures are **fail-safe toward the local replica**: when the winner is undetermined,
the incoming row is *not* applied (the local row is kept).

## 2. Objects

### 2.1 Stamp

Every syncable row carries a **stamp** `σ = ⟨nodeId, hlc, isDeleted⟩`:
- `nodeId ∈ String` — the device UUID that last wrote the row (persistent, in secure
  storage).
- `hlc ∈ String` — a Hybrid Logical Clock timestamp (from the `crdt` package):
  `Hlc = ⟨wallTime, counter, nodeId⟩`, monotonic and skew-tolerant, serialised so that
  `hlc₁ <ₗₑₓ hlc₂` iff `hlc₁` causally-or-tiebreak precedes `hlc₂`. The empty string `""`
  denotes an **unstamped** (legacy/pre-sync) row.
- `isDeleted ∈ Bool` — a soft-delete **tombstone**. A deletion sets `isDeleted := ⊤`; it
  never removes the row, so a deletion is an ordinary edit that can propagate and win.

### 2.2 Row and table

A **row** `r` is `⟨id, σ, payload⟩` with `id ∈ String` a client-assigned UUID (§ why UUID:
6.4). A **syncable table** `T` is a set of rows keyed by `id`. The **LWW table set**
`𝒯_lww` is the 15 tables filtered during a merge (§4.2), i.e. every synced table:

```
{ properties, rooms, storage_containers, categories, tags, items,
  photos, receipts, price_history_entries, policies, maintenance_logs, loans,
  profiles, appraisals, item_tags }
```

`item_tags` is keyed by the pair `(item_id, tag_id)` instead of `id`: one row per pair,
stamped, with a tombstone, so tag links are an LWW-element-set (a remove and a re-add of
the same tag are decided by time). Local writes never hard-delete a link; removing a tag,
deleting an item or deleting a tag tombstones the links, stamped. A link tombstoned by
its item's delete also carries `deleted_with_item_at` (the item tombstone's
`modifiedAt`), synced with the row, so restoring the item revives exactly those links. (Add-wins was the
alternative; it needs a unique id per add, which the pair key cannot hold.)
`video_analyses` and `product_lookup_cache` are not synced. *(2026-09: `profiles`, then
`appraisals` and `item_tags`, joined `𝒯_lww` once their local writes were stamped.)*

### 2.3 Clock

The local clock `C` is an HLC held in memory and persisted. Two operations:
- `next(C)` — `C := increment(C)`; persist; return `C`. Used before *sending* state.
- `merge(C, h)` — `C := max_lex(C, h)`; persist; return `C`. Used after *receiving*
  state. Persisting after every `merge` is what keeps the clock from regressing across a
  restart.

### 2.4 Changeset (the wire object)

A **changeset** is `χ = ⟨senderNodeId, senderHlc, data⟩` where `data` is a map from table
name to a list of serialised rows (a full snapshot of the sender's syncable state).
Serialised as JSON:

```json
{ "senderNodeId": "<uuid>", "senderHlc": "<hlc>", "data": { "items": [ … ], … } }
```

## 3. The last-writer-wins decision

For an incoming row with id `i` and stamp hlc `h_in` targeting table `T`, the predicate
`shouldWrite(T, i, h_in)` decides whether it is applied over the local row (local hlc
`h_loc`, or `∅`):

```
shouldWrite(T, i, h_in) =
    ⊥,                       if wall(h_in) > now + Δ  -- (L0) stamped too far ahead: hold back
    ⊤,                       if localRow(T, i) = ∅    -- (L2) no local row: fill the hole
    ⊥,                       if h_in = ""             -- (L1) unstamped incoming: never overwrite
    ⊤,                       if h_loc = ""            -- (L3) local unstamped: stamped row wins
    ⊤,                       if h_in >ₗₑₓ h_loc       -- (L4) incoming strictly newer
    ⊥,                       otherwise                -- (L5) local newer-or-equal: keep local
```

The cases are tried top to bottom. A stamp that does not parse as an HLC counts as `""`
(as a raw string, `"zzz"` would sort after every real stamp and win forever).

Rule **(L4)** is the heart: an incoming row is applied **only if strictly greater** by
HLC. Ties (`h_in = h_loc`) keep local (L5); because an HLC embeds its `nodeId`, two
*distinct* concurrent writes never produce equal strings, so a tie means the *same* write
and keeping local is both correct and idempotent.

Rule **(L1)** is Peckish's `_wins` rule, adopted 2026-09: an unstamped row can only fill a
hole. Before, an unstamped incoming row blind-applied, so any peer could bypass LWW by
sending `hlc: ""`.

Rule **(L0)** is the future-clock bound, `Δ = ImportService.maxFutureSkew = 10 min` (the
sync kernel design's `MAX_FUTURE_SKEW`). It applies even to a hole: a row stamped a year
ahead would otherwise win every later edit of that row. The row is held back, not
rejected: every changeset is a full snapshot, so the peer offers it again next sync and
it lands once local time has caught up (`now` is this device's wall clock).

## 4. The merge

`merge(χ)` applies a received changeset to the local database. It is
`apply` → `importFromJson(·, lww=⊤)` → `merge(C, χ.senderHlc)`.

### 4.1 Structure
```
merge(χ):
    j        := { version:"1.0", app:"still_life", data: χ.data }
    result   := importFromJson(j, lww=⊤)     -- §4.2–4.3, transactional
    C        := merge(C, χ.senderHlc)         -- advance local clock
    return result
```

### 4.2 Stage 1 — LWW filter
Before any write, for each `T ∈ 𝒯_lww` and each incoming row `r ∈ χ.data[T]`, drop `r`
unless `shouldWrite(T, r.id, r.hlc)`. Rows in tables ∉ `𝒯_lww` are not filtered here.

Then, walking tables parents-first, drop every surviving row whose non-null foreign key
names a parent that is neither stored locally (tombstoned counts) nor surviving in `χ`.
SQLite enforces the declared foreign keys (`PRAGMA foreign_keys = ON`, set in
`beforeOpen`), so such an orphan would otherwise fail the whole merge. A child therefore
waits with a parent held back by (L0), transitively (room → items → photos), and lands on
a later sync once the parent does. The merge counts what (L0) and this step held back
and the sync line says it ("3 changes wait for a later sync"), so a sync with rows
waiting does not read as complete. The references are read from `PRAGMA
foreign_key_list`, so this step cannot drift from the schema. A file import (`lww=⊥`)
does not drop orphans: one orphan fails the import and nothing is written.

### 4.3 Stage 2 — transactional upsert
Inside **one** database transaction (§5, invariant **A**), insert the surviving rows in
**foreign-key dependency order** (properties → rooms → storage_containers → categories →
tags → profiles → items → loans → item_tags → photos → receipts → price_history →
policies → maintenance_logs → appraisals), each via `insertOnConflictUpdate` (an upsert
keyed by `id`). Because Stage 1 already discarded every losing row, the upsert only ever
writes winners, so:

> **(LWW soundness, intended.)** After `merge(χ)`, for every `T ∈ 𝒯_lww` and id `i`, the
> stored row is the `≻`-greater of the pre-merge local row and `χ`'s row — never a
> strictly-older overwrite, and never a resurrected newer tombstone.
> Two deliberate exceptions (§3): a row stamped beyond the future bound is held back
> (L0), and an unstamped incoming row never replaces an existing local row (L1).

### 4.4 The per-row join
The effective join is a **last-writer-wins register at row granularity**:

```
r_local ⊕ r_in =  r_in,     if shouldWrite(·, id, r_in.hlc)
                  r_local,  otherwise
```

`⊕` is commutative and idempotent on `𝒯_lww` under the total order `<ₗₑₓ` (with `nodeId`
as an embedded tiebreak). It is **not** per-field: the winning row replaces the loser
wholesale, so a concurrent edit to a *different field* of the loser is discarded (§6.1).

## 5. Import data-safety invariants

`importFromJson` is the sole ingest path for restores, WebDAV fetches, **and** LAN sync
changesets — i.e. partially-untrusted input. It upholds:

- **(A) Atomicity.** The entire multi-table upsert runs in one transaction; any exception
  rolls back. There is no half-applied state.
- **(B) Schema gate.** Reject before opening the transaction unless `app = "still_life"`
  and `version ≠ null`.
- **(C) Path sandbox.** Any file path a row references (`photos.filePath`,
  `receipts.photoPath`, `rooms.photoPath`) must resolve **within** one of the sanctioned
  media subdirectories `{photos, thumbnails, receipts}` of the app documents directory —
  checked by normalised `p.isWithin`, rejecting absolute escapes and `..` traversal. A
  violating photo/receipt row is **skipped**; a violating room photo is **nulled**.
  - *Rationale (the closed hole):* the SQLite file `still_life.db` lives in the documents
    **root**, not a media subdir. Validating against the whole root let a crafted import
    point a `filePath` at the database; a later row delete would `unlink` it and wipe the
    database. Restricting to media subdirs makes the database file unreferenceable.
- **(D) Merge vs. restore.** `lww=⊤` (sync merge) runs the §4.2 filter so a stale peer
  can't clobber newer data; `lww=⊥` (backup restore) intentionally replaces wholesale.
  Both share (A)–(C).

> **(Import safety, intended.)** No importable payload — including a changeset from an
> authenticated-but-malicious LAN peer — can (i) leave the database partially written,
> (ii) reference a file outside the media directories, or (iii) cause deletion/corruption
> of `still_life.db`.

## 6. The transport & protocol

> **Superseded wire (see the addendum above and ADR-0007).** The table and the
> Authentication bullet below describe the original plaintext transport. Today
> `/sync/status` returns `{nodeId, hlc, proto, challenge}`, the export and import bodies
> are AEAD frames, and possession of the key replaces the Bearer gate. The merge
> semantics are unchanged.

The LAN sync server (`shelf`, bound `0.0.0.0:8420`) exposes three endpoints behind a
shared-secret gate:

| Method · path | Body | Effect |
|---|---|---|
| `GET /sync/status` | — | `{nodeId, hlc, itemCount(live), deviceName}` (read-only; no clock side-effect) |
| `GET /sync/export` | — | a full-snapshot changeset; advances the sender clock via `next(C)` |
| `POST /sync/import` | changeset JSON | `merge(χ)`; returns `{recordsApplied[, error]}` |

- **Authentication.** Every request requires header `Authorization: Bearer <secret>`
  where `<secret>` is the shared sync code (≥ 16 chars, §6.3). Mismatch ⇒ `401` before
  any handler runs.
- **Body bound.** `/sync/import` rejects a payload `> 20 MB` (declared `Content-Length`
  pre-check and post-read length check) with `413`.
- **Merge failure isolation.** A changeset that fails to parse or merge returns `422`/
  `500` with the reason; by (A) the local database is unchanged. Each peer exchange is an
  independent call, so one bad peer cannot corrupt the replica or a different peer's sync.
- **Log redaction.** The request logger (debug builds only) records method + path,
  **never** headers (which carry the secret) or bodies.

A full sync `syncWith(peer)` is symmetric: **pull** the peer's export and `merge` it,
then `next(C)`, export local state, and **push** it for the peer to `merge`. Because `⊕`
is commutative/idempotent, repeated pairwise syncs drive both replicas toward the per-row
`≻`-max over `𝒯_lww` (eventual convergence on that table set).

## 7. What is guaranteed — and what is not

**Guaranteed (by construction + test):**
- **LWW soundness** (§4.3): a merge never overwrites a strictly-newer local row nor
  resurrects a strictly-newer tombstone, over `𝒯_lww`.
- **Import safety** (§5): atomic, schema-gated, path-sandboxed; the database file cannot
  be referenced or wiped by an import.
- **Deterministic resolution:** the `<ₗₑₓ` order with embedded `nodeId` is total on
  distinct writes, so conflicts resolve identically regardless of sync direction/order —
  and hence converge on `𝒯_lww`.
- Covered by `untimestamped_rows_test` (L0–L3), `merge_engine_test`, `crdt_manager_test`, `lan_sync_{server,client}_test`,
  `import_service_path_traversal_test`, and the export/import round-trip tests.

**Not guaranteed / out of scope (honest edges):**
- **Per-row, not per-field.** Concurrent edits to different fields of one row do not
  merge; the newer row wins wholesale and the other field edit is lost.
- **Unstamped rows fill holes only.** *(Updated 2026-09.)* By (L1) a row with
  `hlc = ""` never overwrites a local row on the sync path; it is inserted only where
  the id is absent. By (L3) a stamped incoming row still replaces an unstamped local
  one. Every local write through a repository stamps (`SyncStamp`); unstamped rows now
  come only from writes made while the keystore is unavailable (stamping degrades to an
  unstamped write rather than failing the save) and from an explicit old-file import.
  An explicit file import (`lww=⊥`) still applies unstamped rows wholesale, after the
  UI warns that the file's records will replace the device's own. Two devices that both
  hold an unstamped copy of one id keep their own copies: that row does not converge
  until someone edits it.
- **Seeded defaults sync as the same rows everywhere.** The default categories,
  the first home and its rooms, the consumables starter kit and the import
  fallbacks get an id derived from what they are (UUID v5 of
  `stilllife:seed:<kind>:<key>`) and a fixed stamp `seedHlc` (year 2000, node
  `seed`) that is older than any real edit and non-empty. Two devices that seed
  separately hold identical rows: a sync merges them (a tie keeps local, L5), so
  defaults neither duplicate nor fight, and any real edit beats the seed on every
  device, even one that seeds later. Rows seeded before this change keep their
  random ids; two such devices still show two sets of defaults.
- **State-based, not delta.** A changeset is a full snapshot; there is no incremental
  sync, so cost grows with database size.
- **Media is not state.** Photo/receipt *files* are not in `data` (`photosIncluded:false`);
  replicas converge on metadata only.
- **Transport is encrypted but not forward-secret.** *(Rewritten for ADR-0007; the
  original said "plaintext on the LAN".)* Bodies are ChaCha20-Poly1305 frames under a
  static key derived from the shared code, so confidentiality rests on keeping that code
  secret; a later compromise exposes previously captured frames. The Bearer gate and its
  non-constant-time compare are gone.
- **Clock monotonicity depends on persistence.** If the persisted HLC/secure storage is
  wiped, the clock resets; `merge(C, h)` re-raises it on the next sync, but a replica that
  regresses and writes before syncing could momentarily produce lower stamps.
- **This spec is not machine-verified.** The properties are design intent enforced by
  tests, not a proof. The serialisation/`<ₗₑₓ` correspondence and the path-sandbox
  normalisation are trusted code and the places a bug would hide.

---

*This specification describes the current implementation as authored by an AI assistant.
Discrepancies between this document and the code are bugs in one or the other — verify
against the tests before relying on any stated property.*
