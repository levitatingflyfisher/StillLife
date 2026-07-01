# ADR-0006: Import is sandboxed and transactional

- **Status:** Accepted
- **Date:** 2026-07-03 (documenting a fix for a crafted-import DB-wipe vector)

## Context

Still Life accepts JSON payloads from three sources that are not fully trusted: a
restored backup file, a WebDAV-fetched backup, and — most importantly — a **sync
changeset from a LAN peer**. All three flow through one code path,
`ImportService.importFromJson`, which upserts rows across every table. Several tables
store *file paths* (photo `filePath`, receipt `photoPath`, room `photoPath`), and the
app later `unlink`s those files when the owning row is deleted.

That combination was exploitable. The app's SQLite file, `still_life.db`, lives in the
*root* of the app documents directory. An earlier version validated import file paths
against that whole documents root — which meant a crafted import could set a row's
`filePath` to point at `still_life.db` itself. A later delete of that row would then
unlink the database file and **wipe the entire inventory.**

## Decision

Harden the single import path with three guards:

1. **Path sandbox.** `_isPathSafe()` accepts a file path only if it resolves *inside*
   one of the dedicated media subdirectories — `photos/`, `thumbnails/`, `receipts/` —
   never the documents root. This structurally prevents any import from referencing the
   database file (or anything else outside the media dirs). Absolute-escape and `..`
   traversal are rejected; unsafe photo/receipt rows are skipped, an unsafe room photo
   is nulled.
2. **Transactional application.** The entire multi-table upsert runs inside one
   `_db.transaction(...)`, so a mid-import failure rolls back cleanly — never a
   half-applied database.
3. **Schema gate before any write.** The payload must declare `app == "still_life"` and
   a non-null `version`, checked before the transaction opens.

Sync merges additionally pass `lww: true` so the HLC last-writer-wins filter (ADR-0004)
runs; a backup *restore* keeps `lww: false` (an intentional wholesale replace). Both
share the same sandbox and transaction guards. Covered by
`import_service_path_traversal_test.dart` and the round-trip tests.

## Consequences

- **Buys:** an untrusted import — including a malicious sync peer on the LAN — cannot
  delete or corrupt the database or reach outside the media directories. Failures are
  atomic.
- **Costs:** legitimate imports that reference files outside the sanctioned media dirs
  are silently dropped; the media-directory layout is now a load-bearing invariant that
  other code must respect.
- **Forecloses:** storing user-referenced files anywhere but the sanctioned media
  subdirectories, and any non-transactional bulk write on the import path.

## Alternatives considered

- **Validate against the whole documents root** — this *was* the original design; it is
  exactly the hole that let a path point at `still_life.db`. Rejected.
- **Trust LAN peers implicitly** (they authenticated with the shared secret) — rejected:
  authentication proves *who*, not *what*; a compromised or buggy peer must still be
  unable to wipe the database. Defense in depth.
