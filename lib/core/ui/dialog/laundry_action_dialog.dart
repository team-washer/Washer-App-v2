import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/enums/laundry_action_type.dart';
import 'package:washer/core/theme/color.dart';
import 'package:washer/core/theme/spacing.dart';
import 'package:washer/core/theme/typography.dart';
import 'package:washer/core/ui/circle_widget.dart';
import 'package:washer/core/ui/dialog/washer_dialog.dart';
import 'package:washer/features/report/presentation/viewmodels/report_view_model.dart';
import 'package:washer/features/reservation/presentation/viewmodels/reservation_view_model.dart';

class LaundryActionDialog extends ConsumerStatefulWidget {
  final LaundryActionType actionType;
  final int machineId;
  final String deviceId;
  final int reservationId;

  const LaundryActionDialog({
    super.key,
    required this.actionType,
    required this.machineId,
    required this.deviceId,
    required this.reservationId,
  });

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
    try {
      switch (widget.actionType) {
        case LaundryActionType.reserve:
          await ref
              .read(reservationViewModelProvider.notifier)
              .confirmAndWatch(reservationId: widget.reservationId);
          if (!mounted) return;
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('기기가 켜졌는지 확인 중입니다')),
          );
          break;
        case LaundryActionType.cancelReservation:
          await ref
              .read(reservationViewModelProvider.notifier)
              .cancel(reservationId: widget.reservationId);
          if (!mounted) return;
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('예약이 취소되었습니다')),
          );
          break;
        case LaundryActionType.reportBroken:
          final description = textController.text.trim();
          if (description.isEmpty) {
            focusNode.requestFocus();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('고장 내용을 입력해 주세요')),
            );
            return;
          }

          await ref
              .read(reportViewModelProvider.notifier)
              .createMalfunctionReport(
                machineId: widget.machineId,
                description: description,
              );

          final reportState = ref.read(reportViewModelProvider);
          if (reportState.status == ReportActionStatus.error) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  reportState.errorMessage ?? '고장 신고에 실패했습니다',
                ),
              ),
            );
            return;
          }

          if (!mounted) return;
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('신고가 완료되었습니다')),
          );
          break;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
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
  final String confirmText;
  final Color? confirmColor;

  const _ActionConfig({
    required this.confirmText,
    this.confirmColor,
  });

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
        return const _ActionConfig(
          confirmText: '신고하기',
        );
    }
  }
}

class _ActionContentText extends StatelessWidget {
  final LaundryActionType actionType;
  final String deviceId;

  const _ActionContentText({
    required this.actionType,
    required this.deviceId,
  });

  @override
  Widget build(BuildContext context) {
    switch (actionType) {
      case LaundryActionType.reserve:
        return Text(
          '세탁을 시작하시겠습니까?',
          style: WasherTypography.subTitle4(),
        );
      case LaundryActionType.cancelReservation:
        return Text(
          '$deviceId의 예약을 취소하시겠습니까?',
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
  final TextEditingController controller;
  final FocusNode focusNode;

  const _ReportTextField({
    required this.controller,
    required this.focusNode,
  });

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
        Text('고장 내용', style: WasherTypography.subTitle4()),
        const CircleWidget(color: CircleColor.red),
      ],
    );
  }
}

class _ReportInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  const _ReportInputField({
    required this.controller,
    required this.focusNode,
  });

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
        hintText: '고장 증상을 자세히 설명해주세요',
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
