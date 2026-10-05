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

Place the generated `upload-keystore.jks` in the `android/` directory (`android/upload-keystore.jks`).

`storeFile` in `android/key.properties` is resolved relative to `android/app/`, so `../upload-keystore.jks` points to `android/upload-keystore.jks`, not the project root.

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
- `android/upload-keystore.jks`
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
- `1` -> 로컬 빌드에서만 version code로 쓰입니다. CI 배포에서는 `1000 + GITHUB_RUN_NUMBER`로 덮어씁니다(`release-android.yml`).

## 6. GitHub Actions CD

`main`에 push(=PR 머지)되면 `.github/workflows/release.yml`이 `.github/workflows/release-android.yml`을 호출해 AAB를 빌드·서명하고 Google Play **production** 트랙에 출시합니다(`fastlane android release_play_store`). 수동 실행은 GitHub Actions → `Release - Android Play Store` → `Run workflow`에서 가능하며, `dry_run=true`면 빌드·서명까지만 하고 업로드는 건너뜁니다. 자세한 흐름은 `docs/cd_handover.md`를 참고하세요.

PR 단계의 `.github/workflows/flutter-ci.yaml`은 analyze·test만 실행하며 Android release 산출물은 빌드하지 않습니다.

필요한 GitHub Actions secrets:

- `ANDROID_KEY_PROPERTIES`: `android/key.properties` 전체 내용
- `ANDROID_KEYSTORE_BASE64`: `android/upload-keystore.jks` 파일을 base64 인코딩한 값
- `ANDROID_GOOGLE_SERVICES_JSON`: `android/app/google-services.json` 전체 내용
- `ENV_PRODUCTION`: `.env.production` 전체 내용
- `ENV_DEVELOPMENT`: `.env.development` 전체 내용
- `GOOGLE_PLAY_JSON_KEY`: Google Play Console 서비스 계정 JSON 전체 내용 (`google-services.json`과 다른 별도 키). 미설정이면 Android 배포를 건너뜁니다.

예시:

```bash
# macOS
base64 -i android/upload-keystore.jks | tr -d '\n'

# Linux
base64 android/upload-keystore.jks | tr -d '\n'
```

GitHub Secret에는 생성된 한 줄 문자열만 넣습니다. `-----BEGIN ...-----` 같은 PEM 형식 텍스트나 원본 바이너리 파일 내용을 그대로 넣으면 `base64: invalid input` 에러가 납니다.

Fastlane 직접 실행 (`ANDROID_VERSION_NAME`, `ANDROID_BUILD_NUMBER`, `SUPPLY_JSON_KEY_DATA` 환경 변수 필요):

```bash
# internal 트랙
bundle exec fastlane android upload_play_store

# production 트랙 (CI와 동일)
bundle exec fastlane android release_play_store
```
