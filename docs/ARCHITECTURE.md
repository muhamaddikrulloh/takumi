# Takumi Architecture

This document describes the implementation in the repository. It is not a
proposed directory template.

## Runtime Scope

Takumi currently supports Android. Flutter source is organized by feature and
uses Riverpod for state management and dependency injection. Firebase Auth and
Cloud Firestore provide identity and synchronized data. Deadline reminders are
scheduled locally on each device.

## Bootstrap

`lib/main.dart` performs the runtime bootstrap in this order:

1. Initialize Flutter bindings and locale date data.
2. Initialize Firebase from Android native resources.
3. Enable Firestore persistence with a 100 MiB cache.
4. Load SharedPreferences and remove legacy local keys that exposed encoded
   email addresses or avatar URLs.
5. Create the root `ProviderContainer` with preferences injected.
6. Initialize local notifications without allowing plugin failure to abort app
   startup.
7. Coordinate authentication changes, task reminder reconciliation, and
   notification-tap navigation.

`lib/app.dart` owns the fixed dark theme, locale, and authentication gates. A
session proceeds through signed-out, email-verification, profile-setup, and
main-navigation states as applicable.

## Layers

```text
Presentation (screens, modals, widgets)
                |
Riverpod providers and AsyncNotifiers
                |
Repositories and domain models
                |
Firebase Auth / Firestore / local platform services
```

- `presentation/` renders state and forwards user actions.
- `providers/` owns asynchronous state and application behavior.
- `domain/` contains immutable models and enums.
- `data/` owns Firebase reads and writes.
- `core/` contains cross-feature services, providers, constants, and utilities.
- `shared/widgets/` contains reusable visual components.

Widgets do not issue Firestore reads or writes directly.

## Feature Map

```text
lib/
  core/
    constants/           Colors, theme, application constants
    localization/        Indonesian and English strings
    providers/           Clock, connectivity, locale, preferences
    services/            Notification and privacy-aware local-data services
    utils/               Logging, dates, status helpers, validators
  features/
    auth/                Repository, auth provider, login/register/reset/verify UI
    home/                Dashboard provider and screen
    tasks/               Task model, repository, providers, screens, modals
    calendar/            Calendar derivation and presentation
    navigation/          Four-tab navigation with central add action
    profile/             Profile model, repository, setup/edit presentation
  shared/widgets/        Glass UI, navigation, avatar, and state widgets
  app.dart
  main.dart
```

## Authentication and Account Isolation

`authStateProvider` exposes Firebase authentication changes. Firestore-backed
features require a non-null, email-verified user.

Profile and task mutations capture the initiating UID. Repository guards verify
that Firebase Auth still represents that UID, and post-await provider guards
discard stale results after account changes. Task stream data also carries an
internal owner UID so reminders cannot be reconciled from a previous account's
temporarily retained state.

On logout or account switch, bootstrap coordination resets search/filter and
sync-error state, clears account-photo cache entries, and removes local task
notifications and queued taps.

## Firestore Data

Task documents use this path:

```text
users/{uid}/tasks/{taskId}
```

```text
title        string, 1..300 characters
subject      string, 1..120 characters
description  string, 0..5000 characters
deadline     timestamp
status       belum | progress | done
created_at   timestamp
updated_at   timestamp
```

The task ID is the Firestore document ID and is not duplicated as a document
field.

Profile data uses:

```text
users/{uid}/profile/info
```

Allowed fields are `display_name`, `institution`, `major`, `avatar_id`,
`setup_complete`, and `updated_at`. Email and account photo URL remain sourced
from Firebase Auth.

`firestore.rules` requires verified ownership, restricts field names and types,
preserves `created_at`, rejects new past deadlines, permits editing an existing
overdue task only when its deadline remains unchanged, and denies unknown
paths by default.

## Task State and Offline Writes

`TaskListNotifier` subscribes to the authenticated user's ordered task query.
Mutations update Riverpod state optimistically and call `TaskRepository`.
Online failures roll back the latest applicable mutation. When connectivity is
known to be offline, Firestore's queued write is retained and a later failure is
reported through `taskSyncErrorProvider`.

Profile mutations follow the same account and queued-write safeguards.

## Notification Model

`NotificationService` reconciles the complete desired set of reminders against
Android's persisted pending requests. For every active, non-completed task it
targets:

```text
deadline - 72 hours
deadline - 24 hours
deadline - 12 hours
deadline - 3 hours
deadline
```

Elapsed triggers are skipped. Deterministic 31-bit ID blocks and payload
metadata support cancellation, collision probing, and restart reconciliation.
Exact alarms are used when allowed; scheduling retries with an inexact alarm if
needed. Completing/deleting a task removes its pending reminders during the
next reconciliation. Logout and account switches clear pending and displayed
notifications immediately.

Notification taps are queued until authentication, task data, and navigation
are ready. Payloads contain a task ID and schedule metadata, but no task title
or description; task details are resolved from the current account's state.

## Local Data

SharedPreferences stores:

- `locale`.
- Password-reset throttling timestamps under SHA-256-derived keys.
- Bounded account-photo bytes under SHA-256-derived URL keys.

Remote avatar loading requires HTTPS, validates an image content type, applies
a timeout, limits content to 5 MiB, and ignores stale responses. Legacy keys
containing encoded identity data are removed during startup.

## Logging and Errors

`logDebug` emits application diagnostics only in debug builds. This does not
disable logging by Flutter, native Android code, or third-party SDKs. Login
errors avoid distinguishing an unknown email from an incorrect password;
password-reset responses also avoid revealing whether an account exists.

## Configuration Boundaries

The repository tracks reusable Rules, indexes, and emulator configuration. It
does not track Firebase project identity, project aliases, release keystores,
signing properties, local Android SDK paths, environment files, or Firebase
Admin credentials. See [Firebase Setup](FIREBASE_SETUP.md).

## Presentation and Tests

The app uses a fixed dark theme in `core/constants/app_theme.dart`, semantic
colors in `app_colors.dart`, and localized strings in
`core/localization/app_translations.dart`. Shared glass cards, buttons, inputs,
and modal shells live in `shared/widgets/`. Profile avatars are drawn by
`GeneratedAvatar` or loaded from the authenticated account; there is no bundled
avatar image collection.

Flutter tests exercise models, providers, account transitions, notification
scheduling, and presentation. `test/run_rules_tests.js` checks ownership and
schema validation against the Firestore emulator. The opt-in visual review
harness renders real widgets with in-memory sample data; it is not a device
integration test. See [Contributing](../CONTRIBUTING.md) for commands.
