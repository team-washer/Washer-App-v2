import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/features/auth/data/repositories/auth_repository.dart';

class AuthCallbackViewModel extends AsyncNotifier<void> {
  late final AuthRepository _authRepository;

  @override
  FutureOr<void> build() {
    _authRepository = ref.watch(authRepositoryProvider);
  }

  Future<bool> handleAuthCode(String authCode) async {
    state = const AsyncLoading();

    try {
      await _authRepository.login(authCode);
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }
}

final authCallbackViewModelProvider =
    AsyncNotifierProvider<AuthCallbackViewModel, void>(
      AuthCallbackViewModel.new,
    );
