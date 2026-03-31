import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/features/alarm/presentation/widgets/alarm_base_scaffold.dart';
import 'package:washer/features/alarm/presentation/viewmodels/alarm_view_model.dart';
import 'package:washer/features/alarm/presentation/widgets/alarm_list_widget.dart';

/// 알람 화면 — 세탁/건조 완료 알람 리스트
///
/// AlarmListWidget으로 이루어져 있으므로 최상위 화면 역할
class AlarmScreen extends ConsumerStatefulWidget {
  const AlarmScreen({super.key});

  @override
  ConsumerState<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends ConsumerState<AlarmScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(alarmViewModelProvider.notifier).fetchAlarmList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const AlarmBaseScaffold(
      alarmList: AlarmListWidget(),
    );
  }
}
