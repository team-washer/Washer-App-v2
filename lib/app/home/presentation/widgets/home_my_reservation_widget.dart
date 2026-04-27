import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:washer/core/constants/durations.dart';
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
import 'package:washer/core/utils/user_formatter.dart';
import 'package:washer/features/reservation/data/models/local/active_reservation_model.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_status_provider.dart';
import 'package:washer/features/user/presentation/providers/my_user_provider.dart';

class HomeMyReservationWidget extends ConsumerWidget {
  const HomeMyReservationWidget({super.key});

  static final double _cardWidth = 348.w;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservationsAsync = ref.watch(activeReservationProvider);
    final myUserAsync = ref.watch(myUserProvider);
    final myUserId = myUserAsync.whenOrNull(data: (user) => user?.id);
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
                ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: reservations
                          .asMap()
                          .entries
                          .map(
                            (entry) => Padding(
                              padding: EdgeInsets.only(
                                right: entry.key == reservations.length - 1
                                    ? 0
                                    : AppSpacing.h12,
                              ),
                              child: SizedBox(
                                width: _cardWidth,
                                child: _MyReservationCard(
                                  reservation: entry.value,
                                  isOwnedByMe:
                                      myUserId != null &&
                                      entry.value.userId == myUserId,
                                ),
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  )
                : Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: AppSpacing.v24,
                      ),
                      child: Text(
                        '현재 예약하거나 사용 중인 기기가 없습니다.',
                        style: WasherTypography.body1(
                          WasherColor.baseGray300,
                        ),
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
    required this.isOwnedByMe,
  });

  final ActiveReservationModel reservation;
  final bool isOwnedByMe;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppPadding.card,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.card,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              reservation.machineType.icon(),
              AppGap.h8,
              Expanded(
                child: Text(
                  reservation.machineName,
                  style: WasherTypography.subTitle3(),
                ),
              ),
              AppGap.h8,
              ReservationStateWidget(
                label:
                    reservation.laundryStatus == LaundryStatus.inUse &&
                        !_hasText(reservation.expectedCompletionTime)
                    ? '분석중'
                    : reservation.laundryStatus.label,
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
          if (!isOwnedByMe) ...[
            AppGap.v4,
            _ReservedUserInfo(
              laundryStatus: reservation.laundryStatus,
              userStudentId: reservation.userStudentId,
              userName: reservation.userName,
            ),
          ],
          _BottomSection(
            laundryMachineType: reservation.machineType,
            laundryStatus: reservation.laundryStatus,
            machineId: reservation.machineId,
            reservationId: reservation.id,
            deviceId: reservation.machineName,
            isOwnedByMe: isOwnedByMe,
          ),
        ],
      ),
    );
  }
}

class _ReservedUserInfo extends StatelessWidget {
  const _ReservedUserInfo({
    required this.laundryStatus,
    this.userStudentId,
    required this.userName,
  });

  final LaundryStatus laundryStatus;
  final String? userStudentId;
  final String userName;

  @override
  Widget build(BuildContext context) {
    final userLabel =
        UserFormatter.formatUserLabel(
          studentId: userStudentId,
          userName: userName,
        ) ??
        userName.trim();
    final message = '$userLabel 이용중...';

    return Text(
      message,
      style: WasherTypography.body2(WasherColor.baseGray500),
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
    final hasReservedAt = reservedAt != null && reservedAt!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasReservedAt) ...[
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
    final hasFinishedAt = finishedAt != null && finishedAt!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${laundryMachineType.text} 사용 중',
          style: WasherTypography.body2(WasherColor.baseGray500),
        ),
        if (hasFinishedAt) ...[
          AppGap.v4,
          _InUseCountdownText(
            laundryMachineType: laundryMachineType,
            finishedAt: finishedAt,
          ),
        ] else ...[
          AppGap.v4,
          Text(
            '분석중',
            style: WasherTypography.body2(WasherColor.baseGray500),
          ),
        ],
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
        reservedTime.add(reservationExpiryDuration).difference(now),
        expiredText: '만료됨',
      );
    }

    return Text(
      '예약 만료까지: $countdown',
      style: WasherTypography.body2(WasherColor.errorColor),
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
      '남은 ${laundryMachineType == LaundryMachineType.washer ? '세탁' : '건조'} 시간: $countdown',
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
    final hasFinishedAt = finishedAt != null && finishedAt!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${laundryMachineType.text} 완료',
          style: WasherTypography.body2(WasherColor.baseGray500),
        ),
        if (hasFinishedAt) ...[
          AppGap.v4,
          Text(
            '${laundryMachineType.text} 완료 시간: ${DateTimeFormatter.formatToShortWithTime(finishedAt)}',
            style: WasherTypography.body2(WasherColor.baseGray500),
          ),
        ],
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
    required this.isOwnedByMe,
  });

  final LaundryMachineType laundryMachineType;
  final LaundryStatus laundryStatus;
  final int? machineId;
  final int reservationId;
  final String deviceId;
  final bool isOwnedByMe;

  @override
  Widget build(BuildContext context) {
    if (!isOwnedByMe || machineId == null) {
      return const SizedBox.shrink();
    }

    final canCancel = laundryStatus == LaundryStatus.reserved;

    if (!canCancel) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        Expanded(
          child: CustomSmallButton(
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
        ),
      ],
    );
  }
}

String _formatDuration(
  Duration duration, {
  required String expiredText,
  bool includeHours = true,
}) {
  if (duration.isNegative) {
    return expiredText;
  }

  return DateTimeFormatter.formatDurationParts(
    duration,
    includeHours: includeHours,
  );
}

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;
