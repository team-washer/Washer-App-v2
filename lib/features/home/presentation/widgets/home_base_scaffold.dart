import 'package:flutter/material.dart';
import 'package:washer/core/theme/spacing.dart';

/// 홈 화면의 기본 레이아웃 구조를 정의하는 스캐폴드
///
/// 구성:
/// - 상단: 내 예약 현황 섹션
/// - 중간: 세탁기 섹션
/// - 하단: 건조기 섹션
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        myReservation,
        AppGap.v8,
        washerSection,
        AppGap.v24,
        dryerSection,
        AppGap.v24,
      ],
    );
  }
}
