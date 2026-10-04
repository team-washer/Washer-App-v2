# history

기기 한 대의 최근 사용 기록을 다이얼로그로 보여주는 모듈입니다.

## 기능

- 사용 기록 다이얼로그: 예약 화면의 기기 카드에서 기록 아이콘(`MachineHistoryIconButton`)을 누르면 열립니다.
- 조회 범위는 **전날 00:00 ~ 오늘 23:59:59**입니다. 앱을 주로 밤(21:20~새벽)에 쓰기 때문에, 자정이 지나도 전날 기록을 볼 수 있게 했습니다.
- 페이지가 여러 개면 모든 페이지(`size: 50`)를 순회해 합칩니다.

## 구조

```
history/
  data/
    data_sources/history_remote_data_source.dart   # Retrofit HistoryApiService
    models/machine_history_response.dart            # 페이지 응답 + HistoryContent
  presentation/
    models/history_status.dart                      # 서버 상태 문자열 → HistoryStatus (라벨·색·시간 라벨)
    providers/history_provider.dart                 # HistoryNotifier, historyProvider(machineId)
    states/history_state.dart                       # isLoading, error, historyList
    widgets/history_dialog.dart, history_card.dart
```

repository 없이 provider가 data source를 직접 사용합니다. 화면(screen)은 없습니다.

## API

| 메서드 | 경로 | 용도 |
| --- | --- | --- |
| GET | `machines/{machineId}/history?startDate&endDate&page&size` | 기기 사용 기록(페이지) |

## 동작 흐름

```
MachineHistoryIconButton (reservation) → showDialog(HistoryDialog)
  → initState post-frame (mounted일 때만): historyProvider(machineId).notifier.fetchRecentHistory()
      → guardApiCall(getMachineHistory) 를 last == true 까지 반복
      → 성공: HistoryState.historyList
      → 실패: HistoryState.error = AppException
  → HistoryDialog가 ref.listen(historyProvider(machineId).select(error)) → WasherToast.error
  → 목록: HistoryCard (상태 배지, 예약 호실, 예약 시간, 완료/취소/예정 시간)
```

## 의존성

- 사용: `core/network`, `core/utils`(`DateTimeFormatter`), `shared/theme`, `shared/ui`(`WasherDialog`, `StatusBadge`, `WasherToast`)
- 이 모듈을 쓰는 곳: `reservation`(`machine_history_icon_button.dart`)

## 주의사항

- 알 수 없는 상태 문자열은 `HistoryStatus.reserved`로 처리합니다(`HistoryStatusX.fromString`).
- `HistoryCard`의 마지막 시간 값: 취소는 `createdAt`, 그 외는 `completionTime`을 씁니다(없으면 `-`).
- `historyProvider`는 `machineId`별 `autoDispose` family입니다. 기기마다 상태가 따로 있고 다이얼로그가 닫히면 해제됩니다.
- 응답을 받은 뒤 상태가 해제됐거나(`ref.mounted == false`) 같은 기기에서 더 최신 조회가 시작됐으면 그 응답은 버립니다. 늦은 응답이 다른 기기나 최신 조회 결과를 덮지 않게 하기 위해서입니다.

## 테스트

- `test/features/history/history_provider_test.dart`: 기기별 상태 격리, 늦은 응답 무시
- `test/features/history/history_dialog_test.dart`: 다이얼로그 조회 시작·즉시 닫기
