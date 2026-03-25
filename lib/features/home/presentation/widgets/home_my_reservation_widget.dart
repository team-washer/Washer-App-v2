import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/enums/laundry_action_type.dart';
import 'package:washer/core/enums/laundry_machine_type.dart';
import 'package:washer/core/enums/laundry_status.dart';
import 'package:washer/core/theme/color.dart';
import 'package:washer/core/theme/spacing.dart';
import 'package:washer/core/theme/typography.dart';
import 'package:washer/core/ui/buttons/custom_small_button.dart';
import 'package:washer/core/ui/dialog/laundry_action_dialog.dart';
import 'package:washer/core/ui/reservation_state_widget.dart';
import 'package:washer/core/utils/date_time_formatter.dart';
import 'package:washer/features/home/presentation/viewmodels/home_view_model.dart';
import 'package:washer/features/reservation/data/models/local/active_reservation_model.dart';
import 'package:washer/features/user/presentation/viewmodels/my_user_view_model.dart';

class HomeMyReservationWidget extends ConsumerWidget {
  const HomeMyReservationWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservationsAsync = ref.watch(activeReservationProvider);
    final myUserAsync = ref.watch(myUserProvider);
    final roomNumber =
        myUserAsync.whenOrNull(data: (user) => user?.roomNumber) ??
        reservationsAsync.whenOrNull(
          data: (reservations) => reservations.isNotEmpty
              ? reservations.first.userRoomNumber
              : null,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ReservationTitle(roomNumber: roomNumber),
        Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.v16),
          child: reservationsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.v24),
                child: Text(
                  '예약 정보를 불러오지 못했습니다.',
                  style: WasherTypography.body1(WasherColor.baseGray300),
                ),
              ),
            ),
            data: (reservations) => reservations.isNotEmpty
                ? reservations.length == 1
                      ? _MyReservationCard(
                          reservation: reservations.first,
                          width: double.infinity,
                        )
                      : SizedBox(
                          height: 220,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.zero,
                            itemCount: reservations.length,
                            separatorBuilder: (_, __) => AppGap.h12,
                            itemBuilder: (context, index) {
                              return _MyReservationCard(
                                reservation: reservations[index],
                                width: 300,
                              );
                            },
                          ),
                        )
                : Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: AppSpacing.v24,
                      ),
                      child: Text(
                        '현재 예약하거나 사용 중인 기기가 없습니다.',
                        style: WasherTypography.body1(WasherColor.baseGray300),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _ReservationTitle extends StatelessWidget {
  const _ReservationTitle({this.roomNumber});

  final String? roomNumber;

  @override
  Widget build(BuildContext context) {
    final normalizedRoomNumber = roomNumber?.trim();
    final title = normalizedRoomNumber == null || normalizedRoomNumber.isEmpty
        ? '내 예약 현황'
        : '$normalizedRoomNumber호 예약 현황';

    return Text(
      title,
      style: WasherTypography.h2(),
    );
  }
}

class _MyReservationCard extends StatelessWidget {
  const _MyReservationCard({
    required this.reservation,
    required this.width,
  });

  final ActiveReservationModel reservation;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: AppPadding.card,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              reservation.machineType.icon(),
              AppGap.h8,
              // Ensure long machine names don't overflow the row
              Expanded(
                child: Text(
                  reservation.machineName,
                  style: WasherTypography.subTitle3(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ReservationStateWidget(
                label: reservation.laundryStatus.label,
                color: reservation.laundryStatus.color,
              ),
            ],
          ),
          AppGap.v12,
          _ReservationBody(
            laundryMachineType: reservation.machineType,
            laundryStatus: reservation.laundryStatus,
            reservedAt: reservation.reservedAt,
            confirmedAt: reservation.confirmedAt,
            remainDuration: null,
            finishedAt: reservation.expectedCompletionTime,
          ),
          _BottomSection(
            laundryMachineType: reservation.machineType,
            laundryStatus: reservation.laundryStatus,
            machineId: reservation.machineId,
            reservationId: reservation.id,
            deviceId: reservation.machineName,
          ),
        ],
      ),
    );
  }
}

class _ReservationBody extends StatelessWidget {
  const _ReservationBody({
    required this.laundryMachineType,
    required this.laundryStatus,
    required this.reservedAt,
    required this.confirmedAt,
    required this.remainDuration,
    required this.finishedAt,
  });

  final LaundryMachineType laundryMachineType;
  final LaundryStatus laundryStatus;
  final String? reservedAt;
  final String? confirmedAt;
  final String? remainDuration;
  final String? finishedAt;

  @override
  Widget build(BuildContext context) {
    switch (laundryStatus) {
      case LaundryStatus.reserved:
        return _WaitingBody(
          reservedAt: reservedAt,
          remainDuration: remainDuration,
        );
      case LaundryStatus.confirmed:
        return _ConfirmedBody(
          confirmedAt: confirmedAt,
          finishedAt: finishedAt,
        );
      case LaundryStatus.needConfirm:
        return const _NeedConfirmBody();
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
  const _WaitingBody({
    required this.reservedAt,
    required this.remainDuration,
  });

  final String? reservedAt;
  final String? remainDuration;

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
        _ReservationExpiryText(
          reservedAt: reservedAt,
          remainDuration: remainDuration,
        ),
        AppGap.v12,
      ],
    );
  }
}

class _ConfirmedBody extends StatelessWidget {
  const _ConfirmedBody({
    this.confirmedAt,
    this.finishedAt,
  });

  final String? confirmedAt;
  final String? finishedAt;

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
        _ConfirmationCountdownText(
          confirmedAt: confirmedAt,
          finishedAt: finishedAt,
        ),
        AppGap.v12,
      ],
    );
  }
}

