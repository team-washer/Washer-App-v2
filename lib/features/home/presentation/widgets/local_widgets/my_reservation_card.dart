part of '../home_my_reservation_widget.dart';

class _MyReservationCard extends StatelessWidget {
  final LaundryMachineType laundryMachineType;
  final LaundryStatus laundryStatus;
  final String machine;
  final String? reservedAt;
  final String? remainDuration;
  final String? finishedAt;
  final String? message;

  const _MyReservationCard({
    required this.laundryMachineType,
    required this.laundryStatus,
    required this.machine,
    this.reservedAt,
    this.remainDuration,
    this.finishedAt,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return _ReservationCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(
            laundryMachineType: laundryMachineType,
            laundryStatus: laundryStatus,
            machine: machine,
          ),
          AppGap.v12,
          _Body(
            laundryMachineType: laundryMachineType,
            laundryStatus: laundryStatus,
            reservedAt: reservedAt,
            remainDuration: remainDuration,
            finishedAt: finishedAt,
            message: message,
          ),
          _BottomSection(
            laundryMachineType: laundryMachineType,
            laundryStatus: laundryStatus,
          ),
        ],
      ),
    );
  }
}
