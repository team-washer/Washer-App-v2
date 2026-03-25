# 앱 링크 서버 검증 파일

이 디렉토리의 파일들을 서버의 `/.well-known/` 경로에 배포해야 합니다.

## 배포 경로

| 파일 | URL |
|------|-----|
| `assetlinks.json` | `https://washer.com/.well-known/assetlinks.json` |
| `apple-app-site-association` | `https://washer.com/.well-known/apple-app-site-association` |

---

## Android - assetlinks.json

`sha256_cert_fingerprints` 에 실제 서명 키의 SHA-256 지문을 입력해야 합니다.

### SHA-256 지문 얻기

**디버그 키스토어 (개발용)**
```bash
keytool -list -v \
  -keystore ~/.android/debug.keystore \
  -alias androiddebugkey \
  -storepass android -keypass android
```

**릴리즈 키스토어 (배포용)**
```bash
keytool -list -v \
  -keystore <your-release-keystore.jks> \
  -alias <key-alias>
```

출력에서 `SHA256:` 값을 복사하여 `assetlinks.json`에 입력하세요.

---

## iOS - apple-app-site-association

`appID` 의 `TEAMID` 를 Apple Developer에서 발급받은 Team ID로 교체하세요.

- Apple Developer Console → Membership → Team ID 확인
- 예: `A1B2C3D4E5.com.washer.v2`

---

## 서버 응답 헤더 요구사항

| 파일 | Content-Type |
|------|-------------|
| `assetlinks.json` | `application/json` |
| `apple-app-site-association` | `application/json` |

> ⚠️ 두 파일 모두 반드시 HTTPS로 제공되어야 합니다.
