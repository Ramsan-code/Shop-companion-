# Shop Companion: phase-by-phase build plan

Source: *Shop Companion PRD v4.0 (Flutter + Firebase mobile app)*, 1 Oct 2026.

The PRD's release plan (R0–R4, section 12.2) is the outer frame. R0 and R1 are split
into smaller build phases so each one ends with something that runs, has tests, and
can be reviewed on its own. Each phase lists the PRD IDs it covers and an exit gate.

| Phase | PRD release | Theme | Status |
|---|---|---|---|
| 0 | R0 | Foundations: app shell, design system, Rules + emulator tests, D3 templates, voice benchmark harness | **Built** |
| 1 | R1 | Auth, app lock, shop setup, members and invites | **Built** |
| 2 | R1 | Offline-first ledger: customers, credit, payments, receipts | **Built** |
| 3 | R1 | Voice entry end to end | **Built** |
| 4 | R1 | Collections Brain: Trust Score, Safe Credit Limit, Who To Ask Today | **Built** |
| 5 | R1 | Reminders, statement link, LankaQR, customer confirmation | Next |
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

**Covers:** C10, C11, US8, US9; flow 7.1-1 up to "say shop name".

Built in this phase:

- **Config and flavors.** Android `dev` / `staging` / `prod` flavors (own app IDs and invite
  hosts). Backend picked at build time: `fake` (no Firebase), `emulator` (local Emulator
  Suite, `demo-shop-companion`) or `firebase` (real project via
  `--dart-define-from-file`, no keys in git). See `config/README.md`.
- **Firebase start-up.** Unlimited offline cache; App Check with Play Integrity in prod and
  the debug provider in dev/staging.
- **Phone OTP login.** Sri Lankan number check (same rule as the server), SMS auto-read via
  `verificationCompleted`, code entry as fallback, resend and change number. First sign-in
  creates `users/{uid}`.
- **App lock.** 4-digit PIN entered twice, stored only as a salted PBKDF2-SHA256 hash in
  `flutter_secure_storage`, per user. Fingerprint unlock (`local_auth`). Auto-lock after
  5 idle minutes or 5 minutes in the background. 5 wrong PINs wipe the PIN and sign out, so
  getting back in needs a new OTP. Every cold start opens locked.
- **Router guard**, in order: session → signed in → PIN set and unlocked → shop (or join
  from an invite) → role shell.
- **Functions** (`asia-south1`): `createShop`, `inviteMember`, `acceptInvite`,
  `removeMember` callables (App Check enforced when deployed) and `expireInvites`
  (every 6 hours). Each writes an audit log and refreshes the `shops` custom claim; the app
  force-refreshes its ID token afterwards.
- **Invites.** 7-day single-use token, stored only as a SHA-256 hash; bound to the invited
  phone number, so a forwarded link is useless. A new invite to the same phone replaces the
  old one. The owner shares it from the Members screen through the Android share sheet (SMS
  or WhatsApp). `/invite/{token}` opens the app via App Links, or a Tamil/English page on
  Hosting with the Play Store link.
- **Members screen** (owner only): list, invite as Partner or Helper, remove with confirm.
- **Rules:** `users/{uid}.activeShopId` and `inviteTokens` are server-only; a client can't
  set its own phone number to anything but its verified one.

**Exit:** a new phone restores the shop after OTP (the session is rebuilt from
`users/{uid}.activeShopId` → membership → shop, all server-side); a Partner invite lands in
the right shell. Covered by 13 emulator tests on the functions, 264 Rules tests, and
49 Flutter tests including the full first-time setup flow. Not yet run on a device (see below).

**Decisions:**
- One shop per user until multi-shop (G4, Release 3): `createShop` and `acceptInvite`
  refuse a second shop.
- Invite SMS goes through the owner's share sheet for now; automatic sending from the server
  uses the SMS gateway adapter built in Phase 5.
