# user

로그인한 사용자 정보(id, 이름, 호실) 조회와 회원 탈퇴를 담당하는 모듈입니다. 화면은 없고 provider만 제공합니다.

## 기능

- 내 정보 조회·보관: `myUserProvider` (keepAlive, 앱 실행 중 유지)
- 회원 탈퇴: 탈퇴 API → 로그아웃 → 내 정보 비우기

## 구조

```
user/
  data/
    data_sources/remote/user_remote_data_source.dart   # Retrofit UserApiService
    models/my_user_model.dart                           # 수동 fromJson (freezed 아님)
  presentation/
    providers/
      my_user_provider.dart                             # MyUserNotifier
      withdraw_provider.dart                            # WithdrawNotifier
```

repository 없이 provider가 data source를 직접 사용합니다.

## API

| 메서드 | 경로 | 용도 |
| --- | --- | --- |
| GET | `users/my` | 내 정보. 응답이 비었거나 404면 `null` |
| DELETE | `users/me` | 회원 탈퇴 |

## 동작 흐름

**내 정보**

```
SplashScreen._bootstrap
  → userRemoteDataSource.getMyUser() → myUserProvider.setUser(user)
  (조회 실패·로그인 필요 시 myUserProvider.clear())

HomeBody
  → 앱 resume 시 ref.invalidate(myUserProvider)
  → 당겨서 새로고침 시 myUserProvider.notifier.refresh()
```

`myUserProvider` 구독처:
- `home`: 호실 번호로 표시할 층과 "{호실}호 예약 현황" 제목을 정합니다.
- `reservation`: 내 예약인지 판별(`userId`)하고 기본 층을 선택합니다.
- `ReservationSyncController`: polling에서 내 예약을 식별합니다.

**회원 탈퇴** (앱바 설정 다이얼로그에서 호출)

```
WasherAppBar → WithdrawNotifier.withdraw()
  → guardApiCall { DELETE users/me → AuthRepository.logout() }
  → 성공: myUserProvider.clear() → 완료 다이얼로그 → authNotifier.logout() → /login
  → 실패: withdrawProvider의 error로 에러 토스트
```

## 의존성

- 사용: `auth`(`AuthRepository`), `core/network`
- 이 모듈을 쓰는 곳: `home`, `reservation`, `shared/ui/app_bar/washer_app_bar.dart`, `lib/splash_screen.dart`

## 주의사항

- 서버 응답의 키 이름이 일정하지 않아서 `MyUserModel.fromJson`이 여러 후보 키(`name`/`userName`/`nickname`, `roomNumber`/`roomNo`/`room.number` 등)에서 값을 찾습니다. 키를 추가할 때는 이 목록에 넣습니다.
- `MyUserModel`은 freezed 모델이 아니어서 build_runner 대상이 아닙니다.
