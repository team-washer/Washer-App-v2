import 'package:flutter/material.dart';
import 'package:project_setting/core/enums/laundry_action_type.dart';
import 'package:project_setting/core/theme/color.dart';
import 'package:project_setting/core/theme/typography.dart';
import 'package:project_setting/presentation/common/buttons/custom_big_button.dart';
import 'package:project_setting/presentation/common/circle_widget.dart';

class LaundryActionDialog extends StatelessWidget {
  final LaundryActionType actionType;
  final String deviceId;

  const LaundryActionDialog({
    super.key,
    required this.actionType,
    required this.deviceId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTopText(),
          const SizedBox(height: 16),
          if (actionType == LaundryActionType.reportBroken) ...[
            _buildReportTextField(),
            const SizedBox(height: 16),
          ],
          _buildBottomButtons(
            context,
            actionType == LaundryActionType.reserve ? "예약하기" : "신고하기",
          ),
        ],
      ),
    );
  }

  Widget _buildTopText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "기기 ${actionType.text}",
          style: WasherTypography.subTitle3(),
        ),
        const SizedBox(height: 16),
        actionType == LaundryActionType.reserve
            ? Text(
                "$deviceId를 예약하시겠습니까?",
                style: WasherTypography.subTitle4(),
              )
            : RichText(
                text: TextSpan(
                  text: '기기명 ',
                  style: WasherTypography.subTitle4(),
                  children: [
                    TextSpan(
                      text: deviceId,
                      style: WasherTypography.body1(
                        WasherColor.baseGray500,
                      ),
                    ),
                  ],
                ),
              ),
      ],
    );
  }

  Widget _buildReportTextField() {
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
        const SizedBox(height: 4),
        TextField(
          maxLines: 5,
          decoration: InputDecoration(
            hintText: '고장 증상을 자세히 설명해주세요',
            hintStyle: WasherTypography.body4(
              WasherColor.baseGray300,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: WasherColor.baseGray300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: WasherColor.baseGray300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: WasherColor.baseGray700,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: WasherColor.errorColor,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: WasherColor.errorColor,
              ),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons(BuildContext context, String actionText) {
    return Row(
      children: [
        CustomBigButton(
          text: "뒤로가기",
          onPressed: () {
            Navigator.of(context).pop(); // TODO: GoRouter로 변경
          },
          color: WasherColor.baseGray200,
        ),
        const SizedBox(width: 4),
        CustomBigButton(
          text: actionText,
          onPressed: () {
            // TODO: Action 수행
          },
          color: WasherColor.mainColor500,
        ),
      ],
    );
  }
}
