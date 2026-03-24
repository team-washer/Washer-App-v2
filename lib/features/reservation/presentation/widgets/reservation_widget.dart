import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:washer/core/enums/laundry_action_type.dart';
import 'package:washer/core/enums/laundry_machine_type.dart';
import 'package:washer/core/enums/reservation_state.dart';
import 'package:washer/core/theme/color.dart';
import 'package:washer/core/theme/icon.dart';
import 'package:washer/core/theme/spacing.dart';
import 'package:washer/core/theme/typography.dart';
import 'package:washer/core/ui/buttons/custom_big_button.dart';
import 'package:washer/core/ui/dialog/laundry_action_dialog.dart';
import 'package:washer/core/ui/reservation_state_widget.dart';
import 'package:washer/core/utils/date_time_formatter.dart';
import 'package:washer/features/history/presentation/widgets/history_dialog.dart';
import 'package:washer/features/home/presentation/viewmodels/home_view_model.dart';

class ReservationWidget extends StatelessWidget {
  const ReservationWidget({
    super.key,
    required this.laundryMachineType,
    required this.reservationState,
    required this.machineName,
    this.machineId = 0,
    this.reservationId = 0,
    this.room,
    this.reservedAt,
    this.finishedAt,
    this.remainDuration,
    this.onReserve,
  });

  final LaundryMachineType laundryMachineType;
  final ReservationState reservationState;
  final String machineName;
  final int machineId;
  final int reservationId;
  final String? room;
  final String? reservedAt;
  final String? finishedAt;
  final String? remainDuration;
  final VoidCallback? onReserve;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: 137.h),
      padding: AppPadding.card,
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        color: Colors.white,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    laundryMachineType.icon(
                      color: reservationState.color,
                    ),
                    AppGap.h8,
                    Expanded(
                      child: Text(
                        machineName,
                        style: WasherTypography.subTitle3(
                          WasherColor.baseGray700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              AppGap.h8,
              ReservationStateWidget(
                label: reservationState.label,
                color: reservationState.color,
                textStyle: WasherTypography.caption(Colors.white),
              ),
            ],
          ),
          AppGap.v12,
          ReservationBottomSection(
            machineId: machineId,
            reservationId: reservationId,
            machineName: machineName,
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

class ReservationBottomSection extends StatelessWidget {
  const ReservationBottomSection({
    super.key,
    required this.reservationState,
    required this.laundryMachineType,
    this.machineId = 0,
    this.reservationId = 0,
    this.machineName = '',
    this.room,
    this.reservedAt,
    this.finishedAt,
    this.remainDuration,
    this.onReserve,
  });

  final LaundryMachineType laundryMachineType;
  final ReservationState reservationState;
  final int machineId;
  final int reservationId;
  final String machineName;
  final String? room;
  final String? reservedAt;
  final String? finishedAt;
  final String? remainDuration;
  final VoidCallback? onReserve;

  static String? formatRoom(String? room) {
    if (room == null) {
      return null;
    }

    final normalized = room.trim();
    if (normalized.isEmpty || normalized.endsWith('호')) {
      return normalized;
    }

    return '$normalized호';
  }

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
          machineId: machineId,
          machineName: machineName,
          laundryMachineType: laundryMachineType,
          onReserve: onReserve,
        );
      case ReservationState.reservedByMe:
        return _ReservedByMeBottom(
          laundryMachineType: laundryMachineType,
          reservedAt: reservedAt,
          machineId: machineId,
          reservationId: reservationId,
          machineName: machineName,
        );
      case ReservationState.confirmed:
        return _ConfirmedByMeBottom(
          laundryMachineType: laundryMachineType,
          reservedAt: reservedAt,
          finishedAt: finishedAt,
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
  const _InUseBottom({
    required this.laundryMachineType,
    this.finishedAt,
    this.room,
  });

  final LaundryMachineType laundryMachineType;
  final String? finishedAt;
  final String? room;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${laundryMachineType.text} 사용 중',
          style: WasherTypography.body2(WasherColor.baseGray400),
        ),
        AppGap.v4,
        Text(
          '${laundryMachineType.text} 완료 예정 시간: ${DateTimeFormatter.formatToShortWithTime(finishedAt)}',
          style: WasherTypography.body2(WasherColor.baseGray400),
        ),
        AppGap.v4,
        if (room != null)
          Text(
            '사용 호실: ${ReservationBottomSection.formatRoom(room)}',
            style: WasherTypography.body2(WasherColor.baseGray400),
          ),
      ],
    );
  }
}

