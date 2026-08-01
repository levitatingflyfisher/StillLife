# Still Life — White Paper

*A catalogue of your belongings that you actually own — for insurance and peace of
mind, that never phones home.*

**Status:** conceptual/strategic overview. For the invariants see
[VISION.md](../VISION.md); for the mechanics, [architecture/OVERVIEW.md](architecture/OVERVIEW.md);
for what leaves the device, the [privacy model](privacy-model.md); for the sync
semantics, the [yellow paper](spec/yellow-paper.md). This document is honest about the
line between what is built and what is aspirational — see §7.

---

## Abstract

A home inventory is the single most useful document to have after a fire, a flood, a
burglary, or a move — and the single most sensitive list to hand to a stranger's server.
Every mainstream home-inventory app resolves that tension the wrong way: it requires an
account and stores your possessions, photos, serial numbers, and values in its cloud,
making your household an entry in someone else's database and making the app worthless
the day the company folds. Still Life takes the other branch. It is a **local-first**
catalogue that runs fully offline with no account, keeps everything in an on-device
database, and treats every path off the device — sync, backup, AI — as an **opt-in,
off-by-default** edge that reaches only destinations *you* control. The private list
stays private by construction, not by policy.

## 1. The problem

The value of a home inventory is real and specific. Insurers pay claims faster and more
fully when you can produce an itemised, valued, photographed list; without one, you
reconstruct your possessions from memory on the worst day of your year. So people are
told to keep an inventory — and the tools that help them do it (Sortly, Itemtopia,
Encircle, HomeZada) almost all require an account and put the list in their cloud.

That default has three failure modes, and they are not hypothetical:

- **It's a honeypot.** A cloud of households' most valuable possessions, with photos and
  addresses, is exactly what a breach would most like to find.
- **It's rented, not owned.** When the vendor shuts down, pivots, or raises the price,
  your inventory — the thing you built over years — leaves with them.
- **It's monetisable.** Once your possessions are on someone's server, the incentive to
  analyse, cross-sell, or sell them exists whether or not it's exercised today.

## 2. The idea

**A catalogue you own.** Keep the data on the device, in an open format, usable forever,
offline, with the company entirely absent from the core loop. Then add the conveniences
people legitimately want — multiple devices in step, a backup, a little AI help — *as
edges you switch on*, each reaching only somewhere you already trust:

- **Sync** goes device-to-device over your own Wi-Fi (last-writer-wins by hybrid logical
  clock), never through a cloud account.
- **Backup** goes to your own WebDAV server (HTTPS-enforced) or a local file.
- **AI** defaults to on-device; higher tiers require *your* key or an explicit opt-in.

The load-bearing move is the **default**: nothing leaves unless you turn on a named,
documented switch. "Your data stays on your device" is then a property of the build, not
a promise in a policy — and you can verify it (airplane mode; read the switches; grep the
source). See the [privacy model](privacy-model.md).

## 3. Why local-first matters *here* specifically

Local-first is an OpenHearth value across every app, but the argument is unusually sharp
for a home inventory:

- The dataset is **maximally sensitive** (what you own, what it's worth, where you live)
  and **maximally useful offline** (you consult it precisely when disaster has knocked
  out connectivity).
- The app is **write-mostly and single-household** — it does not need a server to be
  useful, unlike a social or collaborative product. The cloud buys convenience, not
  capability, so refusing the cloud costs the user almost nothing and buys them
  everything.
- The **portability stakes are high**: an inventory you can't export is a hostage. JSON
  backup + CSV export in open formats, under an AGPL licence, mean you can always leave.

## 4. The architecture, in one paragraph

An on-device SQLite database (Drift) is the source of truth, wrapped in Clean
Architecture layers (domain / data / presentation) sliced by feature. Reactive Drift
streams push a single write out to the inventory list, dashboard, and search at once.
The only egress paths are a small, enumerable set of opt-in services. Cross-device sync
is a state-based, per-row, HLC last-writer-wins merge with soft-delete tombstones, run
inside a transaction behind a path-sandbox guard so an untrusted payload cannot corrupt
the store. Full mechanics: [architecture/OVERVIEW.md](architecture/OVERVIEW.md).

## 5. Positioning — against the cloud incumbents

Still Life competes not on having more features but on *owning your own data while
matching the convenience*:

| | Still Life | Cloud incumbents |
|---|---|---|
| Works fully offline | Yes, by default | No — cloud-required |
| Account required | Never | Yes |
| Where your list lives | Your device (+ destinations you choose) | Their servers |
| Multi-device sync | LAN, no cloud | Cloud account |
| AI help | On-device-first; your key optional | Their cloud |
| Open source / exportable | AGPL; JSON + CSV | Proprietary; lock-in |
| Container-level location | Room → container → item | Flat lists |

The bet: a meaningful slice of people who keep a home inventory care that the list of
their valuables isn't sitting on someone else's server — and will choose a tool that is
just as convenient without that cost.

## 6. Who it's for

Households that want the insurance/peace-of-mind payoff of a real inventory without
renting it from a vendor: homeowners and renters documenting for coverage or claims,
privacy-minded families, collectors, and anyone burned by an app that shut down and took
their data. It is a **family tool**, not a business SaaS — optimised for a household, not
monetised against one.

## 7. What is built, and what is not

A white paper that overclaims is marketing. Honestly, as of schema v14:

**Built, tested, load-bearing** (~162 test files): the offline catalogue with the full
place hierarchy, categories/tags, photos/receipts, and value tracking; the financial
dashboard, depreciation, insurance policies with gap detection, and PDF/CSV/JSON export;
LAN sync (HLC last-writer-wins, tombstones, shared-secret auth); the data-safety net
(boot-resilience retry, sandboxed transactional import, formula-injection-safe CSV); QR
labels, loans, maintenance, and opt-in cache-first barcode lookup. Zero telemetry, by
absence.

**Aspirational — documented or scaffolded, not shipped:** on-device AI recognition is
**not implemented** (the privacy-first tier reports itself unavailable and the cascade
skips it); the **hosted AI tier and billing are scaffolding** for a future paid plan; the **appraiser** is an LLM estimate, not the
marketplace scraping the roadmap implies; **sync moves rows, not photo/receipt files**,
ships full snapshots (not deltas), and resolves per-row (not per-field); **iOS is not
shipped**; encrypted off-site backup is roadmap.

The honest boundary: the *offline catalogue* is real and trustworthy, and the privacy
default is enforceable and checkable. AI recognition (photo, shelf, voice, receipt,
video) is real on a tier the user configures — their own Ollama or their own key;
*on-device* recognition, the *paid tier*, and *cross-device media* are still hopes.
See [limitations](limitations.md) and the
[feature status](reference/feature-status.md).

## 8. Why it's worth doing

Because the useful thing — a valued, photographed, searchable record of what you own —
should not require surrendering that record to a company. The contribution here is not a
new algorithm; it is the demonstration that a home inventory can be **just as convenient
as the cloud versions while remaining something you own**, and that "nothing leaves your
device unless you say so" can be a build-time guarantee rather than a marketing line —
for the one dataset where that guarantee matters most.

---

*The code and comments referenced here were authored by an AI assistant and describe
what currently exists — take them with gratitude and a grain of salt, and verify before
relying.*
