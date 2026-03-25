import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

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
