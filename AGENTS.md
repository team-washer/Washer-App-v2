# AGENTS.md

Washer — 기숙사 세탁기·건조기 예약 Flutter 앱 (Android / iOS).
코딩 에이전트(Claude Code, Codex 등)용 프로젝트 가이드입니다. 구조는 실제 `lib/`를 기준으로 합니다.

## 기술 스택

- Flutter `3.38.4` (FVM, `.fvmrc`) / Dart `^3.9.2`
- 상태 관리: Riverpod 3 (`flutter_riverpod`, `hooks_riverpod`, `flutter_hooks`)
- 네트워크: Dio + Retrofit (`@RestApi` data source)
- 모델: `freezed` + `json_serializable`
- 라우팅: `go_router`
- 기타: Firebase (Messaging, Crashlytics, Analytics), `flutter_secure_storage`, `flutter_dotenv`, `flutter_screenutil`

## 명령어

항상 FVM을 통해 실행합니다 (CI와 같은 Flutter 버전 보장).

```bash
fvm flutter pub get
bash scripts/ensure_env_files.sh                  # .env.* 없으면 example에서 생성
fvm dart run build_runner build --delete-conflicting-outputs   # freezed/json/retrofit 코드 생성
fvm flutter analyze --no-fatal-infos             # CI와 동일
fvm flutter test                                  # 전체 테스트
fvm flutter test test/features/reservation        # 특정 경로만
fvm dart format .
```

작업을 마쳤다고 말하기 전에 `analyze`와 `test`를 통과시킵니다. PR CI(`.github/workflows/flutter-ci.yaml`)가 같은 두 단계를 돌립니다.

## 디렉터리 구조

```
lib/
  core/        # 앱 전역: env, network(dio·인터셉터·오류), router, notifications, enums, utils
  features/<feature>/
    data/
      data_sources/remote/   # Retrofit @RestApi + xxxDataSourceProvider
      models/{remote,local,request,response}/   # freezed 모델
      repositories/          # 일부 feature만 (alarm, auth). 없으면 provider가 data source를 직접 사용
    presentation/
      providers/   # Notifier / AsyncNotifier — 비즈니스 로직
      screens/     # 화면 (pages 아님)
      widgets/     # 한 파일에 위젯 하나
  shared/      # theme, 공용 UI(app_bar, buttons, dialog, indicators, layout)
test/          # lib 구조를 미러링 (core/, features/, shared/, architecture/, support/)
```

feature: `alarm`, `auth`, `history`, `home`, `report`, `reservation`, `user`

### 모듈 README

각 feature와 `core`, `shared`에는 `README.md`가 있습니다. README에는 모듈의 기능, 레이어 구성, 동작 흐름, API, 의존성, 주의사항이 정리되어 있습니다.

- 모듈을 수정하기 전에 해당 README를 먼저 읽습니다.
- 다음이 바뀌면 같은 PR에서 README도 갱신합니다.
  - 기능
  - 파일 구성
  - provider
  - API 경로
  - 동작 흐름
  - 모듈 간 의존성
- Claude Code에서는 Stop 훅(`check_module_readme.dart`)이 README 갱신 누락을 확인합니다. 아래 "에이전트 하네스" 참고

## 아키텍처 규칙

- **UI → provider → (repository) → data source** 방향만 허용. 위젯에서 Dio/data source를 직접 호출하지 않습니다.
- 의존성 주입은 Riverpod `Provider`로 합니다 (`dioProvider`, `xxxDataSourceProvider`, `xxxRepositoryProvider`). get_it/injectable은 새 코드에 쓰지 않습니다.
- 비즈니스 로직은 provider(Notifier)에 두고, 위젯은 `ref.watch`/`ref.read`만 합니다. `StatefulWidget`은 꼭 필요할 때만.
- **feature 간 import는 순환 금지** — `test/architecture/feature_dependency_test.dart`가 검사합니다.
  - `report`는 다른 feature를 import하지 않는 leaf입니다.
  - `shared`는 `report`를 import하지 않습니다.
- 한 파일에 위젯 하나, 파일명은 클래스명의 snake_case. 위젯은 200줄 이하로 유지합니다.

## 오류 처리

`lib/core/network/error.dart`의 공통 규칙을 따릅니다.

- API 호출은 `guardApiCall(() => ..., logName: '...')`로 감싸고 `Result<T>`(`ResultSuccess` / `ResultFailure`)를 패턴 매칭합니다. provider에서 직접 try-catch + 로깅을 반복하지 않습니다.
- 모든 오류는 `AppException.from`으로 정규화합니다. 화면별로 상태 코드 → 문구 매핑을 따로 만들지 않습니다.
- 사용자에게 서버의 원시 메시지·스택·예외명을 노출하지 않습니다.
- 사용자에게 보여주는 문구는 "~요" 말투로 씁니다. 음슴체(~음, ~함, ~됨)는 쓰지 않습니다.
- 오류 안내 문구는 `lib/shared/theme/washer_error_message.dart`(`WasherErrorMessage`)에 모읍니다. `AppException`은 errorCode·상태 코드별로 어떤 문구를 쓸지만 정합니다.
- 사용자에게 보여주는 메시지는 모두 토스트(`WasherToast`, `lib/shared/ui/washer_toast.dart`)로 띄웁니다. `SnackBar`/`showSnackBar`는 쓰지 않습니다.
  - 종류는 factory로 고릅니다: 오류·입력 검증은 `WasherToast.error(error)`, 성공은 `WasherToast.success('...')`, 진행 안내는 `WasherToast.info('...')`.
  - `context.showToast(...)`, context가 사라질 수 있는 비동기 이후에는 미리 캡처한 `Overlay.of(context, rootOverlay: true).showToast(...)`.
  - 토스트는 한 번에 하나만 보이고 나머지는 순서대로 대기합니다. 종류와 메시지가 같은 토스트는 최신 것 하나만 보여줍니다.