class _NeedConfirmBody extends StatelessWidget {
  const _NeedConfirmBody();

  @override
  Widget build(BuildContext context) {
    return Text(
      '기기 동작이 감지되었습니다. 확인해주세요.',
      style: WasherTypography.body2(WasherColor.errorColor),
    );
  }
}

class _InUseBody extends StatelessWidget {
  const _InUseBody({
    required this.laundryMachineType,
    required this.finishedAt,
  });

  final LaundryMachineType laundryMachineType;
  final String? finishedAt;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${laundryMachineType.text} 사용 중',
          style: WasherTypography.body2(WasherColor.baseGray500),
        ),
        AppGap.v4,
        _InUseCountdownText(
          laundryMachineType: laundryMachineType,
          finishedAt: finishedAt,
        ),
      ],
    );
  }
}

class _ReservationExpiryText extends ConsumerWidget {
  const _ReservationExpiryText({
    required this.reservedAt,
    required this.remainDuration,
  });

  final String? reservedAt;
  final String? remainDuration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider).asData?.value ?? DateTime.now();
    var countdown = remainDuration ?? '만료됨';

    final reservedTime = reservedAt != null
        ? DateTime.tryParse(reservedAt!)
        : null;
    if (reservedTime != null) {
      countdown = _formatDuration(
        reservedTime.add(const Duration(minutes: 5)).difference(now),
        expiredText: '만료됨',
      );
    }

    return Text(
      '예약 만료까지: $countdown',
      style: WasherTypography.body2(WasherColor.errorColor),
    );
  }
}

class _ConfirmationCountdownText extends ConsumerWidget {
  const _ConfirmationCountdownText({
    this.confirmedAt,
    this.finishedAt,
  });

  final String? confirmedAt;
  final String? finishedAt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider).asData?.value ?? DateTime.now();
    final baseTime =
        (confirmedAt != null ? DateTime.tryParse(confirmedAt!) : null) ??
        (finishedAt != null ? DateTime.tryParse(finishedAt!) : null);
    final countdown = _formatDuration(
      (baseTime ?? now).add(const Duration(minutes: 3)).difference(now),
      expiredText: '만료됨',
    );

    return Text(
      '예정 완료 시간: $countdown',
      style: WasherTypography.body2(WasherColor.baseGray500),
    );
  }
}

class _InUseCountdownText extends ConsumerWidget {
  const _InUseCountdownText({
    required this.laundryMachineType,
    required this.finishedAt,
  });

  final LaundryMachineType laundryMachineType;
  final String? finishedAt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider).asData?.value ?? DateTime.now();
    final countdown = DateTimeFormatter.formatRemainingTimeToKorean(
      finishedAt,
      now: now,
      expiredText: '완료 예정',
      includeHours: true,
    );

    return Text(
      '${laundryMachineType.text} 완료 예정 시간: $countdown',
      style: WasherTypography.body2(WasherColor.baseGray500),
    );
  }
}

class _CompletedBody extends StatelessWidget {
  const _CompletedBody({
    required this.laundryMachineType,
    required this.finishedAt,
  });

  final LaundryMachineType laundryMachineType;
  final String? finishedAt;

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
          '${laundryMachineType.text} 완료 시간: ${DateTimeFormatter.formatToShortWithTime(finishedAt)}',
          style: WasherTypography.body2(WasherColor.baseGray500),
        ),
      ],
    );
  }
}

class _BottomSection extends StatelessWidget {
  const _BottomSection({
    required this.laundryMachineType,
    required this.laundryStatus,
    this.machineId,
    required this.reservationId,
    required this.deviceId,
  });

  final LaundryMachineType laundryMachineType;
  final LaundryStatus laundryStatus;
  final int? machineId;
  final int reservationId;
  final String deviceId;

  @override
  Widget build(BuildContext context) {
    final canCancel =
        laundryStatus == LaundryStatus.reserved ||
        laundryStatus == LaundryStatus.confirmed;
    final canStart = laundryStatus == LaundryStatus.reserved;

    if (!canCancel || machineId == null) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        CustomSmallButton(
          text: '예약 취소',
          onPressed: () {
            if (reservationId > 0) {
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  child: LaundryActionDialog(
                    actionType: LaundryActionType.cancelReservation,
                    deviceId: deviceId,
                    reservationId: reservationId,
                    machineId: machineId!,
                  ),
                ),
              );
            }
          },
          color: WasherColor.baseGray300,
        ),
        AppGap.h4,
        CustomSmallButton(
          text: '${laundryMachineType.text} 시작',
          onPressed: () {
            if (!canStart) {
              return;
            }

            if (reservationId > 0) {
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  child: LaundryActionDialog(
                    actionType: LaundryActionType.reserve,
                    deviceId: deviceId,
                    reservationId: reservationId,
                    machineId: machineId!,
                  ),
                ),
              );
            }
          },
          color: canStart ? WasherColor.mainColor400 : WasherColor.mainColor300,
        ),
      ],
    );
  }
}

String _formatDuration(
  Duration duration, {
  required String expiredText,
  bool includeHours = false,
}) {
  if (duration.isNegative) {
    return expiredText;
  }

  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  final seconds = duration.inSeconds % 60;

  if (includeHours && hours > 0) {
    return '$hours시간 ${minutes.toString().padLeft(2, '0')}분 ${seconds.toString().padLeft(2, '0')}초';
  }

  return '${duration.inMinutes.toString().padLeft(2, '0')}분 ${seconds.toString().padLeft(2, '0')}초';
}
