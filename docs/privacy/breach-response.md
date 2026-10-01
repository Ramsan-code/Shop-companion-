# Personal data breach response plan

Owner: the named **Data Protection Officer** (privacy@shopcompanion.lk — set the real person
and address before pilot). Deputy: the engineering lead.

## 1. Detect (hour 0)
Signals: Firebase App Check / Auth anomalies, unexpected Rules denials spike in Cloud Logging,
a report from a shop or customer, a leaked key in a repository (GitHub secret scanning on).

## 2. Contain (within 4 hours)
- Rotate any leaked secret (`firebase functions:secrets:set`), revoke the service account key.
- Tighten Security Rules with an emergency deploy if a rule is at fault; `firebase deploy --only firestore:rules`.
- Disable a misbehaving function (`firebase functions:delete` or set its max instances to 0).
- Expire statement links for affected shops (delete `statements` where `shopId == X`).
- Preserve evidence: export Cloud Logging for the window; do not delete audit logs.

## 3. Assess (within 24 hours)
Which shops, which data (use docs/privacy/data-map.md), how many customers, risk to them
(phone numbers and debts are sensitive locally: embarrassment, pressure).

## 4. Notify (within 72 hours of becoming aware)
- The Data Protection Authority of Sri Lanka, as the PDPA requires, with what happened, data
  and people affected, likely consequences and measures taken.
- Affected **shop owners** in Tamil by SMS/WhatsApp and in-app; they are the controllers for
  their customers and decide with us how customers are told.
- Customers directly when the risk is high (e.g. phone numbers with balances exposed).

## 5. Learn (within 2 weeks)
Post-incident review; add a Rules test or emulator test that would have caught it.

## Before pilot
- Name the DPO; register with the Data Protection Authority if required.
- Data processing agreements: Google Cloud/Firebase, Meta WhatsApp, SMS gateway.
- Decide the region after PDPA cross-border guidance (PRD 11 data residency).
- Bucket lifecycle rules applied (config/storage-lifecycle.json).
