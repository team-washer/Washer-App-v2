import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/enums/laundry_action_type.dart';
import 'package:washer/shared/theme/washer_color.dart';
import 'package:washer/shared/theme/app_spacing.dart';
import 'package:washer/shared/theme/washer_typography.dart';
import 'package:washer/shared/ui/dialog/dialog_action.dart';
import 'package:washer/shared/ui/dialog/laundry_dialog_actions.dart';
import 'package:washer/shared/ui/dialog/washer_dialog.dart';

/// 기기 예약 시작/예약 취소 확인 다이얼로그. 종류는 [actionType]으로 결정한다.
class LaundryActionDialog extends ConsumerStatefulWidget {
  const LaundryActionDialog({
    super.key,
    required this.actionType,
    required this.machineId,
    required this.deviceId,
    required this.reservationId,
  });

  final LaundryActionType actionType;
  final int machineId;
  final String deviceId;
  final int reservationId;

  @override
  ConsumerState<LaundryActionDialog> createState() =>
      _LaundryActionDialogState();
}

class _LaundryActionDialogState extends ConsumerState<LaundryActionDialog> {
  Future<void> _handleConfirm() async {
    switch (widget.actionType) {
      case LaundryActionType.reserve:
        // pop 직후 context가 무효화될 수 있으므로 미리 캡처한다.
        final navigator = Navigator.of(context);
        final messenger = ScaffoldMessenger.of(context);
        navigator.pop();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('예약 후 자동으로 기기 연결 확인이 진행됩니다.'),
          ),
        );
        break;
      case LaundryActionType.cancelReservation:
        await runDialogAction(
          context,
          LaundryDialogActions.cancelReservation(
            reservationId: widget.reservationId,
          ),
        );
        break;
      case LaundryActionType.reportBroken:
        throw UnsupportedError('ReportBrokenDialog를 사용해주세요.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _ActionConfig.fromType(widget.actionType);

    return WasherDialog(
      title: '기기 ${widget.actionType.text}',
      confirmText: config.confirmText,
      confirmColor: config.confirmColor,
      onConfirmPressed: _handleConfirm,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppGap.v16,
          _ActionContentText(
            actionType: widget.actionType,
            deviceId: widget.deviceId,
          ),
          AppGap.v16,
        ],
      ),
    );
  }
}

/// 액션 종류별 확인 버튼의 문구/색.
class _ActionConfig {
  const _ActionConfig({
    required this.confirmText,
    this.confirmColor,
  });

  final String confirmText;
  final Color? confirmColor;

  factory _ActionConfig.fromType(LaundryActionType type) {
    switch (type) {
      case LaundryActionType.reserve:
        return const _ActionConfig(confirmText: '시작하기');
      case LaundryActionType.cancelReservation:
        return const _ActionConfig(
          confirmText: '취소하기',
          confirmColor: WasherColor.errorColor,
        );
      case LaundryActionType.reportBroken:
        return const _ActionConfig(confirmText: '');
    }
  }
}

class _ActionContentText extends StatelessWidget {
  const _ActionContentText({
    required this.actionType,
    required this.deviceId,
  });

  final LaundryActionType actionType;
  final String deviceId;

  @override
  Widget build(BuildContext context) {
    switch (actionType) {
      case LaundryActionType.reserve:
        return Text(
          '기기를 시작하시겠습니까?',
          style: WasherTypography.subTitle4(),
        );
      case LaundryActionType.cancelReservation:
        return Text(
          '$deviceId 예약을 취소하시겠습니까?',
          style: WasherTypography.subTitle4(),
        );
      case LaundryActionType.reportBroken:
        return const SizedBox.shrink();
    }
  }
}
