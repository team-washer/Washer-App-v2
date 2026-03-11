import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/enums/laundry_machine_type.dart';
import 'package:washer/core/theme/color.dart';
import 'package:washer/core/theme/spacing.dart';
import 'package:washer/core/theme/typography.dart';
import 'package:washer/features/home/presentation/viewmodels/home_view_model.dart';
import 'package:washer/features/home/presentation/widgets/home_base_scaffold.dart';
import 'package:washer/features/home/presentation/widgets/home_machine_section_widget.dart';
import 'package:washer/features/home/presentation/widgets/home_my_reservation_widget.dart';

class HomeBodyWidget extends ConsumerWidget {
  const HomeBodyWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final machineAsync = ref.watch(machineStatusProvider);

    return machineAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _HomeErrorView(
        onRetry: () => ref.read(machineStatusProvider.notifier).refresh(),
      ),
      data: (data) => HomeBaseScaffold(
        myReservation: const HomeMyReservationWidget(),
        washerSection: HomeMachineSectionWidget(
          machines: data.machines,
          machineType: LaundryMachineType.washer,
        ),
        dryerSection: HomeMachineSectionWidget(
          machines: data.machines,
          machineType: LaundryMachineType.dryer,
        ),
      ),
    );
  }
}

class _HomeErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const _HomeErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '기기 현황을 불러오지 못했습니다.',
            style: WasherTypography.body1(WasherColor.baseGray500),
          ),
          AppGap.v12,
          TextButton(
            onPressed: onRetry,
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}
