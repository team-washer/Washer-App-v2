import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/enums/laundry_machine_type.dart';
import 'package:washer/core/enums/reservation_state.dart';
import 'package:washer/core/theme/color.dart';
import 'package:washer/core/theme/icon.dart';
import 'package:washer/core/theme/spacing.dart';
import 'package:washer/core/theme/typography.dart';
import 'package:washer/core/ui/buttons/custom_big_button.dart';
import 'package:washer/core/ui/reservation_state_widget.dart';
import 'package:washer/features/home/presentation/viewmodels/home_view_model.dart';
import 'package:washer/core/utils/date_time_formatter.dart';
import 'package:washer/features/history/presentation/widgets/history_dialog.dart';

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
  final int machineId;

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
    this.machineId = 0, // 기본값 적용
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
              // 예) 아이콘 Washser-3F-L1 사용중
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  laundryMachineType.icon(
                    color: reservationState.color,
                  ),
                  AppGap.h8,
                  Text(
                    machineName,
                    style: WasherTypography.subTitle3(
                      WasherColor.baseGray700,
                    ),
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
          // 상태에 다른 나머지 부분
          ReservationBottomSection(
            machineId: machineId,
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
  final LaundryMachineType laundryMachineType;
  final ReservationState reservationState;
  final int machineId;
  final String machineName;

  final String? room;
  final String? reservedAt;
  final String? finishedAt;
  final String? remainDuration;
  final VoidCallback? onReserve;

  const ReservationBottomSection({
    super.key,
    required this.reservationState,
    required this.laundryMachineType,
    this.machineId = 0,
    this.machineName = '',
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
        // 사용 중 일때
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

/// 사용 중일때
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
        AppGap.v4,
        Text(
          '${laundryMachineType.text} 완료 예정시간: ${DateTimeFormatter.formatToShortWithTime(finishedAt)}',
          style: WasherTypography.body2(WasherColor.baseGray400),
        ),
        AppGap.v4,
        if (room != null)
          Text(
            '사용 호실: ${room ?? ''}',
            style: WasherTypography.body2(WasherColor.baseGray400),
          ),
      ],
    );
  }
}

/// 사용 가능 상태일때
class _AvailableBottom extends StatelessWidget {
  final LaundryMachineType laundryMachineType;
  final VoidCallback? onReserve;
  final int machineId;
  final String machineName;

  const _AvailableBottom({
    required this.laundryMachineType,
    this.onReserve,
    required this.machineId,
    required this.machineName,
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
        AppGap.v12,
        Row(
          children: [
            CustomBigButton(
              text: '예약',
              onPressed: onReserve ?? () {},
              color: WasherColor.mainColor500,
            ),
            AppGap.h8,
            WasherIcon(
              type: WasherIconType.warningCircle,
              color: WasherColor.errorColor,
              size: 33,
            ),
            AppGap.h8,
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => HistoryDialog(
                    machineId: machineId,
                    machineName: machineName,
                  ),
                );
              },
              child: WasherIcon(
                type: WasherIconType.historyCircle,
                color: WasherColor.baseGray200,
                size: 33,
              ),
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

  /// 서버 시간 포멧팅
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
          '예약 시간: ${DateTimeFormatter.formatToShortWithTime(reservedAt)}',
          style: WasherTypography.body2(
            WasherColor.baseGray500,
          ),
        ),
        AppGap.v4,
        Text(
          '예약 만료까지: ${expireAt != null ? _formatCountdown(expireAt, now) : ''}',
          style: WasherTypography.body2(
            WasherColor.errorColor,
          ),
        ),
        AppGap.v12,
        Row(
          children: [
            CustomBigButton(
              text: '예약 취소',
              onPressed: () {}, //TTODO 예약 취소 기능 구현
              color: WasherColor.baseGray200,
            ),
            AppGap.h8,
            CustomBigButton(
              text: '${laundryMachineType.text} 시작',
              onPressed: () {}, //TODO: 세탁/건조 시작 기능 구현
              color: WasherColor.mainColor500,
            ),
          ],
        ),
      ],
    );
  }
}

/// 예약 확인 중 상태 - myReservation 의 confirmed 와 동일한 UI
class _ConfirmedByMeBottom extends ConsumerWidget {
  final LaundryMachineType laundryMachineType;
  final String? reservedAt;
  final String? finishedAt;

  const _ConfirmedByMeBottom({
    required this.laundryMachineType,
    this.reservedAt,
    this.finishedAt,
  });

  String _formatCountdown(DateTime? baseTime, DateTime now) {
    if (baseTime == null) return '';
    final DateTime expiryTime = baseTime.add(const Duration(minutes: 3));
    final Duration remaining = expiryTime.difference(now);
    if (remaining.isNegative) return '만료됨';
    final int m = remaining.inMinutes;
    final int s = remaining.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}분 ${s.toString().padLeft(2, '0')}초';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime now =
        ref.watch(clockProvider).asData?.value ?? DateTime.now();
    final DateTime? reservedTime = reservedAt != null
        ? DateTime.tryParse(reservedAt!)
        : null;
    final String countdown = reservedTime != null
        ? _formatCountdown(reservedTime, now)
        : (finishedAt != null
              ? _formatCountdown(DateTime.tryParse(finishedAt!), now)
              : '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '기기에 연결 중입니다. 잠시만 기다려주세요.',
          style: WasherTypography.body2(
            WasherColor.baseGray500,
          ),
        ),
        AppGap.v4,
        Text(
          '예정 완료 시간: $countdown',
          style: WasherTypography.body2(
            WasherColor.baseGray500,
          ),
        ),
        AppGap.v12,
      ],
    );
  }
}

/// 다른 사람이 예약한 상태 - 예약 불가능
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
          '예약 시간: ${DateTimeFormatter.formatToShortWithTime(reservedAt)}',
          style: WasherTypography.body2(WasherColor.baseGray500),
        ),
        AppGap.v4,
        Text(
          '예약 만료까지: ${remainDuration ?? ''}',
          style: WasherTypography.body2(WasherColor.errorColor),
        ),
        AppGap.v4,
        Text(
          '사용 호실: ${room ?? ''}호',
          style: WasherTypography.body2(WasherColor.baseGray500),
        ),
      ],
    );
  }
}

/// 사용 불가 상태 메시지 - 고장 등의 이유로 예약/사용 모두 불가
class _UnavailableBottom extends StatelessWidget {
  final LaundryMachineType laundryMachineType;

  const _UnavailableBottom({required this.laundryMachineType});

  @override
  Widget build(BuildContext context) {
    return Text(
      '${laundryMachineType.text}기 고장으로 인해 당분간 사용이 정지됩니다.',
      style: WasherTypography.body2(
        WasherColor.errorColor,
      ),
    );
  }
}
