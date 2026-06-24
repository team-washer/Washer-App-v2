# App Version Policy Guide

서버 주도(server-driven) 앱 업데이트 정책 운영 가이드입니다. 새로 합류한 사람도 이 문서만 보고 바로 정책을 갱신할 수 있도록 정리했습니다.

## 동작 개요

- 앱은 스플래시에서 `GET /api/v2/app-versions/status`를 호출합니다. (`splash_screen.dart`의 `_handleForceUpdate()`)
- 서버가 **클라이언트 버전 vs 정책**을 비교해 `updateStatus`를 내려줍니다. 클라는 버전 비교를 직접 하지 않고 서버 응답만 따릅니다.

| updateStatus | 의미 | 앱 동작 |
|--------------|------|---------|
| `SUPPORTED` | 계속 사용 가능 | 그냥 진입 |
| `UPDATE_AVAILABLE` | 권장 업데이트 | 팝업 표시, **진입 가능** |
| `UPDATE_REQUIRED` | 강제 업데이트 | 팝업 표시, **진입 차단** |

> 최신 버전 유저는 항상 `SUPPORTED`라 절대 막히지 않습니다. 최신인데 막힌다면 정책 문제가 아니라 다른 버그입니다.

## 정책 갱신: 누가, 어떻게

- 정책 등록/수정은 관리자 API `PUT /api/v2/admin/app-versions/{platform}`로 합니다.
- 이 앱에는 관리자 화면이 없으므로, **`Set App Version Policy` GitHub Actions 워크플로**(`.github/workflows/set-version-policy.yml`)를 `workflow_dispatch`로 수동 실행합니다.
- ⚠️ **새 버전이 스토어에서 실제로 다운로드 가능해진 뒤에만** 실행하세요. 라이브 전에 `minSupported`를 올리면 유저가 아직 받을 수 없는 버전으로 강제 업데이트되어 **앱에 갇힙니다.**

## 최초 1회 세팅

**스토어 링크 채우기** — `.github/workflows/set-version-policy.yml`의 `env`:

- `ANDROID_STORE_URL`: `com.washer.v2`(applicationId)로 이미 채워둠
- `IOS_STORE_URL`: `idPUT_APP_ID` → App Store **숫자 App ID**로 교체 (bundle id 아님, App Store Connect에서 확인)

> 이 admin API는 인증이 필요 없어 별도 토큰/시크릿 설정은 없습니다.

## 릴리스마다 절차

```
[1] develop → main 머지        → release-android / release-ios CD 자동 실행 (스토어 업로드/심사 제출)
[2] 스토어에서 "실제 다운로드 가능" 확인  (iOS=심사통과+출시, Android=롤아웃 완료)
[3] Actions → "Set App Version Policy" → Run workflow → 폼 입력 → 실행
```

3단계 폼 입력값:

| 입력 | 값 | 비고 |
|------|-----|------|
| `platform` | `ANDROID` / `IOS` | 플랫폼별로 따로 실행 (iOS는 심사 때문에 시점이 다름) |
| `latest_version_name` | pubspec 버전 (예 `1.4.0`) | 방금 올린 버전 |
| `latest_version_code` | 빌드번호 | **Android = `1000 + run number`**, **iOS = run number** (해당 release CD 런 로그에서 확인) |
| `min_supported_version_name` | 강제 업데이트 하한 버전명 | 안 바꾸면 직전 값 그대로 |
| `min_supported_version_code` | 강제 업데이트 하한 빌드번호 | 올리면 그 미만 유저 전부 강제 업데이트 |
| `update_message` | 안내 문구 | 비우면 기본 문구 |

## 운영 규칙

- **권장 업데이트만** → `latest`만 올리고 `minSupported`는 그대로. 유저는 팝업만 보고 진입은 됨.
- **강제 업데이트** → `minSupported`를 올림. 단 **2단계(라이브 확인) 후에만.**
- iOS/Android는 정책이 platform별이라 **각각 따로** 실행.
- 업데이트 유도가 필요 없는 자잘한 릴리스는 정책을 건드릴 필요 없음 (스토어 출시만으로 충분).
- `latest_version_code`는 **실제 업로드된 빌드번호와 정확히 일치**시킬 것. 더 높게 넣으면 최신 유저까지 받을 수 없는 버전으로 안내/락아웃됨.
