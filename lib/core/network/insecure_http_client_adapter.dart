import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

void allowAllCertificates(Dio dio) {
  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    },
  );
}
