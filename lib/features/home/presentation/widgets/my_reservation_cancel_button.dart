import 'package:flutter/material.dart';
import 'package:washer/core/enums/laundry_action_type.dart';
import 'package:washer/core/enums/laundry_machine_type.dart';
import 'package:washer/core/enums/laundry_status.dart';
import 'package:washer/shared/theme/washer_color.dart';
import 'package:washer/shared/ui/buttons/washer_small_button.dart';
import 'package:washer/shared/ui/dialog/laundry_action_dialog.dart';

/// 예약 카드 하단의 "예약 취소" 버튼.
/// 내 예약이면서 예약(reserved) 상태일 때만 표시되고, 그 외에는 빈 위젯이다.
class MyReservationCancelButton extends StatelessWidget {
  const MyReservationCancelButton({
    super.key,
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
