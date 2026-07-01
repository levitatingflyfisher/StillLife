# ADR-0001: Flutter + Clean Architecture (domain / data / presentation)

- **Status:** Accepted
- **Date:** 2026-07-03 (documenting a decision load-bearing since Phase 1)

## Context

Still Life is a mobile-first app that must run cross-platform (Android today; iOS,
desktop, and web are all realistic targets) from one codebase, with a rich, offline,
reactive UI over a local database. It is also intended to live for years and take
contributions, so the code has to stay legible as features multiply (inventory,
sync, AI, billing, appraisal, …). Two questions had to be answered up front: *what UI
toolkit* and *how to keep a growing feature set from turning into a mud-ball*.

## Decision

Build on **Flutter**, and structure the code in **Clean Architecture** layers, sliced
by feature:

- `lib/features/<feature>/domain/` — entities and repository *interfaces*. No Flutter,
  no Drift. Pure Dart.
- `lib/features/<feature>/data/` — repository *implementations* backed by Drift DAOs.
- `lib/features/<feature>/presentation/` — Riverpod controllers + Flutter screens.
- Cross-cutting services (`lib/services/`) and DI (`lib/core/providers/`) wire the
  concrete implementations to the interfaces at the edges.

The dependency rule is one-directional: presentation and data depend on domain; domain
depends on nothing app-specific.

## Consequences

- **Buys:** one codebase for every platform; features are testable in isolation (the
  domain layer has no framework to mock); the ~123-file test suite can exercise
  repositories and controllers without a running app; new contributors learn one shape
  and reuse it per feature.
- **Costs:** more files and more indirection than a screen-driven app — a trivial
  feature still pays for three layers. Some presentation-only features (labels,
  onboarding) legitimately skip domain/data, which is a permitted exception, not a
  violation.
- **Forecloses:** business logic in widgets; direct Drift access from the UI.

## Alternatives considered

- **A native Android/iOS split** — rejected: doubles the surface for a small team and
  defeats "one recipe" portability.
- **A flat, screen-first Flutter app** (logic in widgets/providers) — rejected: fine at
  five screens, unmaintainable at fifty; the layering is what keeps sync/AI/billing
  from bleeding into the inventory UI.
