import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/enums/laundry_machine_type.dart';
import 'package:washer/core/enums/machine_state.dart';
import 'package:washer/core/theme/spacing.dart';
import 'package:washer/core/theme/typography.dart';
import 'package:washer/core/ui/dialog/washer_dialog.dart';
import 'package:washer/features/reservation/presentation/viewmodels/reservation_view_model.dart';

class LaundryStatusDialog extends ConsumerWidget {
  const LaundryStatusDialog({
    super.key,
    required this.machineType,
    required this.machineName,
    required this.machineId,
    required this.isUsed,
    this.isUnavailable = false,
    this.machineState,
    this.roomNumber,
    this.expectedTime,
  });

  final LaundryMachineType machineType;
  final String machineName;
  final int machineId;
  final bool isUsed;
  final bool isUnavailable;
  final MachineState? machineState;
  final String? roomNumber;
  final String? expectedTime;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAvailable = !isUsed && !isUnavailable;
    final title = machineType == LaundryMachineType.washer
        ? '세탁기 현황'
        : '건조기 현황';
    final statusText = _buildStatusText(isUnavailable, isUsed, machineState);
    final roomText = roomNumber ?? '없음';
    final notesText = _buildNotesText(
      machineType: machineType,
      isUnavailable: isUnavailable,
      machineState: machineState,
      expectedTime: expectedTime,
    );

    return Dialog(
      child: WasherDialog(
        title: title,
        confirmText: isAvailable ? '예약하기' : '확인',
        backText: isAvailable ? '취소' : null,
        onConfirmPressed: isAvailable
            ? () async {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);
                final reservationNotifier = ref.read(
                  reservationViewModelProvider.notifier,
                );

                navigator.pop();

                try {
                  final reservationState = await reservationNotifier.reserve(
                    machineId: machineId,
                  );

                  if (reservationState.status ==
                      ReservationActionStatus.error) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          '예약 실패: ${reservationState.errorMessage}',
                        ),
                      ),
                    );
                    return;
                  }

                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        '$machineName 예약이 완료되었습니다\n5분 이내에 기기를 켜주세요',
                      ),
                    ),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('예약 실패: $e')),
                  );
                }
              }
            : null,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppGap.v10,
            _InfoRow(label: '기기명', value: machineName),
            AppGap.v8,
            _InfoRow(label: '상태', value: statusText),
            AppGap.v10,
            _InfoRow(label: '사용호실', value: roomText),
            AppGap.v10,
            _InfoRow(label: '특이사항', value: notesText),
            AppGap.v10,
          ],
        ),
      ),
    );
  }

  static String _buildStatusText(
    bool isUnavailable,
    bool isUsed,
    MachineState? machineState,
  ) {
    if (isUnavailable) return '사용 불가(기기고장)';
    if (!isUsed) return '사용 가능';
    if (machineState != null) return '사용중 (${machineState.text})';
    return '사용중';
  }

  static String _buildNotesText({
    required LaundryMachineType machineType,
    required bool isUnavailable,
    required MachineState? machineState,
    required String? expectedTime,
  }) {
    if (isUnavailable) {
      final machineTypeText = machineType == LaundryMachineType.washer
          ? '세탁기'
          : '건조기';
      return '$machineTypeText 사용 불가';
    }

    if (expectedTime == null) return '없음';

    if (machineState == MachineState.delayWash) {
      return '예약 만료까지: $expectedTime';
    }
    if (machineType == LaundryMachineType.dryer) {
      return '건조 완료 예정시간: $expectedTime';
    }
    return '세탁 완료 예정시간: $expectedTime';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: WasherTypography.subTitle4(),
        ),
        AppGap.h8,
        Expanded(
          child: Text(
            value,
            style: WasherTypography.body1(),
          ),
        ),
      ],
    );
  }
}
