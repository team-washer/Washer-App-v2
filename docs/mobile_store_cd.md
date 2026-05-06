# Mobile Store CD Guide

`main` 브랜치에 push되면 플랫폼별 GitHub Actions 워크플로가 Fastlane으로 스토어 배포를 실행합니다.

- iOS: `.github/workflows/ios-testflight.yaml` — IPA 빌드 후 TestFlight 업로드
- Android: `.github/workflows/android-playstore.yaml` — AAB 빌드 후 Google Play 업로드

수동 실행(`workflow_dispatch`) 시 각 워크플로를 재실행할 수 있고, Android는 Google Play track/release status를 선택할 수 있습니다.

## Required GitHub Secrets

공통:

- `ENV_PRODUCTION`: `.env.production` 전체 내용

Android signing/build:

- `ANDROID_KEY_PROPERTIES`: `android/key.properties` 전체 내용
- `ANDROID_KEYSTORE_BASE64`: `upload-keystore.jks` 파일을 base64 인코딩한 값
- `ANDROID_GOOGLE_SERVICES_JSON`: `android/app/google-services.json` 전체 내용

Google Play upload:

- `PLAY_STORE_SERVICE_ACCOUNT_JSON`: Google Play Console service account JSON 전체 내용
- 또는 `PLAY_STORE_SERVICE_ACCOUNT_JSON_BASE64`: 같은 JSON 파일을 base64 인코딩한 값

둘 중 하나만 있으면 됩니다. base64 secret이 있으면 우선 사용합니다.

Apple/TestFlight:

- `IOS_BUILD_CERTIFICATE_BASE64`: Apple Distribution `.p12` 인증서를 base64 인코딩한 값
- `IOS_P12_PASSWORD`: `.p12` export password
- `IOS_BUILD_PROVISION_PROFILE_BASE64`: App Store provisioning profile `.mobileprovision`을 base64 인코딩한 값
- `IOS_KEYCHAIN_PASSWORD`: GitHub Actions 임시 keychain password
- `APP_STORE_CONNECT_API_KEY`: App Store Connect API key `.p8` 전체 내용

## Required GitHub Variables

Apple/TestFlight:

- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_KEY_ID`

선택 Android variables:

- `PLAY_STORE_TRACK`: 기본값 `internal`
- `PLAY_STORE_RELEASE_STATUS`: 기본값 `completed`
- `ANDROID_BUILD_NUMBER`: 미설정 시 `GITHUB_RUN_NUMBER` 사용

## Versioning

`pubspec.yaml`의 `version:`에서 version name을 읽고, 빌드 번호는 기본적으로 `GITHUB_RUN_NUMBER`를 사용합니다.

```yaml
version: 1.0.0+4
```

- iOS `CFBundleShortVersionString`: `1.0.0`
- iOS `CFBundleVersion`: `GITHUB_RUN_NUMBER`
- Android `versionName`: `1.0.0`
- Android `versionCode`: `GITHUB_RUN_NUMBER` 또는 `ANDROID_BUILD_NUMBER`

Play Store는 이전에 업로드한 `versionCode`보다 큰 값만 허용하므로 필요하면 repository variable `ANDROID_BUILD_NUMBER`를 더 큰 값으로 지정하세요.

## Fastlane lanes

```bash
bundle exec fastlane ios upload_testflight
bundle exec fastlane android upload_play_store
```

Android lane은 기본적으로 Google Play `internal` track에 업로드합니다. production 배포가 필요하면 수동 실행 input 또는 `PLAY_STORE_TRACK=production` variable을 사용하세요.
