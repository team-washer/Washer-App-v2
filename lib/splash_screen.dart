import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:washer/core/network/dio_client.dart';
import 'package:washer/core/network/token_utils.dart';
import 'package:washer/core/router/route_paths.dart';
import 'package:washer/core/services/version_check_service.dart';
import 'package:washer/shared/theme/icon.dart';
import 'package:washer/shared/ui/base_scaffold.dart';
import 'package:washer/shared/ui/dialog/force_update_dialog.dart';
import 'package:washer/core/utils/app_logger.dart';
import 'package:washer/features/user/data/data_sources/remote/user_remote_data_source.dart';
import 'package:washer/features/user/presentation/providers/my_user_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
    });
  }

  Future<void> _bootstrap() async {
    final storage = ref.read(secureStorageProvider);

    // 버전 체크(스토어 조회)를 먼저 시작해 사용자 조회와 병렬로 진행한다.
    final versionStatusFuture = ref
        .read(versionCheckServiceProvider)
        .fetchUpdatableStatus();

    final accessToken = await storage.read(key: 'access_token');
    final refreshToken = await storage.read(key: 'refresh_token');
    final hasAccessToken = accessToken != null && accessToken.isNotEmpty;
    final hasRefreshToken =
        refreshToken != null &&
        refreshToken.isNotEmpty &&
        !TokenUtils.isExpired(refreshToken);

    final needsLogin =
        (!hasAccessToken && !hasRefreshToken) ||
        (hasAccessToken &&
            TokenUtils.isExpired(accessToken) &&
            !hasRefreshToken);

    // 로그인 상태면 사용자 조회도 버전 체크와 병렬로 시작한다.
    final myUserFuture = needsLogin
        ? null
        : ref.read(userRemoteDataSourceProvider).getMyUser();

    // 버전 체크를 기다리는 동안 사용자 조회에서 에러가 나도 미처리 async 에러로
    // 보고되지 않도록 즉시 ignore()를 등록한다. 이후 await 시에는 에러가 그대로
    // 던져져 try/catch에서 처리된다.
    myUserFuture?.ignore();

    // 강제 업데이트가 필요하면 팝업을 띄우고 이후 진입을 중단한다.
    final versionStatus = await versionStatusFuture;
    if (versionStatus != null) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => ForceUpdateDialog(
          onUpdatePressed: () => ref
              .read(versionCheckServiceProvider)
              .openStore(versionStatus.appStoreLink),
        ),
      );
      return;
    }

    if (myUserFuture == null) {
      await _goToLogin(storage);
      return;
    }

    try {
      final myUser = await myUserFuture;
      ref.read(myUserProvider.notifier).setUser(myUser);
      if (!mounted) return;
      context.go(RoutePaths.home);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        AppLogger.error(
          '스플래시 사용자 정보 조회 중 인증 오류가 발생했습니다.',
          name: 'SplashScreen',
          error: e,
          stackTrace: e.stackTrace,
        );
        await _goToLogin(storage);
        return;
      }

      AppLogger.error(
        '스플래시 사용자 정보 조회 중 네트워크 오류가 발생했습니다.',
        name: 'SplashScreen',
        error: e,
        stackTrace: e.stackTrace,
      );
      ref.read(myUserProvider.notifier).clear();
      if (!mounted) return;
      context.go(RoutePaths.home);
    } catch (error, stackTrace) {
      AppLogger.error(
        '스플래시 초기화 중 오류가 발생했습니다.',
        name: 'SplashScreen',
        error: error,
        stackTrace: stackTrace,
      );
      ref.read(myUserProvider.notifier).clear();
      if (!mounted) return;
      context.go(RoutePaths.home);
    }
  }

  Future<void> _goToLogin(FlutterSecureStorage storage) async {
    await storage.delete(key: 'access_token');
    await storage.delete(key: 'refresh_token');
    ref.read(myUserProvider.notifier).clear();
    if (!mounted) return;
    context.go(RoutePaths.login);
  }

  @override
  Widget build(BuildContext context) {
    return const BaseScaffold(
      body: Center(
        child: WasherIcon(
          type: WasherIconType.logo,
          size: 120,
        ),
      ),
    );
  }
}
