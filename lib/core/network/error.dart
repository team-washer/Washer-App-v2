import 'package:dio/dio.dart';
import 'package:washer/core/network/server_error_code.dart';
import 'package:washer/core/utils/app_logger.dart';
import 'package:washer/shared/theme/washer_error_message.dart';

/// 사용자에게 그대로 보여줄 메시지를 가진 예외.
abstract interface class UserFacingException implements Exception {
  String get userMessage;
}

/// 다양한 예외를 사용자용 메시지로 정규화한 앱 공통 예외.
///
/// 서버 오류 응답은 공통 wrapper(`message`, `data.errorCode`, `data.fieldErrors`,
/// `data.traceId`)를 사용한다. 원인은 `data.errorCode`([ServerErrorCode])로 구분하고,
/// 상태 코드는 원인별 코드가 없을 때(구버전 서버, 상태 이름 코드)의 보조 기준이다.
/// 400 요청 검증·예약 거부 · 401 인증 실패 · 403 권한 부족·이용 제한 ·
/// 404 사용자/예약/기기 없음 · 409 기기 점유·취소 충돌·동시 요청 충돌 ·
/// 451 이용 대상이 아닌 사용자 · 502 SmartThings 상태/명령 실패 · 503 일시 장애.
///
/// 화면 문구는 [_errorCodeMessages] → [_statusMessages] → 서버 `message`(4xx만)
/// 순으로 고른다. 서버 문구는 기술적이거나 톤이 달라 고정 문구를 우선하되,
/// 이용 제한처럼 서버 문구에만 제한 대상·해제 시각이 담긴 코드는
/// [_serverMessageCodes]로 서버 문구를 그대로 보여준다.
/// 원인 추적은 [errorCode]/[traceId]로 한다.
class AppException {
  AppException({
    required this.message,
    this.statusCode,
    this.debugMessage,
    this.errorCode,
    this.traceId,
    this.fieldErrors,
    this.serverMessage,
    this.isCancelled = false,
  });

  final String message;
  final int? statusCode;
  final String? debugMessage;

  /// 서버가 내려준 오류 코드(`data.errorCode`, [ServerErrorCode]). 없으면 null.
  final String? errorCode;

  /// 서버 로그와 대조할 수 있는 추적 ID(`data.traceId`). 없으면 null.
  final String? traceId;

  /// 요청 검증 오류의 필드별 상세(`data.fieldErrors`). 서버 형태 그대로 보관한다.
  final Object? fieldErrors;

  /// 서버가 내려준 원문 `message`. 분기에는 쓰지 않는다. 없으면 null.
  final String? serverMessage;

  /// 앱이 요청을 스스로 취소한 경우(예: 토큰 갱신 실패로 로그아웃되며 중단).
  /// 사용자가 조치할 오류가 아니므로 화면에 안내하지 않는다.
  final bool isCancelled;

  /// 서버 입력 검증 오류인지 여부.
  bool get isValidationError => ServerErrorCode.validation.contains(errorCode);

  /// [fieldErrors]를 사용자에게 보여줄 문구 목록으로 바꾼다.
  ///
  /// 서버 형태는 `[{field, message}]`다. 필드 이름은 [fieldLabel]로 사용자용 이름을
  /// 찾을 수 있을 때만 앞에 붙이고, 모르는 필드는 개발용 이름을 노출하지 않도록
  /// 문구만 보여준다.
  List<String> get fieldErrorMessages {
    final errors = fieldErrors;
    if (errors is! List) {
      return const [];
    }

    final messages = <String>[];
    for (final error in errors) {
      if (error is! Map) continue;
      final message = error['message'];
      if (message is! String || message.trim().isEmpty) continue;

      final field = error['field'];
      final label = field is String ? fieldLabel(field) : null;
      messages.add(
        label == null ? message.trim() : '$label: ${message.trim()}',
      );
    }
    return messages;
  }

  /// 서버 필드 이름의 사용자용 이름. 기능별 예외가 재정의한다.
  String? fieldLabel(String field) => null;

