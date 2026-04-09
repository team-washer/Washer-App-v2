import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/theme/color.dart';
import 'package:washer/core/theme/spacing.dart';
import 'package:washer/core/theme/typography.dart';
import 'package:washer/core/ui/circle_widget.dart';
import 'package:washer/core/ui/dialog/washer_dialog.dart';
import 'package:washer/features/report/presentation/states/report_action_state.dart';
import 'package:washer/features/report/presentation/viewmodels/report_view_model.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_status_provider.dart';

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

  Future<void> _handleConfirm() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final description = _textController.text.trim();

    if (description.isEmpty) {
      _focusNode.requestFocus();
      messenger.showSnackBar(
        const SnackBar(content: Text('고장 내용을 입력해주세요.')),
      );
      return;
    }

    try {
      navigator.pop();
      final reportState = await ref
          .read(reportViewModelProvider.notifier)
          .createMalfunctionReport(
            machineId: widget.machineId,
            description: description,
          );

      if (mounted && reportState.status == ReportActionStatus.success) {
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
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('오류: $e')));
    }
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
          _ReportTextField(
            controller: _textController,
            focusNode: _focusNode,
          ),
          AppGap.v16,
        ],
      ),
    );
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
          child: const CircleWidget(
            color: CircleColor.red,
          ),
        ),
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
