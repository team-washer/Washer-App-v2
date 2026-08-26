import 'package:dio/dio.dart';

class AppException {
  AppException({
    required this.message,
    this.statusCode,
    this.debugMessage,
  });

  final String message;
  final int? statusCode;
  final String? debugMessage;

  factory AppException.from(Object? error) {
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
        statusCode == null) {
      return AppException(
        message: '네트워크 연결을 확인해주세요.',
        statusCode: statusCode,
        debugMessage: exception.message,
      );
    }

    final serverMessage = _serverMessageFrom(exception.response?.data);
    if (serverMessage != null) {
      return AppException(
        message: serverMessage,
        statusCode: statusCode,
        debugMessage: exception.message,
      );
    }

    if (statusCode == 400) {
      return AppException(
        message: '요청 정보가 올바르지 않습니다.',
        statusCode: statusCode,
        debugMessage: exception.message,
      );
    }

    if (statusCode == 401) {
      return AppException(
        message: '로그인이 만료되었습니다. 다시 로그인해주세요.',
        statusCode: statusCode,
        debugMessage: exception.message,
      );
    }

    if (statusCode == 404) {
      return AppException(
        message: '요청한 정보를 찾을 수 없습니다.',
        statusCode: statusCode,
        debugMessage: exception.message,
      );
    }

    if (statusCode >= 500) {
      return AppException(
        message: '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
        statusCode: statusCode,
        debugMessage: exception.message,
      );
    }

    return AppException(
      message: '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
      statusCode: statusCode,
      debugMessage: exception.message,
    );
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
}
