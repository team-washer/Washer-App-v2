import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:washer/core/network/error.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_error_mapper.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_exceptions.dart';

/// 실제 서버의 공통 오류 wrapper 형태로 예약 API 오류를 만든다.
/// 코드와 문구는 백엔드 #196(PR #209)의 `ErrorCode`·서비스 예외를 따른다.
DioException _serverError(
  int statusCode, {
  String? message,
  String? errorCode,
  String? traceId,
  List<Map<String, String>>? fieldErrors,
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
        'data': {
          if (errorCode != null) 'errorCode': errorCode,
          if (traceId != null) 'traceId': traceId,
          if (fieldErrors != null) 'fieldErrors': fieldErrors,
        },
      },
    ),
  );
}

ReservationException _reserve(Object error) =>
    reservationErrorToAppException(error, action: ReservationAction.reserve)
        as ReservationException;

ReservationException _cancel(Object error) =>
    reservationErrorToAppException(error, action: ReservationAction.cancel)
        as ReservationException;

void main() {
  group('예약 생성 400', () {
    test('개인 활성 예약은 기존 예약 확인을 안내한다', () {
      final result = _reserve(
        _serverError(
          400,
          message: '이미 활성 예약이 존재합니다. 1인 1예약만 가능합니다.',
          errorCode: 'USER_ACTIVE_RESERVATION',
        ),
      );

      expect(result.cause, ReservationErrorCause.activeReservationExists);
      expect(result.message, contains('기존 예약을 확인'));
    });

    test('호실 동일 유형 예약은 다른 유형 선택 또는 대기를 안내한다', () {
      final result = _reserve(
        _serverError(
          400,
          message: '해당 호실에 이미 세탁기 예약이 존재합니다. 동일 유형의 기기는 동시에 두 개 이상 예약할 수 없습니다.',
          errorCode: 'ROOM_MACHINE_TYPE_RESERVED',
        ),
      );

      expect(result.cause, ReservationErrorCause.roomSameTypeReserved);
      expect(result.message, contains('다른 종류의 기기'));
    });

    test('쿨다운·패널티·호실 제한·시간 제한은 서버가 준 제한 대상과 시각을 그대로 보여준다', () {
      const cases = {
        'RESERVATION_COOLDOWN_ACTIVE': '예약 취소 후 5분간 세탁기 예약이 제한됩니다',
        'ROOM_RESERVATION_RESTRICTED': '48시간 내 취소 횟수를 초과하여 예약이 제한됩니다',
        'USER_PENALTY_ACTIVE': '현재 예약이 제한되어 있습니다. 제한 해제까지 12분 남았습니다.',
        'RESERVATION_TIME_RESTRICTED': '2학년은 21:20 이후에만 예약할 수 있습니다',
      };

      cases.forEach((code, message) {
        final result = _reserve(
          _serverError(400, message: message, errorCode: code),
        );
        expect(result.cause, ReservationErrorCause.restricted, reason: code);
        expect(result.message, message, reason: code);
      });
    });

    test('제한 코드인데 서버 문구가 없으면 고정 문구로 안내한다', () {
      final result = _reserve(
        _serverError(400, errorCode: 'RESERVATION_COOLDOWN_ACTIVE'),
      );

      expect(result.cause, ReservationErrorCause.restricted);
      expect(result.message, contains('같은 종류의 기기'));
    });

    test('사용할 수 없는 기기는 다른 기기 선택을 안내한다', () {
      final result = _reserve(
        _serverError(
          400,
          message: '해당 기기를 사용할 수 없습니다. 기기: 3F-W1',
          errorCode: 'MACHINE_UNAVAILABLE',
        ),
      );

      expect(result.cause, ReservationErrorCause.machineOccupied);
      expect(result.message, contains('다른 기기'));
    });

    test('입력 검증 오류는 필드를 사용자용 이름으로 안내한다', () {
      final result = _reserve(
        _serverError(
          400,
          message: '기기 ID는 필수입니다',
          errorCode: 'VALIDATION_FAILED',
          traceId: 'trace-1',
          fieldErrors: [
            {'field': 'machineId', 'message': '기기 ID는 필수입니다'},
            {'field': 'internalFlag', 'message': '값이 올바르지 않습니다'},
          ],
        ),
      );

      expect(result.cause, ReservationErrorCause.validation);
      expect(result.message, '입력한 정보를 다시 확인해주세요.');
      expect(result.fieldErrorMessages, [
        '기기: 기기 ID는 필수입니다',
        // 모르는 필드는 개발용 이름을 노출하지 않는다.
        '값이 올바르지 않습니다',
      ]);
      expect(result.traceId, 'trace-1');
    });

    test('원인별 코드가 없는 400은 입력 오류로 단정하지 않고 서버 문구를 쓴다', () {
      final result = _reserve(
        _serverError(400, message: '요청을 처리할 수 없습니다.', errorCode: 'BAD_REQUEST'),
      );

      expect(result.cause, ReservationErrorCause.unknown);
      expect(result.message, '요청을 처리할 수 없습니다.');
    });

    test('errorCode도 message도 없는 구버전 400도 입력 오류 문구로 왜곡하지 않는다', () {
      final options = RequestOptions(path: '/reservations');
      final result = _reserve(
        DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(requestOptions: options, statusCode: 400),
        ),
      );

      expect(result.cause, ReservationErrorCause.unknown);
      expect(result.message, isNot('입력한 정보를 다시 확인해주세요.'));
    });
  });

  group('예약 생성 403', () {
    test('호실 세탁 금지는 권한 문구가 아닌 제한 안내를 한다', () {
      final result = _reserve(
        _serverError(
          403,
          message: '해당 호실은 현재 세탁이 금지된 상태입니다.',
          errorCode: 'ROOM_WASHING_BANNED',
        ),
      );

      expect(result.cause, ReservationErrorCause.restricted);
      expect(result.message, contains('세탁이 금지'));
    });
  });

  group('예약 생성 451', () {
    test('이용 대상이 아닌 층의 사용자는 제한 해제 대기가 아닌 이용 불가로 분류한다', () {
      final result = _reserve(
        _serverError(
          451,
          message: '1~4층 기숙사생이 아니라면 서비스를 이용할 수 없습니다.',
          errorCode: 'USER_FLOOR_RESTRICTED',
        ),
      );

      expect(result.cause, ReservationErrorCause.notEligible);
      expect(result.message, '5층 기숙사생은 워셔를 이용할 수 없어요.');
    });
  });

  group('예약 생성 409', () {
    test('기기 점유·사용 중은 새로고침 후 다른 기기 선택을 안내한다', () {
      for (final code in ['MACHINE_ALREADY_RESERVED', 'MACHINE_IN_USE']) {
        final result = _reserve(
          _serverError(409, message: '서버 문구', errorCode: code),
        );

        expect(
          result.cause,
          ReservationErrorCause.machineOccupied,
          reason: code,
        );
        expect(result.message, contains('새로고침'), reason: code);
        expect(result.message, isNot(contains('취소')), reason: code);
      }
    });

    test('동시성 충돌·기기 종료 중은 재시도를 안내하고 취소 문구를 쓰지 않는다', () {
      for (final code in ['CONFLICT', 'MACHINE_SHUTDOWN_IN_PROGRESS']) {
        final result = _reserve(
          _serverError(409, message: '서버 문구', errorCode: code),
        );

        expect(result.cause, ReservationErrorCause.conflict, reason: code);
        expect(result.message, contains('다시 시도'), reason: code);
        expect(result.message, isNot(contains('취소')), reason: code);
      }
    });

    test('원인별 코드가 없는 생성 409는 취소 문구가 아닌 충돌 안내를 한다', () {
      final result = _reserve(_serverError(409));

      expect(result.cause, ReservationErrorCause.conflict);
      expect(result.message, isNot(contains('취소')));
    });
  });

  group('예약 취소', () {
    test('사용 시작 후 취소는 취소할 수 없다는 기존 안내를 유지한다', () {
      final result = _cancel(
        _serverError(
          409,
          message: '이미 기기 사용이 시작되어 예약을 취소할 수 없습니다. 최신 상태를 확인해주세요.',
          errorCode: 'RESERVATION_CANCELLATION_CONFLICT',
        ),
      );

      expect(result.cause, ReservationErrorCause.alreadyStarted);
      expect(result.message, '이미 사용이 시작된 예약은 취소할 수 없어요.');
    });

    test('구버전 서버의 상태 이름 코드(CONFLICT) 취소 409는 사용 시작 안내로 처리한다', () {
      // 구버전 서버는 취소 중 사용 시작 충돌을 data.errorCode: CONFLICT로 내려준다.
      final result = _cancel(
        _serverError(
          409,
          message: '이미 기기 사용이 시작되어 예약을 취소할 수 없습니다.',
          errorCode: 'CONFLICT',
        ),
      );

      expect(result.cause, ReservationErrorCause.alreadyStarted);
      expect(result.message, '이미 사용이 시작된 예약은 취소할 수 없어요.');
      expect(result.errorCode, 'CONFLICT');
    });

    test('errorCode가 없는 구버전 취소 409도 사용 시작 안내로 처리한다', () {
      final result = _cancel(_serverError(409));

      expect(result.cause, ReservationErrorCause.alreadyStarted);
      expect(result.message, '이미 사용이 시작된 예약은 취소할 수 없어요.');
    });

    test('취소할 수 없는 상태의 예약은 최신 상태 확인을 안내한다', () {
      final result = _cancel(
        _serverError(
          400,
          message: '취소할 수 있는 상태의 예약이 아닙니다',
          errorCode: 'RESERVATION_STATE_INVALID',
        ),
      );

      expect(result.cause, ReservationErrorCause.conflict);
      expect(result.message, contains('최신 상태'));
    });
  });

  group('앱 도메인 예외', () {
    test('사전 조회에서 이미 예약된 기기로 확인되면 기기 점유로 분류한다', () {
      final result = _reserve(const AlreadyReservedException());

      expect(result.cause, ReservationErrorCause.machineOccupied);
      expect(result.message, contains('새로고침'));
    });

    test('사전 조회에서 패널티로 막히면 남은 시간을 안내한다', () {
      final result = _reserve(
        ReservationPenaltyException(
          DateTime.now().add(const Duration(minutes: 3, seconds: 30)),
        ),
      );

      expect(result.cause, ReservationErrorCause.restricted);
      expect(result.message, contains('3분 후'));
    });
  });

  group('추적 정보와 기존 안내 유지', () {
    test('분류해도 statusCode·errorCode·traceId·serverMessage는 보존된다', () {
      final result = _reserve(
        _serverError(
          400,
          message: '이미 활성 예약이 존재합니다. 1인 1예약만 가능합니다.',
          errorCode: 'USER_ACTIVE_RESERVATION',
          traceId: 'trace-7',
        ),
      );

      expect(result.statusCode, 400);
      expect(result.errorCode, 'USER_ACTIVE_RESERVATION');
      expect(result.traceId, 'trace-7');
      expect(result.serverMessage, '이미 활성 예약이 존재합니다. 1인 1예약만 가능합니다.');
    });

    test('예약 원인이 아닌 오류는 공통 문구를 그대로 쓴다', () {
      const cases = {
        401: 'ACCESS_TOKEN_EXPIRED',
        403: 'FORBIDDEN',
        404: 'MACHINE_NOT_FOUND',
        451: null,
        502: null,
        503: 'RESERVATION_RESTRICTION_UNAVAILABLE',
      };

      cases.forEach((code, errorCode) {
        final error = _serverError(
          code,
          message: '서버 문구 $code',
          errorCode: errorCode,
        );
        final result = reservationErrorToAppException(
          error,
          action: ReservationAction.reserve,
        );

        expect(result, isNot(isA<ReservationException>()), reason: '$code');
        expect(
          result.message,
          AppException.from(error).message,
          reason: '$code',
        );
      });
    });
  });
}
