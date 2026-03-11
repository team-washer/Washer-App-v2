import 'package:flutter/material.dart';
import 'package:washer/core/ui/base_scaffold.dart';

class AlarmBaseScaffold extends StatelessWidget {
  final Widget alarmList;

  const AlarmBaseScaffold({super.key, required this.alarmList});

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(body: alarmList);
  }
}
