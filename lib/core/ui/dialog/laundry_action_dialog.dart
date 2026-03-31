import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/enums/laundry_action_type.dart';
import 'package:washer/core/theme/color.dart';
import 'package:washer/core/theme/spacing.dart';
import 'package:washer/core/theme/typography.dart';
import 'package:washer/core/ui/circle_widget.dart';
import 'package:washer/core/ui/dialog/washer_dialog.dart';
import 'package:washer/features/report/presentation/states/report_action_state.dart';
import 'package:washer/features/report/presentation/viewmodels/report_view_model.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_status_provider.dart';
import 'package:washer/features/reservation/presentation/states/reservation_action_state.dart';
import 'package:washer/features/reservation/presentation/viewmodels/reservation_view_model.dart';

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
  late final TextEditingController textController;
  late final FocusNode focusNode;

  @override
  void initState() {
    super.initState();
    textController = TextEditingController();
    focusNode = FocusNode();
  }

  @override
  void dispose() {
    textController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final reservationNotifier = ref.read(reservationViewModelProvider.notifier);
    final reportNotifier = ref.read(reportViewModelProvider.notifier);

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
          final cancelState = await reservationNotifier.cancel(
            reservationId: widget.reservationId,
          );
          if (cancelState.status == ReservationActionStatus.success) {
            await refreshReservationStatusWidgets(ref);
          }
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                cancelState.status == ReservationActionStatus.success
                    ? '예약이 취소되었습니다.'
                    : (cancelState.errorMessage ?? '예약 취소에 실패했습니다.'),
              ),
            ),
          );
          break;
        case LaundryActionType.reportBroken:
          final description = textController.text.trim();
          if (description.isEmpty) {
            focusNode.requestFocus();
            messenger.showSnackBar(
              const SnackBar(content: Text('고장 내용을 입력해주세요.')),
            );
            return;
          }

          navigator.pop();
          final reportState = await reportNotifier.createMalfunctionReport(
            machineId: widget.machineId,
            description: description,
          );
          if (reportState.status == ReportActionStatus.success) {
            await refreshReservationStatusWidgets(ref);
          }
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                reportState.status == ReportActionStatus.success
                    ? '신고가 완료되었습니다.'
                    : (reportState.errorMessage ?? '고장 신고에 실패했습니다.'),
              ),
            ),
          );
          break;
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('오류: $e')),
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
          if (widget.actionType == LaundryActionType.reportBroken) ...[
            _ReportTextField(
              controller: textController,
              focusNode: focusNode,
            ),
            AppGap.v16,
          ],
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
        return const _ActionConfig(confirmText: '신고하기');
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
        return RichText(
          text: TextSpan(
            text: '기기명 ',
            style: WasherTypography.subTitle4(),
            children: [
              TextSpan(
                text: deviceId,
                style: WasherTypography.body1(WasherColor.baseGray400),
              ),
            ],
          ),
        );
    }
  }
}

class _ReportTextField extends StatelessWidget {
  const _ReportTextField({
    required this.controller,
    required this.focusNode,
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel(),
        AppGap.v4,
        _ReportInputField(
          controller: controller,
          focusNode: focusNode,
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            '고장 내용',
            style: WasherTypography.subTitle4(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const CircleWidget(color: CircleColor.red),
      ],
    );
  }
}

class _ReportInputField extends StatelessWidget {
  const _ReportInputField({
    required this.controller,
    required this.focusNode,
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    final baseBorder = OutlineInputBorder(
      borderRadius: AppRadius.small,
      borderSide: const BorderSide(color: WasherColor.baseGray300),
    );

    return TextField(
      controller: controller,
      focusNode: focusNode,
      maxLines: 5,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        hintText: '고장 증상이나 특이사항을 자세히 설명해주세요.',
        hintStyle: WasherTypography.body4(WasherColor.baseGray300),
        border: baseBorder,
        enabledBorder: baseBorder,
        focusedBorder: baseBorder.copyWith(
          borderSide: const BorderSide(color: WasherColor.baseGray700),
        ),
        errorBorder: baseBorder.copyWith(
          borderSide: const BorderSide(color: WasherColor.errorColor),
        ),
        focusedErrorBorder: baseBorder.copyWith(
          borderSide: const BorderSide(color: WasherColor.errorColor),
        ),
        contentPadding: AppPadding.content,
      ),
    );
  }
}
