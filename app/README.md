# AETHERA Flutter application

This is the Flutter client. Run it locally with the Flutter SDK from VS Code; it is not part of the Docker Compose build.

```powershell
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

The FastAPI backend is expected at `http://localhost:8000` when running through the root Docker Compose setup. See the repository-root `README.md` for the complete workflow.
