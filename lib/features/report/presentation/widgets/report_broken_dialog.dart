import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/shared/theme/washer_color.dart';
import 'package:washer/shared/theme/app_spacing.dart';
import 'package:washer/shared/theme/washer_typography.dart';
import 'package:washer/shared/ui/indicators/status_dot.dart';
import 'package:washer/shared/ui/dialog/dialog_action.dart';
import 'package:washer/shared/ui/dialog/laundry_dialog_actions.dart';
import 'package:washer/shared/ui/dialog/washer_dialog.dart';

/// 기기 고장 내용을 입력받아 신고하는 다이얼로그
class ReportBrokenDialog extends ConsumerStatefulWidget {
  const ReportBrokenDialog({
    super.key,
    required this.machineId,
    required this.deviceId,
  });

  final int machineId;
  final String deviceId;

  @override
  ConsumerState<ReportBrokenDialog> createState() => _ReportBrokenDialogState();
}

class _ReportBrokenDialogState extends ConsumerState<ReportBrokenDialog> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// 내용이 비어 있으면 안내 후 포커스를 주고, 아니면 고장 신고를 실행한다.
  Future<void> _handleConfirm() async {
    final description = _textController.text.trim();

    if (description.isEmpty) {
      _focusNode.requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('고장 내용을 입력해주세요.')),
      );
      return;
    }

    await runDialogAction(
      context,
      LaundryDialogActions.reportBroken(
        machineId: widget.machineId,
        description: description,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WasherDialog(
      title: '기기 고장 신고',
      confirmText: '신고하기',
      onConfirmPressed: _handleConfirm,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppGap.v16,
          RichText(
            text: TextSpan(
              text: '기기명 ',
              style: WasherTypography.subTitle4(),
              children: [
                TextSpan(
                  text: widget.deviceId,
                  style: WasherTypography.body1(WasherColor.baseGray700),
                ),
              ],
            ),
          ),
          AppGap.v16,
          const _FieldLabel(),
          AppGap.v4,
          _ReportInputField(
            controller: _textController,
            focusNode: _focusNode,
          ),
          AppGap.v16,
        ],
      ),
    );
  }
}

/// '고장 내용' 라벨과 필수 표시 점
class _FieldLabel extends StatelessWidget {
  const _FieldLabel();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Text(
            '고장 내용',
            style: WasherTypography.subTitle4(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -2),
          child: const StatusDot(
            color: StatusDotColor.red,
          ),
        ),
      ],
    );
  }
}

/// 고장 증상을 입력하는 여러 줄 텍스트 필드
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
