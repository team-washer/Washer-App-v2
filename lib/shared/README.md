# shared

여러 feature가 함께 쓰는 디자인 시스템(theme)과 공용 UI입니다. 앱 공통 틀(`MainShell`·앱바·하단 탭), 공통 다이얼로그, 에러 토스트, 로딩 오버레이가 여기 있습니다.

## 구조

```
shared/
  theme/
    washer_color.dart           # 색상 팔레트 (mainColor100~, baseGray, errorColor 등)
    washer_typography.dart      # 텍스트 스타일 (SUIT 폰트, .sp)
    app_spacing.dart            # AppSpacing / AppGap / AppPadding / AppRadius
    washer_icon.dart            # WasherIconType(SVG), WasherIcon, WasherIconButton
    washer_theme.dart           # ThemeData
    washer_error_message.dart   # 사용자 노출 오류·안내 문구 모음
  ui/
    layout/
      main_shell.dart           # 로그인 후 공통 틀 (앱바 + 하단 탭 + StatefulShell 본문)
      base_scaffold.dart        # 배경색·여백·SafeArea·(선택) 앱바
      nav_tab_type.dart         # 탭 종류 (선언 순서 = shell 브랜치 인덱스: dryer, home, washer)
      washer_bottom_navigation_bar.dart
    app_bar/
      washer_app_bar.dart       # 로고 + 설정/알림, 로그아웃·회원탈퇴 흐름 조율
      app_bar_actions.dart      # 설정/알림 아이콘 (알림 파란 점)
      setting_dialog.dart, logout_confirm_dialog.dart, withdraw_confirm_dialog.dart, withdraw_complete_dialog.dart
    dialog/
      washer_dialog.dart        # 공통 확인 다이얼로그 (제목 + 본문 + 뒤로가기/확인)
      dialog_action.dart        # DialogAction + runDialogAction (비동기 액션 공통 실행기)
      laundry_dialog_actions.dart   # 예약·예약 취소 DialogAction 정의
      laundry_action_dialog.dart    # 예약 취소 확인 다이얼로그
      laundry_status_dialog.dart    # 기기 현황 다이얼로그 (사용 가능하면 예약하기)
      dialog_info_row.dart, force_update_dialog.dart
    buttons/                    # WasherBigButton, WasherSmallButton, WasherTextButton
    indicators/                 # StatusBadge, StatusDot
    error_toast.dart            # showErrorToast (BuildContext / OverlayState 확장)
    loading_overlay.dart        # showLoadingWhile, runWithLoadingOverlay
```

## 주요 흐름

**에러 토스트** (`ui/error_toast.dart`)

- 사용자에게 보여주는 메시지(오류, 입력 검증, 성공·안내)는 모두 에러 토스트로 띄웁니다. `SnackBar`는 쓰지 않습니다.
- context가 유효할 때는 `context.showErrorToast(error)`를 씁니다.
- 비동기 작업 뒤에는 미리 캡처한 `Overlay.of(context, rootOverlay: true).showErrorToast(error)`를 씁니다.
- 넘긴 값은 `AppException.from`으로 변환됩니다.
  - 문자열을 그대로 넘기면 "알 수 없는 오류"가 되므로 `AppException(message: '...')`로 감쌉니다.
  - 취소된 요청(`isCancelled`)은 띄우지 않습니다.
- 토스트는 화면에 하나만 떠 있고, 5초 뒤 자동으로 닫힙니다.

**다이얼로그 액션** (`ui/dialog/dialog_action.dart`)

```
호출부 → runDialogAction(context, DialogAction)
  → await 전에 navigator / ProviderContainer / root overlay 캡처
  → (popFirst) 다이얼로그 pop
  → action.run(container)          # showLoading이면 로딩 오버레이
  → 성공: onSuccess() → successMessage 토스트
  → 실패: failureError(container) ?? fallbackMessage 토스트
```

- 액션 정의는 한곳에 모읍니다.
  - 예약·취소: `LaundryDialogActions`
  - 고장 신고: `report`의 `ReportDialogActions`
- `run`은 위젯 `ref`가 아니라 `ProviderContainer`를 받습니다. 그래서 pop 뒤에 실행돼도 안전합니다.

**메인 틀** (`ui/layout/main_shell.dart`)

- `MainShell`은 `alarmProvider`를 구독해 알림 뱃지를 표시합니다.
- 현재 탭을 다시 누르면 그 탭의 첫 화면으로 돌아갑니다.
- 앱바 알림 버튼을 누르면 현재 탭 아래의 `alarm` 경로로 push합니다. 이미 알림 화면이면 다시 push하지 않습니다.
- 설정 메뉴에서 로그아웃(`logoutProvider`)과 회원탈퇴(`withdrawProvider`)를 실행합니다.

## 의존성

- 사용하는 feature
  - `alarm`: `alarmProvider`
  - `auth`: `logoutProvider`
  - `user`: `withdrawProvider`
  - `reservation`: 액션·상태 provider, 모델, 에러 매퍼
- 사용: `core/network`(`AppException`, `authNotifier`), `core/enums`, `core/router`, `core/utils`
- 이 모듈을 쓰는 곳: 모든 feature와 `core/network/error.dart`(`WasherErrorMessage`)

## 주의사항

- **`report`를 import하지 않습니다.** `test/architecture/feature_dependency_test.dart`가 검사합니다.
- 색·글꼴·간격은 하드코딩하지 않고 `WasherColor`, `WasherTypography`, `AppSpacing`/`AppGap`/`AppPadding`/`AppRadius`를 씁니다.
- 사용자 노출 문구는 `washer_error_message.dart`에 추가하고 "~요" 말투로 씁니다.
- `LaundryActionDialog`의 `reserve` 타입은 현재 여는 곳이 없습니다.
  - 예약은 `LaundryStatusDialog`와 예약 화면 버튼이 `LaundryDialogActions.reserve`를 직접 실행합니다.
  - `reportBroken` 타입은 `UnsupportedError`를 던집니다. 고장 신고는 `ReportBrokenDialog`를 씁니다.

## 테스트

`test/shared/` 아래에 있습니다.

- `dialog_action_test.dart`
- `error_toast_test.dart`
- `washer_app_bar_test.dart`
