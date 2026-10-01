import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:washer/core/notifications/fcm_diagnostic.dart';

void main() {
  test('diagnostic snapshot contains stages but never token values', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final diagnostics = container.read(fcmDiagnosticProvider.notifier);
    final cycleId = diagnostics.beginSync(
      FcmSyncTrigger.manual,
      registrationEnabled: true,
      registrationBlocked: false,
    );

    diagnostics.record(
      cycleId,
      const FcmDiagnosticEvent(
        FcmDiagnosticEventType.permission,
        permission: 'authorized',
      ),
    );
    diagnostics.record(
      cycleId,
      const FcmDiagnosticEvent(
        FcmDiagnosticEventType.apnsSuccess,
        retryAttempt: 2,
      ),
    );
    diagnostics.record(
      cycleId,
      const FcmDiagnosticEvent(FcmDiagnosticEventType.fcmSuccess),
    );
    diagnostics.record(
      cycleId,
      const FcmDiagnosticEvent(
        FcmDiagnosticEventType.postSuccess,
        statusCode: 200,
      ),
    );

    final state = container.read(fcmDiagnosticProvider);
    final text = state.toDiagnosticText();

    expect(state.lastSyncTrigger, FcmSyncTrigger.manual);
    expect(state.apnsTokenStatus, 'success');
    expect(state.fcmTokenStatus, 'success');
    expect(state.serverPostStatus, 'success');
    expect(state.postSuccessStatusCode, 200);
    expect(text, isNot(contains('apns-secret-token')));
    expect(text, isNot(contains('fcm-secret-token')));
    expect(text, isNot(contains('access-secret-token')));
  });

  test('diagnostic snapshot records server failure details', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final diagnostics = container.read(fcmDiagnosticProvider.notifier);
    final cycleId = diagnostics.beginSync(
      FcmSyncTrigger.login,
      registrationEnabled: true,
      registrationBlocked: false,
    );

    diagnostics.record(
      cycleId,
      const FcmDiagnosticEvent(
        FcmDiagnosticEventType.postFailed,
        statusCode: 500,
        errorCode: 'FCM_REGISTER_FAILED',
        failureStage: 'server_post',
        message: '서버 등록 실패',
      ),
    );

    final state = container.read(fcmDiagnosticProvider);
    expect(state.failureStatusCode, 500);
    expect(state.errorCode, 'FCM_REGISTER_FAILED');
    expect(state.failureStage, 'server_post');
  });
}