- 로그는 `AppLogger`를 사용합니다 (`print` 금지).

## 코드 생성

- `*.g.dart`, `*.freezed.dart`는 **저장소에 커밋합니다.** 모델·Retrofit 인터페이스를 바꿨으면 build_runner를 돌리고 생성 파일도 함께 커밋합니다.
- 생성 파일은 직접 수정하지 않습니다.

## 환경 변수 / 시크릿

- `.env.development`, `.env.production`은 시크릿이며 커밋하지 않습니다. 필요하면 `scripts/ensure_env_files.sh`로 example에서 만듭니다.
- 시크릿 동기화는 `scripts/secrets-*.ps1`을 사용합니다. 값을 코드·로그·PR에 남기지 않습니다.

## Git 워크플로

기본 브랜치는 `develop`, 릴리스는 `main`입니다. 작업은 항상 **이슈 → 브랜치 → PR(→ develop)** 순서로 진행합니다.

### 이슈
- 제목: `<이모지> :: <한글 설명>` (예: `🐛 :: 예약 오류 원인이 상태 코드 고정 문구로 왜곡되는 문제`)
- 본문: `## Describe` / `## 계획` / `## Additional` (`.github/ISSUE_TEMPLATE` 참고)
- 라벨: 버그 `bug`, 기능·리팩터링 `enhancement`, 문서 `documentation`

### 브랜치
- `<type>/#<이슈번호>-<kebab-case>` — `origin/develop`에서 분기
- type: `feature`, `fix`, `refactor`, `chore`

### 커밋
- 형식: `<이모지> :: <한글 설명> (#이슈번호)`
- ✨ 기능 · 🐛 버그 수정 · ♻️ 리팩터링 · 🔥 제거 · ✅ 테스트 · 🔧 설정 · 👷 CI · 📝 문서 · 🔖 버전

### PR
- 제목: `🔀 :: (#이슈번호) - <한글 제목>`, base는 `develop`
- 본문은 `.github/PULL_REQUEST_TEMPLATE.md`를 그대로 채우고 `Close #이슈번호`를 넣습니다.
- 본문 끝에 "Generated with Claude Code" 같은 도구 표기를 넣지 않습니다.
- `gh pr create --body-file`로 UTF-8 파일을 넘깁니다 (PowerShell 인코딩 깨짐 방지).
- 리뷰 지적을 반영하면 해당 리뷰 코멘트에 `반영 했습니다 <커밋 해시 7자리>` 한 줄로만 답글을 답니다.
- 릴리스가 아닌 main 대상 PR에는 `skip-release-check` 라벨을 붙입니다.

## 작업 원칙

- 어떤 작업이든 이슈·브랜치·PR을 만들기 전에 사용자에게 내용(제목, 브랜치명, 대상 브랜치)을 보여주고 허가를 받습니다. `.claude/settings.json`의 `ask` 규칙으로 해당 명령은 항상 확인을 거칩니다.
- 변경은 이슈 범위 안에서 최소로. 관련 없는 파일을 리팩터링하지 않습니다.
- 새 코드를 쓰기 전에 같은 feature의 기존 패턴과 이름을 먼저 확인하고 중복 구현을 피합니다.
- 버그 수정·동작 변경에는 `test/`의 해당 위치에 테스트를 추가합니다. 서버 응답이 필요하면 `test/support/mock_washer_server.dart`를 사용합니다.
- 사용자 노출 문구, 커밋·이슈·PR은 한국어로 작성합니다.

## 에이전트 하네스 (Claude Code)

- `.claude/settings.json`: 팀 공용 권한·훅. 개인 설정은 `.claude/settings.local.json`에 둡니다.
  - 검증·조회 명령(`fvm flutter analyze/test`, `git status/diff/log`, `gh issue/pr view` 등)은 확인 없이 허용
  - `.env`, `.env.development`, `.env.production`, `android/key.properties`는 읽기·수정 차단, 키스토어·Firebase 설정 파일은 읽기 차단
  - `git diff --no-index`는 차단 (Claude Code는 읽기 전용 git 명령을 기본 허용하므로, 이 명령으로 git 밖 파일을 읽는 경로를 막음)
- 훅 (Write/Edit 후 자동 실행)
  - `.claude/hooks/format_dart.dart`: Dart 파일에 `dart format` 적용 (생성 파일 제외, FVM 우선)
  - `.claude/hooks/check_dart_conventions.dart`: `lib/` 파일의 파일명·위치·레이어 import·위젯 규칙, SnackBar 사용, 중복 선언(같은 파일명, 같은 public 타입·provider)을 검사. 수정 전에 없던 위반만 알립니다. 전체 점검은 `dart .claude/hooks/check_dart_conventions.dart --all`
- 훅 (응답을 끝낼 때 자동 실행, Stop)
  - `.claude/hooks/check_module_readme.dart`: 이번 턴에 수정한 모듈의 구조가 바뀌었는데 그 모듈의 `README.md`가 바뀌지 않았으면 끝내기 전에 README 갱신 여부를 확인하게 합니다.
    - 구조 변경: Dart 파일 추가·삭제·이름 변경, feature의 `data_sources/`·`repositories/`·`providers/` 파일 수정 (커밋되지 않은 변경 기준, 생성 파일 제외)
    - 한 턴에 한 번만 막습니다. README에 영향이 없으면 그대로 끝내도 됩니다.
- 스킬 `.claude/skills/add-code`: 기능·파일·코드를 추가하기 전에 중복 코드를 찾고 위치·이름을 정하는 체크리스트
