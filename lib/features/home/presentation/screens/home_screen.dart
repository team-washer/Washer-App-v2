import 'package:flutter/material.dart';
import 'package:washer/core/enums/laundry_machine_type.dart';
import 'package:washer/core/enums/laundry_status.dart';
import 'package:washer/core/theme/spacing.dart';
import 'package:washer/features/home/presentation/widgets/home_section_header_widget.dart';
import 'package:washer/features/home/presentation/widgets/laundry_reservation_status_item.dart';
import 'package:washer/features/home/presentation/widgets/my_reservation_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final itemRatio = 170 / 52;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeSectionTitleWidget(title: '301호 예약 현황'),
          // TODO: 예약 없을 때 EmptyReservationWidget() 표시로 교체
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: MyReservationWidget(
              laundryMachineType: LaundryMachineType.dryer,
              laundryStatus: LaundryStatus.waiting,
              machine: 'Dryer-3F-L1',
              reservedAt: '25.8.18. 00:45:03',
              remainDuration: '00:02:32',
            ),
          ),
          HomeSectionHeaderWidget(
            title: '세탁기 예약 현황',
            onViewAll: () {},
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
          HomeSectionHeaderWidget(
            title: '건조기 예약 현황',
            onViewAll: () {},
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