- Plan limits on staff numbers (Free 1 user, Plus 1 helper, Pro 5) are enforced with billing
  in Phase 7, not yet.

**Needs you:**
- Firebase projects, then `config/<flavor>.json` from the examples and
  `functions/.env.<project-id>` with `INVITE_BASE_URL`.
- Enable Phone sign-in in Firebase Auth; register the app's SHA-256 for Play Integrity.
- A device run: this environment can't download the Android SDK, so no APK was built here.

## Phase 2: Offline-first ledger (R1)

**Covers:** C2, C3, C8, N6, US6, part of C9.

Built in this phase:

- **Customers.** Add or edit (name, kinship term, phone, village, income type, pay day),
  pick from the phone's contacts, list sorted by highest dues, search by name, village or
  phone with a 250 ms rxdart debounce in `CustomersBloc`, swipe a row to record a payment
  or call. Customer IDs are made on the phone, so customers can be added offline.
- **Ledger entries** at `shops/{shopId}/entries/{clientId}` with a UUID made on the phone.
  Writes are not awaited: Firestore stores them locally at once and uploads when signal
  returns; a re-sent clientId can't duplicate.
- **Pending balance.** The app shows server balance + entries the server hasn't applied yet
  (`applied == null`), with a "waiting to sync" marker, then switches to the confirmed value
  without double-counting.
- **Payments.** Cash, bank, LankaQR, wallet; partial payments; Owner/Partner can "settle"
  (payment + discount entry for the rest). Back-dated entries via the date picker, ordered
  by transaction date. Receipt shared as a PNG through the share sheet or WhatsApp.
- **Customer page.** Balance, give credit / record payment, full history with the running
  balance. Edit an entry (author within 24 hours: direct; Owner/Partner: any entry via
  `editEntry`); Owner/Partner delete (soft) via `deleteEntry`.
- **Helper Entry tab.** Give credit / record payment → pick customer → form.
- **Functions:** `onEntryCreated` / `onEntryUpdated` apply each entry idempotently (the entry
  stores `applied`, the change already made; triggers move balances only by the difference,
  so retries, duplicates and out-of-order events can't double-count, and the trigger's own
  write is a no-op). Every create and edit is audited. `reconcileBalances` (02:30 Colombo)
  recomputes every balance from entries, fixes and audits drift, and sets the exact oldest
  unpaid date (oldest credit first).
- **Sync engine:** a redux `SyncState` (online, pending count, oldest pending, last synced,
  refused writes), fed only by `SyncService` from connectivity_plus and the ledger. App-bar
  badge with the count, offline state, and a warning after 24 hours unsynced.
- **Rules:** new `ledger:editAny` (Owner, Partner). Customers: field allow-list and
  validation. Entries: payment method, dates and note checked, `applied` may only start
  null, edits must carry `updatedBy` = editor.

**Exit:** balances are proven by 22 emulator tests (incl. three concurrent triggers on one
entry counting once) and a run of the real triggers in the Functions emulator. The offline
behaviour (pending balance, badge, confirmation without double count) is covered by widget
tests. **Not yet done:** the airplane-mode day test on a real phone (300 entries, kill app,
reboot). It needs a device.

**Decisions:**
- **Receipts are images, not PDFs.** PDF libraries without a text shaper break Tamil vowel
  signs; Flutter renders Tamil correctly.
- **No drift outbox yet.** Ledger writes go through Firestore's own offline queue, as the PRD
  intends. Nothing in Phase 2 uploads files, so the drift outbox for audio and photos comes
  with the first file upload: voice clips in Phase 3.
- **Pending marker on edits is per customer page.** The customer list counts new unconfirmed
  entries; an unconfirmed edit shows on the customer's own page until the server applies it.
- **Helpers ask, they don't change:** an entry from someone else, or older than 24 hours,
  shows "only the owner or partner can change this". The request flow for helpers is part of
  the helper audit view (D13, Release 2).

