import 'dart:io';

/// `DioExceptionType.connectionError`의 원인([rawError])에 맞는 안내 문구를 돌려준다.
/// 소켓 오류가 아니면 null(호출부에서 기본 문구를 쓴다).
String? connectionErrorMessageFor(Object? rawError) {
  if (rawError is! SocketException) {
    return null;
  }
  if (rawError.message.contains('Connection refused')) {
    return '서버 연결이 거부되었습니다. 서버 상태를 확인해주세요.';
  }
  return '네트워크 연결에 실패했습니다. 인터넷 또는 서버 상태를 확인해주세요.';
}
