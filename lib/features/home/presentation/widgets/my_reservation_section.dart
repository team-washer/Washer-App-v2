import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:washer/features/home/presentation/widgets/my_reservation_card.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_status_provider.dart';
import 'package:washer/features/user/presentation/providers/my_user_provider.dart';
import 'package:washer/shared/theme/app_spacing.dart';
import 'package:washer/shared/theme/washer_color.dart';
import 'package:washer/shared/theme/washer_typography.dart';

/// 홈 화면 상단의 "내 예약 현황" 섹션 — 제목과 활성 예약 카드 가로 목록을 표시
class MyReservationSection extends ConsumerWidget {
  const MyReservationSection({super.key});

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

    // 호실을 알면 "{호실}호 예약 현황", 모르면 "내 예약 현황"
    final normalizedRoomNumber = roomNumber?.trim();
    final title = normalizedRoomNumber == null || normalizedRoomNumber.isEmpty
        ? '내 예약 현황'
        : '$normalizedRoomNumber호 예약 현황';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: WasherTypography.h2(),
        ),
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
                                child: MyReservationCard(
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
