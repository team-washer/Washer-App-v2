import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/network/error.dart';
import 'package:washer/features/auth/data/repositories/auth_repository.dart';
import 'package:washer/features/user/data/data_sources/remote/user_remote_data_source.dart';
import 'package:washer/features/user/presentation/providers/my_user_provider.dart';

/// 회원 탈퇴 요청과 그 진행 상태를 관리하는 Notifier.
class WithdrawNotifier extends AsyncNotifier<void> {
  late final UserRemoteDataSource _userDataSource;
  late final AuthRepository _authRepository;

  @override
  Future<void> build() async {
    _userDataSource = ref.watch(userRemoteDataSourceProvider);
    _authRepository = ref.watch(authRepositoryProvider);
  }

  /// 탈퇴 API 호출 후 로그아웃하고 내 정보를 비운다. 성공 여부를 반환한다.
  Future<bool> withdraw() async {
    state = const AsyncLoading();

    final result = await guardApiCall(() async {
      await _userDataSource.withdraw();
      await _authRepository.logout();
    }, logName: 'WithdrawNotifier');

    switch (result) {
      case ResultSuccess():
        ref.read(myUserProvider.notifier).clear();
        state = const AsyncData(null);
        return true;
      case ResultFailure(:final error):
        state = AsyncError(error, StackTrace.current);
        return false;
    }
  }
}

final withdrawProvider = AsyncNotifierProvider<WithdrawNotifier, void>(
  WithdrawNotifier.new,
);
