# Aethera — Flutter

Flutter (Material 3) port of the Aethera React/Lovable app: same design tokens, fonts (Figtree, Bricolage, Noto Arabic), Lucide icons, Arabic/French with RTL, all farmer / expert / admin pages, Supabase auth + risk radar.

## Setup
```bash
flutter create . --project-name aethera --org io.aethera --platforms=android,ios
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```
(Defaults to the project's public values in `lib/config.dart` if omitted.) Requires Flutter 3.27+.

## Platform config
The Android and iOS folders are included and already contain the required configuration.
**Android** `android/app/src/main/AndroidManifest.xml` includes
```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.INTERNET"/>
```
and the callback inside `<activity>`:
```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW"/>
  <category android:name="android.intent.category.DEFAULT"/>
  <category android:name="android.intent.category.BROWSABLE"/>
  <data android:scheme="io.aethera.app" android:host="login-callback"/>
</intent-filter>
```
**iOS** `ios/Runner/Info.plist` includes `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, and
```xml
<key>CFBundleURLTypes</key><array><dict><key>CFBundleURLSchemes</key><array><string>io.aethera.app</string></array></dict></array>
```

## Notes
- Google sign-in uses Supabase OAuth; enable the provider in Supabase and allow `io.aethera.app://login-callback/` as a redirect URL.
- Lucide icons are bundled as an icon font.
- Voice/sensor features exist only as i18n strings, as in the source.
- Arabic switches the entire app to RTL and uses the bundled Noto Arabic font, including text input fields.
