import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/enums/laundry_machine_type.dart';
import 'package:washer/core/enums/laundry_status.dart';
import 'package:washer/core/theme/color.dart';
import 'package:washer/core/theme/spacing.dart';
import 'package:washer/core/theme/typography.dart';
import 'package:washer/core/ui/buttons/custom_small_button.dart';
import 'package:washer/core/ui/reservation_state_widget.dart';
import 'package:washer/features/home/presentation/viewmodels/home_view_model.dart';
import 'package:washer/features/reservation/data/models/active_reservation_model.dart';

part 'local_widgets/my_machine_card.dart';
part 'local_widgets/my_reservation_card.dart';
part 'local_widgets/reservation_card.dart';
part 'local_widgets/reservation_body.dart';
part 'local_widgets/reservation_bottom_section.dart';

class HomeMyReservationWidget extends ConsumerWidget {
  const HomeMyReservationWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservationAsync = ref.watch(activeReservationProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${reservationAsync.whenOrNull(data: (r) => r?.userRoomNumber) ?? ''}호 예약 현황',
          style: WasherTypography.h2(),
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
                ? _MyMachineCard(reservation: reservation)
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
