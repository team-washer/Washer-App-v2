import 'package:flutter/material.dart';
import 'package:washer/core/errors/app_exception.dart';

extension ErrorSnackBarExtension on BuildContext {
  void showErrorSnackBar(Object? error) {
    final appException = AppException.from(error);
    final messenger = ScaffoldMessenger.of(this);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(appException.message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
