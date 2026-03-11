part of '../home_my_reservation_widget.dart';

class _MyMachineCard extends StatelessWidget {
  final MachineModel machine;

  const _MyMachineCard({required this.machine});

  LaundryMachineType get _machineType =>
      machine.type == 'WASHER' ? LaundryMachineType.washer : LaundryMachineType.dryer;

  LaundryStatus get _laundryStatus {
    switch (machine.jobState) {
      case 'waiting':
        return LaundryStatus.waiting;
      case 'reserved':
        return LaundryStatus.reserved;
      case 'need_confirm':
        return LaundryStatus.needConfirm;
      case 'completed':
        return LaundryStatus.completed;
      default:
        return LaundryStatus.inUse;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _MyReservationCard(
      laundryMachineType: _machineType,
      laundryStatus: _laundryStatus,
      machine: machine.name,
      finishedAt: machine.expectedCompletionTime,
    );
  }
}
