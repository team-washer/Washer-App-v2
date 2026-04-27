import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/enums/laundry_action_type.dart';
import 'package:washer/core/theme/color.dart';
import 'package:washer/core/theme/spacing.dart';
import 'package:washer/core/theme/typography.dart';
import 'package:washer/core/ui/dialog/washer_dialog.dart';
import 'package:washer/core/utils/app_logger.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_status_provider.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_action_provider.dart';

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
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final reservationNotifier = ref.read(reservationActionProvider.notifier);

    try {
      switch (widget.actionType) {
        case LaundryActionType.reserve:
          navigator.pop();
          messenger.showSnackBar(
            const SnackBar(
              content: Text('예약 후 자동으로 기기 연결 확인이 진행됩니다.'),
            ),
          );
          break;
        case LaundryActionType.cancelReservation:
          navigator.pop();
          final didCancel = await reservationNotifier.cancel(
            reservationId: widget.reservationId,
          );
          if (mounted && didCancel) {
            await refreshReservationStatusWidgets(ref);
          }
          final error = ref.read(reservationActionProvider).error;
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                didCancel
                    ? '예약이 취소되었습니다.'
                    : reservationActionErrorMessage(
                        error,
                        fallback: '예약 취소에 실패했습니다.',
                      ),
              ),
            ),
          );
          break;
        case LaundryActionType.reportBroken:
          throw UnsupportedError('ReportBrokenDialog를 사용해주세요.');
      }
    } catch (error, stackTrace) {
      AppLogger.error(
        '세탁 액션 처리 중 오류가 발생했습니다.',
        name: 'LaundryActionDialog',
        error: error,
        stackTrace: stackTrace,
      );
      messenger.showSnackBar(
        SnackBar(content: Text('오류: $error')),
      );
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
