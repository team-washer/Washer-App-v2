part of '../home_my_reservation_widget.dart';

class _ReservationCard extends StatelessWidget {
  final Widget child;

  const _ReservationCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.card,
      ),
      child: child,
    );
  }
}

class _Header extends StatelessWidget {
  final LaundryMachineType laundryMachineType;
  final LaundryStatus laundryStatus;
  final String machine;

  const _Header({
    required this.laundryMachineType,
    required this.laundryStatus,
    required this.machine,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        laundryMachineType.icon(),
        AppGap.h8,
        Text(machine, style: WasherTypography.body1()),
        const Spacer(),
        ReservationStateWidget(
          label: laundryStatus.label,
          color: laundryStatus.color,
        ),
      ],
    );
  }
}
