# core

feature에 속하지 않는 앱 전역 기반 코드입니다. 환경 설정, 네트워크, 오류 처리, 라우팅, 푸시 알림, 공용 enum·유틸이 들어 있습니다.

## 구조

```
core/
  constants/reservation_durations.dart   # 예약 만료(5분), 재확인 대기(500ms)
  enums/          # LaundryMachineType, LaundryStatus, LaundryActionType, MachineState, ReservationState
  env/app_environment.dart               # .env.* 로드, AppEnvironment.instance / appEnvironmentProvider
  network/
    dio_client.dart                      # DioClient, secureStorageProvider, dioClientProvider, dioProvider
    auth_interceptor.dart                # 토큰 첨부·갱신·재시도·강제 로그아웃
    auth_notifier.dart                   # authNotifier (GoRouter refreshListenable)
    error.dart                           # AppException, UserFacingException, Result, guardApiCall
    server_error_code.dart               # 서버 data.errorCode 상수 (백엔드 #196)
    api_response_parser.dart             # castJsonMap, extractDataMap, extractNullableDataMap
    token_utils.dart                     # JWT exp 기반 만료 판단
    http_client_adapter_config.dart      # 개발용 자체 서명 인증서 허용
  notifications/
    notification_service.dart            # FCM 권한·토큰 저장·갱신·Android foreground 수신
    android_notification_display.dart    # Android foreground 알림 표시용 네이티브 채널
    notification_bootstrapper.dart       # 앱 시작 시 알림 초기화 위젯
  router/
    app_router.dart                      # GoRouter, 인증 redirect(resolveAuthRedirect)
    route_paths.dart                     # 경로 상수
  services/version_check_service.dart    # 스토어 버전 비교 (강제 업데이트)
  utils/          # AppLogger, DateTimeFormatter, RoomFormatter, UserFormatter
```

## 앱 시작 흐름

```
main()
  → AppEnvironment.initialize() + 세로 고정 + Firebase.initializeApp (병렬)
  → Crashlytics 오류 핸들러 등록 (debug에서는 수집 비활성화)
  → ProviderScope → NotificationBootstrapper(FCM 초기화) → MyApp(MaterialApp.router)

appRouter (initialLocation: /splash)
  → SplashScreen._bootstrap (lib/splash_screen.dart)
      → 버전 체크(VersionCheckService)와 내 정보 조회를 병렬 시작
      → 업데이트 필요: ForceUpdateDialog 후 중단
      → 로그인 필요 / 401·403: 토큰 삭제 → /login
      → 그 외: myUserProvider.setUser → /home (조회 실패도 /home, 내 정보만 비움)
```

## 푸시 알림

- `NotificationService.initialize()`에서 Firebase 알림 권한을 요청합니다. Android 13 이상도 `FirebaseMessaging.requestPermission()`을 사용하며, 결과 상태만 로그에 남깁니다.
- Android `MainActivity`는 시작 시 Manifest와 같은 `laundry_completion` 채널을 생성합니다. 동일 채널을 다시 생성해도 사용자의 기존 알림 설정은 유지됩니다.
- Android foreground의 `onMessage`는 notification payload가 있을 때만 네이티브 채널로 알림을 표시합니다. 동일 messageId는 같은 알림을 갱신하고, data-only 메시지는 임의로 표시하지 않습니다.
- background/terminated의 notification payload는 Firebase SDK가 표시합니다. background handler에서 다시 표시하지 않습니다. 알림 탭은 앱을 열며, 별도의 화면 라우팅은 추가하지 않습니다.
- iOS presentation options와 APNs 처리, 로그인/app start/resume/token refresh의 FCM 서버 동기화 흐름은 유지됩니다. Android 표시 실패가 토큰 동기화를 차단하지 않습니다.
- 알림 권한이나 채널을 사용자가 차단한 경우에는 표시할 수 없습니다. Android 강제 종료 후에는 앱을 다시 열어야 합니다.

## 라우팅

