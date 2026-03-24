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
