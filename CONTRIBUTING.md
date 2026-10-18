# Contributing

Contributions are welcome when they preserve Takumi's account isolation,
offline behavior, and Android notification semantics.

By participating, you agree to follow the [Code of Conduct](CODE_OF_CONDUCT.md).

## Setup

1. Fork the repository and clone your fork. Create a focused branch from `dev`.
2. Install Flutter 3.47.2, Android tooling, and JDK 21, then run `flutter pub get`.
3. Follow [Firebase Setup](docs/FIREBASE_SETUP.md) to run the Android app with
   your own project. Flutter tests do not require Firebase configuration.
4. For Rules tests, install Node.js 22 and Firebase CLI 15.28.2 (the CI versions):

   ```bash
   npm install --global firebase-tools@15.28.2
   npm ci
   ```

Set `JAVA_HOME` to your JDK directory and make sure `java` is on `PATH`.

Personal Firebase config, release signing files, environment files, and Admin
credentials must never be committed.

## Before Opening a Pull Request

Run:

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
npm audit
npm test
```

`npm test` runs a local Firestore emulator with the demo project ID
`demo-task-track` on port 8080. It does not require Firebase login or a live
project. The opt-in visual rendering test is skipped by the normal Flutter
suite; its invocation is documented in `test/visual_review_test.dart`.

Add focused regression coverage for behavior changes. Changes to Firestore
paths, field validation, ownership, or authentication requirements must include
Rules emulator tests.

## Pull Requests

- Open pull requests against `dev` and link the relevant issue when available.
- Keep changes scoped and explain user-visible behavior.
- Document manual Android/device checks that cannot be automated.
- Update README or architecture documentation when configuration or data flow
  changes.
- Do not include generated build output or unrelated formatting.
- Do not weaken authorization to make a client operation pass.

By contributing, you agree that your source-code contribution is licensed under
the [MIT License](LICENSE). Document the origin and redistribution terms of any
new artwork, fonts, or icons in [Asset Licenses](docs/ASSET_LICENSES.md).