```
/splash
/login
StatefulShellRoute (MainShell: 앱바 + 하단 탭)
  /dryer  → ReservationScreen(dryer)   └ alarm
  /home   → HomeScreen                 └ alarm
  /washer → ReservationScreen(washer)  └ alarm
```

- redirect(`resolveAuthRedirect`)
  - 유효한 access 토큰이나 만료되지 않은 refresh 토큰이 없으면 `/login`으로 보냅니다.
  - 세션이 있는데 `/login`이면 `/splash`로 보냅니다.
  - `/splash`는 redirect하지 않습니다.
- `authNotifier.logout()`을 호출하면 redirect가 다시 실행됩니다. 강제 로그아웃·탈퇴 시 사용합니다.
- 탭 순서는 `shared/ui/layout/nav_tab_type.dart`의 선언 순서와 같습니다.

## 네트워크

```
data source (Retrofit) → dioProvider → AuthInterceptor → 서버
```

- `DioClient`
  - `baseUrl`은 `AppEnvironment.apiBaseUrl`에서 가져옵니다.
  - timeout은 30초이고, debug 빌드에서는 `LogInterceptor`를 붙입니다.
- `AuthInterceptor`
  - `auth/` 경로를 뺀 요청에 `Bearer` 토큰을 붙입니다. 토큰이 만료됐으면 먼저 갱신합니다.
  - 401, 또는 `errorCode` 없는 403을 받으면 갱신한 뒤 한 번 재시도합니다. `errorCode` 있는 403은 권한 거부라서 갱신하지 않습니다.
  - 갱신에 실패하면 토큰을 지우고 `authNotifier.logout()`을 부릅니다. 여러 요청이 동시에 실패해도 한 번만 부릅니다.
  - `clearCache()`(로그아웃)는 세션 세대를 올립니다. 로그아웃 전에 시작한 갱신 결과는 저장하지 않습니다(#279).
- 응답 파싱
  - 서버는 `{ message, data }` wrapper를 씁니다.
  - `extractDataMap` / `extractNullableDataMap`으로 `data`를 꺼냅니다.

## 오류 처리 (`network/error.dart`)

- provider에서 API를 부를 때는 `guardApiCall(() => ..., logName: '...')`로 감싸고 `Result`(`ResultSuccess` / `ResultFailure`)를 패턴 매칭합니다.
- 모든 오류는 `AppException.from`으로 정규화합니다.
  - 이미 `AppException`이면 그대로 돌려줍니다(멱등).
  - `UserFacingException` → `userMessage`
  - `DioException` → 아래 순서로 문구를 고릅니다.
  - `FormatException` / `TypeError` → 데이터 파싱 오류 문구
- `DioException` 문구 선택 순서
  1. 취소(`isCancelled`)는 화면에 띄우지 않습니다.
  2. 연결 오류·타임아웃 → 네트워크 문구
  3. 서버 문구 우선 코드(`_serverMessageCodes`: 패널티·쿨다운 등 해제 시각이 담긴 코드)
  4. `errorCode` 문구(`_errorCodeMessages`)
  5. 상태 코드 문구(`_statusMessages`)
  6. 서버 `message`(4xx만). 5xx 메시지는 노출하지 않습니다.
- 문구 자체는 `shared/theme/washer_error_message.dart`에 있습니다.
- 기능별로 원인 분류가 필요하면 `AppException`을 상속합니다. 예: `reservation`의 `ReservationException`

## 주의사항

- `AppEnvironment.instance`는 `initialize()` 이후에만 쓸 수 있습니다. 테스트에서는 `AppEnvironment.test()`를 씁니다.
- production 빌드는 URL이 https가 아니면 초기화에 실패합니다(`_ensureProductionHttps`).
- `core`는 feature를 import하지 않는 것이 원칙입니다. 예외는 화면을 등록하는 `router/app_router.dart`뿐입니다.
- 로그는 `AppLogger.debug/error`를 씁니다(`print` 금지).

## 테스트

`test/core/` 아래에 있습니다.

- `app_exception_contract_test.dart`
- `auth_interceptor_test.dart`
- `router_test.dart`
- `core_test.dart`
