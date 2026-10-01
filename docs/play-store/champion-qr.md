# Field champion QR codes (PRD N9)

Each champion gets a QR code for `https://<prod-host>/get/<championId>` (letters, digits,
`-`, `_`; up to 32). The page sends the phone to the Play Store listing with the install
referrer `utm_source=champion&utm_medium=qr&utm_content=<championId>`, so Play Console
(Acquisition reports) and Analytics (`first_open` campaign) count installs per champion.

Make the codes with any QR tool, e.g. `npx qrcode -o champ-42.png https://<prod-host>/get/champ-42`.
Print on the A6 card with the Tamil install steps (Play Store → தமிழ் → OTP → PIN → say shop name).
