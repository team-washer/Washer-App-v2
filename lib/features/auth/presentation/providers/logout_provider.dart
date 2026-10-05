import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/network/auth_notifier.dart';
import 'package:washer/core/network/error.dart';
import 'package:washer/features/auth/data/repositories/auth_repository.dart';

/// 로그아웃 처리(서버 FCM 토큰/로컬 토큰 정리 후 세션 종료) Notifier
class LogoutNotifier extends AsyncNotifier<void> {
  late final AuthRepository _authRepository;

  @override
  Future<void> build() async {
    _authRepository = ref.watch(authRepositoryProvider);
  }

  Future<void> logout() async {
    state = const AsyncLoading();

    final result = await guardApiCall(
      _authRepository.logout,
      logName: 'LogoutNotifier',
    );

    switch (result) {
      case ResultSuccess():
        authNotifier.logout();
        state = const AsyncData(null);
      case ResultFailure(:final error):
        state = AsyncError(error, StackTrace.current);
    }
  }
}

final logoutProvider = AsyncNotifierProvider<LogoutNotifier, void>(
  LogoutNotifier.new,
);
