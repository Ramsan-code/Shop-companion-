# Shop Companion: phase-by-phase build plan

Source: *Shop Companion PRD v4.0 (Flutter + Firebase mobile app)*, 1 Oct 2026.

The PRD's release plan (R0–R4, section 12.2) is the outer frame. R0 and R1 are split
into smaller build phases so each one ends with something that runs, has tests, and
can be reviewed on its own. Each phase lists the PRD IDs it covers and an exit gate.

| Phase | PRD release | Theme | Status |
|---|---|---|---|
| 0 | R0 | Foundations: app shell, design system, Rules + emulator tests, D3 templates, voice benchmark harness | **Built** |
| 1 | R1 | Auth, app lock, shop setup, members and invites | Next |
| 2 | R1 | Offline-first ledger: customers, credit, payments, receipts | |
| 3 | R1 | Voice entry end to end | |
| 4 | R1 | Collections Brain: Trust Score, Safe Credit Limit, Who To Ask Today | |
| 5 | R1 | Reminders, statement link, LankaQR, customer confirmation | |
| 6 | R1 | Daily shop: sales/expenses, Close Day, stock, Profit Mirror lite, low-literacy mode | |
| 7 | R1 | Switch-in import, export/backup, PDPA, hardening, pilot release | |
| 8 | R2 | Smart seasons | |
| 9 | R3 | Trust and finance | |
| 10 | R4 | Scale | |

---

## Phase 0: Foundations (R0, Oct–Nov 2026)

**Covers:** app shell, go_router, design system, Firebase project layout, Security Rules,
emulator tests, D3 templates, voice benchmark tooling.

Built in this phase:

- Flutter project (`lib/` laid out exactly as PRD 9.4) with Android as the only platform.
- `lib/app/`: Material 3 Tamil-first theme (48 dp targets, large numerals, system Noto Sans
  Tamil so nothing extra ships in the APK), Tamil/English ARB files, `go_router` with the
  redirect guard (not signed in → login, no shop → setup, role → shell).
- Owner/Partner shell on `convex_bottom_bar` (Home, Customers, **Mic**, Stock, More) and
  Helper shell on `bottom_navy_bar` (Entry, Customers, Close Day). Screens are placeholders.
- `lib/core/`: `Money` (integer cents, LKR formatting), `Failure` + `fpdart` result types,
  riverpod service providers, the `Role`/`Permission` model mirrored from `seed/roles.json`.
- Session is a `SessionCubit` over a fake auth repository; Phase 1 swaps in Firebase Auth.
- `features/voice/domain`: the v0 phrase parser ("Ravi annai 500 kadan", Tamil script,
  Tamil number words) and `tool/voice_benchmark.dart`, which scores a transcript CSV against
  the NFR targets (amount ≥ 90 %, customer ≥ 85 %).
- `firestore.rules` / `storage.rules`: deny by default, `isMember` / `hasPerm`, entry create
  validation, function-only paths. `rules-tests/` runs a role × permission matrix on the emulator.
- `functions/`: D3 reminder templates (kinship term × tone × language) and the reminder send
  policy (08:00–20:00 Colombo, one per customer per 3 days, STOP), both with unit tests.
- CI workflow for the folder: `flutter analyze`, `dart format`, Flutter tests, Functions tests,
  Rules tests on the emulator.

**Exit gate (PRD):** STT provider chosen; Rules tests pass.
Rules tests pass (263 cases on the emulator). The STT choice needs the field benchmark with 30+ Vanni speakers;
the harness is ready for their transcripts (see `tool/README.md`).

