import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:washer/features/auth/domain/repositories/auth_repository.dart';
import 'package:washer/features/user/data/repositories/user_repository_impl.dart';
import 'package:washer/features/user/domain/repositories/user_repository.dart';
import 'package:washer/features/user/presentation/viewmodels/my_user_view_model.dart';

class WithdrawViewModel extends AsyncNotifier<void> {
  late final UserRepository _userRepository;
  late final AuthRepository _authRepository;

  @override
  Future<void> build() async {
    _userRepository = ref.watch(userRepositoryProvider);
    _authRepository = ref.watch(authRepositoryProvider);
  }

  Future<bool> withdraw() async {
    state = const AsyncLoading();
    final nextState = await AsyncValue.guard(() async {
      await _userRepository.withdraw();
      await _authRepository.logout();
      ref.read(myUserProvider.notifier).clear();
    });
    state = nextState;
    return !nextState.hasError;
  }
}

final withdrawViewModelProvider =
    AsyncNotifierProvider<WithdrawViewModel, void>(
      WithdrawViewModel.new,
    );
