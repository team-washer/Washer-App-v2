import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/theme/color.dart';
import 'package:washer/core/theme/icon.dart';
import 'package:washer/core/theme/typography.dart';
import 'package:washer/core/ui/buttons/custom_big_button.dart';
import 'package:washer/core/ui/reservation_state_widget.dart';
import 'package:washer/core/enums/laundry_machine_type.dart';
import 'package:washer/core/enums/reservation_state.dart';
import 'package:washer/core/theme/spacing.dart';
import 'package:washer/features/home/presentation/viewmodels/home_view_model.dart';

/// 예약 가능 기계를 카드 단위로 표시하는 위젯
/// 
/// 기능:
/// - 기계 상태별 요약 (가용/예약/사용중 등)
/// - 예약/예약 취소/시작 버튼 제공
/// - 사용했던 실나 점율 표시
class ReservationWidget extends StatelessWidget {
  final LaundryMachineType laundryMachineType;
  final ReservationState reservationState;
  final String machineName;

  final String? room;
  final String? reservedAt;
  final String? finishedAt;
  final String? remainDuration;
  final VoidCallback? onReserve;

  const ReservationWidget({
    super.key,
    required this.laundryMachineType,
    required this.reservationState,
    required this.machineName,
    this.room,
    this.reservedAt,
    this.finishedAt,
    this.remainDuration,
    this.onReserve,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppPadding.card,
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  laundryMachineType.icon(color: reservationState.color),
                  AppGap.h8,
                  Text(
                    machineName,
                    style: WasherTypography.subTitle3(WasherColor.baseGray700),
                  ),
                ],
              ),
              ReservationStateWidget(
                label: reservationState.label,
                color: reservationState.color,
                textStyle: WasherTypography.caption(Colors.white),
              ),
            ],
          ),
          AppGap.v12,
          ReservationBottomSection(
            laundryMachineType: laundryMachineType,
            reservationState: reservationState,
            room: room,
            reservedAt: reservedAt,
            finishedAt: finishedAt,
            remainDuration: remainDuration,
            onReserve: onReserve,
          ),
        ],
      ),
    );
  }
}
/// 예약 상태별 하단 섹션 정보 렌더링class ReservationBottomSection extends StatelessWidget {
  final LaundryMachineType laundryMachineType;
  final ReservationState reservationState;

  final String? room;
  final String? reservedAt;
  final String? finishedAt;
  final String? remainDuration;
  final VoidCallback? onReserve;

  const ReservationBottomSection({
    super.key,
    required this.reservationState,
    required this.laundryMachineType,
    this.room,
    this.reservedAt,
    this.finishedAt,
    this.remainDuration,
    this.onReserve,
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
        return _AvailableBottom(
          laundryMachineType: laundryMachineType,
          onReserve: onReserve,
        );

      case ReservationState.reservedByMe:
        return _ReservedByMeBottom(
          laundryMachineType: laundryMachineType,
          reservedAt: reservedAt,
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

/// 사용 중 상태 메시지
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

/// 가용 가능 상태 메시지
class _AvailableBottom extends StatelessWidget {
  final LaundryMachineType laundryMachineType;
  final VoidCallback? onReserve;

  const _AvailableBottom({
    required this.laundryMachineType,
    this.onReserve,
  });

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
              onPressed: onReserve ?? () {},
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

/// 내가 예약한 상태 메시지 - 시간 카운트다운 표시
class _ReservedByMeBottom extends ConsumerWidget {
  final LaundryMachineType laundryMachineType;
  final String? reservedAt;

  const _ReservedByMeBottom({
    required this.laundryMachineType,
    this.reservedAt,
  });

  String _formatCountdown(DateTime expireAt, DateTime now) {
    final remaining = expireAt.difference(now);
    if (remaining.isNegative) return '만료됨';
    final m = remaining.inMinutes;
    final s = remaining.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}분 ${s.toString().padLeft(2, '0')}초';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider).asData?.value ?? DateTime.now();
    // reservedAt 기준 5분 후가 만료 시각
    final reservedTime = reservedAt != null
        ? DateTime.tryParse(reservedAt!)
        : null;
    final expireAt = reservedTime?.add(const Duration(minutes: 5));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '예약 시간: ${reservedAt ?? ''}',
          style: WasherTypography.body2(WasherColor.baseGray500),
        ),
        const SizedBox(height: AppSpacing.v4),
        Text(
          '예약 만료까지: ${expireAt != null ? _formatCountdown(expireAt, now) : ''}',
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
              text: '${laundryMachineType.text} 시작',
              onPressed: () {},
              color: WasherColor.mainColor500,
            ),
          ],
        ),
      ],
    );
  }
}

/// 단 늟 나눠로 줋닸 는 비른 메시지 - 다른 사람의 예약
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
        AppGap.v4,
        Text(
          '예약 만료까지: ${remainDuration ?? ''}',
          style: WasherTypography.body2(WasherColor.errorColor),
        ),
        AppGap.v4,
        Text(
          '사용 호실: ${room ?? ''}',
          style: WasherTypography.body2(WasherColor.baseGray500),
        ),
      ],
    );
  }
}

/// 사용 불가 상태 메시지
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
