# Washer App v2

기숙사 세탁실의 세탁기/건조기 상태를 확인하고, 예약·사용 기록·고장 신고·알림을 처리하는 Flutter 모바일 앱입니다.

## 주요 기능

- **로그인/세션 관리**: 인증 코드 기반 로그인, access/refresh token 저장 및 갱신
- **세탁기/건조기 상태 조회**: 층별 장비 상태, 사용 가능 여부, 예약 상태 표시
- **예약 관리**: 장비 예약, 예약 취소, 예약 만료 카운트다운, 상태 동기화
- **사용 기록 조회**: 장비별 당일 사용 이력 조회
- **고장 신고**: 장비 고장 내용 신고 및 서버 에러 메시지 처리
- **알림**: FCM 토큰 저장/등록/삭제, 알림 목록 조회
- **회원 관리**: 내 정보 조회, 회원 탈퇴

## 기술 스택

- Flutter / Dart
- Riverpod 3: 상태 관리
- Dio + Retrofit: HTTP 통신
- Freezed / json_serializable: 모델 생성
- GoRouter: 라우팅
- Firebase Messaging: FCM 알림
- Flutter Secure Storage: 토큰 저장
- ScreenUtil: 화면 대응

## 프로젝트 구조

```text
lib/
├─ core/                         # 앱 공통 코드
│  ├─ constants/                  # 공통 상수
│  ├─ enums/                      # 공통 enum
│  ├─ env/                        # 환경 설정
│  ├─ network/                    # Dio, 인증 인터셉터, 토큰 유틸
│  ├─ notifications/              # Firebase Messaging 초기화/토큰 관리
│  ├─ router/                     # GoRouter 라우팅
│  ├─ states/                     # 공통 presentation state
│  ├─ theme/                      # 색상, 아이콘, 간격, 타이포그래피
│  ├─ ui/                         # 공통 UI 컴포넌트/다이얼로그
│  └─ utils/                      # formatter, logger, background task
│
├─ features/
│  ├─ alarm/                      # 알림 목록, FCM 토큰 서버 등록/삭제
│  ├─ auth/                       # 로그인, 로그아웃, 토큰 저장
│  ├─ history/                    # 사용 기록 조회
│  ├─ report/                     # 고장 신고
│  ├─ reservation/                # 장비 상태 조회, 예약/취소, 상태 동기화
│  └─ user/                       # 내 정보 조회, 회원 탈퇴
│
├─ firebase_options.dart
├─ main.dart
└─ splash_screen.dart
```

### 레이어 기준

현재 구조는 불필요한 `domain` 레이어와 pass-through repository를 제거하고, 기능 책임이 있는 곳만 repository를 둡니다.

- `data/data_sources`: Retrofit API 호출, 응답 파싱
- `data/models`: API 응답/요청 모델, 앱 내부에서 쓰는 local model
- `data/repositories`: 여러 데이터 소스나 부가 로직을 조합할 때만 사용
  - 현재 유지 대상: `auth`, `alarm`
- `presentation/viewmodels`, `presentation/providers`: 화면 상태와 비즈니스 흐름 관리
- `presentation/states`: 화면/action 상태 모델
- `presentation/widgets`, `screens`: UI

## 상태 관리 규칙

- Riverpod 기반으로 상태를 관리합니다.
- UI는 DataSource를 직접 호출하지 않고 ViewModel/Provider를 통해 상태를 읽습니다.
- 단순 조회 Provider는 DataSource를 직접 사용할 수 있습니다.
- 여러 API 호출, 토큰 저장, FCM 처리처럼 흐름이 있는 경우만 Repository를 둡니다.
- action 상태는 `core/states/presentation_state.dart`의 `ActionState` / `ActionStatus`를 사용합니다.

## 네트워크 규칙

- API 정의는 Retrofit으로 작성합니다.
- 공통 Dio 설정은 `core/network/dio_client.dart`에서 관리합니다.
- 인증 헤더/토큰 갱신은 `AuthInterceptor`에서 처리합니다.
- 서버 응답 파싱은 `core/network/api_response_parser.dart`를 사용합니다.

## 알림/FCM

- 로컬 FCM 토큰 생성·저장은 `core/notifications/notification_service.dart`가 담당합니다.
- 서버에 FCM 토큰을 등록/삭제하는 API는 알림 기능 책임으로 보고 `features/alarm`에 둡니다.
- 로그인/로그아웃은 `AuthRepository`에서 알림 Repository를 호출해 흐름만 연결합니다.

## 테스트 구조

기능별로 테스트 파일을 하나씩 유지합니다. UI 문구 확인보다 비즈니스 로직과 상태 변화 중심으로 작성합니다.

```text
test/
├─ core/core_test.dart
├─ features/report/report_test.dart
└─ features/reservation/reservation_test.dart
```

## 개발 명령어

```bash
# 의존성 설치
flutter pub get

# 코드 생성
flutter pub run build_runner build --delete-conflicting-outputs

# 정적 분석
flutter analyze

# 테스트
flutter test

# 포맷
dart format lib test

# 실행
flutter run
```

## 환경 파일

앱은 다음 env 파일을 asset으로 사용합니다.

```text
.env.development
.env.production
```

예시는 `.env.development.example`, `.env.production.example`을 참고하세요.

## 배포/CI

- Android release 빌드와 iOS TestFlight/Google Play 업로드 워크플로우가 포함되어 있습니다.
- 모바일 스토어 CD 설정은 [docs/mobile_store_cd.md](docs/mobile_store_cd.md)를 참고하세요.
- iOS Xcode Cloud 사용 시 `ios/ci_scripts/ci_post_clone.sh`가 Flutter SDK 설치, env 파일 생성, `flutter pub get`, `pod install`을 수행합니다.

필요한 주요 GitHub Actions secrets:

- `ANDROID_KEY_PROPERTIES`
- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_GOOGLE_SERVICES_JSON`
- `ENV_PRODUCTION`
- `ENV_DEVELOPMENT` (선택)
