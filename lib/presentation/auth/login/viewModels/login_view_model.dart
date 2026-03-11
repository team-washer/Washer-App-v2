import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/data/repositories/auth_repository.dart';

class LoginViewModel extends AsyncNotifier<void> {
  late final AuthRepository _authRepository;

  @override
  Future<void> build() async {
    _authRepository = ref.watch(authRepositoryProvider);
  }

  Future<void> loginWithCode(String authCode) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _authRepository.login(authCode));
  }
}

final loginViewModelProvider = AsyncNotifierProvider<LoginViewModel, void>(
  LoginViewModel.new,
);
