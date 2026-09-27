import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/enums/laundry_machine_type.dart';
import 'package:washer/shared/theme/app_spacing.dart';
import 'package:washer/core/utils/room_formatter.dart';
import 'package:washer/features/alarm/presentation/providers/alarm_provider.dart';
import 'package:washer/features/home/presentation/widgets/home_error_view.dart';
import 'package:washer/features/home/presentation/widgets/machine_status_section.dart';
import 'package:washer/features/home/presentation/widgets/my_reservation_section.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_status_provider.dart';
import 'package:washer/features/user/presentation/providers/my_user_provider.dart';
import 'package:washer/core/network/error.dart';
import 'package:washer/shared/ui/error_toast.dart';

/// 홈 화면 본문 - 내 예약 + 세탁기/건조기 현황을 스크롤 목록으로 표시하고,
/// 앱 resume 시 기기/유저/활성 예약 provider를 갱신한다.
class HomeBody extends ConsumerStatefulWidget {
  const HomeBody({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomeBodyState();
}

class _HomeBodyState extends ConsumerState<HomeBody>
    with WidgetsBindingObserver {
  // resume 갱신 최소 간격 (연속 resume 이벤트로 인한 중복 요청 방지)
  static const Duration _resumeRefreshThrottle = Duration(seconds: 5);

  AppLifecycleState? _lastLifecycleState;
  DateTime? _lastResumeRefreshAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(activeReservationProvider.notifier).ensureLoaded();
      // 앱/홈 진입 시 알람을 불러와 알림 뱃지를 갱신한다.
      // (force=false라 이미 로드됐으면 중복 호출하지 않는다.)
      ref.read(alarmProvider.notifier).fetchAlarmList();
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
      // machineStatusProvider만 갱신하면 활성 예약이 서버에서 완료 처리된 뒤에도
      // 홈 화면 예약 카드가 갱신되지 않을 수 있다(#276).
      ref.read(activeReservationProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AppException?>(pollingErrorProvider, (_, error) {
      if (error == null) return;
      context.showErrorToast(error);
      ref.read(pollingErrorProvider.notifier).state = null;
    });

    final machineAsync = ref.watch(machineStatusProvider);
    final myUserAsync = ref.watch(myUserProvider);
    final activeReservationAsync = ref.watch(activeReservationProvider);

    return machineAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => HomeErrorView(
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
        // 내 호실 기준 층의 기기만 표시 (호실을 알 수 없으면 전체 표시)
        final targetFloor = RoomFormatter.floorFromRoomNumber(roomNumber);
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
              ref
                  .read(alarmProvider.notifier)
                  .fetchAlarmList(
                    force: true,
                  ),
            ]);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(
                child: RepaintBoundary(
                  child: MyReservationSection(),
                ),
              ),
              SliverToBoxAdapter(child: AppGap.v8),
              MachineStatusSection(
                machines: washerMachines,
                machineType: LaundryMachineType.washer,
              ),
              SliverToBoxAdapter(child: AppGap.v24),
              MachineStatusSection(
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