class _AvailableBottom extends StatelessWidget {
  const _AvailableBottom({
    required this.laundryMachineType,
    this.onReserve,
    required this.machineId,
    required this.machineName,
  });

  final LaundryMachineType laundryMachineType;
  final VoidCallback? onReserve;
  final int machineId;
  final String machineName;

  @override
  Widget build(BuildContext context) {
    final isReserveEnabled = onReserve != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '미사용 중',
          style: WasherTypography.body2(WasherColor.baseGray400),
        ),
        AppGap.v12,
        Row(
          children: [
            CustomBigButton(
              text: '예약',
              onPressed: onReserve,
              color: isReserveEnabled
                  ? WasherColor.mainColor400
                  : WasherColor.baseGray300,
            ),
            AppGap.h8,
            WasherIconButton(
              type: WasherIconType.warningCircle,
              color: WasherColor.errorColor,
              size: 33,
              padding: EdgeInsets.zero,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    child: LaundryActionDialog(
                      actionType: LaundryActionType.reportBroken,
                      machineId: machineId,
                      deviceId: machineName,
                      reservationId: 0,
                    ),
                  ),
                );
              },
            ),
            AppGap.h8,
            WasherIconButton(
              type: WasherIconType.historyCircle,
              color: WasherColor.baseGray300,
              size: 33,
              padding: EdgeInsets.zero,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => HistoryDialog(
                    machineId: machineId,
                    machineName: machineName,
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _ReservedByMeBottom extends StatelessWidget {
  const _ReservedByMeBottom({
    required this.laundryMachineType,
    this.reservedAt,
    required this.machineId,
    required this.reservationId,
    required this.machineName,
  });

  final LaundryMachineType laundryMachineType;
  final String? reservedAt;
  final int machineId;
  final int reservationId;
  final String machineName;

  String _formatCountdown(DateTime expireAt, DateTime now) {
    final remaining = expireAt.difference(now);
    if (remaining.isNegative) return '만료됨';

    final minutes = remaining.inMinutes.remainder(60);
    final seconds = remaining.inSeconds.remainder(60);
    final hours = remaining.inHours;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}시간 '
          '${minutes.toString().padLeft(2, '0')}분 '
          '${seconds.toString().padLeft(2, '0')}초';
    }

    return '${remaining.inMinutes.toString().padLeft(2, '0')}분 '
        '${seconds.toString().padLeft(2, '0')}초';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '예약 시간: ${DateTimeFormatter.formatToShortWithTime(reservedAt)}',
          style: WasherTypography.body2(WasherColor.baseGray500),
        ),
        AppGap.v4,
        _ReservedByMeCountdownText(
          reservedAt: reservedAt,
          formatCountdown: _formatCountdown,
        ),
        AppGap.v12,
        Row(
          children: [
            CustomBigButton(
              text: '예약 취소',
              onPressed: () {
                if (reservationId > 0) {
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      child: LaundryActionDialog(
                        actionType: LaundryActionType.cancelReservation,
                        deviceId: machineName,
                        reservationId: reservationId,
                        machineId: machineId,
                      ),
                    ),
                  );
                }
              },
              color: WasherColor.baseGray300,
            ),
            AppGap.h8,
            CustomBigButton(
              text: '${laundryMachineType.text} 시작',
              onPressed: () {
                if (reservationId > 0) {
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      child: LaundryActionDialog(
                        actionType: LaundryActionType.reserve,
                        deviceId: machineName,
                        reservationId: reservationId,
                        machineId: machineId,
                      ),
                    ),
                  );
                }
              },
              color: WasherColor.mainColor400,
            ),
          ],
        ),
      ],
    );
  }
}

