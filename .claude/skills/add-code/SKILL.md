---
name: add-code
description: lib/에 기능·파일·클래스·위젯·provider·API 호출을 새로 추가하거나 옮길 때 사용. 코드를 쓰기 전에 중복 코드가 있는지 찾고, 아키텍처 위치와 파일명 규칙을 정한다.
---

# 코드 추가 체크리스트

새 코드를 쓰기 **전에** 아래 순서를 따른다. 규칙 원문은 `AGENTS.md`.

## 1. 중복 확인 (먼저 찾고, 있으면 재사용)

만들려는 것의 이름과 역할 키워드로 `lib/`를 검색한다. 생성 파일(`*.g.dart`, `*.freezed.dart`)은 제외한다.

| 만들려는 것 | 먼저 볼 곳 |
| --- | --- |
| 날짜·호실·사용자 표시 포맷 | `lib/core/utils/*_formatter.dart` |
| 로그 | `lib/core/utils/app_logger.dart` (`AppLogger`) |
| API 오류 처리 | `lib/core/network/error.dart` (`AppException`, `guardApiCall`, `Result`) |
| Dio·인증·토큰 | `lib/core/network/` (`dioProvider`, 인터셉터) |
| 상태 enum (세탁기·예약 상태 등) | `lib/core/enums/` |
| 공용 버튼·다이얼로그·앱바·로딩·토스트 | `lib/shared/ui/` |
| 색·타이포그래피·간격·아이콘 | `lib/shared/theme/` (`washer_color`, `washer_typography`, `app_spacing`, `washer_icon`) |
| 같은 기능의 모델·data source·provider | `lib/features/<feature>/` |

- 비슷한 코드가 있으면 새로 만들지 말고 재사용하거나 확장한다. 확장 범위가 크면 사용자에게 먼저 묻는다.
- 두 feature 이상에서 쓰는 UI는 `lib/shared/ui/`, 로직·유틸은 `lib/core/`로 올린다. 이때 feature 간 import 순환이 생기지 않는지 확인한다 (`test/architecture/feature_dependency_test.dart`).

## 2. 위치 결정

```
lib/features/<feature>/
  data/data_sources/     Retrofit @RestApi + xxxDataSourceProvider
  data/models/           freezed 모델 (remote/, local/, request/, response/)
  data/repositories/     여러 data source를 묶을 때만
  presentation/providers/  Notifier / AsyncNotifier (비즈니스 로직)
  presentation/screens/    화면
  presentation/widgets/    화면 조각
  presentation/models|states/  UI 전용 모델·상태
```

- `lib/` 바로 아래나 `core/`, `features/`, `shared/` 밖에는 두지 않는다.
- UI(screens, widgets, shared/ui)는 provider만 사용한다. dio, retrofit, data source, repository를 직접 import하지 않는다.

## 3. 이름

- 파일명은 snake_case, 위젯 클래스명은 파일명의 PascalCase (`machine_card_footer.dart` → `MachineCardFooter`)
- 한 파일에 public 위젯 하나. 보조 위젯은 `_Private`로 두거나 파일을 나눈다.
- provider는 `xxxProvider`, data source는 `xxxRemoteDataSource`(현재 alarm만 `AlarmDataSource`). 같은 feature의 기존 이름 패턴을 따른다.

## 4. 작성 후 검증

```bash
dart .claude/hooks/check_dart_conventions.dart --all   # 아키텍처·파일명·중복 전체 점검
fvm dart run build_runner build --delete-conflicting-outputs   # 모델·Retrofit 변경 시
fvm flutter analyze --no-fatal-infos
fvm flutter test
```

`check_dart_conventions` 훅은 파일을 쓸 때마다 자동으로 실행된다. 훅이 위반을 알리면 무시하지 말고 고친다.
기존 파일에 원래 있던 위반(`--all`에서 보이는 것)은 이슈 범위가 아니면 고치지 않는다.
