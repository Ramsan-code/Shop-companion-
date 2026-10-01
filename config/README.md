# Build configuration

The app reads its backend and Firebase settings from compile-time defines,
so nothing project-specific is committed. Copy an example, fill it in and keep
the real file out of git (`config/*.json` is ignored; `*.example.json` is not).

| Flavor | Command |
|---|---|
| dev, fake backend (no Firebase) | `flutter run --flavor dev` |
| dev, local emulators | `flutter run --flavor dev --dart-define-from-file=config/dev.json` |
| staging | `flutter run --flavor staging --dart-define-from-file=config/staging.json` |
| prod | `flutter build appbundle --flavor prod --dart-define-from-file=config/prod.json` |

`BACKEND` is `fake`, `emulator` or `firebase` (default: `fake` for dev,
`firebase` otherwise).

For the emulators, start them from the repo root with
`firebase emulators:start --project demo-shop-companion` after
`npm --prefix functions run build`. Use `EMULATOR_HOST=10.0.2.2` for the
Android emulator, or your computer's LAN IP for a real phone. Phone OTP codes
appear in the Emulator UI (http://localhost:4000/auth).

Values for staging/prod come from Firebase console → Project settings → Your
apps → Android app (`lk.shopcompanion.shop_companion.staging` / `lk.shopcompanion.shop_companion`).
Staging uses the App Check debug provider: register the debug token printed in
logcat in the console. Prod uses Play Integrity.
