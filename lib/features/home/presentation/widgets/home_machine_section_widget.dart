import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:washer/core/enums/laundry_machine_type.dart';
import 'package:washer/core/enums/machine_state.dart';
import 'package:washer/core/router/route_paths.dart';
import 'package:washer/core/theme/color.dart';
import 'package:washer/core/theme/icon.dart';
import 'package:washer/core/theme/spacing.dart';
import 'package:washer/core/theme/typography.dart';
import 'package:washer/core/ui/dialog/laundry_status_dialog.dart';
import 'package:washer/features/reservation/data/models/local/laundry_machine_model.dart';

class HomeMachineSectionWidget extends StatelessWidget {
  const HomeMachineSectionWidget({
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(title: _title),
            _ViewAll(
              onTap: () {
                final route = machineType == LaundryMachineType.washer
                    ? RoutePaths.washer
                    : RoutePaths.dryer;
                context.go(route);
              },
            ),
          ],
        ),
        AppGap.v16,
        if (machines.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.v16),
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
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.v8,
              mainAxisSpacing: AppSpacing.h8,
              childAspectRatio: _itemRatio,
            ),
            itemCount: machines.length,
            itemBuilder: (context, index) {
              return _StatusItem(machine: machines[index]);
            },
          ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: WasherTypography.h2(WasherColor.baseGray700),
    );
  }
}

class _ViewAll extends StatelessWidget {
  const _ViewAll({this.onTap});

  final VoidCallback? onTap;

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
          const WasherIcon(
            type: WasherIconType.back,
            size: 16,
            color: WasherColor.baseGray300,
          ),
        ],
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  const _StatusItem({required this.machine});

  final MachineModel machine;

  MachineState? _toMachineState() {
    final operatingState = machine.operatingState?.toLowerCase();
    if (operatingState == 'running') return MachineState.run;
    if (operatingState == 'delay_wash') return MachineState.delayWash;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final machineType = machine.type == 'WASHER'
        ? LaundryMachineType.washer
        : LaundryMachineType.dryer;
    final isAvailable = machine.isAvailable;
    final machineState = _toMachineState();

    return GestureDetector(
      onTap: () async {
        await showDialog(
          context: context,
          builder: (_) => LaundryStatusDialog(
            machineType: machineType,
            machineName: machine.name,
            machineId: machine.machineId,
            isUsed: !isAvailable,
            isUnavailable: machine.isUnavailable,
            machineState: machineState,
            roomNumber: machine.roomNumber,
            expectedTime: machine.expectedCompletionTime,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
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
              AppGap.h12,
              Text(
                machine.name,
                style: WasherTypography.body3(
                  isAvailable
                      ? WasherColor.baseGray700
                      : WasherColor.baseGray200,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
