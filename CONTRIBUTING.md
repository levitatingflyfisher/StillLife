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

## Contributor License Agreement

**This project uses a dual-license model (AGPL-3.0 + commercial).** Because
[LLC Name] distributes Still Life under both an open-source license and a
separate commercial license, contributors must agree to the following before
their contribution can be accepted:

> By submitting a pull request, you (a) confirm that you have the right to
> license your contribution, (b) grant [LLC Name] a perpetual, worldwide,
> royalty-free license to use, reproduce, modify, and distribute your
> contribution under both the AGPL-3.0 and any commercial license terms
> that [LLC Name] offers, and (c) agree that your contribution is made
> available under the AGPL-3.0.

This is a standard requirement for dual-licensed projects and ensures
[LLC Name] can continue to offer both free and commercial versions of
the software.
