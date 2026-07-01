# Documentation

Organized on the [Diátaxis](https://diataxis.fr/) model — four kinds of docs for
four different needs. Find what you need by *what you're trying to do*, not by
guessing a filename.

| I want to… | I need | Go to |
|---|---|---|
| **learn by doing** | a Tutorial | [Tutorials](#tutorials) |
| **accomplish a specific task** | a How-to guide | [How-to guides](#how-to-guides) |
| **look up exact details** | Reference | [Reference](#reference) |
| **understand why** | Explanation | [Explanation](#explanation) |

New here? Start with the [README quickstart](../README.md), then the
[Vision](../VISION.md), then [Explanation § concepts](concepts.md).

---

## Tutorials
*Learning-oriented — take me by the hand through my first success.*

The entry point today is the **[README quickstart](../README.md#getting-started)** —
clone, generate code, and run the app with no configuration.

*Gap (contributions welcome):* a hand-held "catalogue your first room and export an
insurance PDF in 10 minutes" tutorial. If you write one, put it in `docs/tutorials/`.

## How-to guides
*Task-oriented — how do I accomplish X (assumes you know the basics)?*

- **[Build & run](how-to/build-and-run.md)** — from clone to a running app, including
  the mandatory codegen step.
- **[Set up LAN sync](how-to/lan-sync.md)** — sync two devices on the same Wi-Fi with
  a shared code, no account, no cloud.
- **[Export for insurance](how-to/export-for-insurance.md)** — produce a PDF report,
  a CSV, or a full JSON backup.
- **[Make an encrypted backup](how-to/encrypted-backup.md)** — a `.ohbk` (records) or
  `.ohbkz` (records + photos) sealed with 12 recovery words you hold.
- Agent-guidance for working *in* this repo: **[AGENTS.md](../AGENTS.md)**.

## Reference
*Information-oriented — tell me exactly, precisely, completely.*

- **[Data model](reference/data-model.md)** — every table, the CRDT stamp columns, and
  the entity relationships.
- **[Feature status](reference/feature-status.md)** — what's shipped vs scaffolded, by
  area (the honest, per-feature version).
- **[Formal specification (yellow paper)](spec/yellow-paper.md)** — the rigorous sync
  semantics: HLC last-writer-wins, the wire format, and the import DB-safety invariants.

## Explanation
*Understanding-oriented — help me understand the ideas and the why.*

- **[Vision](../VISION.md)** — the one idea, the invariants, the honest scorecard.
- **[Architecture overview](architecture/OVERVIEW.md)** — the layers + data-flow diagrams.
- **[Architecture Decision Records](adr/)** — why each load-bearing choice was made.
- **[Concepts](concepts.md)** — the domain model, the CRDT stamp, value & depreciation,
  QR labels, the AI tiers.
- **[Privacy model](privacy-model.md)** — exactly what can leave the device, and how to
  verify that nothing does by default.
- **[Limitations](limitations.md)** — read before adopting. What it does *not* do.

---

### The white paper & yellow paper

Two long-form documents complement this tree:
- **[White paper](whitepaper.md)** — the conceptual case: why a home inventory should be
  local-first, who it's for, and how it differs from the cloud incumbents.
- **[Yellow paper / formal spec](spec/yellow-paper.md)** — the rigorous specification of
  the sync merge semantics and the data-safety invariants.
