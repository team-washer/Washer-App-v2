import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:washer/core/errors/app_exception.dart';

/// 서버 오류 응답 계약(공통 wrapper + 상태 코드별 의미)을 앱이 그대로 따르는지 검증한다.
DioException _serverError(
  int statusCode, {
  String? message,
  Map<String, Object?>? data,
}) {
  final options = RequestOptions(path: '/reservations');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: statusCode,
      data: {
        'status': '$statusCode',
        'code': statusCode,
        if (message != null) 'message': message,
        if (data != null) 'data': data,
      },
    ),
  );
}

void main() {
  group('공통 오류 wrapper 파싱', () {
    test('message, errorCode, traceId, fieldErrors를 읽는다', () {
      final exception = AppException.from(
        _serverError(
          400,
          message: '요청 값이 올바르지 않습니다.',
          data: {
            'errorCode': 'VALIDATION_FAILED',
            'traceId': 'trace-123',
            'fieldErrors': [
              {'field': 'machineId', 'message': '필수 값입니다.'},
            ],
          },
        ),
      );

      expect(exception.message, '요청 값이 올바르지 않습니다.');
      expect(exception.statusCode, 400);
      expect(exception.errorCode, 'VALIDATION_FAILED');
      expect(exception.traceId, 'trace-123');
      expect(exception.fieldErrors, isA<List<dynamic>>());
    });

    test('추적 정보는 debugMessage에 남겨 로그로 서버와 대조할 수 있다', () {
      final exception = AppException.from(
        _serverError(
          409,
          message: '이미 사용이 시작되었습니다.',
          data: {'errorCode': 'RESERVATION_RUNNING', 'traceId': 'trace-9'},
        ),
      );

      expect(exception.debugMessage, contains('errorCode=RESERVATION_RUNNING'));
      expect(exception.debugMessage, contains('traceId=trace-9'));
    });

    test('data가 없는 오류 응답도 안전하게 처리한다', () {
      final exception = AppException.from(
        _serverError(404, message: '예약을 찾을 수 없습니다.'),
      );

      expect(exception.message, '예약을 찾을 수 없습니다.');
      expect(exception.errorCode, isNull);
      expect(exception.traceId, isNull);
      expect(exception.fieldErrors, isNull);
    });

    test('data가 Map이 아니어도 죽지 않는다', () {
      final options = RequestOptions(path: '/x');
      final exception = AppException.from(
        DioException(
          requestOptions: options,
          response: Response<dynamic>(
            requestOptions: options,
            statusCode: 400,
            data: {'message': '잘못된 요청', 'data': 'unexpected'},
          ),
        ),
      );

      expect(exception.message, '잘못된 요청');
      expect(exception.traceId, isNull);
    });
  });

  group('상태 코드별 문구', () {
    test('서버가 message를 주면 그 문구를 우선한다 (400/401/403/404/409/451)', () {
      for (final code in [400, 401, 403, 404, 409, 451]) {
        final exception = AppException.from(
          _serverError(code, message: '서버 문구 $code'),
        );

        expect(exception.message, '서버 문구 $code', reason: 'status $code');
      }
    });

    test('서버 message가 없으면 상태 코드별 기본 문구를 쓴다', () {
      final expected = <int, String>{
        400: '요청 정보가 올바르지 않습니다.',
        401: '로그인이 만료되었습니다. 다시 로그인해주세요.',
        403: '이 작업을 수행할 권한이 없습니다.',
        404: '요청한 정보를 찾을 수 없습니다.',
        409: '현재 상태에서는 요청을 처리할 수 없습니다.',
        451: '서비스 이용 대상이 아닙니다.',
      };

      expected.forEach((code, message) {
        expect(
          AppException.from(_serverError(code)).message,
          message,
          reason: 'status $code',
        );
      });
    });

    test('502/503은 서버 메시지가 기술적이어도 사용자용 고정 문구를 보여준다', () {
      final badGateway = AppException.from(
        _serverError(502, message: 'SmartThings API timeout: connect refused'),
      );
      final unavailable = AppException.from(
        _serverError(
          503,
          message: 'Redis connection failed',
          data: {'errorCode': 'REDIS_DOWN', 'traceId': 't-1'},
        ),
      );

      expect(badGateway.message, '기기 서비스와 연결하지 못했습니다. 잠시 후 다시 시도해주세요.');
      expect(unavailable.message, '서버가 일시적으로 불안정합니다. 잠시 후 다시 시도해주세요.');
      // 기술적인 원인은 화면에 노출하지 않고 추적 정보로만 남긴다.
      expect(unavailable.message, isNot(contains('Redis')));
      expect(unavailable.traceId, 't-1');
      expect(unavailable.errorCode, 'REDIS_DOWN');
    });

    test('그 밖의 5xx는 서버 메시지가 없으면 일반 서버 오류 문구다', () {
      expect(
        AppException.from(_serverError(500)).message,
        '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
      );
    });

    test('응답이 없는 네트워크 오류는 연결 확인 문구다', () {
      final exception = AppException.from(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(exception.message, '네트워크 연결을 확인해주세요.');
    });
  });
}
