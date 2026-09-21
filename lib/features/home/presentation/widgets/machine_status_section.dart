import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:washer/core/enums/laundry_machine_type.dart';
import 'package:washer/core/router/route_paths.dart';
import 'package:washer/features/home/presentation/widgets/machine_section_header.dart';
import 'package:washer/features/home/presentation/widgets/machine_status_tile.dart';
import 'package:washer/features/reservation/data/models/local/machine_model.dart';
import 'package:washer/shared/theme/washer_color.dart';
import 'package:washer/shared/theme/app_spacing.dart';
import 'package:washer/shared/theme/washer_typography.dart';

/// 기기를 층 -> 배치 번호 -> 좌/우 -> 이름 순으로 정렬한다. (null 값은 뒤로)
List<MachineModel> _sortMachinesByPlacement(List<MachineModel> machines) {
  int compareNullableInt(int? a, int? b) {
    if (a == null && b == null) {
      return 0;
    }
    if (a == null) {
      return 1;
    }
    if (b == null) {
      return -1;
    }
    return a.compareTo(b);
  }

  int sideOrder(MachineSide? side) {
    return switch (side) {
      MachineSide.left => 0,
      MachineSide.right => 1,
      null => 2,
    };
  }

  final sorted = List<MachineModel>.from(machines);
  sorted.sort((a, b) {
    final floorCompare = compareNullableInt(a.floorNumber, b.floorNumber);
    if (floorCompare != 0) {
      return floorCompare;
    }

    final orderCompare = compareNullableInt(
      a.placement?.number,
      b.placement?.number,
    );
    if (orderCompare != 0) {
      return orderCompare;
    }

    final sideCompare = sideOrder(a.placement?.side).compareTo(
      sideOrder(b.placement?.side),
    );
    if (sideCompare != 0) {
      return sideCompare;
    }

    return a.name.compareTo(b.name);
  });
  return sorted;
}

/// 홈 화면의 세탁기/건조기 기기 현황 섹션 (헤더 + 2열 그리드 sliver)
class MachineStatusSection extends StatelessWidget {
  const MachineStatusSection({
    super.key,
    required this.machines,
    required this.machineType,
  });

  static const double _itemRatio = 170 / 52;

  final List<MachineModel> machines;
  final LaundryMachineType machineType;

  String get _title =>
      machineType == LaundryMachineType.washer ? '세탁기 예약 현황' : '건조기 예약 현황';

  @override
  Widget build(BuildContext context) {
    final sortedMachines = _sortMachinesByPlacement(machines);

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: MachineSectionHeader(
            title: _title,
            onViewAll: () {
              final route = machineType == LaundryMachineType.washer
                  ? RoutePaths.washer
                  : RoutePaths.dryer;
              context.go(route);
            },
          ),
        ),
        SliverToBoxAdapter(child: AppGap.v16),
        if (sortedMachines.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.v16),
              child: Center(
                child: Text(
                  '현재 예약하거나 사용중인 기기가 없습니다.',
                  style: WasherTypography.body1(WasherColor.baseGray500),
                ),
              ),
            ),
          )
        else
          SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) =>
                  MachineStatusTile(machine: sortedMachines[index]),
              childCount: sortedMachines.length,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.v8,
              mainAxisSpacing: AppSpacing.h8,
              childAspectRatio: _itemRatio,
            ),
          ),
      ],
    );
  }
}