  /// 원인별 코드의 사용자용 문구. [_statusMessages]보다 우선한다.
  /// 문구 자체는 디자인 시스템([WasherErrorMessage])에서 관리한다.
  static const Map<String, String> _errorCodeMessages = {
    ServerErrorCode.validationFailed: WasherErrorMessage.validation,
    ServerErrorCode.invalidRequestBody: WasherErrorMessage.validation,
    ServerErrorCode.typeMismatch: WasherErrorMessage.validation,
    ServerErrorCode.missingParameter: WasherErrorMessage.validation,
    ServerErrorCode.withdrawnRejoinRestricted:
        WasherErrorMessage.withdrawnRejoinRestricted,
    ServerErrorCode.userFloorRestricted: WasherErrorMessage.userFloorRestricted,
    ServerErrorCode.userNotFound: WasherErrorMessage.userNotFound,
    ServerErrorCode.reservationNotFound: WasherErrorMessage.reservationNotFound,
    ServerErrorCode.machineNotFound: WasherErrorMessage.machineNotFound,
    ServerErrorCode.roomNotFound: WasherErrorMessage.roomNotFound,
    ServerErrorCode.roomWashingBanned: WasherErrorMessage.roomWashingBanned,
    ServerErrorCode.userPenaltyActive: WasherErrorMessage.userPenaltyActive,
    ServerErrorCode.reservationCooldownActive:
        WasherErrorMessage.reservationCooldownActive,
    ServerErrorCode.roomReservationRestricted:
        WasherErrorMessage.roomReservationRestricted,
    ServerErrorCode.reservationTimeRestricted:
        WasherErrorMessage.reservationTimeRestricted,
    ServerErrorCode.userActiveReservation:
        WasherErrorMessage.userActiveReservation,
    ServerErrorCode.roomMachineTypeReserved:
        WasherErrorMessage.roomMachineTypeReserved,
    ServerErrorCode.machineUnavailable: WasherErrorMessage.machineUnavailable,
    ServerErrorCode.machineAlreadyReserved: WasherErrorMessage.machineTaken,
    ServerErrorCode.machineInUse: WasherErrorMessage.machineTaken,
    ServerErrorCode.machineShutdownInProgress:
        WasherErrorMessage.machineShuttingDown,
    ServerErrorCode.reservationCancellationConflict:
        WasherErrorMessage.reservationAlreadyStarted,
    ServerErrorCode.reservationStateInvalid:
        WasherErrorMessage.reservationStateChanged,
    ServerErrorCode.reservationAccessDenied:
        WasherErrorMessage.reservationAccessDenied,
    ServerErrorCode.conflict: WasherErrorMessage.conflict,
  };

  /// 서버 문구에만 제한 대상·해제 시각(남은 분, 예약 가능 시각)이 담긴 코드.
  /// 서버 문구가 있으면 그대로 보여주고, 없으면 [_errorCodeMessages]를 쓴다.
  static const Set<String> _serverMessageCodes = {
    ServerErrorCode.userPenaltyActive,
    ServerErrorCode.reservationCooldownActive,
    ServerErrorCode.roomReservationRestricted,
    ServerErrorCode.reservationTimeRestricted,
  };

  /// 원인별 코드가 없을 때의 상태 코드별 문구.
  static const Map<int, String> _statusMessages = {
    400: WasherErrorMessage.validation,
    401: WasherErrorMessage.loginRequired,
    403: WasherErrorMessage.forbidden,
    404: WasherErrorMessage.reservationNotFound,
    409: WasherErrorMessage.conflict,
    451: WasherErrorMessage.userNotEligible,
    502: WasherErrorMessage.deviceConnection,
    503: WasherErrorMessage.serviceUnavailable,
  };

  /// 임의의 에러를 종류별로 분류해 [AppException]으로 변환한다.
  ///
  /// 이미 [AppException]으로 정규화된 값(예: [guardApiCall] 결과)이 들어오면
  /// 그대로 반환한다(멱등). 그래야 정규화된 에러를 다시 넘겨도 메시지가 유지된다.
  factory AppException.from(Object? error) => switch (error) {
    AppException e => e,
    UserFacingException e => AppException(
      message: e.userMessage,
      debugMessage: e.toString(),
    ),
    DioException e => AppException._fromDioException(e),
    FormatException e => AppException(
      message: WasherErrorMessage.dataParsing,
      debugMessage: e.message,
    ),
    TypeError e => AppException(
      message: WasherErrorMessage.dataParsing,
      debugMessage: e.toString(),
    ),
    _ => AppException(
      message: WasherErrorMessage.unknown,
      debugMessage: error?.toString(),
    ),
  };

