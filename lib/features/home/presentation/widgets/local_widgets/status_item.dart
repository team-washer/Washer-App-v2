part of '../home_machine_section_widget.dart';

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
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.circular,
      ),
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
    );
  }
}
