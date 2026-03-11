import 'package:flutter/material.dart';
import 'package:washer/core/theme/color.dart';

class AuthBaseScaffold extends StatelessWidget {
  final Widget body;

  const AuthBaseScaffold({super.key, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WasherColor.backgroundColor,
      body: SafeArea(child: body),
    );
  }
}
