import 'package:flutter/material.dart';
import 'package:project_setting/core/enums/laundry_machine_type.dart';
import 'package:project_setting/core/enums/laundry_status.dart';
import 'package:project_setting/core/theme/color.dart';
import 'package:project_setting/core/theme/typography.dart';
import 'package:project_setting/presentation/common/buttons/custom_small_button.dart';
import 'package:project_setting/presentation/common/reservation_state_widget.dart';

class MyReservationWidget extends StatelessWidget {
  final LaundryMachineType laundryMachineType;
  final LaundryStatus laundryStatus;
  final String machine;
  final String firstText;
  final String secondText;

  const MyReservationWidget({
    super.key,
    required this.laundryMachineType,
    required this.laundryStatus,
    required this.machine,
    required this.firstText,
    required this.secondText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildWidgetHeader(),
          SizedBox(height: 12),
          _buildTexts(),
          _buildWidgetBottom(),
        ],
      ),
    );
  }

  Widget _buildWidgetHeader() {
    return Row(
      children: [
        laundryMachineType.icon(),
        SizedBox(width: 8),
        Text(machine, style: WasherTypography.subTitle3()),
        Spacer(),
        ReservationStateWidget(
          label: laundryStatus.label,
          color: laundryStatus.color,
        ),
      ],
    );
  }

  Widget _buildTexts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          firstText,
          style: WasherTypography.body2(WasherColor.baseGray500),
        ),
        SizedBox(height: 4),
        Text(
          secondText,
          style: WasherTypography.body2(WasherColor.errorColor),
        ),
      ],
    );
  }

  Widget _buildWidgetBottom() {
    return Column(
      children: [
        laundryStatus.needsSpacing
            ? Column(
                children: [
                  const SizedBox(height: 12),
                  _buildButtons(),
                ],
              )
            : const SizedBox(),
      ],
    );
  }

  Widget _buildButtons() {
    return Row(
      children: [
        Expanded(
          child: CustomSmallButton(
            text: '예약 취소',
            onPressed: () {},
            color: WasherColor.baseGray200,
          ),
        ),
        SizedBox(width: 4),
        Expanded(
          child: CustomSmallButton(
            text: '${laundryMachineType.text} 시작',
            onPressed: () {},
            color: WasherColor.mainColor500,
          ),
        ),
      ],
    );
  }
}
