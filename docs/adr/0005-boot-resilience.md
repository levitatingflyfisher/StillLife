# ADR-0005: Boot survives a transient DB-open failure instead of bricking

- **Status:** Accepted
- **Date:** 2026-07-03 (documenting a fix for a real onboarding-brick bug)

## Context

Still Life opens its SQLite file lazily via Drift's `LazyDatabase`, resolving the app
documents directory through `path_provider` (a platform-channel call). On some devices,
that channel is not yet registered the instant it is first called right after launch,
and it throws ("Unable to establish connection on channel").

This interacted catastrophically with a specific `LazyDatabase` behaviour: **it caches
the first open error for the entire session.** A single transient failure therefore
didn't just fail once — it *permanently* broke every database write for the whole app
session, first-run onboarding included. The user would create their first profile,
hit an opaque error, and be trapped on the onboarding screen with no way forward and no
recovery short of killing and relaunching the app. This was a real, observed brick.

## Decision

Make the boot path fail *safe and recoverable*, not fatal:

1. **Bounded retry on directory resolution.** `resolveAppDocumentsDir()` retries
   `getApplicationDocumentsDirectory()` up to 5 times with increasing backoff, giving
   the platform channel time to come up, before throwing a descriptive `StateError`.
   `resolve`/`sleep` are injectable so the retry logic is unit-tested.
2. **Time-boxed, best-effort launch init.** `main.dart` pre-warms the fragile channels
   inside a time-boxed best-effort wrapper, so a hung or throwing channel can't freeze
   the splash screen.
3. **Never trap the user.** `resolveInitialLocation()` never throws (a keystore failure
   defaults to onboarding), and onboarding surfaces the *real* device error and offers
   **"Continue without a profile"** so the first-run flow always has an exit.

Regression tests cover each: `resolve_app_documents_dir_test.dart`, `boot_test.dart`,
and `onboarding_save_failure_test.dart`.

## Consequences

- **Buys:** a transient platform hiccup no longer bricks the family's database; the
  first-run experience is robust; the failure modes are tested.
- **Costs:** a few seconds of retry latency in the (rare) worst case before a genuine,
  non-transient failure is reported. Slightly more boot code than a naive open.
- **Forecloses:** any "open the DB once, assume it worked" shortcut on the boot path.
  New boot-time platform calls must be best-effort or retried, never fatal.

## Alternatives considered

- **Let it throw and show a crash screen** — rejected: the failure is usually
  transient, so crashing punishes the user for a race that a short retry resolves.
- **Bypass `LazyDatabase`** — rejected: lazy open is desirable (fast start, open on
  first use); the fix is to make the *resolution it wraps* resilient, not to abandon it.
