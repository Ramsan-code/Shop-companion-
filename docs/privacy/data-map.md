# Data map (record of processing)

PDPA No. 9 of 2022 (as amended 2025). The **shop owner** is the controller for their
customers' data; Shop Companion is the processor for it and the controller for account data.
Region: Firestore and Functions in `asia-south1` (confirm after PDPA cross-border guidance).

| Data | Whose | Where | Why | Kept | Who reads it |
|---|---|---|---|---|---|
| Phone number, PIN status, locale, FCM tokens | Shop staff | `users/{uid}`, Firebase Auth | Sign-in, morning push | Until account deletion | The user; functions |
| PIN hash | Shop staff | Phone only (secure storage) | App lock | On the phone | Nobody else |
| Shop name, settings, LankaQR payload | Shop | `shops/{id}` | Running the shop | Until shop deletion | Members |
| Customer name, phone, village, pay day, kinship term, consent | Customer | `customers/{id}` | Ledger, reminders (with consent) | Until erased or shop deleted | Members by role |
| Credit, payments, sales, expenses (amounts, dates, notes) | Shop / customer | `entries/{id}` | The books | Until shop deleted; notes removed on erasure | Members |
| Trust score, safe credit limit | Customer | `customers/{id}/private/score` | Who to ask; credit warning | Recomputed nightly | Owner, Partner |
| Reminders and delivery status | Customer | `reminders/{id}`, `messageIndex`, `optOutIndex` | Sending, STOP | Until erased or shop deleted | Owner, Partner; functions |
| Statement snapshot | Customer | `statements/{token}` | Customer's own statement link | 30 days | Whoever has the link |
| Voice clips | Shop staff | Storage `shops/{id}/voice/` | Cloud speech fallback | Deleted after recognition (≤ 1 day lifecycle) | Functions only |
| Exports | Shop | Storage `shops/{id}/exports/` | Free export (N1), PDPA portability | 7 days (lifecycle) | Owner |
| Nightly backup | All | `gs://<project>-backups/backups/{date}/` | Disaster recovery | 30 days | Platform admins (break-glass) |
| Audit logs | Shop | `auditLogs/{id}` | Accountability | Until shop deletion | Owner |
| Analytics, Crashlytics | Device | Google Analytics / Crashlytics | Funnel and stability | Google defaults (14 months / 90 days) | Product team; **no names, phones or amounts** |

Processors: Google (Firebase, Cloud Speech-to-Text), Meta (WhatsApp Cloud API), the SMS gateway.
Each needs a data processing agreement before pilot (see breach-response.md "Before pilot").
