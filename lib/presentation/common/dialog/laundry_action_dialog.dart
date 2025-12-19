import 'package:flutter/material.dart';
import 'package:project_setting/core/enums/laundry_action_type.dart';
import 'package:project_setting/core/theme/color.dart';
import 'package:project_setting/core/theme/spacing.dart';
import 'package:project_setting/core/theme/typography.dart';
import 'package:project_setting/presentation/common/circle_widget.dart';
import 'package:project_setting/presentation/common/dialog/washer_dialog.dart';

class LaundryActionDialog extends StatefulWidget {
  final LaundryActionType actionType;
  final String deviceId;
  final TextEditingController? textController;
  final FocusNode? focusNode;

  const LaundryActionDialog({
    super.key,
    required this.actionType,
    required this.deviceId,
    this.textController,
    this.focusNode,
  });

  @override
  State<LaundryActionDialog> createState() => _LaundryActionDialogState();
}

class _LaundryActionDialogState extends State<LaundryActionDialog> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;
  late final bool _shouldDisposeController;
  late final bool _shouldDisposeFocusNode;

  @override
  void initState() {
    super.initState();
    _shouldDisposeController = widget.textController == null;
    _shouldDisposeFocusNode = widget.focusNode == null;
    _textController = widget.textController ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void dispose() {
    if (_shouldDisposeController) {
      _textController.dispose();
    }
    if (_shouldDisposeFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String actionText;
    Color? confirmColor;

    switch (widget.actionType) {
      case LaundryActionType.reserve:
        actionText = "예약하기";
        break;
      case LaundryActionType.cancelReservation:
        actionText = "취소하기";
        confirmColor = WasherColor.errorColor;
        break;
      case LaundryActionType.reportBroken:
        actionText = "신고하기";
        break;
    }

    return WasherDialog(
      title: "기기 ${widget.actionType.text}",
      confirmText: actionText,
      confirmColor: confirmColor,
      onConfirmPressed: () {
        // TODO: Action 수행
      },
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: AppSpacing.v16),
          _buildContentText(),
          SizedBox(height: AppSpacing.v16),
          if (widget.actionType == LaundryActionType.reportBroken) ...[
            _buildReportTextField(),
            SizedBox(height: AppSpacing.v16),
          ],
        ],
      ),
    );
  }

  Widget _buildContentText() {
    if (widget.actionType == LaundryActionType.reserve) {
      return Text(
        "${widget.deviceId}를 예약하시겠습니까?",
        style: WasherTypography.subTitle4(),
      );
    } else if (widget.actionType == LaundryActionType.cancelReservation) {
      return Text(
        "${widget.deviceId}의 예약을 취소하시겠습니까?",
        style: WasherTypography.subTitle4(),
      );
    } else {
      return RichText(
        text: TextSpan(
          text: '기기명 ',
          style: WasherTypography.subTitle4(),
          children: [
            TextSpan(
              text: widget.deviceId,
              style: WasherTypography.body1(
                WasherColor.baseGray500,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildReportTextField() {
    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: WasherColor.baseGray300,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "고장 내용",
              style: WasherTypography.subTitle4(),
            ),
            CircleWidget(
              color:
                  CircleColor.red, // Use the appropriate CircleColor enum value
            ),
          ],
        ),
        SizedBox(height: AppSpacing.v4),
        TextField(
          controller: _textController,
          focusNode: _focusNode,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: '고장 증상을 자세히 설명해주세요',
            hintStyle: WasherTypography.body4(
              WasherColor.baseGray300,
            ),
            border: baseBorder,
            enabledBorder: baseBorder,
            focusedBorder: baseBorder.copyWith(
              borderSide: BorderSide(
                color: WasherColor.baseGray700,
              ),
            ),
            errorBorder: baseBorder.copyWith(
              borderSide: BorderSide(
                color: WasherColor.errorColor,
              ),
            ),
            focusedErrorBorder: baseBorder.copyWith(
              borderSide: BorderSide(
                color: WasherColor.errorColor,
              ),
            ),
            contentPadding: AppPadding.content,
          ),
        ),
      ],
    );
  }
}
