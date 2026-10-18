# Security Policy

## Supported Version

Security fixes are applied to the latest revision of the default branch. No
older release line is currently maintained.

## Reporting a Vulnerability

Use **Report a vulnerability** in this repository's Security tab when private
vulnerability reporting is enabled. Include the affected revision, impact,
reproduction steps, and any suggested mitigation. Redact credentials and
personal data from attachments.

If that option is unavailable, use a private contact method listed on the
[maintainer's profile](https://github.com/muhamaddikrulloh). If no private
contact is listed, open an issue requesting a private reporting channel,
without vulnerability details. Never post credentials, personal data, or
exploit details in a public issue.

Please allow time for validation and a coordinated fix before public disclosure.

## Scope

Relevant reports include authentication/account isolation, Firestore Rules,
notification privacy, exposed credentials, unsafe local data handling, and
dependency vulnerabilities with a demonstrated impact on this project.

Firebase client configuration is not a server credential by itself, but a
report is still relevant if configuration exposure enables unauthorized access
because of another control failure.

## Deployment Boundaries

The checked-in Rules enforce verified ownership of task and profile paths.
Emulator tests validate those files, not the Rules deployed to a Firebase
project. Operators are responsible for project access, API-key restrictions,
OAuth configuration, and deployment. See [Firebase
Setup](docs/FIREBASE_SETUP.md#production-and-android-distribution).
