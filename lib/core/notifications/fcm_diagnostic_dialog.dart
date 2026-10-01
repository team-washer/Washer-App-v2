import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/network/dio_client.dart';
import 'package:washer/core/notifications/fcm_diagnostic.dart';
import 'package:washer/core/notifications/fcm_session.dart';
import 'package:washer/core/utils/app_logger.dart';
import 'package:washer/features/alarm/data/repositories/alarm_repository.dart';

// TODO(#251): Remove this TestFlight-only diagnostic dialog and the logo
// long-press entry point after the iOS FCM registration issue is verified.
Future<void> showFcmDiagnosticDialog(
  BuildContext context,
  WidgetRef ref,
) {
  return showDialog<void>(
    context: context,
    builder: (_) => const FcmDiagnosticDialog(),
  );
}

class FcmDiagnosticDialog extends ConsumerStatefulWidget {
  const FcmDiagnosticDialog({super.key});

  @override
  ConsumerState<FcmDiagnosticDialog> createState() =>
      _FcmDiagnosticDialogState();
}

class _FcmDiagnosticDialogState extends ConsumerState<FcmDiagnosticDialog> {
  bool _isSyncing = false;

  Future<void> _runManualSync() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);

    final diagnostics = ref.read(fcmDiagnosticProvider.notifier);
    try {
      final storage = ref.read(secureStorageProvider);
      if (!await hasActiveNotificationSession(storage)) {
        diagnostics.recordSessionUnavailable(FcmSyncTrigger.manual);
        return;
      }

      final repository = ref.read(alarmRepositoryProvider);
      repository.enableFcmRegistrationForExistingSession();
      await repository.registerCurrentFcmToken(
        trigger: FcmSyncTrigger.manual,
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Manual FCM diagnostic sync failed.',
        name: 'FcmDiagnosticDialog',
        error: error,
        stackTrace: stackTrace,
      );
      final current = ref.read(fcmDiagnosticProvider);
      final cycleId = current.lastSyncTrigger == FcmSyncTrigger.manual
          ? current.cycleId
          : diagnostics.beginSync(
              FcmSyncTrigger.manual,
              registrationEnabled: current.registrationEnabled,
              registrationBlocked: current.registrationBlocked,
            );
      diagnostics.record(
        cycleId,
        const FcmDiagnosticEvent(
          FcmDiagnosticEventType.message,
          failureStage: 'manual_sync',
          message: '수동 FCM 동기화 실행 중 오류가 발생했습니다.',
        ),
      );
      diagnostics.reportTerminalFailure(
        cycleId,
        message: '수동 FCM 동기화 실행 중 오류가 발생했습니다.',
      );
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _copyDiagnostics(FcmDiagnosticState state) async {
    await Clipboard.setData(ClipboardData(text: state.toDiagnosticText()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('FCM 진단 정보를 복사했습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fcmDiagnosticProvider);
    final lastSyncTime = state.lastSyncTime
        ?.toLocal()
        .toString()
        .split('.')
        .first;

    return AlertDialog(
      title: const Text('FCM 진단 (#251)'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DiagnosticRow(
                label: '마지막 trigger',
                value: state.lastSyncTrigger?.name ?? 'none',
              ),
              _DiagnosticRow(
                label: '마지막 sync',
                value: lastSyncTime ?? 'none',
              ),
              _DiagnosticRow(
                label: '알림 권한',
                value: state.authorizationStatus,
              ),
              _DiagnosticRow(
                label: '등록 활성화',
                value: state.registrationEnabled.toString(),
              ),
              _DiagnosticRow(
                label: '등록 차단',
                value: state.registrationBlocked.toString(),
              ),
              _DiagnosticRow(
                label: 'APNs token',
                value: state.apnsTokenStatus,
              ),
              _DiagnosticRow(
                label: 'APNs retry',
                value: state.apnsRetryCount.toString(),
              ),
              const Divider(height: 20),
              _DiagnosticRow(
                label: '네이티브 진단',
                value: state.nativeApns.available.toString(),
              ),
              _DiagnosticRow(
                label: 'Firebase swizzling',
                value: state.nativeApns.firebaseAppDelegateProxyEnabled
                    .toString(),
              ),
              _DiagnosticRow(
                label: 'APNs 등록 호출',
                value: state.nativeApns.registerCallCount.toString(),
              ),
              _DiagnosticRow(
                label: '마지막 등록 호출',
                value: state.nativeApns.lastRegisterCallAt ?? 'none',
              ),
              _DiagnosticRow(
                label: '시스템 APNs 등록',
                value: state.nativeApns.isRegisteredForRemoteNotifications
                    .toString(),
              ),
              _DiagnosticRow(
                label: '네이티브 callback',
                value: state.nativeApns.callbackStatus,
              ),
              _DiagnosticRow(
                label: '성공 callback',
                value: state.nativeApns.didRegisterCallbackCount.toString(),
              ),
              _DiagnosticRow(
                label: '실패 callback',
                value: state.nativeApns.didFailCallbackCount.toString(),
              ),
              _DiagnosticRow(
                label: '무응답 timeout',
                value: state.nativeApns.callbackTimeoutCount.toString(),
              ),
              _DiagnosticRow(
                label: '성공 callback 시각',
                value: state.nativeApns.lastDidRegisterCallbackAt ?? 'none',
              ),
              _DiagnosticRow(
                label: '실패 callback 시각',
                value: state.nativeApns.lastDidFailCallbackAt ?? 'none',
              ),
              _DiagnosticRow(
                label: 'timeout 시각',
                value: state.nativeApns.lastCallbackTimeoutAt ?? 'none',
              ),
              _DiagnosticRow(
                label: 'APNs token 길이',
                value: state.nativeApns.deviceTokenLength?.toString() ?? 'none',
              ),
              _DiagnosticRow(
                label: 'APNs error domain',
                value: state.nativeApns.errorDomain ?? 'none',
              ),
              _DiagnosticRow(
                label: 'APNs error code',
                value: state.nativeApns.errorCode?.toString() ?? 'none',
              ),
              _DiagnosticRow(
                label: 'APNs error 설명',
                value: state.nativeApns.errorDescription ?? 'none',
              ),
              _DiagnosticRow(
                label: '앱 상태',
                value: state.nativeApns.applicationState,
              ),
              const Divider(height: 20),
              _DiagnosticRow(
                label: 'FCM token',
                value: state.fcmTokenStatus,
              ),
              _DiagnosticRow(
                label: '서버 POST',
                value: state.serverPostStatus,
              ),
              _DiagnosticRow(
                label: 'POST 성공 코드',
                value: state.postSuccessStatusCode?.toString() ?? 'none',
              ),
              _DiagnosticRow(
                label: '실패 statusCode',
                value: state.failureStatusCode?.toString() ?? 'none',
              ),
              _DiagnosticRow(
                label: 'errorCode',
                value: state.errorCode ?? 'none',
              ),
              _DiagnosticRow(
                label: 'Firebase code',
                value: state.firebaseExceptionCode ?? 'none',
              ),
              _DiagnosticRow(
                label: '실패 stage',
                value: state.failureStage ?? 'none',
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: SelectableText(state.message),
              ),
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton.icon(
          onPressed: () => _copyDiagnostics(state),
          icon: const Icon(Icons.copy, size: 18),
          label: const Text('진단 정보 복사'),
        ),
        FilledButton.icon(
          onPressed: _isSyncing ? null : _runManualSync,
          icon: _isSyncing
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.sync, size: 18),
          label: const Text('FCM 강제 재등록'),
        ),
      ],
    );
  }
}

class _DiagnosticRow extends StatelessWidget {
  const _DiagnosticRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}