  factory AppException._fromDioException(DioException exception) {
    final statusCode = exception.response?.statusCode;
    final type = exception.type;

    // 로그아웃 흐름이 화면 전환을 처리하므로 "네트워크 오류"로 오안내하지 않는다.
    if (type == DioExceptionType.cancel) {
      return AppException(
        message: WasherErrorMessage.cancelled,
        debugMessage: exception.error?.toString() ?? exception.message,
        isCancelled: true,
      );
    }

    if (type == DioExceptionType.connectionError ||
        type == DioExceptionType.receiveTimeout ||
        type == DioExceptionType.sendTimeout ||
        type == DioExceptionType.connectionTimeout ||
        exception.response == null) {
      return AppException(
        message: WasherErrorMessage.network,
        statusCode: statusCode,
        debugMessage: exception.message,
      );
    }

    final body = exception.response?.data;
    final detail = _errorDetailFrom(body);
    final debugMessage = _debugMessage(exception.message, detail);
    // 5xx의 서버 메시지는 스택/예외명 같은 기술적 내용일 수 있어 노출하지 않는다.
    final isServerFault = statusCode != null && statusCode >= 500;
    final serverMessage = isServerFault ? null : _serverMessageFrom(body);

    AppException build(String message) => AppException(
      message: message,
      statusCode: statusCode,
      debugMessage: debugMessage,
      errorCode: detail.errorCode,
      traceId: detail.traceId,
      fieldErrors: detail.fieldErrors,
      serverMessage: serverMessage,
    );

    final errorCode = detail.errorCode;
    if (serverMessage != null && _serverMessageCodes.contains(errorCode)) {
      return build(serverMessage);
    }

    final codeMessage = _errorCodeMessages[errorCode];
    if (codeMessage != null) {
      return build(codeMessage);
    }

    final fixedMessage = _statusMessages[statusCode];
    if (fixedMessage != null) {
      return build(fixedMessage);
    }

    if (serverMessage != null) {
      return build(serverMessage);
    }

    return build(WasherErrorMessage.serverError);
  }

  static String? _serverMessageFrom(Object? data) {
    if (data is Map) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }

    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }

    return null;
  }

  /// 공통 오류 wrapper의 `data`에서 `errorCode`/`traceId`/`fieldErrors`를 꺼낸다.
  static ({String? errorCode, String? traceId, Object? fieldErrors})
  _errorDetailFrom(Object? body) {
    final data = body is Map ? body['data'] : null;
    if (data is! Map) {
      return (errorCode: null, traceId: null, fieldErrors: null);
    }

    String? text(Object? value) =>
        value is String && value.trim().isNotEmpty ? value.trim() : null;

    return (
      errorCode: text(data['errorCode']),
      traceId: text(data['traceId']),
      fieldErrors: data['fieldErrors'],
    );
  }

  static String? _debugMessage(
    String? base,
    ({String? errorCode, String? traceId, Object? fieldErrors}) detail,
  ) {
    final extras = [
      if (detail.errorCode != null) 'errorCode=${detail.errorCode}',
      if (detail.traceId != null) 'traceId=${detail.traceId}',
    ];
    if (extras.isEmpty) {
      return base;
    }
    return '${base ?? ''} [${extras.join(', ')}]'.trim();
  }
}

/// API 호출 결과를 성공/실패로 표현하는 공통 타입.
///
/// Flutter 공식 클린 아키텍처 샘플(flutter/samples)의 `Result` 패턴을 따른다.
/// viewmodel(Notifier)이 매번 try-catch로 에러를 잡는 대신 [guardApiCall]로
/// 호출을 감싸면, 실패는 항상 [AppException]으로 정규화되어 [ResultFailure]로 돌아온다.
sealed class Result<T> {
  const Result();
}

final class ResultSuccess<T> extends Result<T> {
  const ResultSuccess(this.value);

  final T value;
}

final class ResultFailure<T> extends Result<T> {
  const ResultFailure(this.error);

  final AppException error;
}

/// [action]을 실행하고 성공/실패를 [Result]로 감싸 반환한다.
///
/// 실패하면 예외를 [AppException.from]으로 정규화하고 [logName] 태그로 로그를
/// 남긴다. 호출부(viewmodel)는 try-catch 없이 [Result]를 패턴 매칭으로 처리하면 된다.
Future<Result<T>> guardApiCall<T>(
  Future<T> Function() action, {
  required String logName,
}) async {
  try {
    return ResultSuccess(await action());
  } catch (error, stackTrace) {
    final appException = AppException.from(error);
    AppLogger.error(
      appException.debugMessage ?? appException.message,
      name: logName,
      error: error,
      stackTrace: stackTrace,
    );
    return ResultFailure(appException);
  }
}
