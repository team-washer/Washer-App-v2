import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/utils/app_logger.dart';
import 'package:washer/features/auth/data/repositories/auth_repository.dart';

class LoginNotifier extends AsyncNotifier<void> {
  late final AuthRepository _authRepository;

  @override
  Future<void> build() async {
    _authRepository = ref.watch(authRepositoryProvider);
  }

  Future<void> loginWithCode({
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
    } catch (error, stackTrace) {
      AppLogger.error(
        '로그인 중 오류가 발생했습니다.',
        name: 'LoginNotifier',
        error: error,
        stackTrace: stackTrace,
      );
      state = AsyncError(error, stackTrace);
    }
  }
}

final loginProvider = AsyncNotifierProvider<LoginNotifier, void>(
  LoginNotifier.new,
);
