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

## Cloud Functions configuration

Per Firebase project, in `functions/.env.<project-id>` (not secret):

| Param | Example |
|---|---|
| `PUBLIC_BASE_URL` | `https://shop-companion-prod.web.app` (invite and statement links) |
| `WHATSAPP_PHONE_NUMBER_ID` | from Meta Business → WhatsApp → API setup |
| `SMS_USER_ID`, `SMS_SENDER_ID` | from the SMS gateway (Notify.lk adapter today) |

Secrets, set with `firebase functions:secrets:set NAME --project <id>`:
`WHATSAPP_TOKEN`, `WHATSAPP_APP_SECRET`, `WHATSAPP_VERIFY_TOKEN`, `SMS_API_KEY`.

WhatsApp setup:
1. Register the six utility templates from `functions/src/reminders/templates.ts`
   (`due_reminder_{gentle,normal,firm}_{ta,en}`), each with body parameters
   {{1}}–{{4}} and two quick-reply buttons: Confirm, Dispute.
2. Point the app's webhook at
   `https://asia-south1-<project>.cloudfunctions.net/messagingWebhook` with
   `WHATSAPP_VERIFY_TOKEN`, and subscribe to `messages`.
3. Enable the Cloud Tasks API (reminder queue) and Cloud Speech-to-Text API.
