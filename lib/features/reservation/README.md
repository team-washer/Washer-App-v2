# reservation

세탁기·건조기 현황 조회, 예약 생성·취소, 내 활성 예약 동기화(polling)를 담당하는 앱의 핵심 모듈입니다. 기기 상태와 활성 예약 provider는 `home`과 `shared`에서도 사용합니다.

## 기능

- 예약 화면(세탁기 탭 `/washer`, 건조기 탭 `/dryer`)
  - 층 선택 칩과 배치도 보기(`LaundryLayoutDialog`)
  - 기기 카드마다 상태별 하단 영역: 예약 가능, 내 예약, 남의 예약, 사용 중, 사용 불가, 통세척 중
  - 카드에서 예약, 예약 취소, 고장 신고(`report`), 사용 기록(`history`)
- 예약 생성: 패널티 사전 확인 → 최신 기기 상태 재확인 → 예약 → polling 시작
- 예약 취소: polling 복구 보류 → DELETE 성공 경계에서 이전 polling 무효화·대상 제거 → 상태 재조회
- 내 활성 예약 polling(10초): 완료·취소를 감지하고 기기 상태를 갱신합니다.
- 예약 실패 원인 분류(`ReservationErrorCause`, #306)

## 구조

```
reservation/
  data/
    data_sources/remote/
      reservation_remote_data_source.dart          # 생성·취소 (POST/DELETE)
      reservation_status_remote_data_source.dart   # 기기 상태·활성 예약·예약 가능 여부 조회 (GET)
    models/
      local/machine_model.dart                     # MachineModel(상태 판정 getter), MachineStatusResponse
      local/active_reservation_model.dart          # 활성 예약 한 건
      remote/cancel_reservation_response.dart
      remote/reservation_availability_response.dart
  presentation/
    providers/
      reservation_status_provider.dart   # machineStatusProvider, activeReservationProvider, clockProvider, pollingErrorProvider
      reservation_action_provider.dart   # reservationActionProvider (예약·취소)
      reservation_sync_controller.dart   # reservationSyncControllerProvider (polling)
      my_reservation_update.dart         # polling 결과를 호실 목록에 반영하는 값 객체
      reservation_exceptions.dart        # 도메인 예외, ReservationErrorCause, ReservationException
      reservation_error_mapper.dart      # 실패 → ReservationException 정규화
    screens/reservation_screen.dart
    widgets/                             # reservation_machine_list, machine_reservation_card(+ _MachineHistoryIconButton),
                                         # machine_card_footer(+ _MachineCardCleaningFooter, _MachineCardUnavailableFooter),
                                         # machine_card_*_footer, floor_selector_row, laundry_layout_dialog 등
```

repository 없이 provider가 data source를 직접 사용합니다.

## API

| 메서드 | 경로 | 용도 |
| --- | --- | --- |
| GET | `machines/status` | 전체 기기 상태 |
| GET | `reservations/active/room` | 내 호실의 활성 예약 목록 (홈 최초 진입, 백그라운드 재동기화) |
| GET | `reservations/active` | 내 활성 예약 한 건 (polling). 없으면 `data: null` |
| GET | `reservations/availability` | 예약 가능 여부·패널티 만료 시각 |
| POST | `reservations` | 예약 생성 (`{machineId, startTime}`) |
| DELETE | `reservations/{id}` | 예약 취소 |

서버 계약(`ReservationStatusRemoteDataSourceImpl` 주석):
- 활성 예약이 없으면 404가 아니라 200 + 빈 목록 또는 `data: null`입니다. **404는 오류**입니다.
- **451**(이용 대상이 아닌 사용자)만 빈 결과로 대체합니다.

## 레이어와 provider

| provider | 타입 | 역할 |
| --- | --- | --- |
| `machineStatusProvider` | `AsyncNotifier<MachineStatusResponse>` (keepAlive) | 기기 상태. `refresh()` |
| `activeReservationProvider` | `AsyncNotifier<List<ActiveReservationModel>>` (keepAlive) | 호실 활성 예약. `ensureLoaded()`, `refresh()`, `reloadInBackground()`, `applyMyReservation()`, `removeCancelledReservation()` |
| `reservationActionProvider` | `AsyncNotifier<ActiveReservationModel?>` | `reserve()`, `cancel()`. 같은 대상의 중복 요청은 single-flight로 합침(#261) |
| `reservationSyncControllerProvider` | `Provider<ReservationSyncController>` | `startPolling()`, `stopPolling()`, `syncActiveReservation()`, 기존 예약 polling 복구 |
| `clockProvider` | `StreamProvider<DateTime>` | 1초 시계. 카운트다운 텍스트만 구독 |
| `pollingErrorProvider` | `StateProvider<AppException?>` | 조회·polling 실패 안내. home의 `_HomeBody`가 토스트로 띄움 |

## 동작 흐름

**화면 진입**

```
ReservationScreen → ReservationMachineList
  → initState: reservationSyncControllerProvider 초기화
             + activeReservationProvider.ensureLoaded()   # 한 번만 GET reservations/active/room
  → 활성 예약과 내 정보 조회 성공: 내 userId의 예약이 있고 polling 중이 아니면 polling 복구
  → build: machineStatusProvider + activeReservationProvider + myUserProvider 조합
      → _toReservationState(machine, reservations, myUserId)
         우선순위: unavailable → cleaning → 내 예약(inUse/reservedByMe) → available → inUse → reservedByOther
      → 층: 사용자가 고른 층 → 내 호실 층 → 첫 층
  → 당겨서 새로고침: refreshReservationStatusWidgets(기기 상태 + 활성 예약)
```

**예약 생성**

```
예약 버튼 (state == available && 액션 로딩 아님)
  → runDialogAction(LaundryDialogActions.reserve, popFirst: false, onSuccess: go(/home))
  → ReservationActionNotifier.reserve(machineId)
      1. _ensureNotPenalized()        # GET reservations/availability. canReserve=false이고 만료 전이면 ReservationPenaltyException
                                      #   (조회 실패는 서버 검증에 맡기고 진행)
      2. _findMachine()               # GET machines/status. 사용 중으로 보이면 500ms 뒤 한 번 더 확인
                                      #   그래도 불가면 AlreadyReservedException
      3. POST reservations
      4. refreshReservationStatusProviders()
      5. ReservationSyncController.startPolling(reservationId, userId)
  → 실패: state = AsyncError → reservationErrorToAppException(action: reserve) → 에러 토스트
```

**예약 취소**

```
LaundryActionDialog(cancelReservation) → runDialogAction(LaundryDialogActions.cancelReservation)
  → ReservationActionNotifier.cancel(reservationId)
      → suspendPollingRestore() + stopPolling()
      → DELETE reservations/{id}
      → 성공: removeCancelledReservation(id)로 새 요청 순번 경계 생성 + 대상만 즉시 제거
              기기 refresh + 호실 reloadInBackground (조회 실패해도 취소 성공·남은 예약 유지)
      → DELETE 실패: 예약 유지, 원래 polling 중이었다면 재개
      → finally: resumePollingRestore() (취소 성공 시 polling 재시작 없음)
```

**polling** (`ReservationSyncController`, 예약 생성 또는 기존 내 예약 발견 뒤 시작)

```
10초마다 syncActiveReservation()
  → requestId = activeReservationProvider.beginRequest()
  → GET reservations/active
  → applyMyReservation(MyReservationUpdate)     # 늦게 시작한 요청이 이김. 오래된 응답(isStale)은 버림
  → mine == null (완료·취소): polling 종료 + reloadInBackground() + 기기 상태 새로고침
  → mine != null: 6회(약 60초)마다 reloadInBackground()로 룸메이트 예약 반영
                  목록이 바뀌었으면 기기 상태 새로고침
  → 5회 연속 실패: polling 종료 + pollingErrorProvider = '서버 상태가 지연되고 있습니다.'
```

## 의존성

- 사용: `user`(`myUserProvider`), `report`(`ReportBrokenDialog`), `history`(`HistoryDialog`), `core/enums`(`ReservationState`, `LaundryStatus`, `LaundryMachineType`), `core/constants/reservation_durations.dart`, `core/network`(`ServerErrorCode`, `AppException`), `core/utils`, `shared/ui/dialog`, `shared/theme`
- 이 모듈을 쓰는 곳
  - `home`: provider, 모델, 새로고침 함수
  - `shared/ui/dialog/laundry_dialog_actions.dart`: 예약·취소 `DialogAction`, 에러 매퍼
  - `shared/ui/dialog/laundry_status_dialog.dart`
  - `core/router`: `ReservationScreen`

## 주의사항

- **기기 상태 판정은 `MachineModel`의 getter가 기준입니다**(`isUnavailable`, `isCleaning`, `isReserved`, `isInUse`, `isAvailable`).
  - 운전 중 여부는 서버 `availability`로 판단합니다(#228).
  - `CLEANING`은 매주 금요일 오전 10시 자동 통세척입니다.
  - 화면별로 판정 로직을 따로 만들지 않습니다.
- 기기 위치(층·좌우·번호)는 이름 형식 `Washer-3F-L1`을 파싱해서 얻습니다(`MachineModel.placement`).
- `activeReservationProvider`에는 호실 목록 요청과 polling이 동시에 씁니다. 요청 순번(`beginRequest`)을 받지 않고 상태를 직접 바꾸면 응답 순서가 뒤바뀔 때 상태가 과거로 돌아갑니다. `active_reservation_race_test.dart` 참고
- 예약 실패 문구는 `reservationErrorToAppException`이 정합니다.
  - 분류 순서: 도메인 예외 → 서버 `errorCode` → 400/409 상태 코드와 액션
  - UI는 문구 문자열이 아니라 `ReservationErrorCause`로 분기합니다.
- 카운트다운처럼 1초마다 바뀌는 텍스트는 별도 위젯(예: `machine_card_reserved_by_me_footer.dart`의 `_ReservedByMeCountdownText`)으로 분리해 재빌드 범위를 줄입니다. 같은 파일의 private 위젯이어도 위젯 클래스가 따로면 재빌드 범위는 같습니다.
- 예약 확인 뒤 만료 시간은 `reservationExpiryMinutes`(5분)입니다.

## 테스트

`test/features/reservation/` 아래에 있습니다.

- 흐름: `reservation_flow_integration_test.dart`, `reservation_test.dart`
- 경합: `active_reservation_race_test.dart`, `reservation_sync_review_test.dart`
- 데이터 소스: `reservation_status_remote_data_source_test.dart`, `reservation_availability_data_source_test.dart`
- 오류: `reservation_error_mapper_test.dart`, `polling_error_message_test.dart`
- 모델·UI: `machine_model_cleaning_test.dart`, `reservation_machine_list_floor_test.dart`
