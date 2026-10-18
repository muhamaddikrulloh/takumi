# Privacy Notice

This document describes the data flow implemented by the Takumi source code. A
person or organization distributing the app must review this notice, identify
themselves as the data controller, provide a contact method, and adapt it to the
laws and Firebase project settings that apply to their deployment.

## Cloud Data

Takumi uses Firebase Authentication and Cloud Firestore. Depending on the sign-
in method and user input, the operator's Firebase project may process:

- Account UID, email address, verification state, display name, authentication
  provider, and Google account photo URL. Firebase Auth handles passwords and
  sign-in tokens; the app does not manually store them in SharedPreferences.
- Profile display name, institution, major, selected avatar, and setup state.
- Task title, subject, description, deadline, status, and timestamps.

The app uses this data only to authenticate the user, synchronize that user's
profile/tasks, and provide task-management features. Firestore paths are scoped
by authenticated UID and checked by Security Rules.

## Device Data

The app stores the language preference, password-reset throttling timestamps
under hashed keys, and account-photo cache entries in SharedPreferences.
Hashing keys does not encrypt this local storage. Each downloaded photo is
limited to 5 MiB. Native Android preferences also record whether notification
permission has been requested. Firestore persistence is enabled with a 100 MiB
cache setting in the Android application sandbox.

Task titles and deadlines may appear in local notifications. Notifications use
private lock-screen visibility, but the exact presentation remains controlled
by Android and the user's notification settings.

Logout or account switching clears account-photo cache entries and local task
notifications. Firebase SDK caches and authentication storage follow Firebase
and Android platform behavior; the app does not explicitly purge the Firestore
cache on logout. Android backup and cleartext traffic are disabled in the app
manifest.

## Network Services

- Firebase Authentication and Cloud Firestore process account and app data.
- Google Sign-In processes Google authentication when selected.
- A configured account-photo HTTPS host receives normal image requests.
- The `google_fonts` package may retrieve font assets when they are not already
  available locally.

Takumi does not include advertising, analytics, Crashlytics, or custom telemetry
in the current source.

## Retention and Deletion

The source code does not implement in-app account deletion or an automatic data
retention policy. Cloud data remains in the deployment operator's Firebase
project until deleted according to that operator's process. Deleting a Firebase
Auth account alone does not delete its Firestore documents. Before public app
distribution, the operator must provide a support contact and a process for
deleting both the account and its task/profile data, and meet any additional
deletion requirements of the chosen distribution channel.

Uninstalling the app removes ordinary app-sandbox data according to Android
behavior, but it does not delete Firebase cloud data.

## Security

Do not report vulnerabilities or include personal data in public issues. Follow
the private process in [SECURITY.md](SECURITY.md).
