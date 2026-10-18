<p align="center">
  <img src="assets/images/app_logo.png" width="96" alt="Takumi Logo" />
</p>

<h1 align="center">Takumi</h1>

<p align="center">Coursework, deadlines, and smart reminders in one place.</p>

<p align="center">
  <a href="https://www.android.com/"><img src="https://img.shields.io/badge/platform-Android-3DDC84?style=flat-square&logo=android&logoColor=white" alt="Platform: Android" /></a>
  <a href="https://flutter.dev/"><img src="https://img.shields.io/badge/framework-Flutter-02569B?style=flat-square&logo=flutter&logoColor=white" alt="Framework: Flutter" /></a>
  <a href="https://dart.dev/"><img src="https://img.shields.io/badge/language-Dart-0175C2?style=flat-square&logo=dart&logoColor=white" alt="Language: Dart" /></a>
  <a href="pubspec.yaml"><img src="https://img.shields.io/badge/version-1.0.0-2F80ED?style=flat-square" alt="Version: 1.0.0" /></a>
  <a href="https://github.com/muhamaddikrulloh/takumi/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/muhamaddikrulloh/takumi/ci.yml?branch=main&label=CI&style=flat-square" alt="CI Status" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-7A5AF8?style=flat-square" alt="License: MIT" /></a>
</p>

Takumi is an open-source Android application designed for students and self-learners to track coursework, deadlines, and academic priorities. It combines a structured task manager, interactive calendar, cloud synchronization, and reliable local reminders inside a focused dark glass interface.

---

## Overview

Managing assignments across multiple classes often leads to fragmented notes and missed deadlines. Takumi provides a centralized, distraction-free environment to track what needs to be done next.

- **Fast & Responsive**: Built with Flutter and Riverpod for snappy state management and smooth interactions.
- **Offline Capable**: Works without interruption during network dropouts; data syncs automatically with Cloud Firestore once back online.
- **Privacy Centric**: Strict per-user isolation enforced through security rules, with full transparency on stored attributes.

## Features

- **Authentication & Security**: Email/password registration with mandatory verification, Google Sign-In, and rate-limited password recovery.
- **Profile Customization**: Display name, custom visual avatar, and optional academic metadata (major, campus, student ID).
- **Coursework Management**: Create, view, update, search, filter (by status and priority), and complete tasks.
- **Deadline Calendar**: Interactive calendar view highlighting upcoming assignment milestones by date.
- **Multi-Stage Reminders**: Local scheduled notifications delivered at 72h, 24h, 12h, 3h prior to deadline, and at due time, with exact alarm support and graceful inexact fallback.
- **Offline Persistence**: Cloud Firestore cache integration keeps current data accessible without an internet connection.
- **Bilingual Interface**: Full localization support for both Indonesian (`id`) and English (`en`).

## Screenshots

<p align="center">
  <img src="docs/screenshots/home_dark.png" width="22%" alt="Home Dashboard" />
  <img src="docs/screenshots/tasks_dark.png" width="22%" alt="Task Management" />
  <img src="docs/screenshots/calendar_dark.png" width="22%" alt="Deadline Calendar" />
  <img src="docs/screenshots/profile_dark.png" width="22%" alt="User Profile" />
</p>

## Download

Pre-built APK binaries are not yet published for this repository.

Official releases will be distributed via [GitHub Releases](https://github.com/muhamaddikrulloh/takumi/releases) once signed production builds are ready. To try the app right now, build from source using the instructions below.

<!-- Replace status above with release download links once published. -->

## Tech Stack

| Component | Technology |
| --- | --- |
| Runtime & Target | Flutter (Dart SDK `^3.13.2`), Android SDK (API 21+) |
| State Management | Flutter Riverpod 2.6 (`AsyncNotifier`) |
| Authentication | Firebase Authentication, Google Sign-In |
| Cloud Database | Cloud Firestore with offline disk persistence |
| Notifications | `flutter_local_notifications`, `timezone`, `flutter_timezone` |
| Local Preferences | `shared_preferences` |
| Calendar View | `table_calendar` |
| Typography & Icons | Google Fonts (Plus Jakarta Sans), Phosphor Icons |

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) pinned to **3.47.2** (Dart `^3.13.2`).
- Android SDK with JDK 21 configured.
- An Android device or emulator running API 21 or higher.
- A Firebase project configured for Android (see [Configuration](#configuration)).

### Installation & Run

1. Clone repository:
   ```bash
   git clone https://github.com/muhamaddikrulloh/takumi.git
   cd takumi
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure Firebase by placing your `google-services.json` into `android/app/`:
   ```text
   android/app/google-services.json
   ```

4. Launch on a connected device:
   ```bash
   flutter devices
   flutter run -d <device-id>
   ```

### Project Layout

| Directory | Content |
| --- | --- |
| `lib/features/` | Feature modules: auth, home, tasks, calendar, profile, navigation |
| `lib/core/` | Base providers, services, constants, and localization |
| `lib/shared/widgets/` | Reusable UI components and visual primitives |
| `android/` | Native Android wrapper and Gradle configuration |
| `test/` | Unit, widget, responsive, and visual review test suites |
| `docs/` | In-depth setup, architecture, and asset licensing guides |

See [ARCHITECTURE.md](docs/ARCHITECTURE.md) for architectural data flow, reactive state model, and lifecycle rules.

## Configuration

Takumi does not bundle pre-configured Firebase credentials. You must link your own project:

1. Follow the step-by-step [Firebase Setup Guide](docs/FIREBASE_SETUP.md).
2. Register package name `id.takumi.app` (or your custom package ID) in Firebase Console.
3. Generate and register debug SHA-1/SHA-256 signing fingerprints for Google Sign-In.
4. Deploy the checked-in security rules and compound indexes:
   ```bash
   firebase deploy --only firestore:rules,firestore:indexes
   ```

## Development & Testing

Run the standard check suite before committing changes:

```bash
# Code formatting check
dart format --output=none --set-exit-if-changed lib test

# Static analysis
flutter analyze

# Unit and widget test suite
flutter test
```

### Visual Review Harness

To render screen previews to disk for visual inspection:

```bash
flutter test test/visual_review_test.dart --dart-define=RENDER_REVIEW=true
```

Output screenshots will be written to `build/visual_review/`.

### Firestore Rules Unit Tests

Test security rules against local emulators (requires Node 22 and Java 21):

```bash
npm install
npm test
```

## Contributing

Contributions, bug reports, and suggestions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) for detailed development guidelines, coding standards, and pull request procedures.

All participants are expected to adhere to the [Code of Conduct](CODE_OF_CONDUCT.md).

## Security & Privacy

- **Security Disclosures**: Review [SECURITY.md](SECURITY.md) to report vulnerabilities privately.
- **Privacy Policy**: See [PRIVACY.md](PRIVACY.md) for data handling and account management guidelines.
- **Asset Provenance**: Review [ASSET_LICENSES.md](docs/ASSET_LICENSES.md) for trademark notices and artwork licensing details.

## License

This project is open-source and licensed under the [MIT License](LICENSE). Third-party dependencies and assets retain their respective licenses.
