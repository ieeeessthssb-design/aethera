# AETHERA localization — Phase 1

## Implemented in this milestone

- Expanded the English, French, and Arabic ARB catalogs from 26 to 66 shared message keys.
- Added translations for the farmer shell navigation, account/settings labels, profile actions, and the farm list/create/details workflow.
- Added the required `farmSaveError` placeholder metadata and matching generated localization APIs.
- Kept the saved language preference as the single language source in `AppSettings`; unsupported stored locale codes now fall back to English.
- Replaced hardcoded locale triplets in the farmer shell navigation and settings/profile/farm flows with generated localization messages.
- Made directional navigation affordances (sidebar collapse, settings/profile/farm chevrons) respond to the active text direction. Flutter's `MaterialApp` + `GlobalWidgetsLocalizations` already provides RTL `Directionality` for Arabic.
- Added tests for language preference persistence and unsupported-language fallback.

## Not yet complete

This is a first localization milestone, not a claim that every screen is translated. The following still contain hardcoded user-facing copy and need the same ARB migration:

- Authentication and account verification.
- Home/dashboard marketing and operational cards.
- Weather, irrigation, diagnosis, community, and messages.
- Expert/admin workspaces and queue states.
- Voice assistant and its permission/error states.
- API error messages, date/number formatting, and server-provided content.

RTL still needs visual review on every screen, especially custom charts, image overlays, chat bubbles, and any physical left/right padding or icon usage.

## Validation status

- ARB JSON parsed successfully for all three locales.
- All three ARB catalogs have the same 66 message keys.
- Generated localization interface and per-locale implementations contain matching APIs.
- Flutter SDK / Dart CLI were not available in the build environment, so `flutter gen-l10n`, `dart format`, `flutter analyze`, and `flutter test` could not be executed here. Run those commands locally before merging.
