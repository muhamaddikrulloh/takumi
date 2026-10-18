# Changelog

Notable changes are recorded here. No release is announced by this changelog;
`1.0.0+1` in `pubspec.yaml` is the current source build version.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- `CODE_OF_CONDUCT.md` (Contributor Covenant 2.1).
- GitHub pull request template and structured issue templates.
- Email/password and Google authentication via Firebase Auth, with email
  verification, password reset, and first-login profile setup.
- Task create, edit, status update, search, filter, and delete flows with
  per-account Firestore isolation.
- Dashboard summaries and interactive deadline calendar.
- Local reminders at 72, 24, 12, and 3 hours before a deadline, plus the
  deadline itself, with exact-alarm scheduling and inexact fallback.
- Indonesian and English localization, fixed dark glass theme, and Firestore
  offline persistence.
- Firestore Security Rules with emulator test suite.
- CI workflow covering formatting, analysis, Flutter tests, and Rules tests.

### Changed

- Refreshed the dark glass interface and shared presentation widgets.
- Focused the project on Android and removed unsupported iOS scaffolding.
- Updated public documentation and repository links for Takumi.
- Kept agent instructions, planning documents, and audit reports outside the
  source tree.
- Expanded ignore rules for project configuration, signing material, and local
  development notes.
- Regenerated the wrapper for the existing Gradle 9.3.1 distribution and added
  distribution checksum verification.
