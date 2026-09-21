import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

/// [allowBadCertificates]가 true일 때만 자체 서명 인증서를 허용하는
/// HTTP 클라이언트 어댑터를 [dio]에 설정한다. false면 기본 어댑터를 그대로 둔다.
void configureHttpClientAdapter(
  Dio dio, {
  required bool allowBadCertificates,
}) {
  if (!allowBadCertificates) {
    return;
  }

  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      // Development-only override for local/self-signed certificates.
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    },
  );
}