**Needs you (can't be done from code):**
- Create Firebase projects `shop-companion-dev`, `-staging`, `-prod` (asia-south1 or
  asia-southeast1, decide after PDPA cross-border guidance) and put the IDs in `.firebaserc`.
- Native Sri Lankan Tamil writers to review and rewrite the D3 template drafts.
- Record the voice benchmark set.

## Phase 1: Auth, app lock, shop setup, members (R1)

**Covers:** C10, C11, US8, US9; flow 7.1-1 up to "set PIN".

- `flutterfire configure` per flavor (dev/staging/prod), Firebase init, App Check (Play Integrity).
- Phone OTP with SMS auto-read; 4-digit PIN in `flutter_secure_storage` (hash only, never in
  Firestore); fingerprint via `local_auth`; auto-lock after 5 minutes idle.
- Callable `createShop` (writes shop + owner membership + audit), `inviteMember`,
  `acceptInvite`, `removeMember`; custom-claims refresh and forced ID-token refresh.
- `/invite/{token}` deep link; invite SMS with Play Store link.
- Scheduled function expiring invites.
- **Exit:** new phone restores the shop after OTP; a Partner invite lands in the right shell;
  Rules tests extended for members/invites.

## Phase 2: Offline-first ledger (R1)

**Covers:** C2, C3, C8, N6, US6, part of C9.

- Customers (add from contacts, kinship term, village, pay day), sorted by dues, search with
  rxdart debounce.
- Entries written to `shops/{shopId}/entries/{clientId}` with a UUID; balance shown instantly
  from local data and marked pending.
- `onEntryCreated` / `onEntryUpdated`: balance in a transaction, processed marker, audit log;
  `deleteEntry` callable; nightly balance reconciliation job.
- Payments: cash, bank, LankaQR, wallet; partial; settle with discount; receipt image/PDF via
  share sheet.
- Sync engine: redux store (outbox queue, pending badge, conflict log) + drift outbox for
  photos/audio; 24-hour unsynced warning.
- **Exit:** airplane-mode day test (300 entries, kill app, reboot) with zero lost or duplicate
  entries; repository tests on the Firestore emulator.

## Phase 3: Voice entry (R1)

**Covers:** C1, US1, flow 7.1-2.

- `speech_to_text` (on-device ta-LK first) with `parseVoice` callable as cloud fallback,
  using the provider chosen in Phase 0.
- Parser v1: per-shop name list and phonetic keys for customer matching.
- MobX confirm sheet: spoken (flutter_tts) and visual read-back, "sari" or one tap to save,
  keypad fallback always visible; Safe Credit Limit warning hook.
- **Exit:** benchmark ≥ 90 % amount / ≥ 85 % customer on the Vanni set; voice entry under
  10 seconds offline.

## Phase 4: Collections Brain (R1)

**Covers:** D1, D2, D5, US2, US4, flow 7.1-3.

- `recalcTrustScores` (nightly, rules-based, plain-language reasons) into
  `customers/{id}/private/score`; Safe Credit Limit with warning and owner override
  (`overrideLimit` callable).
- `buildWhoToAsk` at 06:00 Asia/Colombo → `insights/{date}` + FCM push; Who To Ask screen
  with one-tap call / WhatsApp / remind / snooze.
- **Exit:** scores reproducible from fixtures; push arrives at 06:00 on a pilot device.

## Phase 5: Reminders and statements (R1)

**Covers:** C7, D3, D8, N8, D18, US3, US5, flow 7.1-4.

- `scheduleReminders` + Cloud Tasks `sendReminder` using the Phase 0 policy and templates;
  WhatsApp utility templates (Cloud API adapter), SMS fallback adapter, delivery status.
- `messagingWebhook`: delivery status, STOP within 1 minute, Confirm / Dispute.
- Statement page on Firebase Hosting from `statements/{token}` with balance, entries,
  Confirm/Dispute and the shop's LankaQR (`qr_flutter` in-app).
- Tone preview in the app; owner approval mode.
- **Exit:** end-to-end reminder on a test number; STOP honoured; opt-out tracked.

## Phase 6: Daily shop (R1)

**Covers:** C4, C5, C6, D11 lite, N10, flow 7.1-5.

- Sales and expense quick-tap categories plus voice.
- Close Day: say counted cash, expected vs counted, Tamil audio summary, tomorrow's follow-ups.
- Basic stock with low-stock alerts (helpers update quantity only).
- Profit Mirror lite in plain Tamil; low-literacy mode (icon-first home, audio help).
- **Exit:** Close Day under 1 minute in usability test with 5 owners.

## Phase 7: Import, export, PDPA, pilot release (R1)

**Covers:** C9, N1, N2, N9 tooling, US10; NFRs in section 11.

- Excel/CSV import (Khatabook, OkCredit, Shopbook) with a MobX preview grid; voice bulk entry.
- Excel/PDF export; `exportShop` / `deleteShop`; `dailyBackup` (30 days).
- Crashlytics, Performance, Analytics (no names, phones or amounts); Remote Config for
  templates, calendars and flags.
- Size (< 25 MB per ABI), cold start (< 2.5 s on 2 GB phone), 60 fps on 500 customers.
- Play Store internal track, Tamil listing, champion QR; Play Billing policy check.
- **Exit (R1 gate):** 60 % of 50–100 pilot shops active 5+ days/week for 4 weeks; zero lost entries.

## Phase 8: R2 Smart seasons (Apr–Sep 2027)

D4 smart timing, D6 notebook photo OCR (`ocrNotebook`), D7 instalments, D9 good-payer badge,
D10 Festival Planner, D12/D13 Cash Drawer Check and helper audit, D14/D15 supplier payables and
expiry alerts, N7 harvest billing, Sinhala, iOS app; Mannar, Kilinochchi, Mullaitivu.
**Exit:** 30-day retention 50 %; first paid conversions.

## Phase 9: R3 Trust and finance (Q4 2027)

D17 Loan Readiness Report, Viber adapter, multi-shop (G4), LankaQR payment auto-match,
optional Windows counter app (fluent_ui), Jaffna. **Exit:** finance partner signed.

## Phase 10: R4 Scale (2028)

Eastern Province and island-wide; D20 only after PDPA guidance and legal review.
**Exit:** positive unit economics in the pilot district.

---

## Decisions taken while building

- **Credit-limit enforcement is not in Security Rules.** A rule that rejects a helper's
  over-limit credit would reject it *after* an offline day, which loses an entry (breaks N6).
  The app warns before saving, and `onEntryCreated` (Phase 2) flags the entry, writes the audit
  log and alerts the owner.
- **Entry types are split across two permissions.** `ledger:create` covers credit, payment and
  sale (helpers have it); `ledger:createExpense` covers expense, purchase and discount
  (owner/partner).
- **Platform Admin has no direct Firestore access.** Audit-log reads with consent and
  time-limited support access go through callable functions that write their own audit entry,
  so every admin read is logged.
- **Custom claims are not trusted in Rules yet.** Rules read the membership doc; claims can be
  stale until the token refreshes. Claims stay a client-side hint for routing.
- **No bundled Tamil font.** Android ships Noto Sans Tamil, which keeps the APK small.
