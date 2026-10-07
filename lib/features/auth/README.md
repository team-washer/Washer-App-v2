# auth

DataGSM OAuth 로그인, 로그아웃, 토큰 저장을 담당하는 모듈입니다.

## 기능

- 로그인 화면: 로고와 DataGSM 로그인 버튼
- OAuth 로그인: 시스템 브라우저(`flutter_web_auth_2`)로 인증 코드를 받아 서버에 로그인하고, access/refresh 토큰을 secure storage에 저장합니다. 요청마다 일회용 state와 PKCE(S256) code verifier를 만들어 callback을 검증합니다(#316).
- 로그아웃: 서버 FCM 토큰 삭제 → 로컬 토큰 삭제 → 인터셉터 캐시 초기화

## 구조

```
auth/
  data/
    data_sources/remote/auth_remote_data_source.dart   # Retrofit AuthApiService (POST auth/login)
    models/
      request/login_request.dart                        # authCode, redirectUri, codeVerifier(PKCE, 선택)
      response/login_response.dart                      # accessToken, expiresIn, refreshToken
    repositories/auth_repository.dart                   # 로그인/로그아웃 + 토큰 저장소
  presentation/
    providers/
      login_provider.dart                               # LoginNotifier (OAuth 진행), webAuthenticatorProvider
      oauth_transaction.dart                            # OAuthTransaction (state·PKCE 생성, callback 검증)
      logout_provider.dart                              # LogoutNotifier
    screens/login_screen.dart                           # + _DgLoginButton, _LoginLogo
```

## 레이어

| 레이어 | 클래스 | 역할 |
| --- | --- | --- |
| data source | `AuthRemoteDataSource` | `POST auth/login` 호출, 응답의 `data`를 `LoginResponse`로 파싱 |
| repository | `AuthRepository` | 토큰 저장·삭제, `DioClient.clearAuthCache()`, `AlarmRepository`로 FCM 토큰 등록·삭제 |
| provider | `loginProvider`, `logoutProvider` | `AsyncNotifier<void>`. 실패는 `AsyncError`로 전달 |
| UI | `LoginScreen`(`_DgLoginButton`) | 로그인 성공 시 `/splash`로 이동, 실패 시 에러 토스트 |

## 동작 흐름

**로그인**

```
_DgLoginButton 탭
  → LoginNotifier.login()
      1. AppEnvironment의 oauthBaseUrl/oauthClientId 확인 (비어 있으면 AsyncError)
      2. OAuthTransaction.create(): 일회용 state + PKCE code verifier
         - 이미 진행 중인 로그인이 있으면 false (트랜잭션을 덮어쓰지 않음)
      3. webAuthenticatorProvider(FlutterWebAuth2.authenticate)
           (redirect_uri=com.washer.v2://auth/callback, state, code_challenge, code_challenge_method=S256)
         - 사용자가 브라우저를 닫으면 오류가 아니라 AsyncData(null) + false
      4. 트랜잭션을 비우고(재사용 불가) callback 검증: scheme·host·path, state 일치, code 존재 (실패 시 AsyncError)
      5. guardApiCall(AuthRepository.login(codeVerifier))
           → POST auth/login {authCode, redirectUri, codeVerifier} → access_token/refresh_token 저장
           → AlarmRepository.registerCurrentFcmToken() (unawaited)
  → 성공: context.go(/splash) → 스플래시가 내 정보 조회 후 /home
  → 실패: ref.listen(loginProvider)가 AsyncError를 받아 WasherToast.error로 표시
```

**로그아웃** (앱바 설정 다이얼로그에서 호출)

```
WasherAppBar → LogoutNotifier.logout()
  → AuthRepository.logout()
      → AlarmRepository.deleteFcmToken()
      → access_token/refresh_token 삭제 + DioClient.clearAuthCache()
  → authNotifier.logout()                 # GoRouter redirect 재실행
  → context.go(/login)
```

## 의존성

- 사용: `alarm`(`AlarmRepository`), `core/network`(`dioClientProvider`, `secureStorageProvider`, `authNotifier`, `guardApiCall`), `core/env`, `core/router`, `shared/ui/washer_toast`
- 이 모듈을 쓰는 곳: `user`(회원 탈퇴 시 `AuthRepository.logout`), `shared/ui/app_bar/washer_app_bar.dart`(`logoutProvider`), `core/router`(`LoginScreen`)

## 주의사항

- 토큰 키 이름(`access_token`, `refresh_token`)은 `AuthInterceptor`, `appRouter`, `SplashScreen`에서도 같은 문자열을 씁니다. 바꾸려면 전부 함께 수정해야 합니다.
- 토큰 갱신(refresh)은 이 모듈이 아니라 `core/network/auth_interceptor.dart`가 처리합니다.
- `auth/`로 시작하는 경로는 인터셉터가 인증 헤더를 붙이지 않습니다.
- PKCE는 서버가 `codeVerifier`를 DataGSM 토큰 교환에 넘겨야 동작합니다. 인가 요청에 `code_challenge`를 보내면 DataGSM이 verifier를 요구하므로, 서버 지원 없이 배포하면 로그인이 실패합니다.
- 로그인 실패 문구는 `_LoginUnavailableException`(`UserFacingException`)이나 `AppException.from`으로 정해집니다. 화면에서 따로 문구를 만들지 않습니다.
