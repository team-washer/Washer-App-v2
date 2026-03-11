import 'package:flutter/material.dart';
import 'package:washer/core/theme/spacing.dart';

class HomeBaseScaffold extends StatelessWidget {
  final Widget myReservation;
  final Widget washerSection;
  final Widget dryerSection;

  const HomeBaseScaffold({
    super.key,
    required this.myReservation,
    required this.washerSection,
    required this.dryerSection,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          myReservation,
          const SizedBox(height: AppSpacing.v8),
          washerSection,
          const SizedBox(height: AppSpacing.v24),
          dryerSection,
        ],
      ),
    );
  }
}
