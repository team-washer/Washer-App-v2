import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:washer/core/enums/laundry_action_type.dart';
import 'package:washer/core/theme/color.dart';
import 'package:washer/core/theme/spacing.dart';
import 'package:washer/core/theme/typography.dart';
import 'package:washer/core/ui/circle_widget.dart';
import 'package:washer/core/ui/dialog/washer_dialog.dart';

class LaundryActionDialog extends HookWidget {
  final LaundryActionType actionType;
  final String deviceId;

  const LaundryActionDialog({
    super.key,
    required this.actionType,
    required this.deviceId,
  });

  @override
  Widget build(BuildContext context) {
    final textController = useTextEditingController();
    final focusNode = useFocusNode();
    final config = _ActionConfig.fromType(actionType);

    return WasherDialog(
      title: "기기 ${actionType.text}",
      confirmText: config.confirmText,
      confirmColor: config.confirmColor,
      onConfirmPressed: () {
        // TODO: API 호출 with textController.text
      },
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppGap.v16,
          _ActionContentText(
            actionType: actionType,
            deviceId: deviceId,
          ),
          AppGap.v16,
          if (actionType == LaundryActionType.reportBroken) ...[
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
        return const _ActionConfig(confirmText: "예약하기");
      case LaundryActionType.cancelReservation:
        return const _ActionConfig(
          confirmText: "취소하기",
          confirmColor: WasherColor.errorColor,
        );
      case LaundryActionType.reportBroken:
        return const _ActionConfig(confirmText: "신고하기");
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
          "$deviceId를 예약하시겠습니까?",
          style: WasherTypography.subTitle4(),
        );
      case LaundryActionType.cancelReservation:
        return Text(
          "$deviceId의 예약을 취소하시겠습니까?",
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
        Text("고장 내용", style: WasherTypography.subTitle4()),
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
