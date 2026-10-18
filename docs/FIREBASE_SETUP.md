# Firebase Setup

Takumi does not include a default Firebase project. Each maintainer or
contributor must use a project they control.

The app has a single Android build configuration: it reads the local
`android/app/google-services.json`. There are no Firebase flavors, automatic
development/production switching, or in-app emulator routing. Keep development
and production in separate Firebase projects and select the appropriate local
config deliberately. Do not test with real users' data.

## 1. Create the Firebase Resources

1. Create a development Firebase project.
2. Create a Cloud Firestore database using production mode (deny access until
   the checked-in Rules are deployed).
3. Enable Email/Password in Firebase Authentication.
4. Enable Google as an Authentication provider.
5. Register an Android app with package `id.takumi.app` for local development.

Anyone distributing a fork must first choose a globally unique Android package
and use that exact value in Firebase and `android/app/build.gradle.kts`.

## 2. Register Signing Fingerprints

Google Sign-In requires the SHA-1 and SHA-256 fingerprints for each signing key
used with the Android app. Generate the local debug signing report from the
`android` directory:

```bash
./gradlew signingReport
```

On Windows PowerShell, use:

```powershell
.\gradlew.bat signingReport
```

Add the debug fingerprints in Firebase Console. Add release fingerprints only
for release keys you own. Re-download the Android config after changing
fingerprints so its OAuth client data is current.

## 3. Install the Android Config

Download `google-services.json` from Firebase Console and place it at:

```text
android/app/google-services.json
```

The path is ignored by Git. Do not force-add it. Takumi calls
`Firebase.initializeApp()` and reads the Android resources generated from this
file. `lib/firebase_options.dart` is not required by the Android app.

Running `flutterfire configure` alone is not a substitute for this step: its
documented output is `lib/firebase_options.dart`, which this Android-only
initialization path intentionally does not import.

## 4. Select a CLI Project and Deploy Rules

Install Firebase CLI (15.28.2 is used in CI), authenticate, and add an alias for
your project:

```bash
firebase login
firebase use --add
firebase use
firebase deploy --project YOUR_FIREBASE_PROJECT_ID --only "firestore:rules,firestore:indexes"
```

Replace `YOUR_FIREBASE_PROJECT_ID` with your actual project ID. Confirm both
the CLI target and the project in `google-services.json` are the ones you
intend to use. `.firebaserc` is ignored because it holds local aliases. A
successful emulator test does not deploy anything to that project.

Rules require a matching authenticated UID and `email_verified == true`. They
allow task documents only at `users/{uid}/tasks/{taskId}` and profile data at
`users/{uid}/profile/info`; other paths are denied. Deploy the Rules before
testing the app. Never relax them to work around a sign-in or setup error.

## 5. Run the App

```bash
flutter pub get
flutter run
```

The app requires verified Firebase Auth users for profile and task access.

## Rules Tests Without a Project

The local Rules suite uses a reserved demo project ID and a local Firestore
emulator, without connecting to a live project:

```bash
npm ci
npm test
```

Use Node.js 22, Firebase CLI 15.28.2, and JDK 21 to match CI. Set `JAVA_HOME`
and put the JDK's `bin` directory on `PATH`. The emulator uses port 8080.

## Package Rename

When publishing a fork under another package, update all of these together:

- `namespace` and `applicationId` in `android/app/build.gradle.kts`.
- The package declaration and directory for `MainActivity.kt`.
- The Android app registered in Firebase Console.
- Debug/release SHA fingerprints and Google OAuth clients.
- The locally downloaded `google-services.json`.

Do not reuse the Takumi Firebase registration for a differently signed or
packaged application.

## Production and Android Distribution

These are preparation requirements for a future distribution. They do not
indicate that an APK has been published or that a production project has been
verified.

### Firebase project and sign-in

- Use an operator-controlled production project, separate from development.
  Enable Email/Password and Google sign-in, configure the OAuth consent/support
  details and email templates, and verify email action links.
- Deploy the checked-in Rules and indexes explicitly to that project and
  confirm their deployed contents. Test with separate verified users to check
  task and profile isolation.
- Register the production Android application ID and the **actual release
  signing certificate's SHA-1 and SHA-256**, then download a fresh
  `google-services.json`. A debug certificate alone does not configure Google
  sign-in for a release APK. If using Play App Signing later, register the app
  signing certificate as well as any certificate used for direct APK installs.
- Review Google API-key API restrictions and Android application/certificate
  restrictions as applicable to each API. Validate Auth and Firestore flows
  after applying restrictions. Firebase client API keys are project identifiers,
  not Admin credentials; Security Rules remain the data-access boundary.
- Review IAM access, OAuth clients, quotas, and billing alerts. App Check is not
  integrated in this source; enabling enforcement requires an implementation
  and rollout decision, not just a Console toggle.

### Android identity and signing

- The application ID and namespace are `id.takumi.app`. The source version is
  `1.0.0+1`; Gradle maps it to version name `1.0.0` and version code `1`.
  Increment the version code for subsequent distributed builds. Android SDK
  levels follow the pinned Flutter toolchain; Java/Kotlin bytecode targets 17.
- Create and back up a distributor-owned release keystore **outside the Git
  working tree**. Copy [key.properties.example](../android/key.properties.example)
  to the ignored `android/key.properties` and replace every placeholder. Use
  an absolute `storeFile` path; on Windows, forward slashes avoid Java properties
  backslash escaping. Do not commit signing passwords or keys.
- The release build uses the private signing configuration and fails when
  `key.properties` is absent. It does not fall back to the Android debug key.
  Keep the existing application ID and signing key for updates; differently
  signed builds cannot replace an existing install. A package rename creates
  a separate app, and debug-signed installs generally cannot be upgraded with
  the release key.
- Permissions declared by the app cover Internet access, notifications, boot
  restore, and exact alarms. Android backup and cleartext traffic are disabled;
  notification receivers are not exported. Review the merged manifest from a
  future release build because plugins can contribute additional permissions.

### Validation before distributing an APK

On physical Android devices, verify registration, email verification, password
reset, Google sign-in with the release certificate, task/profile operations,
offline recovery, logout, and account switching. Also check notification
permission grant/denial, exact-alarm fallback, reboot, timezone changes,
notification taps, and an update signed with the same key and a higher version
code. Reminder delivery remains subject to Android and OEM power management.

Provide an operator-specific [privacy notice](../PRIVACY.md), support contact,
retention policy, and a way to delete both Auth accounts and their Firestore
data. In-app account deletion is not implemented. Review the requirements of
the intended distribution channel and the unresolved artwork provenance in
[Asset Licenses](ASSET_LICENSES.md) before distribution.
