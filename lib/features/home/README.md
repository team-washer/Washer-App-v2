# home

로그인 후 첫 화면(`/home`)입니다. 내 호실 예약 현황과 내 층의 세탁기·건조기 현황을 보여줍니다. **presentation 레이어만** 있고, 데이터는 `reservation`·`user`·`alarm`의 provider를 구독합니다.

## 기능

- "{호실}호 예약 현황" 섹션: 활성 예약 카드를 가로 목록으로 보여줍니다.
  - 상태별 안내: 예약 만료 카운트다운, 남은 세탁·건조 시간 등
  - 내 예약이면서 예약(reserved) 상태일 때만 예약 취소 버튼을 보여줍니다.
- 세탁기/건조기 현황 섹션: 내 호실 층의 기기만 2열 그리드로 보여줍니다.
  - 호실을 모르거나 지원 층(`RoomFormatter.supportedFloors`: 3·4·5층)이 아니면 전체 기기를 보여줍니다.
  - 타일을 탭하면 `LaundryStatusDialog`(shared)가 열리고, 사용 가능한 기기는 거기서 바로 예약할 수 있습니다.
  - "전체보기"를 누르면 `/washer` 또는 `/dryer` 탭으로 이동합니다.
- 당겨서 새로고침, 앱 resume 시 자동 갱신
- 조회·polling 오류(`pollingErrorProvider`)를 에러 토스트로 띄웁니다.

## 구조

```
home/
  presentation/
    screens/home_screen.dart              # 최상위 화면
                                          #   + _HomeBody: provider 구독, 새로고침·resume·오류 토스트 조율
                                          #   + _HomeErrorView: 기기 현황 조회 실패 + 재시도
    widgets/
      my_reservation_section.dart         # 예약 현황 섹션
      my_reservation_card.dart            # 활성 예약 카드 한 장
                                          #   + _MyReservationCancelButton: 예약 취소 → LaundryActionDialog
      my_reservation_status_body.dart     # 상태(laundryStatus)별 본문
                                          #   + _ReservationExpiryText: 예약 만료 카운트다운 (clockProvider)
                                          #   + _InUseCountdownText: 남은 사용 시간 (clockProvider)
      machine_status_section.dart         # 기기 현황 섹션(헤더 + 그리드 sliver), 배치 순 정렬
                                          #   + _MachineSectionHeader: 섹션 제목 + 전체보기
      machine_status_tile.dart            # 기기 타일 → LaundryStatusDialog
```

## 동작 흐름

```
_HomeBody (home_screen.dart)
  initState (첫 프레임 후)
    → activeReservationProvider.ensureLoaded()     # 호실 활성 예약 최초 1회
    → alarmProvider.fetchAlarmList()               # 알림 뱃지
  build
    → ref.listen(pollingErrorProvider) → WasherToast.error 후 null로 초기화
    → machineStatusProvider.when(loading / error: _HomeErrorView / data)
    → 호실: myUserProvider.roomNumber → 없으면 첫 활성 예약의 userRoomNumber
    → 층 필터 → washer/dryer 분리 → MyReservationSection + MachineStatusSection x2
  당겨서 새로고침
    → 기기 상태, 활성 예약, 내 정보 refresh + fetchAlarmList(force: true)
  앱 resume (5초 throttle)
    → invalidate(machineStatusProvider, myUserProvider) + activeReservationProvider.refresh()   # #276
```

## 의존성

- 사용: `reservation`(`machineStatusProvider`, `activeReservationProvider`, `clockProvider`, `pollingErrorProvider`, 모델), `user`(`myUserProvider`), `alarm`(`alarmProvider`), `core/enums`, `core/utils`(`RoomFormatter`, `DateTimeFormatter`), `core/constants`, `core/router`, `shared/ui/dialog`(`LaundryStatusDialog`, `LaundryActionDialog`), `shared/ui/washer_toast`
- 이 모듈을 쓰는 곳: `core/router`(`HomeScreen`)

## 주의사항

- 데이터를 직접 조회하지 않습니다. 새 데이터가 필요하면 해당 feature의 provider를 추가하거나 확장합니다.
- 층 계산은 `RoomFormatter.floorFromRoomNumber`, 기기 층은 `MachineModel.floorNumber`를 사용합니다.
- 카운트다운 텍스트만 `clockProvider`를 구독하게 해서 1초마다 카드 전체가 다시 그려지지 않게 합니다.
- 테스트 폴더(`test/features/home`)는 아직 없습니다.
