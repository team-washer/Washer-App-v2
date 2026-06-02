import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/utils/app_logger.dart';
import 'package:washer/features/auth/data/repositories/auth_repository.dart';
import 'package:washer/features/user/data/data_sources/remote/user_remote_data_source.dart';
import 'package:washer/features/user/presentation/providers/my_user_provider.dart';

class WithdrawNotifier extends AsyncNotifier<void> {
  late final UserRemoteDataSource _userDataSource;
  late final AuthRepository _authRepository;

  @override
  Future<void> build() async {
    _userDataSource = ref.watch(userRemoteDataSourceProvider);
    _authRepository = ref.watch(authRepositoryProvider);
  }

  Future<bool> withdraw() async {
    state = const AsyncLoading();
    try {
      await _userDataSource.withdraw();
      await _authRepository.logout();
      ref.read(myUserProvider.notifier).clear();
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      AppLogger.error(
        '회원 탈퇴 중 오류가 발생했습니다.',
        name: 'WithdrawNotifier',
        error: error,
        stackTrace: stackTrace,
      );
      state = AsyncError(error, stackTrace);
      return false;
    }
  }
}

final withdrawProvider = AsyncNotifierProvider<WithdrawNotifier, void>(
  WithdrawNotifier.new,
);
