import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:washer/core/router/route_paths.dart';
import 'package:washer/shared/ui/error_toast.dart';
import 'package:washer/features/auth/presentation/providers/login_provider.dart';
import 'package:washer/shared/theme/washer_icon.dart';
import 'package:washer/shared/theme/app_spacing.dart';
import 'package:washer/shared/theme/washer_typography.dart';

/// DataGSM OAuth 로그인 버튼 — 성공 시 스플래시로 이동, 실패 시 스낵바 표시
class DgLoginButton extends ConsumerWidget {
  const DgLoginButton({super.key});

  Future<void> _onPressed(BuildContext context, WidgetRef ref) async {
    final isSuccess = await ref.read(loginProvider.notifier).login();
    if (!context.mounted) return;

    if (isSuccess) {
      context.go(RoutePaths.splash);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<void>>(loginProvider, (previous, next) {
      if (next is AsyncError) {
        context.showErrorToast(next.error);
      }
    });

    final isLoading = ref.watch(loginProvider).isLoading;

    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: isLoading ? null : () => _onPressed(context, ref),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.small),
        ),
        child: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  WasherIcon(type: WasherIconType.dgLogo, size: 12),
                  AppGap.h10,
                  Text(
                    'DataGSM으로 로그인',
                    style: WasherTypography.body1(Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
      ),
    );
  }
}