**Bugs found and fixed while testing on a phone-sized screen:**
- Bottom sheets opened inside the tab, under the bottom bar, which hid their Save buttons.
  All sheets now open above the bar.
- The bar label வாடிக்கையாளர் wrapped and overflowed on 411 dp phones; labels are one line.
- The Tamil sync text overflowed the app bar; the chip shows icon and count, with the full
  sentence in the tooltip and TalkBack label.

## Phase 3: Voice entry (R1)

**Covers:** C1, US1, flow 7.1-2.

Built in this phase:

- **Voice sheet** from the centre mic (Owner/Partner) and the Entry tab (Helper):
  tap → speak → spoken read-back in Tamil ("ரவி அண்ணை, 500 ரூபா கடன். சரியா?") and
  on-screen card → say "சரி" / "ஓம்" / "sari" (or tap Save) → saved locally, offline.
  "இல்லை" leaves it open to correct.
- **Keypad fallback is the same form**: customer search, amount and credit/payment are
  always editable, so a misheard amount is fixed by typing and the whole entry can be typed
  when speech isn't available.
- **Recognition (PRD 4.3):** Android's recogniser first, with Sri Lankan Tamil (else any
  Tamil) and the shop's customer names as hints; offline when the Tamil pack is installed.
  If it can't do Tamil and there is signal, **cloud fallback**: an AMR-WB clip goes through
  the drift outbox to Cloud Storage and `parseVoice` transcribes it.
- **Parser v1, customer matching:** sound-alike keys make Tamil script and romanised names
  match ("ரவி" = "Ravi", "தங்கராசா" = "Thangarasa"); the kinship word separates two
  customers with the same name; ambiguous names show choices instead of guessing; an unknown
  name is offered as a new customer. Keys are saved on customers as `phoneticKeys`.
- **MobX** `VoiceEntryStore` holds the sheet's short-lived form state, created and disposed
  with the sheet, as PRD 9.1 sets out.
- **Drift outbox** (`lib/sync/outbox`) for files: queued offline, uploaded oldest first when
  online, retried with backoff up to 5 times, requeued after a crash. Its size shows in the
  sync badge through the redux store. Notebook photos (Release 2) will use it too.
