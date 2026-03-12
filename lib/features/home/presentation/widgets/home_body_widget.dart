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

/// 홈 화면의 주요 컨텐츠 영역 — 세탁기/건조기 현황 표시
/// 
/// 기능:
/// - 예약/사용 중 기기 현황 조회 (캐시 기반, 초기 로드 시만 API 호출)
/// - 앱 포그라운드 진입 시 자동 갱신 (생명주기 감지)
/// - Pull-to-Refresh 지원 (사용자가 수동으로 새로고침)
/// - 에러 메시지 스낵바 표시
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

  /// 앱 생명주기 감지 — 포그라운드 진입 시 자동 갱신
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 앱이 백그라운드에서 포그라운드로 돌아올 때 데이터 새로고침
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(machineStatusProvider);       // 기기 상태 캐시 무효화
      ref.invalidate(activeReservationProvider);   // 현재 예약 정보 캐시 무효화
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

/// 기기 정보 로드 실패 시 예래 내용 초례
/// 미왍 단추 및 상세 내용 제공
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
