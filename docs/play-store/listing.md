# Play Store listing (Tamil first)

**App name:** கடை துணை — Shop Companion
**Short description (ta, ≤ 80):** குரலால் கடன் கணக்கு. யாரிடம் கேட்பது என்று காலையில் சொல்லும்.
**Short description (en):** Voice credit book for small shops. Tells you who to ask each morning.

**Full description (ta):**
கடை துணை உங்கள் கடைக் கடன் கணக்கை எளிதாக்குகிறது.
• "ரவி அண்ணை ஐநூறு கடன்" என்று சொன்னால் போதும் — சேமிக்கப்படும்.
• சிக்னல் இல்லாவிட்டாலும் நாள் முழுவதும் வேலை செய்யும்.
• காலை 6 மணிக்கு இன்று யாரிடம் பணம் கேட்பது என்று சொல்லும்.
• மரியாதையான WhatsApp நினைவூட்டல்கள், வாடிக்கையாளர் சம்மதத்துடன் மட்டும்.
• நாள் முடிவில் காசு சரிபார்ப்பு, இன்றைய இலாபம் எளிய தமிழில்.
• உதவியாளர்களுக்குத் தனி அனுமதிகள்: இலாபத்தைப் பார்க்க முடியாது.
• Khatabook, OkCredit, Shopbook இலிருந்து வாடிக்கையாளர்களை ஒரே படியில் கொண்டுவரலாம்.
• விளம்பரம் இல்லை. உங்கள் தரவு உங்களுடையது: எப்போதும் இலவசமாக Excel ஆகப் பெறலாம்.

**Full description (en):** same points in English.

**Category:** Business. **Contact:** support email + privacy policy
`https://<prod-host>/privacy`. **Account deletion URL:** `https://<prod-host>/delete-account`.

**Screenshots (phone, Tamil UI):** Who To Ask Today; voice entry read-back; customer page with
statement share; Close Day; simple mode. Take them from the staging build on a 1080×2340 phone.

# Data safety form (answers)

| Question | Answer |
|---|---|
| Collects personal info | Yes: phone number (account), name and phone of the shop's customers (entered by the user) |
| Financial info | Yes: "Other financial info" — the shop's credit ledger |
| Audio | Yes: voice clips, only when on-phone recognition fails; processed ephemerally, deleted ≤ 1 day |
| App activity / diagnostics | Yes: app interactions and crash logs, without names, phones or amounts |
| Shared with third parties | No (processors only: Google, Meta WhatsApp, SMS gateway — "service providers" are not sharing) |
| Encrypted in transit | Yes |
| Users can request deletion | Yes, in app and at /delete-account |
| Ads | None |

# Payments policy
Plans (Free / Plus / Pro) bill the **shop as a business service** (PRD 13). Before charging in
the app: digital features unlocked in the app must use **Google Play Billing** unless the
business exemption applies; the current build sells nothing in the app. Decide with Play
policy review: (a) Play Billing subscriptions for Plus/Pro, or (b) invoicing outside the app
with no in-app purchase links. Pilot is free, so this blocks only general availability.