- **Function `parseVoice`:** checks membership and the clip ID, transcribes with Google Cloud
  Speech-to-Text (ta-LK, biased with the shop's customer names) behind a swappable adapter,
  and deletes the clip whatever the outcome. It returns the transcript; the app parses it
  with the same Dart parser as on-device speech, so there is one parser, not two.
- **Benchmark CLI** takes an optional customer-name list: customer accuracy then means
  picking the right customer, as in the app.

**Exit (PRD):** benchmark ≥ 90 % amount / ≥ 85 % customer on the Vanni set; voice entry
under 10 seconds offline. **Not met yet:** both need the field recordings and a phone.
The flow is speak (~3 s) → read-back (~3 s) → "சரி" (~1 s), within the target if the
recogniser is quick.

**Decisions:**
- **Spoken confirmation only after on-device recognition.** A cloud round trip is too slow
  for a one-word answer, so cloud results are confirmed with a tap.
- **Read-back says amounts as digits.** The Tamil TTS voice reads "1500" as ஆயிரத்து
  ஐநூறு itself, more reliably than spelled-out words.
- **No voice audio is kept.** On-device recognition never stores audio; a cloud clip is
  deleted by `parseVoice` and from the phone after use. Add a Storage lifecycle rule
  (delete `shops/*/voice/` after 1 day) as a safety net.
- **The Safe Credit Limit warning** joins this sheet and the entry sheet in Phase 4.

**Needs you:** enable the Cloud Speech-to-Text API on the Firebase projects; record the Vanni
benchmark set; test on a 2 GB Android Go phone with and without the Tamil offline pack.

## Phase 4: Collections Brain (R1)

**Covers:** D1, D2, D5, US2, US4, flow 7.1-3.

Built in this phase:

- **Trust Score (D1)**, rules-based in `functions/src/collections/scoring.ts`: start at 70,
  then overdue days (−15 / −30 / −45 past 30 / 60 / 90 days), regular payments (+10 for 3+ in
  90 days, −10 for none while owing), share of credit repaid in 180 days (+10 ≥ 80 %,
  −10 < 30 %), balance far above usual (−10), customer 6+ months (+5), settled (+5). New
  customers start at 60 and aren't judged on repayment yet. Bands: excellent ≥ 80, good ≥ 60,
  watch ≥ 40, risky. Every score carries its plain reasons (codes the app shows in Tamil).
- **Safe Credit Limit (D2)**: the larger of a month's repayments and twice the usual credit,
  × 2 / 1.5 / 1 / 0.5 by band, rounded to Rs. 100, at least Rs. 500 (not for risky).
  Customers with no payments yet get the shop's new-customer limit (default Rs. 2,000).
  The owner can override it (`overrideLimit`, audited); Partners only when the shop allows.
- **Nightly** `recalcTrustScores` (02:30 Colombo) reads each shop's entries once, reconciles
  balances (this replaces Phase 2's separate `reconcileBalances`), and writes score, reasons
  and limits to `customers/{id}/private/score`. Unchanged scores aren't rewritten.
- **Who To Ask Today (D5)**: `buildWhoToAsk` at 06:00 Colombo ranks up to 10 people by
  overdue days, balance, pay day within 2 days, and band; skips snoozed people and anyone
  called or WhatsApped in the last 2 days; saves `insights/{date}`; pushes "N people · Rs. X"
  to Owner and Partner phones in their language, and drops dead push tokens.
- **Home screen** (Owner/Partner) is now Who To Ask: live balances (marked when paid since
  the morning), plain reason, band, one-tap Call, WhatsApp (pre-filled polite Tamil
  message), Record payment, and Later (3 days or next pay day). Before the 06:00 list exists
  it shows the highest dues instead.
- **Customer page**: band, score, top reasons and the safe limit; owner can change the limit.
- **Limit warning** before saving credit, in the entry sheet and the voice sheet: "This
  takes Ravi to Rs. 2,300, above the safe limit of Rs. 2,000", with a "give anyway" tick.
  An over-limit voice entry is never saved by "சரி" alone.
- **Server safety net**: any first-time credit that leaves a customer above their limit is
  flagged `overLimit` and audited (`limit.exceeded`), whoever entered it, including Helpers,
  who can't see limits.
- **Push**: Owner/Partner phones register for notifications (users/{uid}.fcmTokens, at most
  10); tapping the push opens Who To Ask.
- **Rules**: `collectState/{customerId}` (snooze / last contact) for Owner/Partner, snoozes at
  most 31 days, server time only.

**Exit:** scores are reproducible from fixtures (unit tests on fixed entry histories);
**not yet checked:** the 06:00 push arriving on a pilot phone.

**Decisions:**
- **The limit lives in the private score document, not on the customer.** PRD 10.1 lists
  `creditLimitCents` on the customer, but PRD 6 says Helpers must not see limits and they can
  read customer documents. Section 6 wins.
- **Helpers aren't blocked by limits.** Blocking would lose an offline entry. The server
  flags and audits it; a push to the owner about it comes with helper alerts (D13,
  Release 2).
- **Partners can tick "give anyway"** for a single entry; the server audits it. Changing the
  limit itself is owner-only unless the shop allows Partners.
- **The push shows a count and total only**: no names or amounts per customer on a lock
  screen.
- **Rules first.** The numbers are starting points to tune with pilot shops. Seasonal timing
  (harvests, D4) comes in Release 2.

**Needs you:** check the push on a pilot phone; with pilot owners, review whether the bands
and limits feel right.

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
