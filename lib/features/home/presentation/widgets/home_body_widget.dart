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
import 'package:washer/features/user/presentation/viewmodels/my_user_view_model.dart';

class HomeBodyWidget extends ConsumerStatefulWidget {
  const HomeBodyWidget({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomeBodyWidgetState();
}

class _HomeBodyWidgetState extends ConsumerState<HomeBodyWidget>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(machineStatusProvider);
      ref.invalidate(activeReservationProvider);
      ref.invalidate(myUserProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(pollingErrorProvider, (_, message) {
      if (message == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
      ref.read(pollingErrorProvider.notifier).state = null;
    });

    final machineAsync = ref.watch(machineStatusProvider);
    ref.watch(activeReservationProvider);
    ref.watch(myUserProvider);

    return machineAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _HomeErrorView(
        onRetry: () => ref.read(machineStatusProvider.notifier).refresh(),
      ),
      data: (data) => RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(machineStatusProvider.notifier).refresh(),
            ref.read(activeReservationProvider.notifier).refresh(),
            ref.read(myUserProvider.notifier).refresh(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: HomeBaseScaffold(
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
        ),
      ),
    );
  }
}

class _HomeErrorView extends StatelessWidget {
  const _HomeErrorView({required this.onRetry});

  final VoidCallback onRetry;

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



