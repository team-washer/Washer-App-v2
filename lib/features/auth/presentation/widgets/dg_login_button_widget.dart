import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:washer/core/router/route_paths.dart';
import 'package:washer/features/auth/presentation/providers/auth_callback_provider.dart';
import 'package:washer/shared/theme/icon.dart';
import 'package:washer/shared/theme/spacing.dart';
import 'package:washer/shared/theme/typography.dart';

class DgLoginButtonWidget extends ConsumerWidget {
  const DgLoginButtonWidget({super.key});

  Future<void> _onPressed(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(authCallbackProvider.notifier).login();
    if (!context.mounted) return;

    if (result.isSuccess) {
      context.go(RoutePaths.splash);
      return;
    }

    final message = result.message;
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(authCallbackProvider).isLoading;

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
