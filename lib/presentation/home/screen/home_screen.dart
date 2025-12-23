import 'package:flutter/material.dart';
import 'package:project_setting/core/enums/laundry_machine_type.dart';
import 'package:project_setting/core/enums/laundry_status.dart';
import 'package:project_setting/core/theme/color.dart';
import 'package:project_setting/core/theme/icon.dart';
import 'package:project_setting/core/theme/spacing.dart';
import 'package:project_setting/core/theme/typography.dart';

import '../widgets/laundry_reservation_status_item.dart';
import '../widgets/my_reservation_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    bool reservationEmpty = false;
    final itemRatio = 170 / 52;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReservationSectionTitle(title: '301호 예약 현황'),
          // 임시..
          reservationEmpty
              ? EmptyReservationMessage()
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: MyReservationWidget(
                    laundryMachineType: LaundryMachineType.dryer,
                    laundryStatus: LaundryStatus.waiting,
                    machine: 'Dryer-3F-L1',
                    reservedAt: '25.8.18. 00:45:03',
                    remainDuration: '00:02:32',
                  ),
                ),
          ReservationSectionHeader(
            title: '세탁기 예약 현황',
            onViewAll: () {
              // 전체보기 이동
            },
          ),
          const SizedBox(height: AppSpacing.v16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.v8,
              mainAxisSpacing: AppSpacing.h8,
              childAspectRatio: itemRatio,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
              return LaundryReservationStatusItem(
                machineType: LaundryMachineType.washer,
                floor: 3,
                number: index + 1,
                side: '',
                isUsed: false,
              );
            },
          ),
          const SizedBox(height: AppSpacing.v24),
          ReservationSectionHeader(
            title: '건조기 예약 현황',
            onViewAll: () {
              // 전체보기 이동
            },
          ),
          const SizedBox(height: AppSpacing.v16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.v8,
              mainAxisSpacing: AppSpacing.h8,
              childAspectRatio: itemRatio,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
              return LaundryReservationStatusItem(
                machineType: LaundryMachineType.dryer,
                floor: 3,
                number: index + 1,
                side: '',
                isUsed: false,
              );
            },
          ),
        ],
      ),
    );
  }
}

class ReservationSectionTitle extends StatelessWidget {
  final String title;

  const ReservationSectionTitle({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: WasherTypography.h2(),
    );
  }
}

class EmptyReservationMessage extends StatelessWidget {
  const EmptyReservationMessage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Text(
          '현재 예약하거나 사용중인 기기가 없습니다.',
          style: WasherTypography.body1(WasherColor.baseGray300),
        ),
      ),
    );
  }
}

class ViewAllButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String label;

  const ViewAllButton({
    super.key,
    this.onTap,
    this.label = '전체보기',
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: WasherTypography.body2(
              WasherColor.baseGray300,
            ),
          ),
          const SizedBox(width: 4),
          WasherIcon(
            type: WasherIconType.back,
            size: 16,
            color: WasherColor.baseGray300,
          ),
        ],
      ),
    );
  }
}

class ReservationSectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;

  const ReservationSectionHeader({
    super.key,
    required this.title,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReservationSectionTitle(title: title),
        ViewAllButton(
          onTap: onViewAll,
        ),
      ],
    );
  }
}
