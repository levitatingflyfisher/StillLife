# Still Life — Home Inventory Management

**Know what you own, where it is, what it's worth.**

Still Life is a free, open-source mobile app for cataloguing everything in your home — where it lives, what it's worth, and what condition it's in. It runs entirely on your device. No account required. No subscription. No cloud you don't control.

Built with Flutter. Runs on Android and iOS.

---

## Why Still Life?

Most home inventory apps force you to choose between convenience and privacy — cloud sync means handing your possessions list to a third party; truly local apps feel unfinished. Still Life closes that gap:

| | Still Life | Sortly / Itemtopia | Encircle / HomeZada |
|---|---|---|---|
| Fully local / offline | ✓ | Cloud-required | Cloud-required |
| No account needed | ✓ | Requires signup | Requires signup |
| LAN sync (no cloud) | ✓ | — | — |
| AI-assisted cataloguing | ✓ (bring your key) | — | — |
| Open source | ✓ (AGPL) | Proprietary | Proprietary |
| Free tier | Full feature set | Limited items | Limited items |
| Container hierarchy | ✓ (shelf→item) | — | — |
| QR labels (scan-to-find) | ✓ | Extra cost | — |

---

## Features

### Inventory
- Add items with photos, receipts, serial numbers, barcodes, purchase details, and notes
- Scan a barcode to pre-fill product info (privacy-first: works offline, optional network lookup with your consent)
- Scan receipts with OCR to auto-populate purchase date and price
- Bulk-select items to move or delete in one tap
- Full-text search across name, description, notes, serial number, and barcode

### Organisation
- **Rooms** — group items by where they live in your home
- **Containers** — shelves, boxes, drawers, cabinets within each room
- **Categories** — flexible tagging with custom categories
- **QR labels** — generate and share a printable QR label with a human-readable ID (e.g. `oaken-low-rafter`) for any item or container; scan to jump straight to the detail screen

### Financial
- **Dashboard** — live totals for household value, depreciation, value by room, value by category, and 6-month acquisition trend
- **Value history** — automatic price history chart on every item detail page
- **Depreciation tracking** — per-item depreciation estimates
- **Insurance policies** — record coverage details and surface protection gaps
- **Export** — CSV (for spreadsheets/insurers) or full JSON backup

### AI-Assisted Cataloguing
- Point your camera at a room and let the app identify and describe items
- Four tiers: on-device ML → local Ollama → cloud API (your key) → hosted service
- Works fully offline with the on-device tier

### Maintenance & Warranty
- Schedule recurring maintenance tasks with reminders
- Warranty expiry alerts
- Maintenance log with completion history

### Sync & Backup
- **LAN sync** — sync across devices on the same Wi-Fi with automatic CRDT conflict resolution; secured with a shared sync code
- **WebDAV backup** — back up to Nextcloud, ownCloud, or any WebDAV server

---

## Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.x
- Android SDK (for Android) or Xcode (for iOS)

### Build from source

```bash
git clone https://github.com/[llcdomain]/still-life.git
cd still-life
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

### Optional configuration

Still Life works with no configuration. Enable optional features in **Settings**:

| Feature | Path |
|---------|------|
| AI analysis (cloud API key) | Settings → AI Analysis |
| AI analysis (local Ollama) | Settings → AI Analysis |
| Product barcode lookup | Settings → Barcode Lookup |
| LAN sync | Settings → Sync & Backup |
| WebDAV backup | Settings → WebDAV Backup |

---

## Running Tests

```bash
flutter test test/unit test/widget
```

359 tests as of Phase 14.

---

## Architecture

Clean Architecture with three layers:

- **Domain** — entities, repository interfaces (`lib/features/*/domain/`)
- **Data** — Drift ORM + repository implementations (`lib/features/*/data/`, `lib/services/database/`)
- **Presentation** — Riverpod state + Flutter screens (`lib/features/*/presentation/`)

Key libraries: [Drift](https://drift.simonbinder.eu/) (SQLite ORM), [Riverpod](https://riverpod.dev/) (state management), [GoRouter](https://pub.dev/packages/go_router) (navigation), [fl_chart](https://pub.dev/packages/fl_chart) (charts), [qr_flutter](https://pub.dev/packages/qr_flutter) (QR labels).

---

## Roadmap

See [ROADMAP.md](ROADMAP.md) for the full phasing plan — from fast-add UX and household sharing through to iOS release and B2B integrations.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on reporting bugs and submitting changes.

---

## License

Still Life is dual-licensed:

- **Community (AGPL-3.0):** Free to use, modify, and distribute under the terms of the [GNU Affero General Public License v3](LICENSE). If you deploy a modified version as a network service, your modifications must be released under the same terms.
- **Commercial:** A separate commercial license is available for organizations that need to embed Still Life in proprietary products without AGPL obligations. Contact [LLC Name] for details.

---

## About [LLC Name]

Still Life is developed and maintained by [LLC Name].
