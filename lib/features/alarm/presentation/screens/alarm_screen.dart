import 'package:flutter/material.dart';
import 'package:washer/features/alarm/presentation/widgets/alarm_base_scaffold.dart';
import 'package:washer/features/alarm/presentation/widgets/alarm_list_widget.dart';

class AlarmScreen extends StatelessWidget {
  const AlarmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AlarmBaseScaffold(
      alarmList: AlarmListWidget(),
    );
  }
}
