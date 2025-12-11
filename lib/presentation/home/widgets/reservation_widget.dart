import 'package:flutter/material.dart';
import 'package:project_setting/core/theme/color.dart';
import 'package:project_setting/core/theme/icon.dart';
import 'package:project_setting/core/theme/typography.dart';
import 'package:project_setting/presentation/common/custom_button.dart';
import 'package:project_setting/presentation/home/widgets/state_widget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const TestScreen(),
    );
  }
}

// ⭐ 테스트용 스크린
class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ReservationWidget 테스트")),
      body: const Center(
        child: ReservationWidget(), // ← 여기에서 테스트됨
      ),
      backgroundColor: Colors.grey.shade200,
    );
  }
}

class ReservationWidget extends StatelessWidget {
  const ReservationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              WasherIcon(
                type: WasherIconType.dryCircle,
                color: WasherColor.mainColor400,
              ),
              SizedBox(width: 8),
              Text('Dryer-3F-L1', style: WasherTypography.subTitle3()),
              StateWidget(text: "대기중", color: WasherColor.mainColor200,),
            ],
          ),
        ],
      ),
    );
  }
}
