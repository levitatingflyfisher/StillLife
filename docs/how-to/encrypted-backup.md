# How to make an encrypted backup

Goal: keep a safe, portable copy of your inventory that **only you can read** — no
account, no cloud, protected by 12 recovery words you hold.

Still Life has two backup shapes. Pick by what you need:

| | What it holds | File | Use it for |
|---|---|---|---|
| **Encrypted backup** | Inventory records (no images) | `stilllife-backup-<date>.ohbk` | A small, frequent safety copy |
| **Export with photos** | Records **+** photo/receipt images | `stilllife-backup-<date>.ohbkz` | A complete copy before wiping/switching phones |
| Export Data (plaintext) | Inventory records, **unencrypted** | `still_life_backup_<time>.json` | Moving data to another tool you trust |

All three live under **Settings → Encrypted Backup**. The plaintext JSON export stays in
**Data Management** and is clearly labelled unencrypted.

## First: set up your recovery words

1. **Settings → Encrypted Backup → Set up encrypted backup.**
2. Write down the **12 words** shown. They *are* your key — there is no server that holds
   a copy, and no way to reset them. Store the paper somewhere safe.
3. Re-enter the words to confirm your copy is correct. Backup and restore unlock now.

## Make a backup

- **Encrypted backup** → shares a `.ohbk` file (records only — small).
- **Export with photos** → shows a size estimate first (how many images, roughly how
  large), then shares a `.ohbkz`. Images over 10 MB are skipped and reported, never
  silently dropped. Save the file wherever you keep backups (another device, a drive, a
  private cloud folder — the file is already encrypted).

## Restore

- **Restore from backup** (records only) or **Restore with photos** (accepts `.ohbkz`
  *and* `.ohbk`).
- If this device already has your recovery words, it unlocks the backup directly.
  Otherwise — a new phone, or a backup made under different words — you'll be asked to
  type the 12 words from when the backup was made.
- Restore **merges** the backup in, overwriting records that share an id. Photos already
  on this device are kept, and items you added since the backup stay put. It is **not** a
  wipe.

## What protects it

- Everything is sealed with **ChaCha20-Poly1305**; the key is derived from your 12 words
  (HKDF). A wrong word means "We can't read your data" — a calm, specific error, never a
  partial restore.
- A blob made for one purpose can't be opened as another: a photo can't be read as the
  metadata, and a Still Life backup can't be opened by another app — the crypto rejects
  the swap.
- The details live in [ADR-0007](../adr/0007-sync-and-backup-encryption.md).
