import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:washer/core/enums/laundry_machine_type.dart';
import 'package:washer/core/theme/color.dart';
import 'package:washer/core/theme/spacing.dart';
import 'package:washer/core/theme/typography.dart';
import 'package:washer/features/reservation/data/models/local/laundry_machine_model.dart';

class LaundryLayoutDialog extends StatelessWidget {
  const LaundryLayoutDialog({
    super.key,
    required this.laundryMachineType,
    required this.floor,
    required this.machines,
  });

  final LaundryMachineType laundryMachineType;
  final int floor;
  final List<MachineModel> machines;

  static const _emptyMachine = MachineModel(
    machineId: -1,
    name: '',
    type: '',
    status: '',
    availability: '',
  );

  @override
  Widget build(BuildContext context) {
    final floorMachines = machines
        .where(
          (machine) =>
              machine.floorNumber == floor && machine.placement != null,
        )
        .toList(growable: false);
    final rows = _buildRows(floorMachines);

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.h16,
        vertical: AppSpacing.v24,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.large),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.cardPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LayoutHeader(title: '${laundryMachineType.text} 배치도'),
              AppGap.v16,
              _LayoutBoard(
                laundryMachineType: laundryMachineType,
                rows: rows,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_LayoutRowData> _buildRows(List<MachineModel> floorMachines) {
    final placementNumbers =
        floorMachines
            .map((machine) => machine.placement?.number)
            .whereType<int>()
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));

    return placementNumbers
        .map(
          (number) => _LayoutRowData(
            left: floorMachines.firstWhere(
              (machine) =>
                  machine.placement?.side == MachineSide.left &&
                  machine.placement?.number == number,
              orElse: () => _emptyMachine,
            ),
            right: floorMachines.firstWhere(
              (machine) =>
                  machine.placement?.side == MachineSide.right &&
                  machine.placement?.number == number,
              orElse: () => _emptyMachine,
            ),
          ),
        )
        .toList(growable: false);
  }
}

class _LayoutHeader extends StatelessWidget {
  const _LayoutHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: WasherTypography.subTitle2(WasherColor.baseGray900),
          ),
        ),
        InkWell(
          onTap: () => Navigator.of(context).pop(),
          borderRadius: AppRadius.circular,
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.h4),
            child: const Icon(
              Icons.close,
              color: WasherColor.baseGray400,
            ),
          ),
        ),
      ],
    );
  }
}

class _LayoutBoard extends StatelessWidget {
  const _LayoutBoard({
    required this.laundryMachineType,
    required this.rows,
  });

  final LaundryMachineType laundryMachineType;
  final List<_LayoutRowData> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: WasherColor.baseGray400),
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _BoardEdgeLabel(
            label: '창문',
            border: Border(
              bottom: BorderSide(color: WasherColor.baseGray400),
            ),
          ),
          if (rows.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.v24),
              child: Text(
                '표시할 기기가 없습니다.',
                style: WasherTypography.body4(WasherColor.baseGray400),
              ),
            )
          else
            ...rows.asMap().entries.map(
              (entry) => _LayoutRow(
                data: entry.value,
                laundryMachineType: laundryMachineType,
                showTopBorder: entry.key > 0,
              ),
            ),
          const _BoardEdgeLabel(
            label: '출입문',
            border: Border(
              top: BorderSide(color: WasherColor.baseGray400),
            ),
          ),
        ],
      ),
    );
  }
}

class _BoardEdgeLabel extends StatelessWidget {
  const _BoardEdgeLabel({
    required this.label,
    required this.border,
  });

  final String label;
  final Border border;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(vertical: AppSpacing.v16),
      decoration: BoxDecoration(border: border),
      child: Text(
        label,
        style: WasherTypography.subTitle4(WasherColor.baseGray900),
      ),
    );
  }
}

class _LayoutRow extends StatelessWidget {
  const _LayoutRow({
    required this.data,
    required this.laundryMachineType,
    required this.showTopBorder,
  });

  final _LayoutRowData data;
  final LaundryMachineType laundryMachineType;
  final bool showTopBorder;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            child: _LayoutCell(
              machine: data.left,
              laundryMachineType: laundryMachineType,
              showTopBorder: showTopBorder,
            ),
          ),
          Container(width: 1, color: WasherColor.baseGray400),
          Expanded(
            child: _LayoutCell(
              machine: data.right,
              laundryMachineType: laundryMachineType,
              showTopBorder: showTopBorder,
            ),
          ),
        ],
      ),
    );
  }
}

class _LayoutCell extends StatelessWidget {
  const _LayoutCell({
    required this.machine,
    required this.laundryMachineType,
    required this.showTopBorder,
  });

  final MachineModel machine;
  final LaundryMachineType laundryMachineType;
  final bool showTopBorder;

  bool get _hasMachine => machine.machineId >= 0;

  @override
  Widget build(BuildContext context) {
    final iconColor = _hasMachine && machine.isAvailable
        ? WasherColor.mainColor500
        : WasherColor.baseGray400;

    return Container(
      constraints: BoxConstraints(minHeight: 130.h),
      decoration: BoxDecoration(
        border: Border(
          top: showTopBorder
              ? const BorderSide(color: WasherColor.baseGray400)
              : BorderSide.none,
        ),
      ),
      child: _hasMachine
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                laundryMachineType.icon(color: iconColor, size: 28),
                AppGap.v12,
                Text(
                  machine.name,
                  textAlign: TextAlign.center,
                  style: WasherTypography.body1(
                    WasherColor.baseGray500,
                  ),
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }
}

class _LayoutRowData {
  const _LayoutRowData({
    required this.left,
    required this.right,
  });

  final MachineModel left;
  final MachineModel right;
}
