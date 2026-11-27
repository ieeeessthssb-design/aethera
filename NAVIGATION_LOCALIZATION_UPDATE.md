# AETHERA navigation and settings update

## Navigation layout
- Desktop/tablet widths of 900 px and above use a collapsible `NavigationRail`.
- Smaller screens use a slide-out drawer.
- The desktop rail and mobile drawer expose Home, Farms, Irrigation, AI Assistant, Crop Diagnosis, Weather, Community, Messages, Profile, and Settings.
- The mobile bottom navigation is intentionally limited to Home, Farms, Irrigation, and AI Assistant.
- Profile and Settings are accessible from the sidebar/drawer; the profile page also links to Settings.

## Language and appearance preferences
- Language and theme changes are persisted before publishing the new Riverpod settings state. Unsupported saved language codes fall back to English.
- Localization catalogs contain 71 matching keys in English, French, and Arabic. Farmer navigation, profile/settings, and farm-management strings are now connected to generated resources; other feature screens remain to be migrated.
- Directional chevrons and sidebar collapse affordances in the farmer shell adapt to Arabic RTL direction.
- Supported locales remain English (`en`), French (`fr`), and Arabic (`ar`).
- Flutter's locale-aware directionality provides RTL layout when Arabic is selected.

## Validation
ARB JSON and generated localization API parity were checked for all three locales. Added tests cover preference persistence and unsupported-locale fallback. The archive was checked for ZIP integrity. Flutter/Dart SDK was not available in the packaging environment, so `flutter analyze`, `flutter test`, and device/browser runtime validation still need to be run locally.
