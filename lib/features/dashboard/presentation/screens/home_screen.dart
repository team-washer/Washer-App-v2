import 'package:flutter/material.dart';
import 'package:washer/features/dashboard/presentation/widgets/home_body_widget.dart';

/// 홈 화면 — 기계 현황 및 예약 정보를 표시
///
/// 최상위 화면으로 HomeBodyWidget으로 구성
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeBodyWidget();
  }
}
