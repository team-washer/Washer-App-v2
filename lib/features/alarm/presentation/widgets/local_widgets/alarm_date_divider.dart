part of '../alarm_list_widget.dart';

class _DateDivider extends StatelessWidget {
  final String date;

  const _DateDivider({required this.date});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(color: WasherColor.baseGray200, thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            date,
            style: WasherTypography.body4(WasherColor.baseGray200),
          ),
        ),
        const Expanded(
          child: Divider(color: WasherColor.baseGray200, thickness: 1),
        ),
      ],
    );
  }
}
