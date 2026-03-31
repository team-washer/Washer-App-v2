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
import 'package:washer/features/user/data/repositories/user_repository_impl.dart';
import 'package:washer/features/user/presentation/viewmodels/my_user_view_model.dart';

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
      final myUser = await ref.read(userRepositoryProvider).getMyUser();
      ref.read(myUserProvider.notifier).setUser(myUser);
      if (!mounted) return;
      context.go(RoutePaths.home);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        await _goToLogin(storage);
        return;
      }

      ref.read(myUserProvider.notifier).clear();
      if (!mounted) return;
      context.go(RoutePaths.home);
    } catch (_) {
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
