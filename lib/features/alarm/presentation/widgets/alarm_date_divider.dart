import 'package:flutter/material.dart';
import 'package:washer/shared/theme/washer_color.dart';
import 'package:washer/shared/theme/washer_typography.dart';

/// 날짜 텍스트를 가운데 두고 양옆에 선을 그려 알람 그룹을 구분하는 위젯
class AlarmDateDivider extends StatelessWidget {
  final String date;

  const AlarmDateDivider({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(color: WasherColor.baseGray500, thickness: 1),
        ),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              date,
              style: WasherTypography.body4(WasherColor.baseGray500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const Expanded(
          child: Divider(color: WasherColor.baseGray500, thickness: 1),
        ),
      ],
    );
  }
}
