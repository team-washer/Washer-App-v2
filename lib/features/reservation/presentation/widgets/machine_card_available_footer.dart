import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/enums/laundry_machine_type.dart';
import 'package:washer/core/utils/app_logger.dart';
import 'package:washer/features/report/presentation/widgets/report_broken_dialog.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_status_provider.dart';
import 'package:washer/features/reservation/presentation/widgets/machine_card_layout_helpers.dart';
import 'package:washer/shared/theme/washer_color.dart';
import 'package:washer/shared/theme/washer_icon.dart';
import 'package:washer/shared/theme/app_spacing.dart';
import 'package:washer/shared/theme/washer_typography.dart';
import 'package:washer/shared/ui/buttons/washer_big_button.dart';

/// 예약 가능 상태의 카드 하단. 예약 버튼과 고장 신고 버튼을 보여준다.
class MachineCardAvailableFooter extends StatelessWidget {
  const MachineCardAvailableFooter({
    super.key,
    required this.laundryMachineType,
    this.onReserve,
    required this.machineId,
    required this.machineName,
    this.trailing,
  });

  final LaundryMachineType laundryMachineType;
  final VoidCallback? onReserve;
  final int machineId;
  final String machineName;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isReserveEnabled = onReserve != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        withTrailing(
          Text(
            '미사용 중',
            style: WasherTypography.body2(WasherColor.baseGray500),
          ),
          trailing,
        ),
        AppGap.v12,
        Row(
          children: [
            Expanded(
              child: WasherBigButton(
                text: '예약',
                onPressed: onReserve,
                color: isReserveEnabled
                    ? WasherColor.mainColor400
                    : WasherColor.baseGray300,
              ),
            ),
            AppGap.h8,
            WasherIconButton(
              type: WasherIconType.warningCircle,
              color: WasherColor.errorColor,
              size: 33,
              padding: EdgeInsets.zero,
              onTap: () {
                // 다이얼로그가 닫힌 뒤에도 안전하도록 container를 미리 캡처한다.
                final container = ProviderScope.containerOf(context);
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    child: ReportBrokenDialog(
                      machineId: machineId,
                      deviceId: machineName,
                      onReported: () => _refreshAfterReport(container),
                    ),
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

/// 고장 신고가 접수되면 기기 상태와 활성 예약을 다시 불러온다.
///
/// report feature는 예약 상태를 알지 않으므로 이 갱신은 호출한 쪽(reservation)이
/// 맡는다. 새로고침 실패는 신고 결과에 영향을 주지 않도록 로그만 남긴다.
void _refreshAfterReport(ProviderContainer container) {
  unawaited(
    Future.wait([
      container.read(machineStatusProvider.notifier).refresh(),
      container.read(activeReservationProvider.notifier).refresh(),
    ]).catchError((Object error, StackTrace stackTrace) {
      AppLogger.error(
        '고장 신고 후 상태 새로고침 중 오류가 발생했습니다.',
        name: 'MachineCardAvailableFooter',
        error: error,
        stackTrace: stackTrace,
      );
      return <void>[];
    }),
  );
}
