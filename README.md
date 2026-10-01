# Shop Companion

Tamil-first, voice-first credit ledger for small shops in Vavuniya.
Flutter (Android first) + Firebase. Built from *Shop Companion PRD v4.0*.

**Status: Phases 0–7 built — Release 1 feature-complete; the pilot release needs the steps under Phase 7 "Needs you"** (foundations; auth, app lock, members; offline-first ledger; voice entry; Collections Brain; reminders and statement links; sales, expenses, Close Day, stock and simple mode; import, export, PDPA, backups, observability, release pipeline). See [PLAN.md](PLAN.md) for every phase,
what each covers from the PRD, and its exit gate.

## Layout (PRD 9.4)

```
lib/
  app/        router (go_router), theme, l10n (ta/en ARB), shells
  core/       riverpod providers, Failure + fpdart results, Money (cents), RBAC model
  sync/       redux sync store, sync service, badge; drift outbox for file uploads
  features/   auth, ledger, customers, voice, collections, reminders, close_day, stock, data, settings
test/         unit and widget tests
tool/         voice benchmark CLI (see tool/README.md)
seed/         roles.json: role → permission map seeded into roles/{role}
config/       build-time backend settings (examples committed)
functions/    Cloud Functions (TypeScript): members, ledger, voice, collections, reminders, statements, webhook, closing, data (export, erasure, deletion, backup)
hosting/      Firebase Hosting: invite, statement, champion QR (/get), privacy and account-deletion pages
rules-tests/  Security Rules tests on the Firebase emulator
firestore.rules, storage.rules, firestore.indexes.json, firebase.json
```

State management follows PRD 9.1: blocs/cubits for feature state, riverpod only
for service wiring, fpdart `Either`/`TaskEither` across layers. MobX and redux
join in Phases 2–3, inside the boundaries the PRD sets.

## Run it

Requires Flutter 3.47 (Dart 3.13), Node 22 and Java 21.

```sh
flutter pub get
dart run build_runner build                    # only after changing drift tables
flutter run --flavor dev                       # fake backend, no Firebase needed
```

With the fake backend the OTP is `123456`, and the login screen also has a
role picker (Owner / Partner / Helper). Invite token `demo-partner` joins as
Partner. The fake backend starts with three demo customers.

Against the local Firebase emulators (real OTP flow, functions and rules):

```sh
npm --prefix functions ci && npm --prefix functions run build
npx --prefix functions firebase emulators:start --project demo-shop-companion
cp config/dev.example.json config/dev.json
flutter run --flavor dev --dart-define-from-file=config/dev.json
```

OTP codes appear in the Emulator UI at http://localhost:4000/auth. Staging and
prod builds are described in [config/README.md](config/README.md).

## Checks

```sh
flutter analyze && flutter test
dart format --output=none --set-exit-if-changed lib test tool

cd functions && npm ci && npm run typecheck && npm test && npm run test:emulator
cd rules-tests && npm ci && npm test     # starts the Firestore + Storage emulators
```

CI runs all three in `.github/workflows/ci.yml`.

## Before the pilot

- Create Firebase projects for dev, staging and prod in asia-south1 or
  asia-southeast1, put their IDs in `.firebaserc`, enable Phone sign-in.
- Seed `roles/{role}` from `seed/roles.json`.
- Native Sri Lankan Tamil writers review the reminder drafts in
  `functions/src/reminders/templates.ts` and the app strings in `lib/app/l10n/app_ta.arb`.
