import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:washer/core/env/app_environment.dart';
import 'package:washer/core/network/http_client_adapter_config.dart';

void main() {
  group('인증서 검증 우회 정책 (#321)', () {
    test('release 빌드는 development flavor에서 우회를 켜도 허용하지 않는다', () {
      expect(
        AppEnvironment.resolveAllowBadCertificates(
          flavor: AppFlavor.development,
          rawValue: 'true',
          isReleaseMode: true,
        ),
        isFalse,
      );
    });

    test('production flavor는 debug 빌드에서도 허용하지 않는다', () {
      expect(
        AppEnvironment.resolveAllowBadCertificates(
          flavor: AppFlavor.production,
          rawValue: 'true',
          isReleaseMode: false,
        ),
        isFalse,
      );
    });

    test('debug의 development flavor는 명시적으로 켰을 때만 허용한다', () {
      for (final value in ['true', ' TRUE ', '1', 'yes']) {
        expect(
          AppEnvironment.resolveAllowBadCertificates(
            flavor: AppFlavor.development,
            rawValue: value,
            isReleaseMode: false,
          ),
          isTrue,
          reason: value,
        );
      }
      for (final value in [null, '', 'false', '0']) {
        expect(
          AppEnvironment.resolveAllowBadCertificates(
            flavor: AppFlavor.development,
            rawValue: value,
            isReleaseMode: false,
          ),
          isFalse,
          reason: '$value',
        );
      }
    });

    test('release 빌드는 우회 설정이 들어와도 기본 어댑터를 바꾸지 않는다', () {
      final dio = Dio();
      final defaultAdapter = dio.httpClientAdapter;

      configureHttpClientAdapter(
        dio,
        allowBadCertificates: true,
        isReleaseMode: true,
      );

      expect(identical(dio.httpClientAdapter, defaultAdapter), isTrue);
    });

    test('debug 빌드에서 허용된 경우에만 우회 어댑터를 설정한다', () {
      final dio = Dio();
      final defaultAdapter = dio.httpClientAdapter;

      configureHttpClientAdapter(
        dio,
        allowBadCertificates: true,
        isReleaseMode: false,
      );

      expect(identical(dio.httpClientAdapter, defaultAdapter), isFalse);
    });
  });

  group('HTTPS 강제 정책 (#321)', () {
    test('release 빌드는 development flavor라도 비HTTPS URL을 거부한다', () {
      expect(
        () => AppEnvironment.ensureHttpsPolicy(
          'API_BASE_URL',
          'http://10.0.2.2:8080/api/v2/',
          AppFlavor.development,
          isReleaseMode: true,
        ),
        throwsStateError,
      );
    });

    test('production flavor는 비HTTPS URL을 거부한다', () {
      expect(
        () => AppEnvironment.ensureHttpsPolicy(
          'API_BASE_URL',
          'http://api.example.test/',
          AppFlavor.production,
          isReleaseMode: false,
        ),
        throwsStateError,
      );
    });

    test('release 빌드는 host가 없는 HTTPS 주소를 거부한다', () {
      for (final value in ['https:api.example.test', 'https:///api/v2/']) {
        expect(
          () => AppEnvironment.ensureHttpsPolicy(
            'API_BASE_URL',
            value,
            AppFlavor.development,
            isReleaseMode: true,
          ),
          throwsStateError,
          reason: value,
        );
      }
    });

    test('release 빌드의 HTTPS URL은 허용한다', () {
      expect(
        () => AppEnvironment.ensureHttpsPolicy(
          'API_BASE_URL',
          'https://api.example.test/',
          AppFlavor.development,
          isReleaseMode: true,
        ),
        returnsNormally,
      );
    });

    test('debug의 development flavor는 로컬 HTTP URL을 허용한다', () {
      expect(
        () => AppEnvironment.ensureHttpsPolicy(
          'API_BASE_URL',
          'http://10.0.2.2:8080/api/v2/',
          AppFlavor.development,
          isReleaseMode: false,
        ),
        returnsNormally,
      );
    });
  });
}
