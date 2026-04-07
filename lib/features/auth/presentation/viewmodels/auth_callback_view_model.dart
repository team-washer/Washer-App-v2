import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:washer/features/auth/domain/repositories/auth_repository.dart';

class AuthCallbackViewModel extends AsyncNotifier<void> {
  late final AuthRepository _authRepository;

  @override
  FutureOr<void> build() {
    _authRepository = ref.watch(authRepositoryProvider);
  }

  Future<bool> handleAuthCode({
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
