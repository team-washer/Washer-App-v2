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
import 'package:washer/features/home/presentation/viewmodels/home_view_model.dart';

/// 현재 예약 현황을 표시하는 위젯
///
/// 기능:
/// - 활성 예약 정보 조회 및 표시
/// - 예약 없을 경우 안내 메시지 표시
/// - 로딩 및 에러 상태 처리
class HomeMyReservationWidget extends ConsumerWidget {
  const HomeMyReservationWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservationAsync = ref.watch(activeReservationProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ReservationTitle(
          roomNumber: reservationAsync.whenOrNull(
            data: (r) => r?.userRoomNumber,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.v16),
          child: reservationAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.v24),
                child: Text(
                  '예약 정보를 불러오지 못했습니다.',
                  style: WasherTypography.body1(WasherColor.baseGray300),
                ),
              ),
            ),
            data: (reservation) => reservation != null
                ? _MyReservationCard(
                    laundryMachineType: reservation.machineType,
                    laundryStatus: reservation.laundryStatus,
                    remainDuration: reservation.actualCompletionTime,
                    machine: reservation.machineName,
                    reservedAt: reservation.reservedAt,
                    finishedAt: reservation.expectedCompletionTime,
                    machineId: reservation.machineId,
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.v24,
                      ),
                      child: Text(
                        '현재 예약하거나 사용중인 기기가 없습니다.',
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

/// 호실 번호와 함께 예약 현황 제목 표시
class _ReservationTitle extends StatelessWidget {
  final String? roomNumber;

  const _ReservationTitle({this.roomNumber});

  @override
  Widget build(BuildContext context) {
    return Text(
      '${roomNumber ?? ''}호 예약 현황',
      style: WasherTypography.h2(),
    );
  }
}

class _MyReservationCard extends StatelessWidget {
  final LaundryMachineType laundryMachineType;
  final LaundryStatus laundryStatus;
  final String machine;
  final String? reservedAt;
  final String? remainDuration;
  final String? finishedAt;
  final int? machineId;

  const _MyReservationCard({
    required this.laundryMachineType,
    required this.laundryStatus,
    required this.machine,
    this.reservedAt,
    this.remainDuration,
    this.finishedAt,
    this.machineId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              laundryMachineType.icon(),
              AppGap.h8,
              Text(
                machine,
                style: WasherTypography.body1(),
              ),
              const Spacer(),
              ReservationStateWidget(
                label: laundryStatus.label,
                color: laundryStatus.color,
              ),
            ],
          ),
          AppGap.v12,
          _Body(
            laundryMachineType: laundryMachineType,
            laundryStatus: laundryStatus,
            reservedAt: reservedAt,
            remainDuration: remainDuration,
            finishedAt: finishedAt,
          ),
          _BottomSection(
            laundryMachineType: laundryMachineType,
            laundryStatus: laundryStatus,
            machineId: machineId,
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final LaundryMachineType laundryMachineType;
  final LaundryStatus laundryStatus;
  final String? reservedAt;
  final String? remainDuration;
  final String? finishedAt;

  const _Body({
    required this.laundryMachineType,
    required this.laundryStatus,
    required this.reservedAt,
    required this.remainDuration,
    required this.finishedAt,
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
        return _ReservedBody(finishedAt: finishedAt);
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

// 예약 대기 상태일 때 예약 시간과 남은 시간 표시
class _WaitingBody extends ConsumerWidget {
  final String? reservedAt;
  final String? remainDuration;

  const _WaitingBody({
    required this.reservedAt,
    required this.remainDuration,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 실시간 시간 업데이트를 위해 clockProvider watch
    ref.watch(clockProvider);

    // remainDuration을 실시간 계산 (서버 시간이 정확한 경우)
    String? updatedRemain = remainDuration;
    if (reservedAt != null) {
      final reservedTime = DateTime.tryParse(reservedAt!);
      if (reservedTime != null) {
        final now = DateTime.now();
        if (reservedTime.isAfter(now)) {
          final remaining = reservedTime.difference(now);
          final minutes = remaining.inMinutes;
          final seconds = remaining.inSeconds % 60;
          updatedRemain =
              '${minutes.toString().padLeft(2, '0')}분 ${seconds.toString().padLeft(2, '0')}초';
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '예약 시간: ${reservedAt ?? ''}',
          style: WasherTypography.body2(WasherColor.baseGray500),
        ),
        AppGap.v4,
        Text(
          '예약 만료까지: ${updatedRemain ?? ''}',
          style: WasherTypography.body2(WasherColor.errorColor),
        ),
        AppGap.v12,
      ],
    );
  }
}

class _ReservedBody extends ConsumerWidget {
  final String? finishedAt;

  const _ReservedBody({this.finishedAt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 실시간 시간 업데이트
    ref.watch(clockProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '기기에 연결 중입니다. 잠시만 기다려주세요.',
          style: WasherTypography.body2(
            WasherColor.baseGray500,
          ),
        ),
      ],
    );
  }
}

// 세탁/건조 시작후 확인이 필요한 상태
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

// 사용중일때 남은 시간 계산 및 표시
class _InUseBody extends ConsumerWidget {
  final LaundryMachineType laundryMachineType;
  final String? finishedAt;

  const _InUseBody({
    required this.laundryMachineType,
    required this.finishedAt,
  });

  String _formatCountdown(DateTime? finishTime, DateTime now) {
    if (finishTime == null) return '';
    final remaining = finishTime.difference(now);
    if (remaining.isNegative) return '완료 예정';
    final h = remaining.inHours;
    final m = remaining.inMinutes % 60;
    final s = remaining.inSeconds % 60;
    if (h > 0) {
      return '$h시간 ${m.toString().padLeft(2, '0')}분 ${s.toString().padLeft(2, '0')}초';
    }
    return '${m.toString().padLeft(2, '0')}분 ${s.toString().padLeft(2, '0')}초';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider).asData?.value ?? DateTime.now();
    final finishTime = finishedAt != null
        ? DateTime.tryParse(finishedAt!)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${laundryMachineType.text} 중...',
          style: WasherTypography.body2(
            WasherColor.baseGray500,
          ),
        ),
        AppGap.v4,
        Text(
          '${laundryMachineType.text} 완료 예정 시간: ${_formatCountdown(finishTime, now)}',
          style: WasherTypography.body2(
            WasherColor.baseGray500,
          ),
        ),
      ],
    );
  }
}

// 세탁/건조가 끝났을 경우
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
          '${laundryMachineType.text} 완료!',
          style: WasherTypography.body2(
            WasherColor.baseGray500,
          ),
        ),
        AppGap.v4,
        Text(
          '${laundryMachineType.text} 완료 시간: ${finishedAt ?? ''}',
          style: WasherTypography.body2(
            WasherColor.baseGray500,
          ),
        ),
      ],
    );
  }
}

