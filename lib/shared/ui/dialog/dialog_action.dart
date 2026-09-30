import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/network/error.dart';
import 'package:washer/shared/ui/error_toast.dart';
import 'package:washer/shared/ui/loading_overlay.dart';
import 'package:washer/core/utils/app_logger.dart';

/// 다이얼로그/위젯에서 실행하는 비동기 액션 한 건의 정의.
///
/// "무엇을 실행하고, 성공/실패를 어떻게 판단하며, 어떤 메시지를 띄울지"라는
/// 액션 고유 정보만 담는다. 액션 종류별 정의는 `LaundryDialogActions` 팩토리 한 곳에
/// 모아 두고, 호출부는 그것을 [runDialogAction]에 넘기기만 한다.
///
/// [run]은 위젯의 `ref`가 아니라 lifecycle과 무관한 [ProviderContainer]를
/// 받는다. 따라서 pop(=widget dispose) 이후 실행돼도 "bad state" 오류가 나지
/// 않으며, 호출부가 notifier를 미리 캡처할 필요도 없다.
class DialogAction<R> {
  const DialogAction({
    required this.run,
    required this.isSuccess,
    required this.successMessage,
    required this.fallbackMessage,
    required this.logName,
    this.failureError,
    this.showLoading = false,
  });

  final Future<R> Function(ProviderContainer container) run;
  final bool Function(R result) isSuccess;
  final String successMessage;

  /// 실패했는데 원인 정보([failureError])가 없을 때 에러 토스트에 보여줄 문구.
  final String fallbackMessage;
  final String logName;
  final Object? Function(ProviderContainer container)? failureError;

  /// 작업 동안 루트 오버레이에 로딩 인디케이터를 표시할지 여부.
  final bool showLoading;
}

/// [action]을 실행하고 결과를 에러 토스트로 띄우는 공통 실행기.
///
/// await **이전에** navigator/container/overlay를 모두 캡처하므로
/// pop·화면 이탈 이후에도 안전하다. 이 캡처 로직을 한곳에 모아 두는 것이 목적이며,
/// 각 호출부가 따로 캡처하면 한 곳을 빠뜨려 bad state 오류가 재발하기 쉽다.
///
/// - [popFirst] : 호출 즉시 현재 라우트를 pop할지(다이얼로그면 true).
/// - [onSuccess]: 성공 시 성공 토스트 직전에 실행(예: 화면 이동). 네비게이션처럼
///   context가 필요한 동작은 호출부에서 미리 캡처해 클로저로 넘긴다.
Future<void> runDialogAction<R>(
  BuildContext context,
  DialogAction<R> action, {
  bool popFirst = true,
  VoidCallback? onSuccess,
}) async {
  final navigator = Navigator.of(context);
  final container = ProviderScope.containerOf(context);
  final rootOverlay = Overlay.of(context, rootOverlay: true);

  if (popFirst) {
    navigator.pop();
  }

  try {
    final result = action.showLoading
        ? await runWithLoadingOverlay(rootOverlay, () => action.run(container))
        : await action.run(container);

    if (action.isSuccess(result)) {
      onSuccess?.call();
      // 비동기 작업 도중 앱이 종료되는 등 오버레이가 해제됐을 수 있다.
      if (rootOverlay.mounted) {
        rootOverlay.showErrorToast(
          AppException(message: action.successMessage),
        );
      }
    } else if (rootOverlay.mounted) {
      // 실패는 원인 정보가 없어도 에러 토스트로 통일한다.
      rootOverlay.showErrorToast(
        action.failureError?.call(container) ??
            AppException(message: action.fallbackMessage),
      );
    }
  } catch (error, stackTrace) {
    AppLogger.error(
      '${action.logName} 처리 중 오류가 발생했습니다.',
      name: action.logName,
      error: error,
      stackTrace: stackTrace,
    );
    if (rootOverlay.mounted) {
      rootOverlay.showErrorToast(error);
    }
  }
}
