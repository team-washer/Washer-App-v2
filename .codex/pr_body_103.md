## 💡 개요
ios 환경에서 발생하던 SSL 인증서 오류를 완화할 수 있도록 네트워크 및 프로젝트 설정을 보완하고, GitHub PR 자동 생성 스킬을 추가했습니다.

## 🔗 관련 이슈
Closes #103

## 📃 작업내용
- Dio 기본 클라이언트와 토큰 재발급용 Dio에 인증서 예외 허용 어댑터를 적용했습니다.
- `insecure_http_client_adapter.dart`를 추가해 SSL 인증서 오류 대응 로직을 공통화했습니다.
- iOS `Podfile`을 추가하고 Runner 프로젝트 설정과 `Info.plist` 구성을 정리했습니다.
- `FlutterImplicitEngineDelegate` 적용에 맞춰 iOS 플러그인 등록 방식을 수정했습니다.
- GitHub PR 자동 생성 스킬과 한글 PR 작성 규칙을 추가했습니다.

## 🔍 테스트 방법
- `flutter test` 실행
- 실패: `test/widget_test.dart`의 `Counter increments smoke test`에서 텍스트 `"0"`을 찾지 못해 테스트가 실패했습니다.

## 🖼️ 스크린샷

## 🙋‍♂️ 질문사항
- 개선할 점, 오타, 코드에 이상한 부분이 있다면 Comment 달아주세요.

## ✅ 체크리스트
- [ ] 코드가 정상적으로 컴파일되고 실행되는지 확인했습니다.
- [x] 불필요한 코드가 없는지 확인했습니다.
- [x] 코드 스타일 가이드를 준수했습니다.
- [ ] 기존 기능이 정상적으로 작동하는지 확인했습니다.
