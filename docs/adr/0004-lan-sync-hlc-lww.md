# ADR-0004: LAN sync via HLC last-writer-wins, not a cloud account

- **Status:** Accepted
- **Date:** 2026-07-03 (documenting the Phase 7 sync design + the LWW hardening)

## Context

Households have more than one device, so the catalogue must be able to travel between
them. But ADR-0002 forbids a mandatory cloud account, and a home inventory is too
private to route through a third-party server. That rules out the usual sync answer (a
central backend that everyone reads and writes). We need multi-device reconciliation
with **no server in the middle** and a deterministic, safe resolution of concurrent
edits made on different devices while offline.

## Decision

Sync **device-to-device over the local network**, resolving conflicts with **per-row
last-writer-wins ordered by a Hybrid Logical Clock (HLC)**:

- Every syncable row carries three stamp columns: `nodeId` (which device wrote it),
  `hlc` (a monotonic hybrid logical clock, from the `crdt` package), and `isDeleted`
  (a tombstone — deletes are soft, so a deletion can propagate and win like any edit).
- Peers discover each other by mDNS (`_stilllife._tcp`, port 8420) and talk plain HTTP
  over the LAN, authenticated by a **shared secret Bearer token** (≥ 16 chars) the
  user copies between devices. There is **no cloud relay**.
- A sync is a symmetric exchange of full-state changesets. On receipt, an incoming row
  is applied **only if its HLC is strictly greater** than the local row's — so a stale
  peer can neither overwrite a newer local edit nor resurrect a newer tombstone. HLC
  strings sort lexicographically, giving a total, deterministic order.

The precise semantics — objects, the merge decision procedure, the wire format, and the
fail-safe rules — are specified in the [yellow paper](../spec/yellow-paper.md).

## Consequences

- **Buys:** multi-device sync with zero cloud, zero account, and deterministic conflict
  resolution that's safe against offline edits and clock skew. The private list never
  leaves the user's own network.
- **Costs / honest edges:**
  - It is **state-based**: each sync ships a full snapshot, so bandwidth grows with the
    library. Delta sync is a known future problem.
  - It is **per-row**, not per-field: two devices editing *different* fields of the
    same item will keep only the newer row wholesale — the older device's field change
    is lost.
  - The transport is **plaintext HTTP on the LAN** — it trusts the local network. It is
    not end-to-end encrypted and does not go beyond the LAN.
    **Superseded by [ADR-0007](0007-sync-and-backup-encryption.md):** the wire is now
    AEAD-framed with no plaintext fallback. Left standing as written, because an ADR
    records what was decided at the time; the correction belongs in the record that
    changed it, not painted over the one it replaced.
  - Sync currently moves **database rows, not the photo/receipt image files**; media
    does not yet propagate.
- **Forecloses:** a cloud-account sync model. Any future beyond-LAN sync must preserve
  zero-knowledge-relay properties (see VISION horizons), not become a readable server.

## Alternatives considered

- **Cloud backend sync** — rejected by ADR-0002.
- **A full operation-based CRDT store** — deferred: the `crdt` package supplies the HLC,
  but the row reconciliation is a hand-rolled LWW filter in `import_service` rather than
  a complete CRDT. This is simpler and sufficient for last-writer-wins, at the cost of
  per-field merge; revisiting it is the natural path to delta sync.
- **`modifiedAt`-timestamp LWW** — rejected: wall-clock timestamps are not monotonic
  across devices and break under clock skew; an HLC is the correct causal ordering.
