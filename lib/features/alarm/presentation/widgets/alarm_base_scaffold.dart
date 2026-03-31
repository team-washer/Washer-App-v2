import 'package:flutter/material.dart';
import 'package:washer/core/ui/base_scaffold.dart';

/// 알람 메뉴의 기본 낮은 레이아웃
class AlarmBaseScaffold extends StatelessWidget {
  final Widget alarmList;

  const AlarmBaseScaffold({super.key, required this.alarmList});

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      showAppBar: true,
      body: alarmList,
    );
  }
}
