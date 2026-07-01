# ADR-0003: Drift over sqflite for local storage

- **Status:** Accepted
- **Date:** 2026-07-03 (documenting a decision load-bearing since Phase 1)

## Context

The local database is the heart of a local-first app (ADR-0002), and Still Life leans
on it hard: 17 related tables, full-text search, reactive UI that must update live off
a single write, schema migrations across 11 versions, and a sync layer that needs
per-row conflict metadata. The Flutter ecosystem's obvious options are `sqflite` (a
thin SQLite binding with raw SQL strings) and `drift` (a typed, reactive ORM over
SQLite with code generation).

## Decision

Use **Drift**. Tables are declared in `lib/services/database/tables.dart`, the database
and migrations in `database.dart`, and access is split into 13 DAOs. Code generation
produces the typed row/companion classes and query builders (`*.g.dart`).

Consequences we lean on specifically:

- **Reactive streams** — Drift's `watch` queries drive the live inventory list,
  dashboard totals, and search off one write, with no manual invalidation.
- **Typed migrations** — the `onUpgrade` ladder (v1→v11) is explicit and testable,
  including the addition of CRDT stamp columns (ADR-0004) and FTS5 triggers.
- **`insertOnConflictUpdate`** gives clean idempotent upserts, which the import/sync
  merge relies on.

## Consequences

- **Buys:** compile-time-checked queries, reactive reads for free, first-class
  migrations, and testable database logic (`AppDatabase.memory()` for unit tests). The
  DAO split keeps query logic out of the UI.
- **Costs:** a code-generation step (`build_runner`) that *must* be run after any schema
  or annotation change — forget it and the build breaks. More up-front ceremony than
  raw SQL for a one-off query.
- **Forecloses:** ad-hoc raw-SQL sprawl in the UI layer. Raw statements still appear
  where needed (FTS5 triggers, the HLC comparison in `import_service`), but as
  deliberate exceptions.

## Alternatives considered

- **sqflite + hand-written SQL** — rejected: no reactivity, no type safety, and
  migrations/FTS become error-prone string juggling at this table count.
- **A NoSQL/document store (Hive, Isar)** — rejected: the data is deeply relational
  (property → room → container → item, with policies, loans, receipts, price history),
  and SQL's joins/constraints/FTS are exactly the right tools.