// 하단 버튼들 (예약 취소, 시작하기 등) - 상태에 따라 다르게 표시
class _BottomSection extends StatelessWidget {
  final LaundryMachineType laundryMachineType;
  final LaundryStatus laundryStatus;
  final int? machineId;

  const _BottomSection({
    required this.laundryMachineType,
    required this.laundryStatus,
    this.machineId,
  });

  @override
  Widget build(BuildContext context) {
    if (!laundryStatus.needsSpacing) return const SizedBox();

    return Row(
      children: [
        CustomSmallButton(
          text: '예약 취소',
          onPressed: () {
            if (machineId != null) {
              showDialog(
                context: context,
                builder: (context) => LaundryActionDialog(
                  actionType: LaundryActionType.cancelReservation,
                  deviceId: '',
                  machineId: machineId!,
                ),
              );
            }
          },
          color: WasherColor.baseGray200,
        ),
        AppGap.h4,
        CustomSmallButton(
          text: '${laundryMachineType.text} 시작',
          onPressed: () {
            if (machineId != null) {
              showDialog(
                context: context,
                builder: (context) => LaundryActionDialog(
                  actionType: LaundryActionType.reserve,
                  deviceId: '',
                  machineId: machineId!,
                ),
              );
            }
          },
          color: laundryStatus == LaundryStatus.waiting
              ? WasherColor.mainColor500
              : WasherColor.mainColor200,
        ),
      ],
    );
  }
}
