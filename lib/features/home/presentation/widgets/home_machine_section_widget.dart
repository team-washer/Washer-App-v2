import 'package:flutter/material.dart';
import 'package:washer/core/enums/laundry_machine_type.dart';
import 'package:washer/core/theme/color.dart';
import 'package:washer/core/theme/icon.dart';
import 'package:washer/core/theme/spacing.dart';
import 'package:washer/core/theme/typography.dart';
import 'package:washer/features/reservation/data/models/laundry_machine_model.dart';

part 'local_widgets/section_header.dart';
part 'local_widgets/status_item.dart';

class HomeMachineSectionWidget extends StatelessWidget {
  final List<MachineModel> machines;
  final LaundryMachineType machineType;

  const HomeMachineSectionWidget({
    super.key,
    required this.machines,
    required this.machineType,
  });

  static const double _itemRatio = 170 / 52;

  String get _title =>
      machineType == LaundryMachineType.washer ? '세탁기 예약 현황' : '건조기 예약 현황';

  List<MachineModel> get _filtered => machines
      .where((m) => m.type == machineType.apiValue)
      .toList();

  @override
  Widget build(BuildContext context) {
    final items = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: _title, onViewAll: () {}),
        const SizedBox(height: AppSpacing.v16),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
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
