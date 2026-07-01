# ADR-0002: Local-first, no account required for core functionality

- **Status:** Accepted
- **Date:** 2026-07-03 (documenting the founding constraint)

## Context

A home inventory is a list of a household's most valuable and most private possessions
— exactly the dataset an insurer, a burglar, or a data broker would most like to have.
Every mainstream competitor (Sortly, Itemtopia, Encircle, HomeZada) requires an account
and stores that list on their servers. That is convenient and it is the thing to avoid:
it makes the user's possessions someone else's asset, and it makes the app useless the
day the company or its servers go away.

The tension: users still want convenience — sync across devices, backup, AI help. The
question is whether those require surrendering the local-first, no-account posture.

## Decision

**Core functionality requires no account and no network.** The app opens straight into
a working catalogue backed by on-device SQLite. There is no sign-up, no login, no
server-side identity anywhere in a core path.

Convenience features are added as **opt-in, off-by-default edges** that reach only
destinations the user controls or explicitly chooses:

- Sync goes device-to-device over the user's own LAN (ADR-0004), not through a cloud
  account.
- Backup goes to the user's own WebDAV server (HTTPS-enforced), or to a local file.
- AI cataloguing defaults to on-device; higher tiers require the user to supply a key
  or opt into a hosted proxy.

Every edge is reflected in [docs/privacy-model.md](../privacy-model.md), and adding a
new one means updating that document in the same change.

## Consequences

- **Buys:** the core promise — "your data stays on your device" — is true by
  construction, not by policy. The app works forever, offline, with the company out of
  the picture. It is a genuine market differentiator (see the [white paper](../whitepaper.md)).
- **Costs:** no server means no effortless cross-device sync, no server-side search, no
  central backup unless the user sets one up. Convenience must be *engineered* into
  the local-first model (LAN sync, WebDAV) rather than assumed.
- **Forecloses:** any feature that would require a mandatory account or a server the
  user can't opt out of. A "log in to use the app" flow is off the table.

## Alternatives considered

- **Account-optional but cloud-default** (like the incumbents) — rejected: the default
  is the product; a cloud default silently makes surveillance the norm.
- **Pure local-only, no sync at all** — rejected: households have multiple devices and
  real backup needs; refusing to solve them abandons users to a worse tool. The answer
  is *local-first*, not *local-only*.
