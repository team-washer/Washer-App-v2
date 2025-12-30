import 'package:flutter/material.dart';
import 'package:project_setting/core/theme/color.dart';
import 'package:project_setting/core/theme/icon.dart';
import 'package:project_setting/core/theme/typography.dart';
import 'package:project_setting/presentation/common/buttons/custom_big_button.dart';
import 'package:project_setting/presentation/common/reservation_state_widget.dart';
import '../../../core/enums/laundry_machine_type.dart';
import '../../../core/enums/reservation_state.dart';
import '../../../core/theme/spacing.dart';

class ReservationWidget extends StatelessWidget {
  final LaundryMachineType laundryMachineType;
  final ReservationState reservationState;
  final String machineName;

  final String? room;
  final String? reservedAt;
  final String? finishedAt;
  final String? remainDuration;

  const ReservationWidget({
    super.key,
    required this.laundryMachineType,
    required this.reservationState,
    required this.machineName,
    this.room,
    this.reservedAt,
    this.finishedAt,
    this.remainDuration,
  });

  @override
  Widget build(BuildContext context) {
    return _ReservationCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(
            laundryMachineType: laundryMachineType,
            reservationState: reservationState,
            machineName: machineName,
          ),
          const SizedBox(height: AppSpacing.v12),
          ReservationBottomSection(
            laundryMachineType: laundryMachineType,
            reservationState: reservationState,
            room: room,
            reservedAt: reservedAt,
            finishedAt: finishedAt,
            remainDuration: remainDuration,
          ),
        ],
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final Widget child;

  const _ReservationCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppPadding.card,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        color: Colors.white,
      ),
      child: child,
    );
  }
}

class _Header extends StatelessWidget {
  final LaundryMachineType laundryMachineType;
  final ReservationState reservationState;
  final String machineName;

  const _Header({
    required this.laundryMachineType,
    required this.reservationState,
    required this.machineName,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _MachineInfo(
          type: laundryMachineType,
          state: reservationState,
          name: machineName,
        ),
        _ReservationStatus(state: reservationState),
      ],
    );
  }
}

class _MachineInfo extends StatelessWidget {
  final LaundryMachineType type;
  final ReservationState state;
  final String name;

  const _MachineInfo({
    required this.type,
    required this.state,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        type.icon(
          color: state.color,
        ),
        const SizedBox(width: AppSpacing.h8),
        Text(
          name,
          style: WasherTypography.subTitle3(
            WasherColor.baseGray700,
          ),
        ),
      ],
    );
  }
}

class _ReservationStatus extends StatelessWidget {
  final ReservationState state;

  const _ReservationStatus({required this.state});

  @override
  Widget build(BuildContext context) {
    return ReservationStateWidget(
      label: state.label,
      color: state.color,
      textStyle: WasherTypography.caption(Colors.white),
    );
  }
}

class ReservationBottomSection extends StatelessWidget {
  final LaundryMachineType laundryMachineType;
  final ReservationState reservationState;

  final String? room;
  final String? reservedAt;
  final String? finishedAt;
  final String? remainDuration;

  const ReservationBottomSection({
    super.key,
    required this.reservationState,
    required this.laundryMachineType,
    this.room,
    this.reservedAt,
    this.finishedAt,
    this.remainDuration,
  });

  @override
  Widget build(BuildContext context) {
    switch (reservationState) {
      case ReservationState.inUse:
        return _InUseBottom(
          laundryMachineType: laundryMachineType,
          finishedAt: finishedAt,
          room: room,
        );

      case ReservationState.available:
        return _AvailableBottom(laundryMachineType: laundryMachineType);

      case ReservationState.reservedByMe:
        return _ReservedByMeBottom(
          reservedAt: reservedAt,
          remainDuration: remainDuration,
        );

      case ReservationState.reservedByOther:
        return _ReservedBottom(
          reservedAt: reservedAt,
          remainDuration: remainDuration,
          room: room,
        );

      case ReservationState.unavailable:
        return _UnavailableBottom(laundryMachineType: laundryMachineType);
    }
  }
}

class _InUseBottom extends StatelessWidget {
  final LaundryMachineType laundryMachineType;
  final String? finishedAt;
  final String? room;

  const _InUseBottom({
    required this.laundryMachineType,
    this.finishedAt,
    this.room,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${laundryMachineType.text} 중…',
          style: WasherTypography.body2(WasherColor.baseGray400),
        ),
        const SizedBox(height: AppSpacing.v4),
        Text(
          '${laundryMachineType.text} 완료 예정시간: ${finishedAt ?? ''}',
          style: WasherTypography.body2(WasherColor.baseGray400),
        ),
        const SizedBox(height: AppSpacing.v4),
        if (room != null)
          Text(
            '사용 호실: ${room ?? ''}',
            style: WasherTypography.body2(WasherColor.baseGray400),
          ),
      ],
    );
  }
}

class _AvailableBottom extends StatelessWidget {
  final LaundryMachineType laundryMachineType;

  const _AvailableBottom({required this.laundryMachineType});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '미사용 중',
          style: WasherTypography.body2(WasherColor.baseGray400),
        ),
        const SizedBox(height: AppSpacing.v24),
        Row(
          children: [
            CustomBigButton(
              text: '예약',
              onPressed: () {},
              color: WasherColor.mainColor500,
            ),
            const SizedBox(width: AppSpacing.h8),
            WasherIcon(
              type: WasherIconType.warningCircle,
              color: WasherColor.errorColor,
              size: 33,
            ),
            const SizedBox(width: AppSpacing.h8),
            WasherIcon(
              type: WasherIconType.historyCircle,
              color: WasherColor.baseGray200,
              size: 33,
            ),
          ],
        ),
      ],
    );
  }
}

class _ReservedByMeBottom extends StatelessWidget {
  final String? reservedAt;
  final String? remainDuration;

  const _ReservedByMeBottom({
    this.reservedAt,
    this.remainDuration,
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
        const SizedBox(height: AppSpacing.v4),
        Text(
          '예약 만료까지: ${remainDuration ?? ''}',
          style: WasherTypography.body2(WasherColor.errorColor),
        ),

        const SizedBox(height: AppSpacing.v12),
        Row(
          children: [
            CustomBigButton(
              text: '예약 취소',
              onPressed: () {},
              color: WasherColor.baseGray200,
            ),
            const SizedBox(width: AppSpacing.h8),
            CustomBigButton(
              text: '세탁 시작',
              onPressed: () {},
              color: WasherColor.mainColor500,
            ),
          ],
        ),
      ],
    );
  }
}

class _ReservedBottom extends StatelessWidget {
  final String? reservedAt;
  final String? remainDuration;
  final String? room;

  const _ReservedBottom({
    this.reservedAt,
    this.remainDuration,
    this.room,
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
        const SizedBox(height: AppSpacing.v4),
        Text(
          '예약 만료까지: ${remainDuration ?? ''}',
          style: WasherTypography.body2(WasherColor.errorColor),
        ),
        const SizedBox(height: AppSpacing.v4),
        Text(
          '사용 호실: ${room ?? ''}',
          style: WasherTypography.body2(WasherColor.baseGray500),
        ),
      ],
    );
  }
}

class _UnavailableBottom extends StatelessWidget {
  final LaundryMachineType laundryMachineType;

  const _UnavailableBottom({required this.laundryMachineType});

  @override
  Widget build(BuildContext context) {
    return Text(
      '${laundryMachineType.text} 고장으로 인해 당분간 사용이 정지됩니다.',
      style: WasherTypography.body2(WasherColor.errorColor),
    );
  }
}
