# Android Release Guide

## 1. Create upload keystore

```bash
keytool -genkeypair -v \
  -keystore upload-keystore.jks \
  -alias upload \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

Place the generated `upload-keystore.jks` at the project root.

## 2. Configure signing

Copy the example file and replace the placeholder values:

```bash
cp android/key.properties.example android/key.properties
```

`android/key.properties`

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=../upload-keystore.jks
```

## 3. Required files

- `android/key.properties`
- `upload-keystore.jks`
- `android/app/google-services.json` if Firebase is used for production
- `.env.production`

## 4. Build commands

Install dependencies:

```bash
flutter pub get
```

Build AAB for Google Play:

```bash
flutter build appbundle --release --dart-define=APP_ENV=production
```

Build APK for local verification:

```bash
flutter build apk --release --dart-define=APP_ENV=production
```

## 5. Versioning

Update the release version in `pubspec.yaml`.

Current format:

```yaml
version: 1.0.0+1
```

- `1.0.0` -> Play Store version name
- `1` -> Play Store version code

## 6. GitHub Actions CD

`main` 브랜치에 merge/push되면 `.github/workflows/android-playstore.yaml` 이 Android App Bundle을 빌드하고 Google Play에 업로드합니다. 수동 재실행은 GitHub Actions → `Android Play Store CD` → `Run workflow`에서 가능합니다.

PR 단계에서는 `.github/workflows/flutter-cd.yaml` 이 Android release 산출물을 빌드해 검증합니다.

필요한 GitHub Actions secrets:

- `ANDROID_KEY_PROPERTIES`: `android/key.properties` 전체 내용
- `ANDROID_KEYSTORE_BASE64`: `upload-keystore.jks` 파일을 base64 인코딩한 값
- `ANDROID_GOOGLE_SERVICES_JSON`: `android/app/google-services.json` 전체 내용
- `ENV_PRODUCTION`: `.env.production` 전체 내용
- `PLAY_STORE_SERVICE_ACCOUNT_JSON`: Google Play Console service account JSON 전체 내용
- 또는 `PLAY_STORE_SERVICE_ACCOUNT_JSON_BASE64`: 같은 JSON 파일을 base64 인코딩한 값

예시:

```bash
# macOS
base64 -i upload-keystore.jks | tr -d '\n'

# Linux
base64 upload-keystore.jks | tr -d '\n'
```

GitHub Secret에는 생성된 한 줄 문자열만 넣습니다. `-----BEGIN ...-----` 같은 PEM 형식 텍스트나 원본 바이너리 파일 내용을 그대로 넣으면 `base64: invalid input` 에러가 납니다.

선택 GitHub Actions variables:

- `PLAY_STORE_TRACK`: 기본값 `internal`
- `PLAY_STORE_RELEASE_STATUS`: 기본값 `completed`
- `ANDROID_BUILD_NUMBER`: 미설정 시 `GITHUB_RUN_NUMBER` 사용

Fastlane 직접 실행:

```bash
bundle exec fastlane android upload_play_store
```
