import 'package:flutter/material.dart';
import 'package:project_setting/core/enums/laundry_machine_type.dart';
import 'package:project_setting/core/enums/laundry_status.dart';
import 'package:project_setting/core/theme/color.dart';
import 'package:project_setting/core/theme/spacing.dart';
import 'package:project_setting/core/theme/typography.dart';
import 'package:project_setting/presentation/common/buttons/custom_small_button.dart';
import 'package:project_setting/presentation/common/reservation_state_widget.dart';

class MyReservationWidget extends StatelessWidget {
  final LaundryMachineType laundryMachineType;
  final LaundryStatus laundryStatus;
  final String machine;
  final String? reservedAt;
  final String? remainDuration;
  final String? finishedAt;
  final String? message;

  const MyReservationWidget({
    super.key,
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

class _ReservationCard extends StatelessWidget {
  final Widget child;

  const _ReservationCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppPadding.card,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
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
        Text(machine, style: WasherTypography.subTitle3()),
        const Spacer(),
        ReservationStateWidget(
          label: laundryStatus.label,
          color: laundryStatus.color,
        ),
      ],
    );
  }
}

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
  const _ReservedBody({super.key});

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
  const _NeedConfirmBody({super.key});

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
    super.key,
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
    super.key,
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

  const _WaitingButton({super.key, required this.laundryMachineType});

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

  const _ReservedButton({super.key, required this.laundryMachineType});

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
