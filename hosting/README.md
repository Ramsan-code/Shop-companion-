# Firebase Hosting

Serves `/invite/{token}` (`invite.html`) for people who don't have the app yet.
When the app is installed, Android App Links open the app directly instead and
the app reads the token (`lib/app/router.dart`).

The customer statement page (`/s/{token}`, PRD N8) is added in Phase 5.

## App Links verification (before the pilot)

Android only opens the app for `https://<host>/invite/...` without asking if the
domain proves it trusts the app. After setting up release signing (Phase 7),
add `hosting/public/.well-known/assetlinks.json` per project:

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "lk.shopcompanion.shop_companion",
    "sha256_cert_fingerprints": ["<Play App Signing SHA-256 from Play Console>"]
  }
}]
```

Use `lk.shopcompanion.shop_companion.dev` / `.staging` for those projects.
Until then the link still works: Android shows a "open with" chooser.
