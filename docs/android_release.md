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

`develop` 브랜치에서 `main` 브랜치로 PR을 열면 `.github/workflows/flutter-cd.yaml` 이 Android release 산출물을 생성합니다.

필요한 GitHub Actions secrets:

- `ANDROID_KEY_PROPERTIES`: `android/key.properties` 전체 내용
- `ANDROID_KEYSTORE_BASE64`: `upload-keystore.jks` 파일을 base64 인코딩한 값
- `ANDROID_GOOGLE_SERVICES_JSON`: `android/app/google-services.json` 전체 내용
- `ENV_PRODUCTION`: `.env.production` 전체 내용

예시:

```bash
base64 upload-keystore.jks | tr -d '\n'
```
