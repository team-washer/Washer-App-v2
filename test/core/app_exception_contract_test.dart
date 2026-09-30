import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:washer/core/network/error.dart';

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

      expect(exception.message, '입력한 정보를 다시 확인해주세요.');
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

      expect(exception.message, '예약 정보를 찾을 수 없어요.\n다시 확인해주세요.');
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

      expect(exception.message, '입력한 정보를 다시 확인해주세요.');
      expect(exception.traceId, isNull);
    });
  });

  group('상태 코드별 문구', () {
    test('정의된 상태 코드는 서버 message와 무관하게 항상 고정 문구를 보여준다', () {
      final expected = <int, String>{
        400: '입력한 정보를 다시 확인해주세요.',
        401: '로그인이 필요해요. 다시 로그인해주세요.',
        403: '이 기능을 이용할 수 없어요.',
        404: '예약 정보를 찾을 수 없어요.\n다시 확인해주세요.',
        409: '다른 요청과 겹쳤어요.\n최신 상태를 확인한 뒤 다시 시도해주세요.',
        451: '현재 예약 서비스를 이용할 수 없는 사용자예요.',
        502: '기기와 연결할 수 없어요.\n잠시 후 다시 시도해주세요.',
        503: '서비스가 잠시 불안정해요.\n잠시 후 다시 시도해주세요.',
      };

      expected.forEach((code, message) {
        expect(
          AppException.from(_serverError(code, message: '서버 문구 $code')).message,
          message,
          reason: 'status $code',
        );
        expect(
          AppException.from(_serverError(code)).message,
          message,
          reason: 'status $code (message 없음)',
        );
      });
    });

    test('404는 원인별 코드로 사용자/예약/기기 없음을 구분한다', () {
      String messageFor(String errorCode) => AppException.from(
        _serverError(404, message: '서버 문구', data: {'errorCode': errorCode}),
      ).message;

      expect(messageFor('USER_NOT_FOUND'), contains('사용자 정보'));
      expect(messageFor('RESERVATION_NOT_FOUND'), contains('예약 정보'));
      expect(messageFor('MACHINE_NOT_FOUND'), contains('기기 정보'));
      // 원인별 코드가 없는 404(없는 경로 등)는 상태 코드 문구를 쓴다.
      expect(messageFor('NOT_FOUND'), '예약 정보를 찾을 수 없어요.\n다시 확인해주세요.');
    });

    test('원인별 코드 문구가 상태 코드 문구보다 우선한다', () {
      final withdrawn = AppException.from(
        _serverError(
          403,
          message: '탈퇴 후 30일이 지나지 않아 재가입할 수 없습니다.',
          data: {'errorCode': 'WITHDRAWN_REJOIN_RESTRICTED'},
        ),
      );
      final activeReservation = AppException.from(
        _serverError(
          400,
          message: '이미 활성 예약이 존재합니다. 1인 1예약만 가능합니다.',
          data: {'errorCode': 'USER_ACTIVE_RESERVATION'},
        ),
      );

      final floorRestricted = AppException.from(
        _serverError(
          451,
          message: '1~4층 기숙사생이 아니라면 서비스를 이용할 수 없습니다.',
          data: {'errorCode': 'USER_FLOOR_RESTRICTED'},
        ),
      );

      expect(withdrawn.message, contains('30일'));
      expect(activeReservation.message, isNot('입력한 정보를 다시 확인해주세요.'));
      expect(activeReservation.message, contains('기존 예약'));
      expect(floorRestricted.message, '5층 기숙사생은 워셔를 이용할 수 없어요.');
    });

    test('이용 제한 코드는 제한 대상과 해제 시각이 담긴 서버 문구를 그대로 보여준다', () {
      final exception = AppException.from(
        _serverError(
          400,
          message: '현재 예약이 제한되어 있습니다. 제한 해제까지 12분 남았습니다.',
          data: {'errorCode': 'USER_PENALTY_ACTIVE'},
        ),
      );

      expect(exception.message, '현재 예약이 제한되어 있습니다. 제한 해제까지 12분 남았습니다.');
    });

    test('모르는 코드는 상태 코드 문구로 처리한다', () {
      final exception = AppException.from(
        _serverError(
          409,
          message: '서버 문구',
          data: {'errorCode': 'SOMETHING_NEW'},
        ),
      );

      expect(exception.message, '다른 요청과 겹쳤어요.\n최신 상태를 확인한 뒤 다시 시도해주세요.');
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

      expect(badGateway.message, '기기와 연결할 수 없어요.\n잠시 후 다시 시도해주세요.');
      expect(unavailable.message, '서비스가 잠시 불안정해요.\n잠시 후 다시 시도해주세요.');
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

    test('그 밖의 5xx는 서버 메시지가 있어도 노출하지 않는다', () {
      final exception = AppException.from(
        _serverError(500, message: 'NullPointerException at Service.java:42'),
      );

      expect(exception.message, '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.');
      expect(exception.statusCode, 500);
    });

    test('앱이 취소한 요청은 네트워크 오류가 아니라 취소로 구분한다', () {
      final exception = AppException.from(
        DioException(
          requestOptions: RequestOptions(path: '/reservations'),
          type: DioExceptionType.cancel,
          error: '인증 토큰 갱신에 실패했습니다.',
        ),
      );

      expect(exception.isCancelled, isTrue);
      expect(exception.message, isNot('네트워크 연결을 확인해주세요.'));
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
