import 'package:flutter/material.dart';
import 'package:washer/core/enums/laundry_machine_type.dart';
import 'package:washer/core/enums/laundry_status.dart';
import 'package:washer/core/utils/user_formatter.dart';
import 'package:washer/features/home/presentation/widgets/my_reservation_status_body.dart';
import 'package:washer/features/reservation/data/models/local/active_reservation_model.dart';
import 'package:washer/shared/theme/app_spacing.dart';
import 'package:washer/shared/theme/washer_color.dart';
import 'package:washer/shared/theme/washer_typography.dart';
import 'package:washer/shared/ui/indicators/status_badge.dart';
import 'package:washer/core/enums/laundry_action_type.dart';
import 'package:washer/shared/ui/buttons/washer_small_button.dart';
import 'package:washer/shared/ui/dialog/laundry_action_dialog.dart';

/// 활성 예약 1건을 보여주는 카드 (기기 정보, 상태 뱃지, 상태별 본문, 취소 버튼)
class MyReservationCard extends StatelessWidget {
  const MyReservationCard({
    super.key,
    required this.reservation,
    required this.isOwnedByMe,
  });

  final ActiveReservationModel reservation;

  /// 내 예약 여부 (다른 사람 예약이면 이용자 정보를 표시하고 취소 버튼을 숨김)
  final bool isOwnedByMe;

  @override
  Widget build(BuildContext context) {
    final expectedCompletionTime = reservation.expectedCompletionTime;
    final hasExpectedCompletionTime =
        expectedCompletionTime != null &&
        expectedCompletionTime.trim().isNotEmpty;

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
              StatusBadge(
                // 사용 중인데 완료 예정 시각이 아직 없으면 "분석중"으로 표시
                label:
                    reservation.laundryStatus == LaundryStatus.inUse &&
                        !hasExpectedCompletionTime
                    ? '분석중'
                    : reservation.laundryStatus.label,
                color: reservation.laundryStatus.color,
              ),
            ],
          ),
          AppGap.v12,
          MyReservationStatusBody(
            laundryMachineType: reservation.machineType,
            laundryStatus: reservation.laundryStatus,
            reservedAt: reservation.reservedAt,
            remainDuration: null,
            finishedAt: reservation.expectedCompletionTime,
          ),
          if (!isOwnedByMe) ...[
            AppGap.v4,
            _buildReservedUserInfo(),
          ],
          _MyReservationCancelButton(
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

  /// 다른 사용자가 이용 중인 예약의 "학번 이름 이용중..." 안내 문구
  Widget _buildReservedUserInfo() {
    final userName = reservation.userName;
    final userLabel =
        UserFormatter.formatUserLabel(
          studentId: reservation.userStudentId,
          userName: userName,
        ) ??
        userName.trim();

    return Text(
      '$userLabel 이용중...',
      style: WasherTypography.body2(WasherColor.baseGray500),
    );
  }
}

/// 예약 카드 하단의 "예약 취소" 버튼.
/// 내 예약이면서 예약(reserved) 상태일 때만 표시되고, 그 외에는 빈 위젯이다.
class _MyReservationCancelButton extends StatelessWidget {
  const _MyReservationCancelButton({
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
          child: WasherSmallButton(
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
