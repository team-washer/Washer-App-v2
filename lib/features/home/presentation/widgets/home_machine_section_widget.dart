import 'package:flutter/material.dart';
import 'package:washer/core/enums/laundry_machine_type.dart';
import 'package:washer/core/theme/color.dart';
import 'package:washer/core/theme/icon.dart';
import 'package:washer/core/theme/spacing.dart';
import 'package:washer/core/theme/typography.dart';
import 'package:washer/features/reservation/data/models/laundry_machine_model.dart';

/// 세탁기/건조기 기계 상태를 그리드로 표시하는 위젯
/// 
/// 기능:
/// - 기계 상태에 따른 색상 변경 (가용/예약/사용중)
/// - 2열 그리드 레이아웃으로 기계 표시
/// - 전체보기 링크 제공
class HomeMachineSectionWidget extends StatelessWidget {
  final List<MachineModel> machines;
  final LaundryMachineType machineType;

  const HomeMachineSectionWidget({
    super.key,
    required this.machines,
    required this.machineType,
  });

  static const double _itemRatio = 170 / 52;

  /// 기계 유형별 섹션 제목 반환
  String get _title =>
      machineType == LaundryMachineType.washer ? '세탁기 예약 현황' : '건조기 예약 현황';

  /// 기계 유형에 따라 필터링된 기계 목록 반환
  List<MachineModel> get _filtered =>
      machines.where((m) => m.type == machineType.apiValue).toList();

  @override
  Widget build(BuildContext context) {
    final items = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(title: _title),
            _ViewAll(onTap: () {}),
          ],
        ),
        AppGap.v16,
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.v16),
            child: Center(
              child: Text(
                '기기 정보가 없습니다.',
                style: WasherTypography.body1(WasherColor.baseGray300),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.v8,
              mainAxisSpacing: AppSpacing.h8,
              childAspectRatio: _itemRatio,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return _StatusItem(machine: items[index]);
            },
          ),
      ],
    );
  }
}
/// 섹션 제목 표시 위젯class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: WasherTypography.h2(),
    );
  }
}

/// 전체보기 링크 버튼
class _ViewAll extends StatelessWidget {
  final VoidCallback? onTap;

  const _ViewAll({this.onTap});

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

/// 기계 상태 아이템 (이름 및 아이콘)
class _StatusItem extends StatelessWidget {
  final MachineModel machine;

  const _StatusItem({required this.machine});

  @override
  Widget build(BuildContext context) {
    final machineType = machine.type == 'WASHER'
        ? LaundryMachineType.washer
        : LaundryMachineType.dryer;
    final isAvailable = machine.isAvailable;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 17.5,
        vertical: AppSpacing.v12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.circular,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            machineType.icon(
              color: isAvailable
                  ? WasherColor.mainColor400
                  : WasherColor.baseGray200,
            ),
            const SizedBox(width: AppSpacing.h12),
            Text(
              machine.name,
              style: WasherTypography.body3(
                isAvailable ? WasherColor.baseGray700 : WasherColor.baseGray200,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
