import 'package:flutter/material.dart';
import 'package:washer/core/ui/base_scaffold.dart';

class AlarmBaseScaffold extends StatelessWidget {
  final Widget body;

  const AlarmBaseScaffold({super.key, required this.body});

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(body: body);
  }
}
