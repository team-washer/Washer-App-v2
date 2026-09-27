import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/features/alarm/presentation/providers/alarm_provider.dart';
import 'package:washer/features/alarm/presentation/widgets/alarm_list_body.dart';
import 'package:washer/shared/theme/app_spacing.dart';
import 'package:washer/shared/theme/washer_color.dart';
import 'package:washer/shared/theme/washer_typography.dart';

/// 알림 화면의 제목과 날짜별 알람 목록을 표시하는 위젯
///
/// 기능:
/// - 화면 진입 시 알람 목록 자동 조회
/// - 화면 이탈 시 서버의 알림 전체 삭제
class AlarmList extends ConsumerStatefulWidget {
  const AlarmList({super.key});

  @override
  ConsumerState<AlarmList> createState() => _AlarmListState();
}

class _AlarmListState extends ConsumerState<AlarmList> {
  // dispose 시점에는 ref 사용이 불안정하므로 notifier를 미리 캡처한다.
  late final AlarmNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = ref.read(alarmProvider.notifier);
    // 알림 화면을 열면 자동으로 목록을 불러온다.
    // (force=false라 이미 로드됐으면 다시 호출하지 않는다.)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _notifier.fetchAlarmList();
    });
  }

  @override
  void dispose() {
    // 알림 화면을 벗어나면 서버의 모든 알림을 삭제한다.
    _notifier.clearAllOnLeave();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(alarmProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '알림',
          style: WasherTypography.subTitle3(
            WasherColor.baseGray800,
          ),
        ),
        AppGap.v16,
        Expanded(child: AlarmListBody(state: state)),
      ],
    );
  }
}
