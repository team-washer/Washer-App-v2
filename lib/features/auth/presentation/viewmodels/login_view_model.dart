import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:washer/features/auth/domain/repositories/auth_repository.dart';

class LoginViewModel extends AsyncNotifier<void> {
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
    state = await AsyncValue.guard(
      () => _authRepository.login(
        authCode: authCode,
        redirectUri: redirectUri,
      ),
    );
  }
}

final loginViewModelProvider = AsyncNotifierProvider<LoginViewModel, void>(
  LoginViewModel.new,
);
