# How to build & run Still Life

Goal: get from a fresh clone to the app running on a device or emulator.

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel; the
  project targets Dart SDK `^3.10.7`).
- For Android: the Android SDK + a device or emulator.
- For iOS: Xcode (note iOS is not yet a shipped target — see
  [limitations](../limitations.md)).
- The sibling design-system package at `../OpenHearth/ohStyle/openhearth_design`, which
  `pubspec.yaml` references by relative path. Check it out next to this repo.

## Steps

```bash
# 1. Install Dart/Flutter dependencies
flutter pub get

# 2. Generate code — REQUIRED before the first run and after any schema/annotation change
dart run build_runner build --delete-conflicting-outputs

# 3. Run on a connected device or emulator
flutter run
```

Step 2 is not optional: Drift tables, Riverpod providers, and Freezed classes are all
code-generated. Skipping it leaves `*.g.dart` / `*.freezed.dart` missing and the build
will fail. Re-run it whenever you edit `lib/services/database/tables.dart`,
`database.dart`, or any file with a `@riverpod` / `@freezed` / `@DriftDatabase`
annotation.

## Verify your change

```bash
flutter analyze     # lint — config in analysis_options.yaml (flutter_lints)
flutter test        # the full suite (~123 test files); CI runs it with --coverage
```

Both must be green before you commit. To narrow the run:

```bash
flutter test test/unit test/widget          # skip the slower golden/visual tests
flutter test test/unit/services/sync        # one area
```

## Build artifacts

```bash
flutter build apk --debug     # Android debug APK (what CI builds for sanity)
flutter build linux           # desktop (builds in CI)
flutter build web             # web (builds in CI)
```

## The app has no configuration to run

Still Life starts into a working, empty catalogue with **no setup, no account, no
network**. Everything optional (AI analysis, barcode lookup, LAN sync, WebDAV backup)
is enabled later from **Settings**, and each is off until you turn it on.

## Note on CI

`.github/workflows/ci.yml` runs analyze → test → build (Android / Linux / Web) plus a
Node job for the `server/hosted-llm` worker. Its triggers are `main`/`develop`; the
live branch is `master`, so a push to `master` will not currently trigger CI — run the
checks locally.
