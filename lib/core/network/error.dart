import 'package:dio/dio.dart';
import 'package:washer/core/utils/app_logger.dart';

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
///
/// 화면에는 서버가 내려준 `message` 대신 [_statusMessages]의 고정 문구를 보여준다.
/// 서버 문구는 상태 코드마다 일관되지 않거나 기술적일 수 있어, 토스트 디자인에서
/// 정의한 문구로 통일한다. 원인 추적은 [errorCode]/[traceId]로 한다.
///
/// 404는 사용자/예약/기기 없음을 구분하지 않는다. 세 경우 모두 서버가
/// `data.errorCode: "NOT_FOUND"`로 동일하게 내려주므로 앱에서 구분할 수 없다.
/// 백엔드가 사례별 errorCode를 내려주게 되면 그때 분기한다.
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

  /// 상태 코드별 사용자용 고정 문구. 서버 `message`보다 항상 우선한다.
  static const Map<int, String> _statusMessages = {
    400: '입력한 정보를 다시 확인해주세요.',
    401: '로그인이 필요해요. 다시 로그인해주세요.',
    403: '이 기능을 이용할 수 없어요.',
    404: '예약 정보를 찾을 수 없어요.\n다시 확인해주세요.',
    409: '이미 사용이 시작된 예약은 취소할 수 없어요.',
    451: '현재 예약 서비스를 이용할 수 없는 사용자예요.',
    502: '기기와 연결할 수 없어요.\n잠시 후 다시 시도해주세요.',
    503: '서비스가 잠시 불안정해요.\n잠시 후 다시 시도해주세요.',
  };

  static const String _genericServerMessage = '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';

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
      message: '데이터를 불러오는 중 오류가 발생했습니다.',
      debugMessage: e.message,
    ),
    TypeError e => AppException(
      message: '데이터를 불러오는 중 오류가 발생했습니다.',
      debugMessage: e.toString(),
    ),
    _ => AppException(
      message: '알 수 없는 오류가 발생했습니다.',
      debugMessage: error?.toString(),
    ),
  };

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

    final fixedMessage = _statusMessages[statusCode];
    if (fixedMessage != null) {
      return build(fixedMessage);
    }

    final serverMessage = _serverMessageFrom(body);
    if (serverMessage != null) {
      return build(serverMessage);
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
