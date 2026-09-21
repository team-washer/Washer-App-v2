import 'package:flutter/material.dart';
import 'package:washer/core/errors/app_exception.dart';

/// [BuildContext]에서 바로 에러 스낵바를 띄우는 확장.
extension ErrorSnackBarExtension on BuildContext {
  void showErrorSnackBar(Object? error) {
    ScaffoldMessenger.of(this).showErrorSnackBar(error);
  }
}

/// 에러를 [AppException]으로 변환해 사용자용 메시지를 스낵바로 보여주는 확장.
extension ErrorSnackBarMessengerExtension on ScaffoldMessengerState {
  void showErrorSnackBar(Object? error) {
    final appException = AppException.from(error);
    hideCurrentSnackBar();
    showSnackBar(
      SnackBar(
        content: Text(appException.message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
