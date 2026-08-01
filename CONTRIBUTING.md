# Contributing to Still Life

Thank you for your interest in contributing.

---

## Reporting Bugs

Open a [GitHub Issue](../../issues) with:

- A clear description of what happened and what you expected
- Steps to reproduce
- Device/OS version and Flutter version
- Relevant logs or screenshots if available

---

## Submitting Changes

1. Fork the repository and create a branch from `main`
2. Make your changes with clear, focused commits
3. Ensure all tests pass: `flutter test test/unit test/widget`
4. Open a pull request with a description of what changed and why

Keep pull requests small and focused on a single concern. Large refactors
or feature additions should be discussed in an issue first.

---

## Code Style

- Follow standard Dart/Flutter conventions (`dart format`, `flutter analyze`)
- Keep logic out of widget `build()` methods — use controllers and providers
- Write tests for new features and bug fixes

---

## License

Still Life is [MIT licensed](LICENSE), like the rest of the OpenHearth fleet.
By submitting a pull request you confirm you have the right to license your
contribution, and you agree it is made available under the MIT License.
