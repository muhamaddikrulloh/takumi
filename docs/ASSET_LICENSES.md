# Asset Licenses and Provenance

The [MIT License](../LICENSE) covers project source code. Third-party assets
retain their own terms, and trademarks are not relicensed under MIT. A file
being present in this repository does not establish permission to redistribute
it. Unverified entries below require maintainer review before publication or
distribution.

| Asset group | Location | Status |
| --- | --- | --- |
| Takumi app logo | `assets/images/app_logo.png`, `docs/assets/logo.png` | Created by Muhammad Dikrulloh. All rights reserved. Licensed for use solely within this project and its official distributions; not relicensed under MIT. |
| Android launcher and splash artwork | `android/app/src/main/res/mipmap-*/`, `drawable-nodpi/launch_image.png` | Variants of the app logo created by Muhammad Dikrulloh. Covered under the same project-use license as the app logo. |
| Google sign-in mark | `assets/images/google_logo.png` | Google trademark. The downloaded file's source is not recorded. Review it and the sign-in button against Google's current [branding guidelines](https://developers.google.com/identity/branding-guidelines); it is not MIT artwork. |
| Notification icon | `android/app/src/main/res/drawable/ic_notification.xml` | Clock-shaped vector with no recorded author/source. Confirm its origin and any required notice. |
| Generated profile avatars | `lib/features/profile/presentation/widgets/generated_avatar.dart` | Drawn in Dart; there are no separate avatar image files in the repository. Covered as project source code, subject to contributor rights. |
| Phosphor Icons | `phosphoricons_flutter` dependency | The installed package and its bundled icon fonts declare MIT licensing. Preserve their copyright/license notices. |
| Material Icons | Flutter's `uses-material-design` assets | Supplied by Flutter; retain the upstream Apache-2.0 icon notices. |
| Plus Jakarta Sans | Used through `google_fonts` in `app_theme.dart` | Copyright 2020 The Plus Jakarta Sans Project Authors, SIL Open Font License 1.1 ([upstream license](https://github.com/google/fonts/blob/main/ofl/plusjakartasans/OFL.txt)). No font files are checked into this repository; the package may fetch them at runtime. |

The `google_fonts` package itself uses BSD-3-Clause; that is separate from the
fonts' licenses. Preserve package and font notices in distributed builds.
Flutter collects package license notices, but this app does not currently
provide a dedicated licenses screen. Review notice delivery before APK
distribution; adding a screen would be a separate UI change.

For new or unverified artwork, record the author, original source, license or
written permission, and required attribution here. This audit does not assert
ownership of Takumi's visual identity or approve Google branding compliance.
No visual asset has been removed or replaced.
