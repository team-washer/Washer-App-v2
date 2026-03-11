part of '../home_my_reservation_widget.dart';

class _BottomSection extends StatelessWidget {
  final LaundryMachineType laundryMachineType;
  final LaundryStatus laundryStatus;

  const _BottomSection({
    required this.laundryMachineType,
    required this.laundryStatus,
  });

  @override
  Widget build(BuildContext context) {
    if (!laundryStatus.needsSpacing) return const SizedBox();

    return Column(
      children: [
        _Buttons(
          laundryMachineType: laundryMachineType,
          laundryStatus: laundryStatus,
        ),
      ],
    );
  }
}

class _Buttons extends StatelessWidget {
  final LaundryMachineType laundryMachineType;
  final LaundryStatus laundryStatus;

  const _Buttons({
    required this.laundryMachineType,
    required this.laundryStatus,
  });

  @override
  Widget build(BuildContext context) {
    switch (laundryStatus) {
      case LaundryStatus.waiting:
        return _WaitingButton(laundryMachineType: laundryMachineType);
      case LaundryStatus.reserved:
        return _ReservedButton(laundryMachineType: laundryMachineType);
      case LaundryStatus.needConfirm:
      case LaundryStatus.inUse:
      case LaundryStatus.completed:
        return const SizedBox();
    }
  }
}

class _WaitingButton extends StatelessWidget {
  final LaundryMachineType laundryMachineType;

  const _WaitingButton({required this.laundryMachineType});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CustomSmallButton(
          text: '예약 취소',
          onPressed: () {},
          color: WasherColor.baseGray200,
        ),
        AppGap.h4,
        CustomSmallButton(
          text: '${laundryMachineType.text} 시작',
          onPressed: () {},
          color: WasherColor.mainColor500,
        ),
      ],
    );
  }
}

class _ReservedButton extends StatelessWidget {
  final LaundryMachineType laundryMachineType;

  const _ReservedButton({required this.laundryMachineType});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CustomSmallButton(
          text: '예약 취소',
          onPressed: () {},
          color: WasherColor.baseGray200,
        ),
        AppGap.h4,
        CustomSmallButton(
          text: '${laundryMachineType.text} 시작',
          onPressed: () {},
          color: WasherColor.mainColor200,
        ),
      ],
    );
  }
}
