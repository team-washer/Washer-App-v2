import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/constants/reservation_durations.dart';
import 'package:washer/core/enums/laundry_machine_type.dart';
import 'package:washer/core/enums/laundry_status.dart';
import 'package:washer/core/enums/machine_state.dart';
import 'package:washer/shared/theme/app_spacing.dart';
import 'package:washer/shared/ui/dialog/dialog_action.dart';
import 'package:washer/shared/ui/dialog/dialog_info_row.dart';
import 'package:washer/shared/ui/dialog/laundry_dialog_actions.dart';
import 'package:washer/shared/ui/dialog/washer_dialog.dart';
import 'package:washer/core/utils/date_time_formatter.dart';
import 'package:washer/core/utils/room_formatter.dart';
import 'package:washer/features/reservation/data/models/local/active_reservation_model.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_status_provider.dart';

/// 기기 현황 다이얼로그. 기기명·상태·사용호실·특이사항을 보여주고,
/// 사용 가능한 기기라면 "예약하기" 액션을 제공한다.
class LaundryStatusDialog extends ConsumerWidget {
  const LaundryStatusDialog({
    super.key,
    required this.machineType,
    required this.machineName,
    required this.machineId,
    required this.isUsed,
    this.isUnavailable = false,
    this.isCleaning = false,
    this.machineState,
    this.roomNumber,
    this.expectedTime,
  });

  final LaundryMachineType machineType;
  final String machineName;
  final int machineId;
  final bool isUsed;
  final bool isUnavailable;
  final bool isCleaning;
  final MachineState? machineState;
  final String? roomNumber;
  final String? expectedTime;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider).asData?.value ?? DateTime.now();
    final activeReservations = ref
        .watch(activeReservationProvider)
        .whenOrNull(
          data: (reservations) => reservations,
        );
    final syncedReservation = _findReservationByMachineId(
      activeReservations,
      machineId,
    );
    final isReserved =
        syncedReservation?.laundryStatus == LaundryStatus.reserved;
    final isAvailable = !isUsed && !isUnavailable;
    final title = machineType == LaundryMachineType.washer
        ? '세탁기 현황'
        : '건조기 현황';
    final statusText = _buildStatusText(
      isUnavailable,
      isUsed,
      machineState,
      isReserved: isReserved,
      isCleaning: isCleaning,
    );
    final roomText = RoomFormatter.formatRoomNumber(
      syncedReservation?.userRoomNumber ?? roomNumber,
    );
    final notesText = _buildNotesText(
      machineType: machineType,
      isUnavailable: isUnavailable,
      isCleaning: isCleaning,
      machineState: machineState,
      expectedTime: syncedReservation?.expectedCompletionTime ?? expectedTime,
      reservedAt: syncedReservation?.reservedAt,
      isReserved: isReserved,
      now: now,
    );

    return Dialog(
      child: WasherDialog(
        title: title,
        confirmText: isAvailable ? '예약하기' : '확인',
        backText: isAvailable ? '취소' : null,
        onConfirmPressed: isAvailable
            ? () => runDialogAction(
                context,
                LaundryDialogActions.reserve(
                  machineName: machineName,
                  machineId: machineId,
                ),
              )
            : null,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppGap.v10,
            DialogInfoRow(label: '기기명', value: machineName),
            AppGap.v8,
            DialogInfoRow(label: '상태', value: statusText),
            AppGap.v10,
            DialogInfoRow(label: '사용호실', value: roomText),
            AppGap.v10,
            DialogInfoRow(label: '특이사항', value: notesText),
            AppGap.v10,
          ],
        ),
      ),
    );
  }

  static String _buildStatusText(
    bool isUnavailable,
    bool isUsed,
    MachineState? machineState, {
    required bool isReserved,
    required bool isCleaning,
  }) {
    if (isUnavailable) return '사용 불가(기기고장)';
    if (isCleaning) return '청소중';
    if (isReserved) return '예약중';
    if (!isUsed) return '사용 가능';
    if (machineState != null) return '사용중 (${machineState.text})';
    return '사용중';
  }

  static String _buildNotesText({
    required LaundryMachineType machineType,
    required bool isUnavailable,
    required bool isCleaning,
    required MachineState? machineState,
    required String? expectedTime,
    required String? reservedAt,
    required bool isReserved,
    required DateTime now,
  }) {
    if (isCleaning) {
      return '청소 중이라 잠시 사용할 수 없습니다.';
    }

    if (isUnavailable) {
      final machineTypeText = machineType == LaundryMachineType.washer
          ? '세탁기'
          : '건조기';
      return '$machineTypeText 사용 불가';
    }

    if (isReserved) {
      final reservedDateTime = DateTimeFormatter.parseServerDateTime(
        reservedAt,
      );
      final reservationExpiryTime = reservedDateTime?.add(
        reservationExpiryDuration,
      );
      if (reservationExpiryTime == null) {
        return '예약 만료까지: 확인 중';
      }

      final formattedReservationTime =
          DateTimeFormatter.formatRemainingTimeToKorean(
            reservationExpiryTime.toIso8601String(),
            now: now,
            expiredText: '만료됨',
          );
      return '예약 만료까지: $formattedReservationTime';
    }

    if (expectedTime == null || expectedTime.trim().isEmpty) return '분석중';

    final formattedExpectedTime = DateTimeFormatter.formatRemainingTimeToKorean(
      expectedTime,
      now: now,
      expiredText: machineState == MachineState.delayWash ? '만료됨' : '완료 예정',
    );

    if (machineState == MachineState.delayWash) {
      return '예약 만료까지: $formattedExpectedTime';
    }
    if (machineType == LaundryMachineType.dryer) {
      return '건조 완료 예정시간: $formattedExpectedTime';
    }
    return '세탁 완료 예정시간: $formattedExpectedTime';
  }

  static ActiveReservationModel? _findReservationByMachineId(
    List<ActiveReservationModel>? reservations,
    int machineId,
  ) {
    return reservations?.firstWhereOrNull(
      (reservation) => reservation.machineId == machineId,
    );
  }
}
