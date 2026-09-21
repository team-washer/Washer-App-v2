import 'package:dio/dio.dart';

/// 사용자에게 그대로 보여줄 메시지를 가진 예외.
abstract interface class UserFacingException implements Exception {
  String get userMessage;
}

/// 다양한 예외를 사용자용 메시지로 정규화한 앱 공통 예외.
///
/// 서버 오류 응답은 공통 wrapper(`message`, `data.errorCode`, `data.fieldErrors`,
/// `data.traceId`)를 사용한다. 상태 코드별 계약은 다음과 같다.
/// 400 요청 검증 오류 · 401 인증 실패 · 403 권한 부족 · 404 사용자/예약/기기 없음 ·
/// 409 이미 사용이 시작된 예약 취소 등 상태 충돌 · 451 이용 대상이 아닌 사용자 ·
/// 502 SmartThings 상태/명령 실패 · 503 Redis/외부 서비스 일시 장애.
class AppException {
  AppException({
    required this.message,
    this.statusCode,
    this.debugMessage,
    this.errorCode,
    this.traceId,
    this.fieldErrors,
  });

  final String message;
  final int? statusCode;
  final String? debugMessage;

  /// 서버가 내려준 오류 코드(`data.errorCode`). 없으면 null.
  final String? errorCode;

  /// 서버 로그와 대조할 수 있는 추적 ID(`data.traceId`). 없으면 null.
  final String? traceId;

  /// 요청 검증 오류의 필드별 상세(`data.fieldErrors`). 서버 형태 그대로 보관한다.
  final Object? fieldErrors;

  /// 인프라 장애(502/503)는 서버 메시지가 기술적인 내용일 수 있어, 서버 메시지 대신
  /// 항상 이 문구를 보여준다. 원인은 [errorCode]/[traceId]로 추적한다.
  static const Map<int, String> _infrastructureMessages = {
    502: '기기 서비스와 연결하지 못했습니다. 잠시 후 다시 시도해주세요.',
    503: '서버가 일시적으로 불안정합니다. 잠시 후 다시 시도해주세요.',
  };

  /// 서버가 메시지를 주지 않았을 때 쓰는 상태 코드별 기본 문구.
  static const Map<int, String> _statusFallbackMessages = {
    400: '요청 정보가 올바르지 않습니다.',
    401: '로그인이 만료되었습니다. 다시 로그인해주세요.',
    403: '이 작업을 수행할 권한이 없습니다.',
    404: '요청한 정보를 찾을 수 없습니다.',
    409: '현재 상태에서는 요청을 처리할 수 없습니다.',
    451: '서비스 이용 대상이 아닙니다.',
  };

  static const String _genericServerMessage = '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';

  /// 임의의 에러를 종류별로 분류해 [AppException]으로 변환한다.
  factory AppException.from(Object? error) {
    if (error is UserFacingException) {
      return AppException(
        message: error.userMessage,
        debugMessage: error.toString(),
      );
    }

    if (error is DioException) {
      return AppException._fromDioException(error);
    }

    if (error is FormatException) {
      return AppException(
        message: '데이터를 불러오는 중 오류가 발생했습니다.',
        debugMessage: error.message,
      );
    }

    if (error is TypeError) {
      return AppException(
        message: '데이터를 불러오는 중 오류가 발생했습니다.',
        debugMessage: error.toString(),
      );
    }

    return AppException(
      message: '알 수 없는 오류가 발생했습니다.',
      debugMessage: error?.toString(),
    );
  }

  factory AppException._fromDioException(DioException exception) {
    final statusCode = exception.response?.statusCode;
    final type = exception.type;

    if (type == DioExceptionType.connectionError ||
        type == DioExceptionType.receiveTimeout ||
        type == DioExceptionType.sendTimeout ||
        type == DioExceptionType.connectionTimeout ||
        exception.response == null) {
      return AppException(
        message: '네트워크 연결을 확인해주세요.',
        statusCode: statusCode,
        debugMessage: exception.message,
      );
    }

    final body = exception.response?.data;
    final detail = _errorDetailFrom(body);
    final debugMessage = _debugMessage(exception.message, detail);

    AppException build(String message) => AppException(
      message: message,
      statusCode: statusCode,
      debugMessage: debugMessage,
      errorCode: detail.errorCode,
      traceId: detail.traceId,
      fieldErrors: detail.fieldErrors,
    );

    final infrastructureMessage = _infrastructureMessages[statusCode];
    if (infrastructureMessage != null) {
      return build(infrastructureMessage);
    }

    final serverMessage = _serverMessageFrom(body);
    if (serverMessage != null) {
      return build(serverMessage);
    }

    final fallback = _statusFallbackMessages[statusCode];
    if (fallback != null) {
      return build(fallback);
    }

    return build(_genericServerMessage);
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
