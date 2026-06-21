import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:washer/core/network/dio_client.dart';
import 'package:washer/core/network/token_utils.dart';
import 'package:washer/core/router/route_paths.dart';
import 'package:washer/core/theme/icon.dart';
import 'package:washer/core/ui/base_scaffold.dart';
import 'package:washer/core/ui/dialog/app_update_dialog.dart';
import 'package:washer/core/utils/app_logger.dart';
import 'package:washer/features/app_version/data/models/app_version_status_model.dart';
import 'package:washer/features/app_version/presentation/providers/app_version_check_provider.dart';
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
    if (await _handleForceUpdate()) {
      return;
    }

    final storage = ref.read(secureStorageProvider);
    final accessToken = await storage.read(key: 'access_token');
    final refreshToken = await storage.read(key: 'refresh_token');
    final hasAccessToken = accessToken != null && accessToken.isNotEmpty;
    final hasRefreshToken =
        refreshToken != null &&
        refreshToken.isNotEmpty &&
        !TokenUtils.isExpired(refreshToken);

    if (!hasAccessToken && !hasRefreshToken) {
      await _goToLogin(storage);
      return;
    }

    if (hasAccessToken &&
        TokenUtils.isExpired(accessToken) &&
        !hasRefreshToken) {
      await _goToLogin(storage);
      return;
    }

    try {
      final myUser = await ref.read(userRemoteDataSourceProvider).getMyUser();
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

  /// 서버 버전 정책에 따라 업데이트 안내 팝업을 띄운다.
  ///
  /// 업데이트가 필요하면(권장·강제 구분 없이) 진입을 막아야 하므로 `true`를
  /// 반환하여 이후 초기화(인증/홈 진입)를 중단시킨다. 최신 버전이거나
  /// 판단 불가(네트워크 오류 등)인 경우에는 `false`를 반환해 진입을 허용한다.
  Future<bool> _handleForceUpdate() async {
    final service = ref.read(appVersionCheckServiceProvider);
    final status = await service.fetchStatus();

    if (status == null ||
        status.updateStatus == AppUpdateStatus.supported ||
        status.updateStatus == AppUpdateStatus.unknown) {
      return false;
    }

    if (!status.isForceUpdate && !status.isOptionalUpdate) {
      return false;
    }

    if (!mounted) return true;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AppUpdateDialog(
        message: status.updateMessage,
        onUpdatePressed: () => service.openStore(status.storeUrl),
      ),
    );

    return true;
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
