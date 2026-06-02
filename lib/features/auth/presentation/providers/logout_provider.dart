import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/utils/app_logger.dart';
import 'package:washer/core/network/auth_notifier.dart';
import 'package:washer/features/auth/data/repositories/auth_repository.dart';

class LogoutNotifier extends AsyncNotifier<void> {
  late final AuthRepository _authRepository;

  @override
  Future<void> build() async {
    _authRepository = ref.watch(authRepositoryProvider);
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    try {
      await _authRepository.logout();
      authNotifier.logout();
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      AppLogger.error(
        '로그아웃 중 오류가 발생했습니다.',
        name: 'LogoutNotifier',
        error: error,
        stackTrace: stackTrace,
      );
      state = AsyncError(error, stackTrace);
    }
  }
}

final logoutProvider = AsyncNotifierProvider<LogoutNotifier, void>(
  LogoutNotifier.new,
);
