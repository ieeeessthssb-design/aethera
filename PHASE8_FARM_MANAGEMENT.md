# AETHERA — Phase 8: Farm Management

## Scope

Phase 8 adds editing of existing farm profiles to the Phase 7 project snapshot.

### Flutter
- Farm cards show name, location, area (when provided), soil type and irrigation type.
- Each farm card has an edit action.
- The edit dialog is pre-populated with the selected farm's current values.
- Saving calls `PATCH /farms/{farm_id}` and replaces the existing in-memory card; it does not create a duplicate.
- Success and error feedback are localized in English, French and Arabic.

### FastAPI
- `PATCH /farms/{farm_id}` requires an authenticated user with the `farmer` role.
- The query filters by both farm ID and current user's ID. A missing or non-owned farm returns 404.
- Pydantic validates profile fields. Unspecified fields are left unchanged.
- GPS coordinates are excluded from the profile-update schema and are therefore preserved.
- Existing `PATCH /farms/{farm_id}/location` remains available for coordinate updates.

## Validation performed
- Python backend source compiled with `compileall`.
- English, French and Arabic ARB files parsed as valid JSON.
- Generated localization interfaces and all three locale implementations updated.
- Static invariant checks confirmed ownership filtering, partial updates and exclusion of GPS coordinates.
- ZIP integrity checked after packaging.

Flutter format/analyzer/tests and live API/database integration were not run in this environment because Flutter/Dart and a running AETHERA stack were unavailable.

## Run and verify on Windows

From the project root:

```powershell
docker compose up -d --build
```

In a second terminal:

```powershell
cd app
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

## Manual acceptance test
1. Sign in as a farmer and open **Farms**.
2. Edit an existing farm and confirm the form is pre-populated.
3. Change the name, location, area, soil type and irrigation type, then save.
4. Confirm the existing card changes and no duplicate farm is created.
5. Reload the app and confirm the updated values persist.
6. Repeat in French and Arabic; verify Arabic right-to-left layout.
7. Confirm the farm's saved GPS coordinates remain unchanged after profile editing.
8. Attempt to update another farmer's farm ID through the API; it must return 404.
