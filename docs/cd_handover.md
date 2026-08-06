# CD 인수인계 문서

`main` 브랜치 배포 파이프라인을 넘겨받을 사람이 (1) **지금 CD를 어떻게 돌리는지**, (2) **무엇을 같이 넘겨받아야 하는지**를 한 번에 알 수 있게 정리한 문서.

> ⚠️ `docs/mobile_store_cd.md`는 낡았습니다 (존재하지 않는 워크플로우/시크릿명 참조). **이 문서를 기준**으로 하세요.

---

## 1. 현재 CD 구조

실제로 존재하는 워크플로우는 3개뿐입니다 (`.github/workflows/`).

| 파일 | 트리거 | 하는 일 |
|------|--------|---------|
| `flutter-ci.yaml` | PR(main/develop), `[CI]` 포함한 main push | test / analyze / APK 빌드 + Discord 알림 |
| `release-android.yml` | main push, 수동 | AAB 빌드·서명 → Google Play **production** 트랙 정식 출시 |
| `release-ios.yml` | main push, 수동 | IPA 빌드·서명 → App Store **심사 자동 제출** |

iOS는 GitHub Actions 외에 **Xcode Cloud** 경로도 있습니다: `ios/ci_scripts/ci_post_clone.sh`가 `ENV_PRODUCTION`/`ENV_DEVELOPMENT` 환경변수로 `.env.*`를 만들고 Flutter/Pods를 세팅. Xcode Cloud를 쓴다면 거기에도 같은 env 값을 등록해야 합니다.

- 배포 실행은 Fastlane 이 담당: iOS `release_appstore` / Android `release_play_store` lane (`fastlane/Fastfile`).
- 앱 식별자: `com.washer.v2` (iOS/Android 공통), Apple Team ID `UB2797YAAH` (`fastlane/Appfile`).
- ⚠️ 릴리스 워크플로우 주석은 베타(TestFlight/internal)용 `cd-ios.yml` / `cd-android.yml`을 언급하지만 **현재 레포에 그 파일들은 없습니다.** 베타 배포가 필요하면 새로 만들어야 합니다 (lane은 이미 있음: `upload_testflight` / `upload_play_store`).

---

## 2. 지금 CD 돌리는 법

### 자동 (평상시)
`main`에 push(=PR 머지)되면 `release-android.yml`·`release-ios.yml`이 자동 실행 → 그대로 **스토어에 실배포**됩니다.
- Android: Play production 트랙 즉시 정식 출시.
- iOS: App Store 심사 자동 제출. 심사 승인 후 **출시는 수동**(`automatic_release: false`). 이미 심사 대기/진행 중 버전이 있으면 이번 제출은 자동 skip.

### 수동 (테스트/재실행) — `workflow_dispatch`
GitHub → **Actions** 탭 → 워크플로우 선택 → **Run workflow**.
- `dry_run` 입력 (기본값 **true**): 빌드·서명까지만 하고 **스토어 업로드는 건너뜀**. 시크릿/서명 설정 검증용으로 안전.
- 실제로 수동 배포하려면 `dry_run`을 **false**로 바꿔서 실행.

### 버전 규칙
- version name: **iOS·Android 모두** `pubspec.yaml`의 `version:` (예: `1.1.3+5` → `1.1.3`)에서 읽음. 여기가 단일 출처.
- iOS build number: `GITHUB_RUN_NUMBER`.
- Android versionCode: `1000 + GITHUB_RUN_NUMBER` (과거 내부트랙 업로드 코드와 충돌 방지용 오프셋 — 낮추지 말 것).
- pubspec의 `+5` (빌드번호)는 **어디에도 안 쓰임** — 양쪽 다 run number로 덮어씀. 올려도 되고 안 올려도 무방.
- pubspec 버전이 App Store Connect 최고 버전 이하면 archive **전에** 실패한다(Fastfile `assert_appstore_version_available`). 에러 메시지에 올려야 할 버전이 찍히므로 pubspec을 그 위로 올리고 재실행.

