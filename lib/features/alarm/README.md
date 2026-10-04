# alarm

서버 알림(세탁 완료, 고장, 자동 취소 등) 목록을 보여주고, FCM 토큰을 서버에 등록·삭제하는 모듈입니다.

## 기능

- 알림 화면: 알림을 최신순으로 정렬해 날짜별로 묶어 보여줍니다.
- 알림 뱃지: 앱바 알림 아이콘의 파란 점(`MainShell`이 `alarmProvider`를 구독)
- 알림 화면을 벗어나면 서버의 알림을 모두 삭제합니다.
- FCM 토큰 등록(로그인 시)·삭제(로그아웃 시). `auth`가 `AlarmRepository`를 통해 호출합니다.

## 구조

```
alarm/
  data/
    data_sources/alarm_data_source.dart     # Retrofit AlarmApiService + AlarmDataSource
    models/
      alarm_type.dart                        # 서버 알림 종류 enum (+ unknown 폴백)
      local/alarm_model.dart                 # 화면용 알림 한 건
      response/alarm_list_response.dart      # GET notifications 응답
    repositories/alarm_repository.dart       # 응답 → AlarmModel 변환, FCM 토큰 처리
  presentation/
    providers/alarm_provider.dart            # AlarmNotifier (목록 조회·화면 이탈 시 정리)
    states/alarm_state.dart                  # AlarmStatus(initial/loading/success/error) + 목록
    screens/alarm_screen.dart
    widgets/                                 # alarm_list, alarm_list_body, alarm_date_section, alarm_date_divider, alarm_card
```

## 레이어

| 레이어 | 클래스 | 역할 |
| --- | --- | --- |
| data source | `AlarmDataSource` / `AlarmApiService` | API 호출. 응답이 `data`로 감싸져 있든 아니든 파싱 |
| repository | `AlarmRepository` | `Notifications` → `AlarmModel` 변환. 삭제·FCM 관련 실패는 로그만 남기고 던지지 않음 |
| provider | `alarmProvider` (`AlarmNotifier`) | `guardApiCall`로 조회, `AlarmState` 갱신 |
| UI | `AlarmScreen` → `AlarmList` → `AlarmListBody` | 상태별 화면(안내/로딩/오류+재시도/목록) |

## API

| 메서드 | 경로 | 용도 |
| --- | --- | --- |
| GET | `notifications` | 알림 목록 |
| DELETE | `notifications` | 알림 전체 삭제 |
| POST | `notifications/fcm-token` | FCM 토큰 등록 (`{token}`) |
| DELETE | `notifications/fcm-token` | FCM 토큰 삭제 |

## 동작 흐름

**목록 조회**

```
HomeBody 진입 / AlarmList initState
  → AlarmNotifier.fetchAlarmList()        # 이미 로드했으면 force 없이는 다시 부르지 않음
  → AlarmRepository.fetchAlarms()
  → AlarmDataSource.getAlarmList()        # GET notifications
  → AlarmState(status: success, alarms)   # MainShell 뱃지, AlarmListBody가 구독
```

- 홈 화면을 당겨서 새로고침하면 `fetchAlarmList(force: true)`로 다시 불러옵니다.

**화면 이탈 시 정리**

```
AlarmList.dispose
  → AlarmNotifier.clearAllOnLeave()
  → (이미 정리 중이면 새로 시작하지 않고 진행 중인 정리를 함께 기다림)
  → (목록이 비어 있으면 _hasLoaded = false만 하고 끝냄. 삭제·재조회 없음)
  → deleteAllNotifications()              # DELETE notifications (실패해도 예외 없음)
  → 목록 재조회                           # 서버 기준으로 다시 맞춤 (로컬을 임의로 비우지 않음)
  → _hasLoaded = false                    # 다음 진입 시 새로 조회
```

- 정리(삭제 → 재조회)가 끝나기 전에 알림 화면에 다시 들어오면 `fetchAlarmList()`는 정리가 끝날 때까지 기다린 뒤 한 번 더 조회합니다. 정리 중의 응답에는 그 사이 생긴 알림이 빠져 있을 수 있기 때문입니다. 평소 진입·이탈에서는 추가 조회가 없습니다.
- 정리 중에 세션이 바뀌면 새 세션의 조회는 정리를 기다리지 않고, 이전 세션의 정리는 재조회·로드 플래그 초기화를 하지 않습니다.

**FCM 토큰** (`auth`에서 호출)

- 로그인 성공: `registerCurrentFcmToken()` → `NotificationService.ensureFcmToken()` → `POST notifications/fcm-token`
- 로그아웃: `deleteFcmToken()` → `DELETE notifications/fcm-token` → 로컬 저장 토큰 삭제

## 의존성

- 사용: `core/network`(dio, `guardApiCall`, 응답 파서), `core/notifications`(`NotificationService`), `core/utils`(`DateTimeFormatter`, `AppLogger`), `shared/theme`, `shared/ui/indicators/status_dot`
- 이 모듈을 쓰는 곳: `auth`(`AlarmRepository`), `home`(`alarmProvider` 조회), `shared/ui/layout/main_shell.dart`(뱃지), `core/router`(`AlarmScreen`)

## 주의사항

- 알림 화면은 탭마다 하위 경로(`/home/alarm`, `/washer/alarm`, `/dryer/alarm`)로 열립니다. `RoutePaths.alarmSubRoute` 참고
- 서버가 새 알림 타입을 추가해도 목록이 깨지지 않도록 `AlarmType.unknown`으로 폴백합니다. 새 타입을 지원하려면 `alarm_type.dart`와 `AlarmCard._titleFor`를 함께 수정합니다.
- `dispose`에서는 `ref`를 쓸 수 없어서 `initState`에서 notifier를 미리 캡처해 둡니다.

## 테스트

- `test/features/alarm/alarm_type_test.dart`
- `test/features/alarm/alarm_provider_test.dart` (화면 이탈 후 재진입 조회. 빈 목록, 정리 중 재진입, 겹친 정리, 세션 전환 포함)
