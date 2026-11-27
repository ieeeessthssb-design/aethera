# Flutter asset filename repair

The two image files in `app/assets/images/` had filenames corrupted by character-encoding/mojibake. Their names contained non-ASCII characters that Flutter's Windows web DevFS attempted to copy into `build/flutter_assets`, causing `PathNotFoundException` / Windows error 123.

Renamed without changing image contents:
- `loading.jpeg`
- `loading_1.jpeg`

No Dart source references to the original filenames were found in the supplied project. The asset directory declaration remains unchanged.

After extracting this archive on Windows, run from `app/`:

```powershell
flutter clean
flutter pub get
flutter run -d chrome
```
