# TestFlight Upload

The app is ready for a GitHub Actions TestFlight upload, but the repository must have Apple credentials before the upload can run.

## Required GitHub Secrets

Add these in GitHub:

```text
APP_STORE_CONNECT_KEY_ID
APP_STORE_CONNECT_ISSUER_ID
APP_STORE_CONNECT_API_KEY_P8
APPLE_TEAM_ID
```

Instead of `APP_STORE_CONNECT_API_KEY_P8`, you may use:

```text
APP_STORE_CONNECT_API_KEY_P8_BASE64
```

Optional runtime secrets:

```text
GEMINI_API_KEY
```

Optional GitHub variable:

```text
PRODUCT_BUNDLE_IDENTIFIER = com.triphabibi.atriawallai
```

## Before Upload

Confirm in Apple Developer/App Store Connect:

- Bundle ID exists: `com.triphabibi.atriawallai`
- App record exists in App Store Connect
- Apple Team ID is correct
- App Store Connect API key has access to upload builds
- App Store Connect StoreKit products match `AppStore/iap-products.json`

## Run Upload

After secrets are added:

1. Open GitHub Actions.
2. Select `TestFlight Upload`.
3. Click `Run workflow`.

The workflow runs simulator tests first, then archives, exports an IPA, and uploads it to App Store Connect for TestFlight processing.
