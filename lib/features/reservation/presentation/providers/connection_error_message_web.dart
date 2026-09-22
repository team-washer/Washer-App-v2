/// web은 브라우저가 네트워크 오류 원인을 SocketException 같은 구체 타입으로
/// 주지 않으므로 항상 null을 돌려주고 호출부의 기본 문구를 쓰게 한다.
String? connectionErrorMessageFor(Object? rawError) => null;
