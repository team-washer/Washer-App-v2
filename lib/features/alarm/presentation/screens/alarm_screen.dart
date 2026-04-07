import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/theme/color.dart';
import 'package:washer/features/alarm/presentation/widgets/alarm_list_widget.dart';

/// 알람 화면 — 세탁/건조 완료 알람 리스트
///
/// AlarmListWidget으로 이루어져 있으므로 최상위 화면 역할
class AlarmScreen extends ConsumerWidget {
  const AlarmScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: WasherColor.backgroundColor,
      child: const AlarmListWidget(),
    );
  }
}
