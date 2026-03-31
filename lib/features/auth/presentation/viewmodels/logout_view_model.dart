import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/network/auth_notifier.dart';
import 'package:washer/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:washer/features/auth/domain/repositories/auth_repository.dart';

class LogoutViewModel extends AsyncNotifier<void> {
  late final AuthRepository _authRepository;

  @override
  Future<void> build() async {
    _authRepository = ref.watch(authRepositoryProvider);
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _authRepository.logout();
      authNotifier.logout();
    });
  }
}

final logoutViewModelProvider = AsyncNotifierProvider<LogoutViewModel, void>(
  LogoutViewModel.new,
);
