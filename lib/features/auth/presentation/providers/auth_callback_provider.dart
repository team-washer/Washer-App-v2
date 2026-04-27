import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/utils/app_logger.dart';
import 'package:washer/features/auth/data/repositories/auth_repository.dart';

class AuthCallbackNotifier extends AsyncNotifier<void> {
  late final AuthRepository _authRepository;

  @override
  FutureOr<void> build() {
    _authRepository = ref.watch(authRepositoryProvider);
  }

  Future<bool> handleAuthCode({
    required String authCode,
    required String redirectUri,
  }) async {
    state = const AsyncLoading();

    try {
      await _authRepository.login(
        authCode: authCode,
        redirectUri: redirectUri,
      );
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      AppLogger.error(
        '인증 콜백 처리 중 오류가 발생했습니다.',
        name: 'AuthCallbackNotifier',
        error: error,
        stackTrace: stackTrace,
      );
      state = AsyncError(error, stackTrace);
      return false;
    }
  }
}

final authCallbackProvider = AsyncNotifierProvider<AuthCallbackNotifier, void>(
  AuthCallbackNotifier.new,
);
