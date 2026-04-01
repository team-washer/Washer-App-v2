# 플러터 프로젝트 세팅
플러터 프로젝트를 시작할때 프로젝트 시작할때의 번거로움을 없애기 위해 만들었습니다.

# 이슈 및 PR 템플릿
이슈 및 pr 템플릿을 작성했습니다.

# CI 설정
유지적인 정기보수를 위해 CI를 설정해뒀습니다.

# CD 설정
`develop -> main` PR이 열리면 GitHub Actions에서 Android release `AAB`와 `APK`를 생성하도록 설정했습니다.
실행 전 아래 GitHub Actions secrets가 필요합니다.

- `ANDROID_KEY_PROPERTIES`
- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_GOOGLE_SERVICES_JSON`
- `ENV_PRODUCTION`

# FVM
FVM을 통해 플러터 버전을 불러와 설정하도록 해뒀습니다.

# iOS Xcode Cloud
Xcode Cloud 빌드를 사용하는 경우 `ios/ci_scripts/ci_post_clone.sh`가 클론 직후 자동 실행되어 Flutter SDK 설치, `.env` 파일 생성, `flutter pub get`, `pod install`을 수행합니다.
필수 secret:

- `ENV_PRODUCTION`: `.env.production` 전체 내용

선택 secret:

- `ENV_DEVELOPMENT`: `.env.development` 전체 내용

# iOS TestFlight CD
`main` 브랜치에 머지되면 `.github/workflows/ios-testflight.yaml` 이 iOS IPA를 빌드하고 App Store Connect TestFlight에 업로드합니다.
심사 제출은 하지 않고 빌드 업로드까지만 자동화합니다.

설정 방법은 [docs/ios_testflight_release.md](docs/ios_testflight_release.md) 를 참고하세요.

이 단계가 빠지면 `ios/Flutter/Generated.xcconfig`, `ios/Pods/Target Support Files/...xcfilelist`, `.env.*` asset이 없어져 iOS Release 빌드가 실패할 수 있습니다.

```text
lib
├─ core
│  ├─ constants
│  ├─ enums
│  ├─ env
│  ├─ network
│  ├─ notifications
│  ├─ router
│  ├─ theme
│  ├─ ui
│  │  ├─ buttons
│  │  └─ dialog
│  └─ utils
├─ features
│  ├─ alarm
│  │  ├─ data
│  │  │  └─ models
│  │  └─ presentation
│  │     ├─ screens
│  │     └─ widgets
│  │        └─ local_widgets
│  ├─ auth
│  │  ├─ data
│  │  │  ├─ data_sources
│  │  │  │  └─ remote
│  │  │  ├─ models
│  │  │  │  ├─ request
│  │  │  │  └─ response
│  │  │  └─ repositories
│  │  └─ presentation
│  │     ├─ screens
│  │     ├─ viewmodels
│  │     └─ widgets
│  ├─ dashboard
│  │  ├─ data
│  │  │  ├─ data_sources
│  │  │  │  └─ remote
│  │  │  └─ repositories
│  │  └─ presentation
│  │     ├─ screens
│  │     ├─ viewmodels
│  │     └─ widgets
│  ├─ history
│  │  ├─ data
│  │  │  ├─ data_sources
│  │  │  ├─ models
│  │  │  └─ repositories
│  │  ├─ domain
│  │  │  └─ enum
│  │  └─ presentation
│  │     ├─ viewmodels
│  │     └─ widgets
│  ├─ report
│  │  ├─ data
│  │  │  ├─ data_sources
│  │  │  │  └─ remote
│  │  │  └─ repositories
│  │  └─ presentation
│  │     └─ viewmodels
│  ├─ reservation
│  │  ├─ data
│  │  │  ├─ data_sources
│  │  │  │  └─ remote
│  │  │  ├─ models
│  │  │  │  ├─ local
│  │  │  │  └─ remote
│  │  │  └─ repositories
│  │  └─ presentation
│  │     ├─ screens
│  │     ├─ viewmodels
│  │     └─ widgets
│  └─ user
│     ├─ data
│     │  ├─ data_sources
│     │  │  └─ remote
│     │  ├─ models
│     │  └─ repositories
│     └─ presentation
│        └─ viewmodels
├─ firebase_options.dart
├─ main.dart
└─ splash_screen.dart
```
