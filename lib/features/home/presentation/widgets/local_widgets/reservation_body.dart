part of '../home_my_reservation_widget.dart';

class _Body extends StatelessWidget {
  final LaundryMachineType laundryMachineType;
  final LaundryStatus laundryStatus;
  final String? reservedAt;
  final String? remainDuration;
  final String? finishedAt;
  final String? message;

  const _Body({
    required this.laundryMachineType,
    required this.laundryStatus,
    required this.reservedAt,
    required this.remainDuration,
    required this.finishedAt,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    switch (laundryStatus) {
      case LaundryStatus.waiting:
        return _WaitingBody(
          reservedAt: reservedAt,
          remainDuration: remainDuration,
        );
      case LaundryStatus.reserved:
        return _ReservedBody();
      case LaundryStatus.needConfirm:
        return _NeedConfirmBody();
      case LaundryStatus.inUse:
        return _InUseBody(
          laundryMachineType: laundryMachineType,
          finishedAt: finishedAt,
        );
      case LaundryStatus.completed:
        return _CompletedBody(
          laundryMachineType: laundryMachineType,
          finishedAt: finishedAt,
        );
    }
  }
}

class _WaitingBody extends StatelessWidget {
  final String? reservedAt;
  final String? remainDuration;

  const _WaitingBody({
    required this.reservedAt,
    required this.remainDuration,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '예약 시간: ${reservedAt ?? ''}',
          style: WasherTypography.body2(WasherColor.baseGray500),
        ),
        AppGap.v4,
        Text(
          '예약 만료까지: ${remainDuration ?? ''}',
          style: WasherTypography.body2(WasherColor.errorColor),
        ),
        AppGap.v12,
      ],
    );
  }
}

class _ReservedBody extends StatelessWidget {
  const _ReservedBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '기기에 연결 중입니다. 잠시만 기다려주세요.',
          style: WasherTypography.body2(WasherColor.baseGray500),
        ),
        AppGap.v24,
      ],
    );
  }
}

class _NeedConfirmBody extends StatelessWidget {
  const _NeedConfirmBody();

  @override
  Widget build(BuildContext context) {
    return Text(
      '기기에 이상이 감지되었습니다.\n확인해주세요.',
      style: WasherTypography.body2(WasherColor.errorColor),
    );
  }
}

class _InUseBody extends StatelessWidget {
  final LaundryMachineType laundryMachineType;
  final String? finishedAt;

  const _InUseBody({
    required this.laundryMachineType,
    required this.finishedAt,
  });

  @override
  Widget build(BuildContext context) {
    final String type = laundryMachineType == LaundryMachineType.washer
        ? '헹굼'
        : '건조';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$type 중...',
          style: WasherTypography.body2(WasherColor.baseGray500),
        ),
        AppGap.v4,
        Text(
          '세탁 완료 예정시간: ${finishedAt ?? ''}',
          style: WasherTypography.body2(WasherColor.baseGray500),
        ),
      ],
    );
  }
}

class _CompletedBody extends StatelessWidget {
  final LaundryMachineType laundryMachineType;
  final String? finishedAt;

  const _CompletedBody({
    required this.laundryMachineType,
    required this.finishedAt,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${laundryMachineType.text} 완료',
          style: WasherTypography.body2(WasherColor.baseGray500),
        ),
        AppGap.v4,
        Text(
          '세탁 완료 시간: ${finishedAt ?? ''}',
          style: WasherTypography.body2(WasherColor.baseGray500),
        ),
      ],
    );
  }
}
