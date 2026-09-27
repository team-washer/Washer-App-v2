import 'package:dio/dio.dart';

/// 브라우저는 인증서 신뢰 여부를 앱이 아닌 브라우저가 결정하므로,
/// web에서는 자체 서명 인증서 허용 설정을 적용할 방법이 없다.
void configureHttpClientAdapter(
  Dio dio, {
  required bool allowBadCertificates,
}) {}