class _ConfirmedByMeBottom extends StatelessWidget {
  const _ConfirmedByMeBottom({
    required this.laundryMachineType,
    this.reservedAt,
    this.finishedAt,
  });

  final LaundryMachineType laundryMachineType;
  final String? reservedAt;
  final String? finishedAt;

  String _formatCountdown(DateTime? baseTime, DateTime now) {
    if (baseTime == null) return '';
    final expiryTime = baseTime.add(const Duration(minutes: 3));
    final remaining = expiryTime.difference(now);
    if (remaining.isNegative) return '만료됨';

    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}분 ${seconds.toString().padLeft(2, '0')}초';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '기기 연결을 확인하고 있습니다. 잠시만 기다려주세요.',
          style: WasherTypography.body2(WasherColor.baseGray500),
        ),
        AppGap.v4,
        _ConfirmedByMeCountdownText(
          reservedAt: reservedAt,
          finishedAt: finishedAt,
          formatCountdown: _formatCountdown,
        ),
        AppGap.v12,
      ],
    );
  }
}

class _ReservedByMeCountdownText extends ConsumerWidget {
  const _ReservedByMeCountdownText({
    required this.reservedAt,
    required this.formatCountdown,
  });

  final String? reservedAt;
  final String Function(DateTime expireAt, DateTime now) formatCountdown;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider).asData?.value ?? DateTime.now();
    final reservedTime = reservedAt != null
        ? DateTime.tryParse(reservedAt!)
        : null;
    final expireAt = reservedTime?.add(const Duration(minutes: 5));

    return Text(
      '예약 만료까지: ${expireAt != null ? formatCountdown(expireAt, now) : ''}',
      style: WasherTypography.body2(WasherColor.errorColor),
    );
  }
}

class _ConfirmedByMeCountdownText extends ConsumerWidget {
  const _ConfirmedByMeCountdownText({
    required this.reservedAt,
    required this.finishedAt,
    required this.formatCountdown,
  });

  final String? reservedAt;
  final String? finishedAt;
  final String Function(DateTime? baseTime, DateTime now) formatCountdown;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider).asData?.value ?? DateTime.now();
    final reservedTime = reservedAt != null
        ? DateTime.tryParse(reservedAt!)
        : null;
    final countdown = reservedTime != null
        ? formatCountdown(reservedTime, now)
        : (finishedAt != null
              ? formatCountdown(DateTime.tryParse(finishedAt!), now)
              : '');

    return Text(
      '예정 완료 시간: $countdown',
      style: WasherTypography.body2(WasherColor.baseGray500),
    );
  }
}

class _ReservedBottom extends StatelessWidget {
  const _ReservedBottom({
    this.reservedAt,
    this.remainDuration,
    this.room,
  });

  final String? reservedAt;
  final String? remainDuration;
  final String? room;

  @override
  Widget build(BuildContext context) {
    final formattedReservedAt = DateTimeFormatter.formatToShortWithTime(
      reservedAt,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '예약 시간: ${formattedReservedAt.isEmpty ? '확인 중' : formattedReservedAt}',
          style: WasherTypography.body2(WasherColor.baseGray500),
        ),
        AppGap.v4,
        Text(
          '예약 상태: 사용 대기 중',
          style: WasherTypography.body2(WasherColor.baseGray500),
        ),
        if (room != null && room!.trim().isNotEmpty) ...[
          AppGap.v4,
          Text(
            '사용 호실: ${ReservationBottomSection.formatRoom(room)}',
            style: WasherTypography.body2(WasherColor.baseGray500),
          ),
        ],
      ],
    );
  }
}

class _UnavailableBottom extends StatelessWidget {
  const _UnavailableBottom({required this.laundryMachineType});

  final LaundryMachineType laundryMachineType;

  @override
  Widget build(BuildContext context) {
    return Text(
      '${laundryMachineType.text} 기기 고장으로 인해 당분간 사용할 수 없습니다.',
      style: WasherTypography.body2(WasherColor.errorColor),
    );
  }
}
