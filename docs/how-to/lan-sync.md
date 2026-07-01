# How to sync two devices over your LAN

Goal: keep the catalogue on two phones (or a phone and a tablet) in step, with **no
account and no cloud** — everything stays on your own Wi-Fi.

## Before you start

- Both devices must be on the **same local network** (the same Wi-Fi).
- Sync moves database **records**, not photo/receipt **image files** — the second
  device will know an item has a photo but won't receive the file itself (see
  [limitations](../limitations.md)).
- This is opt-in: nothing syncs until you do the steps below.

## Steps

1. On **device A**, open **Settings → Sync & Backup** and start LAN sync. The device
   begins advertising itself on the network (mDNS service `_stilllife._tcp`, port
   `8420`) and shows its **sync code** — a shared secret of at least 16 characters.
2. On **device B**, open the same screen and enter (or scan) device A's sync code. Both
   devices must hold the **same** code — it is the shared secret the encryption key is
   derived from, so only devices that hold it can read or write a sync. A too-short code
   is rejected.
3. Device B discovers device A in the peer list. Tap it to sync.

## What a sync actually does

A sync is a **symmetric, bidirectional** exchange:

1. Device B fetches device A's full state and merges it in.
2. Device B then pushes its own full state back, and device A merges that.

The merge is **last-writer-wins per row, ordered by a Hybrid Logical Clock (HLC)**: for
each record, the version with the newer HLC is kept. This means:

- Editing the **same item** on both devices while apart → the **most recent edit wins**
  (whole-row, not a per-field merge).
- **Deleting** an item on one device propagates the deletion (deletes are tombstones, so
  they sync and win like any edit) — a stale peer can't resurrect it.
- A device that's been offline and is **behind** cannot overwrite the newer device's
  data; its stale rows are simply not applied.

The precise rules are in the [yellow paper](../spec/yellow-paper.md).

## Security & privacy notes

- Traffic stays on your LAN — there is **no internet hop and no cloud relay**.
- The wire is **encrypted end-to-end** (ChaCha20-Poly1305): the changeset bodies are
  sealed AEAD frames under a key derived from your shared code, so a device on the same
  Wi-Fi cannot read your inventory in flight, and a tampered frame is rejected without
  touching the database. A replayed push is rejected too (single-use challenge). This
  *replaces* the old plaintext-HTTP + Bearer transport — see
  [ADR-0007](../adr/0007-sync-and-backup-encryption.md). It is not forward-secret (the
  key is static, derived from the shared code); the honest scorecard is in the ADR.
- Both devices must run a build new enough to speak the encrypted protocol; an older
  device is refused with a clear "update your other device" message (fail closed — no
  plaintext fallback).
- The sync server never logs the shared secret or request bodies.
- A malicious or buggy peer still can't corrupt you: incoming data is sandboxed,
  applied in a transaction, and filtered by last-writer-wins
  ([ADR-0006](../adr/0006-import-db-safety.md)).

## Troubleshooting

- **Peer doesn't appear:** confirm both devices are on the same Wi-Fi and that the
  network doesn't isolate clients ("AP isolation"). mDNS must be allowed.
- **Sync fails to decrypt / "can't read":** the two sync codes don't match, so the
  encrypted frames won't open. Re-copy the exact code on both devices.
- **"Update your other device":** one device runs an older, plaintext build. Update both
  to the encrypted-sync version.
- **Photos missing after sync:** expected — media files don't transfer yet. Use a
  file/WebDAV backup to move images, or keep the media on the originating device.
