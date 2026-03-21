part of '../alarm_list_widget.dart';

/// 날짜로 구분되는 나누기 위젯
class _DateDivider extends StatelessWidget {
  final String date;

  const _DateDivider({required this.date});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(color: WasherColor.baseGray300, thickness: 1),
        ),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              date,
              style: WasherTypography.body4(WasherColor.baseGray300),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const Expanded(
          child: Divider(color: WasherColor.baseGray300, thickness: 1),
        ),
      ],
    );
  }
}
