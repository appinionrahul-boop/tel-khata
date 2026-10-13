# Tel Khata

Fuel log and mileage calculator for Android (Flutter).

- Multiple vehicles (car, motorcycle, truck, bus, other)
- Fuel log with full-tank mileage calculation (partial fill-ups and missed fill-ups handled)
- Service and expense log (service, repair, tyres, insurance, tax, parking, toll, wash)
- Dashboard: average, last, best and worst mileage, cost per distance, totals, mileage trend chart, 6-month spend chart
- First-launch setup: currency, km or miles, liters or gallons (changeable in Settings)
- Offline-first local database; cloud sync runs on app open, on resume and after every change once a backend is plugged in

## Run it

Requires Flutter 3.24 or newer.

```bash
cd fuel_log
flutter create --org com.appifly --platforms=android .
rm test/widget_test.dart
flutter pub get
flutter run
```

`flutter create .` only adds the missing Android project files; it does not overwrite `lib/`.
Delete the generated `test/widget_test.dart` because it refers to a counter app that doesn't exist here.

Run the tests:

```bash
flutter test
```

Build a release APK:

```bash
flutter build apk --release
```

## Performance on low-end phones

Debug mode (`flutter run`) is always slower and can stutter. Judge smoothness with:

```bash
flutter run --profile
```

For release, build one small APK per CPU type instead of one large APK:

```bash
flutter build apk --release --split-per-abi
```

Use `app-armeabi-v7a-release.apk` for older/budget phones and `app-arm64-v8a-release.apk` for most modern ones.

Built in for smooth UI:
- Light fade + slide page transition instead of the heavier default zoom
- Bottom tabs are built once and kept alive, so switching is instant and keeps scroll position
- Background glows and charts are cached in their own layers, so scrolling doesn't repaint them
- Blurred glow shadows only on a few highlight elements, never on list rows
- Lists build rows lazily; stats are calculated once per data change, not on every frame

## How mileage is calculated

Mileage is calculated on full-tank fill-ups only:

`distance since previous full fill-up / all fuel added since then (including partial fill-ups)`

- The first full fill-up has no mileage; it is the starting point.
- A partial fill-up adds its fuel to the next full fill-up.
- "Missed previous fill-up" resets the chain, since the missing fuel is unknown.
- Average mileage is weighted: total distance / total fuel across all calculated segments.

Values are stored in km and liters and converted for display, so changing units later never corrupts data.

## Project structure

```
lib/
  core/            units, currencies, enums, formatters
  data/
    models/        Vehicle, FuelEntry, ExpenseEntry (all Syncable)
    db/            SQLite schema
    repositories/  SyncableRepository (local CRUD + dirty tracking)
  services/
    mileage_calculator.dart
    settings_service.dart
    sync/          RemoteStore interface + SyncManager
  state/           AppState (provider)
  ui/              screens and widgets
```

## Cloud sync

Every record has a UUID, `updated_at` and a soft-delete flag. Local changes are marked dirty,
pushed on sync, then newer remote rows are pulled (last write wins).

Sync is off until you pass a `RemoteStore` in `lib/main.dart`:

```dart
final sync = SyncManager(repos, settings, null);
```

See `docs/FIREBASE_SYNC.md` to enable it with Firebase.
