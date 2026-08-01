# Architecture Decision Records

An ADR captures **one architectural decision**: the context that forced it, the
choice made, and the consequences we accepted. They are immutable once accepted — if a
decision is revisited, add a *new* ADR that supersedes the old one (and mark the old
one `Superseded by ADR-NNNN`) rather than editing history.

Read these when you're about to change something load-bearing and want to know whether
you're fixing a mistake or unknowingly reopening a settled trade-off.

## Index

| # | Decision | Status |
|---|---|---|
| [0001](0001-flutter-clean-architecture.md) | Flutter + Clean Architecture (domain / data / presentation) | Accepted |
| [0002](0002-local-first-no-account.md) | Local-first, no account required for core functionality | Accepted |
| [0003](0003-drift-over-sqflite.md) | Drift over sqflite for local storage | Accepted |
| [0004](0004-lan-sync-hlc-lww.md) | LAN sync via HLC last-writer-wins, not a cloud account | Accepted — transport superseded by [0007](0007-sync-and-backup-encryption.md) |
| [0005](0005-boot-resilience.md) | Boot survives a transient DB-open failure instead of bricking | Accepted |
| [0006](0006-import-db-safety.md) | Import is sandboxed and transactional | Accepted |
| [0007](0007-sync-and-backup-encryption.md) | The sync wire and the backup file are both encrypted, and fail closed | Accepted |

## Writing a new one

Copy [`0000-template.md`](0000-template.md) to the next number, fill it in, add a row
above. Keep it to ~one screen — an ADR that needs scrolling is two ADRs.
