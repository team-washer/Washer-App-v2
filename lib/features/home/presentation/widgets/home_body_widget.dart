import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/enums/laundry_machine_type.dart';
import 'package:washer/core/theme/color.dart';
import 'package:washer/core/theme/spacing.dart';
import 'package:washer/core/theme/typography.dart';
import 'package:washer/features/home/presentation/viewmodels/home_view_model.dart';
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
  static const Duration _resumeRefreshThrottle = Duration(seconds: 5);

  AppLifecycleState? _lastLifecycleState;
  DateTime? _lastResumeRefreshAt;

  int? _targetFloorFromRoomNumber(String? roomNumber) {
    if (roomNumber == null) {
      return null;
    }

    final normalized = roomNumber.trim();
    if (normalized.isEmpty) {
      return null;
    }

    final digitsOnly = normalized.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length < 3) {
      final floor = int.tryParse(digitsOnly);
      if (floor != null && (floor == 3 || floor == 4)) {
        return floor;
      }
      return null;
    }

    return int.tryParse(digitsOnly.substring(0, digitsOnly.length - 2));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(activeReservationProvider.notifier).ensureLoaded();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final previousState = _lastLifecycleState;
    _lastLifecycleState = state;

    if (state == AppLifecycleState.resumed &&
        previousState != AppLifecycleState.resumed) {
      final now = DateTime.now();
      final lastRefreshAt = _lastResumeRefreshAt;
      final shouldSkipRefresh =
          lastRefreshAt != null &&
          now.difference(lastRefreshAt) < _resumeRefreshThrottle;

      if (shouldSkipRefresh) {
        return;
      }

      _lastResumeRefreshAt = now;
      ref.invalidate(machineStatusProvider);
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
    final myUserAsync = ref.watch(myUserProvider);
    final activeReservationAsync = ref.watch(activeReservationProvider);

    return machineAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _HomeErrorView(
        onRetry: () => ref.read(machineStatusProvider.notifier).refresh(),
      ),
      data: (data) {
        final roomNumber =
            myUserAsync.whenOrNull(data: (user) => user?.roomNumber) ??
            activeReservationAsync.whenOrNull(
              data: (reservations) => reservations.isNotEmpty
                  ? reservations.first.userRoomNumber
                  : null,
            );
        final targetFloor = _targetFloorFromRoomNumber(roomNumber);
        final visibleMachines = targetFloor == null
            ? data.machines
            : data.machines
                  .where((machine) => machine.floorNumber == targetFloor)
                  .toList(growable: false);

        final washerMachines = visibleMachines
            .where(
              (machine) => machine.type == LaundryMachineType.washer.apiValue,
            )
            .toList(growable: false);
        final dryerMachines = visibleMachines
            .where(
              (machine) => machine.type == LaundryMachineType.dryer.apiValue,
            )
            .toList(growable: false);

        return RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              ref.read(machineStatusProvider.notifier).refresh(),
              ref.read(activeReservationProvider.notifier).refresh(),
              ref.read(myUserProvider.notifier).refresh(),
            ]);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(
                child: RepaintBoundary(
                  child: HomeMyReservationWidget(),
                ),
              ),
              SliverToBoxAdapter(child: AppGap.v8),
              HomeMachineSectionSliver(
                machines: washerMachines,
                machineType: LaundryMachineType.washer,
              ),
              SliverToBoxAdapter(child: AppGap.v24),
              HomeMachineSectionSliver(
                machines: dryerMachines,
                machineType: LaundryMachineType.dryer,
              ),
              SliverToBoxAdapter(child: AppGap.v24),
            ],
          ),
        );
      },
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
