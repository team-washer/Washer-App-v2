# report

기기 고장 신고를 담당하는 모듈입니다. 다른 feature를 import하지 않는 **leaf 모듈**입니다.

## 기능

- 고장 신고 다이얼로그: 고장 내용을 입력하고(필수) 신고합니다.
- 내용이 비어 있으면 입력 필드에 포커스를 주고 `WasherErrorMessage.reportDescriptionRequired` 토스트를 띄웁니다.

## 구조

```
report/
  data/
    data_sources/remote/report_remote_data_source.dart   # Retrofit ReportApiService
  presentation/
    providers/
      report_provider.dart                                # ReportNotifier
      report_dialog_actions.dart                          # ReportDialogActions.reportBroken (DialogAction 정의)
    widgets/report_broken_dialog.dart                     # ReportBrokenDialog
```

모델 파일은 없습니다. 요청 본문은 `{machineId, description}` Map으로 보냅니다.

## API

| 메서드 | 경로 | 용도 |
| --- | --- | --- |
| POST | `malfunction-reports` | 고장 신고 |

## 동작 흐름

```
MachineCardAvailableFooter (reservation) → showDialog(ReportBrokenDialog(onReported: ...))
  → 신고하기
  → runDialogAction(ReportDialogActions.reportBroken)      # shared/ui/dialog/dialog_action.dart
      → 다이얼로그 pop
      → ReportNotifier.createMalfunctionReport()           # guardApiCall(POST malfunction-reports)
      → 성공: onReported 콜백 → '신고가 완료되었습니다.' 토스트
      → 실패: reportProvider의 error(없으면 fallback 문구) 토스트
  → onReported(reservation 쪽): machineStatusProvider/activeReservationProvider 새로고침
```

## 의존성

- 사용: `core/network`, `shared/ui/dialog`(`DialogAction`, `runDialogAction`, `WasherDialog`), `shared/ui/washer_toast`, `shared/theme`
- 이 모듈을 쓰는 곳: `reservation`(`machine_card_available_footer.dart`)

## 주의사항

- **다른 feature를 import하지 않습니다.** `test/architecture/feature_dependency_test.dart`가 검사하며, `shared`도 `report`를 import하면 안 됩니다.
  - 그래서 신고 액션은 shared의 `LaundryDialogActions`가 아니라 `ReportDialogActions`에 둡니다.
  - 신고 뒤 기기 상태 갱신처럼 다른 feature의 일은 호출한 쪽이 `onReported` 콜백으로 넘깁니다.
- `onReported`는 다이얼로그가 닫힌 뒤 실행됩니다. 위젯의 `ref`/`context`가 아니라 미리 캡처한 값(예: `ProviderContainer`)만 써야 합니다.

## 테스트

- `test/features/report/report_test.dart`
- `test/features/report/report_broken_dialog_test.dart`
