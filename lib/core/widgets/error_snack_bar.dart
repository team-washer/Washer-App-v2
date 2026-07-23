import 'package:flutter/material.dart';
import 'package:washer/core/errors/app_exception.dart';

extension ErrorSnackBarExtension on BuildContext {
  void showErrorSnackBar(Object? error) {
    ScaffoldMessenger.of(this).showErrorSnackBar(error);
  }
}

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
