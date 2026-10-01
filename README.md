# Shop Companion

Tamil-first, voice-first credit ledger for small shops in Vavuniya.
Flutter (Android first) + Firebase. Built from *Shop Companion PRD v4.0*.

**Status: Phase 0 (Foundations) built.** See [PLAN.md](PLAN.md) for every phase,
what each covers from the PRD, and its exit gate.

## Layout (PRD 9.4)

```
lib/
  app/        router (go_router), theme, l10n (ta/en ARB), shells
  core/       riverpod providers, Failure + fpdart results, Money (cents), RBAC model
  sync/       (Phase 2) redux sync store, drift outbox, connectivity
  features/   auth, ledger, customers, voice, collections, close_day, stock, settings
test/         unit and widget tests
tool/         voice benchmark CLI (see tool/README.md)
seed/         roles.json: role → permission map seeded into roles/{role}
functions/    Cloud Functions (TypeScript): reminder templates + send policy
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
flutter run                 # Android device or emulator
```

Phase 0 has no Firebase yet. The login screen has a debug-only role picker
(Owner / Partner / Helper) to see each shell. The centre mic opens the voice
sheet, which parses typed phrases such as `Ravi annai 500 kadan`.

## Checks

```sh
flutter analyze && flutter test
dart format --output=none --set-exit-if-changed lib test tool

cd functions && npm ci && npm run typecheck && npm test
cd rules-tests && npm ci && npm test     # starts the Firestore + Storage emulators
```

CI runs all three in `.github/workflows/ci.yml`.

## Before Phase 1

- Create Firebase projects for dev, staging and prod in asia-south1 or
  asia-southeast1 and put their IDs in `.firebaserc`.
- Seed `roles/{role}` from `seed/roles.json`.
- Native Sri Lankan Tamil writers review the reminder drafts in
  `functions/src/reminders/templates.ts`.
