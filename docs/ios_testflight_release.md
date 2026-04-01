# iOS TestFlight Release Guide

## 1. What this automation does

When code is merged into `main`, `.github/workflows/ios-testflight.yaml` runs on GitHub Actions and:

- builds an iOS IPA with Flutter
- uploads the build to App Store Connect / TestFlight with `fastlane`
- does not submit the app for review

## 2. Files added for this flow

- `Gemfile`
- `fastlane/Appfile`
- `fastlane/Fastfile`
- `.github/workflows/ios-testflight.yaml`

## 3. Required GitHub secrets

- `ENV_PRODUCTION`: `.env.production` full contents
- `IOS_BUILD_CERTIFICATE_BASE64`: App Store distribution certificate `.p12` encoded as base64
- `IOS_P12_PASSWORD`: password used when exporting the `.p12`
- `IOS_BUILD_PROVISION_PROFILE_BASE64`: App Store provisioning profile `.mobileprovision` encoded as base64
- `IOS_KEYCHAIN_PASSWORD`: temporary macOS keychain password used in GitHub Actions
- `APP_STORE_CONNECT_API_KEY`: App Store Connect API key `.p8` full contents

## 4. Required GitHub variables

- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_KEY_ID`

## 5. Create the certificate and provisioning profile

You need these Apple Developer assets for `com.washer.v2`:

- one `Apple Distribution` certificate exported as `.p12`
- one App Store provisioning profile for the app bundle id

Encode files before adding them to GitHub Secrets:

```bash
# macOS
base64 -i certificate.p12 | tr -d '\n'
base64 -i profile.mobileprovision | tr -d '\n'

# Linux
base64 certificate.p12 | tr -d '\n'
base64 profile.mobileprovision | tr -d '\n'
```

## 6. App Store Connect API key

Create an App Store Connect API key with permission to upload builds, then store:

- the `.p8` file contents in `APP_STORE_CONNECT_API_KEY`
- the key id in `APP_STORE_CONNECT_KEY_ID`
- the issuer id in `APP_STORE_CONNECT_ISSUER_ID`

## 7. Versioning

The workflow reads the app version from `pubspec.yaml`.

Example:

```yaml
version: 1.0.0+1
```

- `1.0.0` becomes the iOS version name
- `GITHUB_RUN_NUMBER` becomes the iOS build number uploaded to TestFlight

If you need a new App Store version, update `pubspec.yaml` before merging to `main`.
