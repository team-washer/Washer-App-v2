part of '../home_machine_section_widget.dart';

// status_item

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;

  const _SectionHeader({
    required this.title,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: title),
        _ViewAllButton(onTap: onViewAll),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: WasherTypography.h2());
  }
}

class _ViewAllButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _ViewAllButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '전체보기',
            style: WasherTypography.body2(WasherColor.baseGray300),
          ),
          AppGap.h4,
          WasherIcon(
            type: WasherIconType.back,
            size: 16,
            color: WasherColor.baseGray300,
          ),
        ],
      ),
    );
  }
}
