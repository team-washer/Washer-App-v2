import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/network/dio_client.dart';
import 'package:washer/features/alarm/data/repositories/alarm_repository.dart';
import 'package:washer/features/auth/data/data_sources/remote/auth_remote_data_source.dart';
import 'package:washer/features/auth/data/models/request/login_request.dart';

/// 로그인/로그아웃을 담당하는 인증 저장소.
///
/// 토큰 저장소와 인증 캐시는 [DioClient]의 세션 API로만 함께 바꾼다(#319).
class AuthRepository {
  final AuthRemoteDataSource _dataSource;
  final DioClient _dioClient;
  final AlarmRepository _alarmRepository;

  const AuthRepository(
    this._dataSource,
    this._dioClient,
    this._alarmRepository,
  );

  Future<void> login({
    required String authCode,
    required String redirectUri,
  }) async {
    final response = await _dataSource.login(
      LoginRequest(authCode: authCode, redirectUri: redirectUri),
    );

    await _dioClient.startSession(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );

    unawaited(_alarmRepository.registerCurrentFcmToken());
  }

  Future<void> logout() async {
    await _alarmRepository.deleteFcmToken();

    await _dioClient.clearAuthCache();
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(authRemoteDataSourceProvider),
    ref.watch(dioClientProvider),
    ref.watch(alarmRepositoryProvider),
  );
});
