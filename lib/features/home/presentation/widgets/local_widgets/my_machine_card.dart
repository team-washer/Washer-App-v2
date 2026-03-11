part of '../home_my_reservation_widget.dart';

class _MyMachineCard extends StatelessWidget {
  final ActiveReservationModel reservation;

  const _MyMachineCard({required this.reservation});

  @override
  Widget build(BuildContext context) {
    return _MyReservationCard(
      laundryMachineType: reservation.machineType,
      laundryStatus: reservation.laundryStatus,
      machine: reservation.machineName,
      reservedAt: reservation.reservedAt,
      finishedAt: reservation.expectedCompletionTime,
    );
  }
}