### 릴리스 누락 방지 (CI)
`main`으로 가는 PR에는 `release_metadata_check` 잡(`flutter-ci.yaml`)이 돌아 아래를 강제합니다.
- `pubspec.yaml`의 version name이 main보다 **높을 것** (동일·다운그레이드 차단).
- `fastlane/metadata/ko/release_notes.txt`(What's New)가 비어있지 않고 main과 **다를 것**.

릴리스가 아닌 PR(문서 수정 등)은 PR에 `skip-release-check` 라벨을 달면 건너뜁니다.
⚠️ Branch protection에서 이 잡을 **required check**로 지정해야 실제로 머지가 막힙니다.

### What's New — 파일 하나로 양쪽 스토어 자동 반영
**`fastlane/metadata/ko/release_notes.txt` 이 파일만 고치면 App Store · Play Store 양쪽에 동일하게 올라갑니다.** 여기가 단일 출처입니다.

- iOS(deliver): 이 경로를 그대로 읽습니다.
- Android(supply): 경로 규칙이 `metadata/android/ko-KR/changelogs/<versionCode>.txt`로 달라서, versionCode가 확정되는 **빌드 시점에 위 파일에서 복사 생성**합니다(Fastfile `prepare_play_changelog`). 생성물은 `.gitignore` 처리 — 커밋하지 마세요.
- ⚠️ supply는 해당 versionCode 파일이 없으면 **에러 없이 빈 릴리스 노트로 업로드**합니다(조용한 실패). 그래서 lane에서 존재·내용을 명시적으로 검증합니다.
- **글자 수 제한 500자** (Play 기준, iOS는 4000자라 빡빡한 쪽에 맞춤). PR CI에서 미리 막고, 빌드 시점에도 한 번 더 검사합니다.
- 등록 언어를 늘리려면 iOS는 `metadata/<locale>/`, Android는 `PLAY_CHANGELOG_LOCALE` 추가가 필요합니다(현재 한국어만).

### ⚠️ iOS 심사 스킵 시 What's New 누적 작성
- iOS 제출이 스킵되면(이전 버전이 `WAITING_FOR_REVIEW`/`IN_REVIEW`/`PENDING_APPLE_RELEASE`/`PROCESSING_FOR_APP_STORE`) **그때 쓴 What's New는 App Store에 반영되지 않습니다.** 다음 릴리스 노트에 **이번 변경사항까지 누적**해서 쓰세요. 스킵되면 Actions 실행 요약에 어떤 버전·어떤 상태 때문인지 경고가 뜹니다.
- 🚨 **가장 흔한 함정: `PENDING_DEVELOPER_RELEASE`** (심사 통과, 개발자가 출시 버튼 누르기 대기). `automatic_release: false`라 승인된 빌드는 항상 이 상태로 남습니다. **방치하면 이후 iOS 배포가 계속 막힙니다.** 승인 알림을 받으면 App Store Connect에서 **출시** 버튼을 눌러 상태를 비우세요.
  - 실제로 2026-08-02·08-05 iOS 배포가 이 상태 때문에 연속 실패했습니다(guard 목록에 이 상태가 빠져 있어 그냥 통과한 뒤 Apple이 새 버전 생성을 거부: `You cannot create a new version of the App in the current state`).
- guard에는 **시간이 지나면 저절로 풀리는 상태만** 담겨 있습니다. `REJECTED`·`INVALID_BINARY`처럼 사람이 손봐야 하는 상태는 일부러 제외해 빨갛게 실패시킵니다.

---

## 3. 인수인계 항목 (⚠️ 핵심)

### 3-1. GitHub Secrets — Settings → Secrets and variables → Actions

새 담당자가 레포/Actions 접근 권한을 받아야 하고, 조직/포크가 바뀌면 **아래 시크릿을 전부 다시 등록**해야 합니다. (전부 GitHub *Secrets*, Variables 아님.)

**Android (`release-android.yml`)**
| Secret | 내용 | 출처 |
|--------|------|------|
| `GOOGLE_PLAY_JSON_KEY` | Play Console 서비스 계정 JSON 전체 | Play Console → 설정 → API 액세스 → 서비스 계정 |
| `ANDROID_KEYSTORE_BASE64` | `android/upload-keystore.jks`를 base64 인코딩 | 로컬 키스토어 파일 (아래 3-2) |
| `ANDROID_KEY_PROPERTIES` | `android/key.properties` 전체 내용 | 로컬 파일 (아래 3-2) |
| `ANDROID_GOOGLE_SERVICES_JSON` | `android/app/google-services.json` 전체 | Firebase 콘솔 |
| `ENV_PRODUCTION` | `.env.production` 전체 내용 | 로컬 파일 (아래 3-2) |
| `ENV_DEVELOPMENT` | `.env.development` 전체 내용 | 로컬 파일 (아래 3-2) |

> `GOOGLE_PLAY_JSON_KEY`가 없으면 guard job이 production 배포를 조용히 skip합니다(워크플로우는 초록). 실배포하려면 반드시 등록.

**iOS (`release-ios.yml`)**
| Secret | 내용 | 출처 |
|--------|------|------|
| `ENV_PRODUCTION` | `.env.production` 전체 | 로컬 파일 |
| `ENV_DEVELOPMENT` | `.env.development` 전체 | 로컬 파일 |
| `IOS_BUILD_CERTIFICATE_BASE64` | Apple Distribution `.p12`를 base64 | 키체인에서 export |
| `IOS_P12_PASSWORD` | 위 `.p12` export 비밀번호 | export 시 지정한 값 |
| `IOS_BUILD_PROVISION_PROFILE_BASE64` | App Store provisioning profile `.mobileprovision`를 base64 | Apple Developer |
| `IOS_KEYCHAIN_PASSWORD` | CI 임시 키체인 비밀번호 (아무 값) | 임의 지정 |
| `APP_STORE_CONNECT_API_KEY` | App Store Connect API 키 `.p8` 원문 전체 | ASC → 사용자 및 액세스 → 통합 → 키 |
| `APP_STORE_CONNECT_KEY_ID` | 위 API 키의 Key ID | ASC |
| `APP_STORE_CONNECT_ISSUER_ID` | ASC Issuer ID | ASC |

**CI (`flutter-ci.yaml`)**
| Secret | 내용 |
|--------|------|
| `DISCORD_WEBHOOK` | CI 결과 알림용 Discord 웹훅 URL (없으면 알림만 skip) |

### 3-2. 로컬 시크릿 파일 — Infisical로 관리 (git에 없음)

아래 파일들은 전부 `.gitignore` 처리돼 레포에 **없고**, **Infisical**에 base64로 저장돼 있습니다. 파일을 손으로 주고받는 게 아니라 **Infisical 접근 권한을 넘겨받고 스크립트로 복원**합니다.

```powershell
infisical login          # 최초 1회
infisical init           # 레포에 프로젝트 연결(최초 1회)
./scripts/secrets-pull.ps1            # dev 환경 시크릿을 제자리에 복원
./scripts/secrets-pull.ps1 -Env prod  # prod 환경
```

`scripts/secrets-map.ps1`이 시크릿명↔경로 매핑을 정의하며, 현재 관리 대상은:

| Infisical Secret | 파일 경로 |
|------------------|-----------|
| `ENV_DEVELOPMENT` | `.env.development` |
| `ENV_PRODUCTION` | `.env.production` |
| `ANDROID_GOOGLE_SERVICES_JSON` | `android/app/google-services.json` |
| `IOS_GOOGLE_SERVICE_INFO_PLIST` | `ios/Runner/GoogleService-Info.plist` |
| `ANDROID_UPLOAD_KEYSTORE_JKS` | `android/upload-keystore.jks` |
| `ANDROID_KEY_PROPERTIES` | `android/key.properties` |

- 로컬에서 파일을 바꿨으면 `./scripts/secrets-push.ps1 [-Env prod]`로 Infisical에 다시 올립니다. 새 시크릿 파일을 추가하려면 `secrets-map.ps1`에 줄 하나 추가.
- ⚠️ **iOS 배포 서명 자료(.p12 / .mobileprovision / ASC .p8)와 Play 서비스 계정 JSON은 이 매핑에 없습니다.** 이건 GitHub Secrets(3-1)에만 있고 Infisical엔 없으니 별도 안전 채널로 인수인계해야 합니다.
- `.env.production`/`.env.development` 키 형식은 `.env.*.example` 참고 (`API_BASE_URL`, `REFRESH_TOKEN_ENDPOINT`, `OAUTH_BASE_URL`, `OAUTH_CLIENT_ID`).
- `upload-keystore.jks`는 **분실 시 Play 앱 서명 복구 불가** → Infisical 외 백업도 권장.

### 3-3. 계정 접근 권한

- Apple Developer / App Store Connect (Team `UB2797YAAH`) — Admin 또는 App Manager 초대.
- Google Play Console — 서비스 계정 + 콘솔 사용자 초대.
- Firebase 프로젝트.
- GitHub 레포 + Actions Secrets 편집 권한.
- **Infisical** 프로젝트 접근 (로컬 시크릿 복원용, 3-2 참고).

---

## 4. 로컬에서 검증하는 법

CI를 건드리지 않고 빌드/서명만 재현:

```powershell
./scripts/secrets-pull.ps1           # 먼저 시크릿 파일 복원 (Infisical, 3-2 참고)
bundle install                       # fastlane 등 gem 설치
# iOS: 스토어 업로드 없이 archive 검증
$env:DRY_RUN="true"; bundle exec fastlane ios release_appstore
# Android: 스토어 업로드 없이 AAB 빌드 검증
$env:DRY_RUN="true"; bundle exec fastlane android release_play_store
```

- Infisical이 아직 없으면 `scripts/ensure_env_files.sh`로 `.env.*`를 example에서 만들 수 있지만 **플레이스홀더 값**이라 실제 서버 연동은 안 됩니다.
- `.env.*`, 서명 파일, `IOS_BUILD_NUMBER`/`IOS_PROVISIONING_PROFILE_UUID` 등 워크플로우가 세팅하는 환경변수가 로컬에도 있어야 완전 재현됩니다. 서명이 필요 없는 순수 빌드만 볼 거면 `fvm flutter build appbundle` / `build ios --no-codesign`.

---

## 5. 알려진 이슈 / 주의

- **커밋된 비밀 위험**: `android/key.properties`에 실제 비밀번호(`washer1234`)가, 그리고 키스토어가 로컬에 평문으로 있음. 현재는 gitignore로 커밋만 막혀 있으니, 조직 이관 시 키스토어/비밀번호 **로테이션 검토** 권장.
- **낡은 문서**: `docs/mobile_store_cd.md`는 실제와 불일치. 이 문서로 대체됨.
- **신규 앱 최초 출시**: Play production은 콘솔에서 최초 1회 수동 출시해야 이후 API 출시가 됩니다 (release-android.yml 상단 주석 참고).
- **Apple 동시 심사 1개**: main에 자주 머지하면 중복 심사 제출이 막히므로 자동 skip 처리됨. main은 릴리스용으로 운용 권장.
