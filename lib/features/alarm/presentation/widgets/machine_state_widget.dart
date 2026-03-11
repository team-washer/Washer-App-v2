import 'package:flutter/material.dart';
import 'package:washer/core/enums/laundry_alarm_status.dart';
import 'package:washer/core/theme/color.dart';
import 'package:washer/core/theme/spacing.dart';
import 'package:washer/core/theme/typography.dart';

class MachineStateWidget extends StatelessWidget {
  final LaundryAlarmStatus laundryStatus;
  final String date;
  final String descriptionText;
  final String reason;

  const MachineStateWidget({
    super.key,
    required this.laundryStatus,
    required this.date,
    required this.descriptionText,
    required this.reason,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppPadding.card,
      decoration: BoxDecoration(
        borderRadius: AppRadius.medium,
        color: Colors.white,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _HeaderRow(laundryStatus: laundryStatus, date: date),
          AppGap.v8,
          _DescriptionText(
            laundryStatus: laundryStatus,
            descriptionText: descriptionText,
            reason: reason,
          ),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final LaundryAlarmStatus laundryStatus;
  final String date;

  const _HeaderRow({required this.laundryStatus, required this.date});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TitleWithStatus(laundryStatus: laundryStatus),
        AppGap.h4,
        _DateText(date: date),
      ],
    );
  }
}

class _TitleWithStatus extends StatelessWidget {
  final LaundryAlarmStatus laundryStatus;

  const _TitleWithStatus({required this.laundryStatus});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          laundryStatus.text,
          style: WasherTypography.subTitle3(
            WasherColor.baseGray700,
          ),
        ),
        if (laundryStatus == LaundryAlarmStatus.washComplete ||
            laundryStatus == LaundryAlarmStatus.dryComplete) ...[
          AppGap.h4,
          laundryStatus.circle,
        ],
      ],
    );
  }
}

class _DateText extends StatelessWidget {
  final String date;

  const _DateText({required this.date});

  @override
  Widget build(BuildContext context) {
    return Text(
      date,
      style: WasherTypography.body4(
        WasherColor.baseGray300,
      ),
    );
  }
}

class _DescriptionText extends StatelessWidget {
  final LaundryAlarmStatus laundryStatus;
  final String descriptionText;
  final String reason;

  const _DescriptionText({
    required this.descriptionText,
    required this.reason,
    required this.laundryStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          descriptionText,
          style: WasherTypography.body1(
            WasherColor.baseGray400,
          ),
        ),
        AppGap.v8,
        laundryStatus == LaundryAlarmStatus.usageWarning
            ? Text(
                '신고 사유: $reason',
                style: WasherTypography.body1(
                  WasherColor.baseGray400,
                ),
              )
            : SizedBox(),
      ],
    );
  }
}
