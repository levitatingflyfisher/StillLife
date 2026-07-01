# ADR-0007: Encrypt the LAN-sync wire and add encrypted backups (sanctuary)

- **Status:** Accepted
- **Date:** 2026-07-12

## Context

Two plaintext gaps sat in an otherwise local-first, privacy-respecting app:

1. **LAN sync was plaintext HTTP.** ADR-0004 shipped device-to-device sync over the
   LAN authenticated by a `Authorization: Bearer <secret>` header, with the changeset
   body as cleartext JSON. Anyone on the same Wi-Fi could read the entire inventory in
   flight, and the Bearer check used a non-constant-time string compare (yellow-paper
   §6/§7 flagged both). A home inventory — serial numbers, values, policy numbers,
   addresses — is exactly the data that must not travel in the clear.
2. **The only "backup" was an unencrypted JSON share.** Settings → Export Data writes
   the whole catalogue as a plaintext `.json` through the OS share sheet. There was a
   disabled "Database Encryption — planned" placeholder and nothing behind it.

The fleet now has a shared crypto core (`sanctuary_auth_core`: HKDF, ChaCha20-Poly1305,
the OHBK backup format) and a drop-in backup UI (`sanctuary_backup_ui`). The decision is
how to close both gaps on those primitives without a server, without breaking the
existing pairing UX, and without a web-build regression.

## Decision

### 1. LAN sync — encrypt the body, fail closed

- **Frame.** `/sync/export` and `/sync/import` bodies become binary AEAD frames
  (`application/octet-stream`): `nonce(12) ‖ ciphertext ‖ mac(16)`, sealed by
  `EnvelopeCipher` (ChaCha20-Poly1305) via a thin `SyncCodec` seam. Binary framing (not
  base64-in-JSON) avoids the +33 % expansion that would trip the 20 MB import cap.
- **Key.** A 32-byte key HKDF-derived from the **existing** shared sync secret:
  `KeyDerivation.deriveKey(utf8(syncSecret), domain: 'stilllife.lan.v1')`. The pairing
  UX is unchanged and the secret survives the upgrade — no re-pairing.
- **AAD.** `stilllife-lan/v1 | <endpoint> | <proto>`, with `<endpoint>` ∈
  {`export`, `import`}. This binds each frame to its endpoint, so an export frame can
  never be replayed against import (or vice-versa).
- **Replay.** `/sync/status` issues a fresh single-use **challenge** (server-tracked,
  TTL-bounded set). A push must echo one the server issued and has not yet consumed; the
  challenge is bound into the import AAD *and* checked-then-consumed before decrypt, so a
  replayed import is rejected `401` with **no DB mutation**.
- **Auth.** The Bearer gate is **gone**. Producing a frame that opens under the shared
  key *is* the proof of pairing (AEAD possession), which retires the non-constant-time
  compare.
- **Negotiation / fail-closed.** `/sync/status` stays a minimal cleartext probe —
  now `{nodeId, hlc, proto: 2, challenge}`, dropping the old `deviceName` + `itemCount`
  leak — and the mDNS TXT record advertises `proto`. A peer that cannot speak `proto ≥ 2`
  is **refused** ("Update StillLife on your other device to sync securely."). The server
  rejects any unframed/plaintext body `400`. There is no plaintext fallback path.

### 2. Encrypted backup — `.ohbk` metadata + `.ohbkz` container

- **Metadata `.ohbk`** via `sanctuary_backup_ui`: `StillLifeBackupSerializer.dumpAll` is
  the existing JSON export envelope (`photosIncluded:false`), OHBK-sealed under context
  `stilllife-backup/v1`, app-domain `stilllife`. `restoreAll` validates the envelope
  (reject wrong app / future schema) then `importFromJson(lww:false)`.
- **Restore is an upsert-merge, not a wipe.** `importFromJson(lww:false)` overwrites
  matching rows by id and leaves absent BLOB columns untouched. This is a **conscious
  deviation from the destructive-replace convention**: a metadata restore that wiped
  first would null every photo/receipt BLOB the metadata backup deliberately omits. The
  restore-confirmation copy says so honestly ("merges … overwriting records with the same
  id; photos already on this device are kept") — no "erase everything" button over an
  operation that doesn't erase.
- **`.ohbkz` container** (the chunked-media pilot): a ZIP holding `metadata.ohbk` plus
  `photos/<id>.ohbk` and `receipts/<id>.ohbk`, each BLOB individually OHBK-sealed under
  context `stilllife-photo/v1`, each ≤ 10 MB — the container never exceeds sanctuary's
  single-blob format; media is chunked across entries. Import detects zip vs bare `.ohbk`
  by magic bytes, enforces zip-bomb guards (entry-count + per-entry + total declared-size
  ceilings, before decompression), restores metadata first, then re-attaches BLOBs by id.

## Consequences

- **Buys:** the LAN wire and all backups are confidential and tamper-evident; a replayed
  push cannot mutate the DB; unpaired/old devices fail closed with a clear message; photo
  backups are possible without exceeding the 10 MB blob format; the existing pairing UX
  and plaintext-JSON export both survive unchanged.
- **Costs:** old (plaintext `proto 1`) and new builds cannot interoperate — a household
  mid-upgrade must update both devices. Pure-Dart ChaCha runs on the main isolate, so a
  very large export/container has a perceptible (non-streaming) crypto pass.
- **Forecloses:** nothing new; sync stays serverless and LAN-only (ADR-0002/0004).

### Honest scorecard (what this is NOT)

- **No forward secrecy.** The frame key is a *static* key derived from the shared
  secret; sanctuary exports no X25519/ECDH, so there is no ephemeral handshake. A future
  compromise of the sync secret exposes past captured frames. The single-use challenge is
  **replay separation, not forward secrecy** — stated plainly here and in the code.
- **`/sync/export` has no request-side possession proof.** It is a read-only GET with no
  body to authenticate; anyone on the LAN can trigger an export (and its benign `nextHlc`
  increment). Confidentiality holds (the response is ciphertext). **Accepted** for the
  household threat model; gating it is a clean follow-up.
- **`/sync/status` still leaks `nodeId` + `hlc`** in cleartext — the minimum needed to
  negotiate.

## Alternatives considered

- **Fold per-session nonces into the key/AAD (the brief's first suggestion).** Rejected:
  the nonces are exchanged in cleartext and echoed by the client on every request, so a
  replay attacker resends them and the server re-derives the same key — it buys nothing
  against wire replay and would be theatre to call "replay separation." The
  server-tracked single-use challenge is the only construction that earns the name, and
  replay is *not* idempotent here (unstamped/last-received-wins rows —
  `profiles`/`appraisals`/`item_tags` — can regress), so the ~30 extra lines are worth it.
- **BIP39 pairing for sync (fleet-aligned).** Rejected for tonight: it breaks every
  existing pairing and needs new onboarding. The `v-next` option.
- **Base64-in-JSON framing (smallest diff).** Rejected: +33 % blows the 20 MB cap; binary
  is the honest AEAD shape.
- **Destructive wipe-then-restore for `.ohbk`.** Rejected: destroys the photo BLOBs the
  metadata backup omits. Upsert-merge with honest copy is safer and more faithful.
