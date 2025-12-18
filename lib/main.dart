import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:project_setting/core/enums/laundry_action_type.dart';
import 'package:project_setting/core/enums/laundry_machine_type.dart';
import 'package:project_setting/core/enums/machine_state.dart';
import 'package:project_setting/firebase_options.dart';
import 'package:project_setting/presentation/common/dialog/laundry_action_dialog.dart';
import 'package:project_setting/presentation/common/dialog/laundry_status_dialog.dart';
import 'package:project_setting/presentation/home/widgets/laundry_reservation_status_item.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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

class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('다이얼로그 테스트'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '세탁기 클릭 → 상태 다이얼로그',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => _showStatusDialog(
                          context,
                          LaundryMachineType.washer,
                          3,
                          'L',
                          1,
                          false,
                        ),
                        child: LaundryReservationStatusItem(
                          machineType: LaundryMachineType.washer,
                          floor: 3,
                          side: 'L',
                          number: 1,
                          isUsed: false,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => _showStatusDialog(
                          context,
                          LaundryMachineType.washer,
                          3,
                          'L',
                          2,
                          true,
                          machineState: MachineState.spin,
                          roomNumber: '503호',
                          expectedTime: '25.08.18. 01:24',
                        ),
                        child: LaundryReservationStatusItem(
                          machineType: LaundryMachineType.washer,
                          floor: 3,
                          side: 'L',
                          number: 2,
                          isUsed: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => _showStatusDialog(
                          context,
                          LaundryMachineType.dryer,
                          3,
                          'R',
                          1,
                          false,
                        ),
                        child: LaundryReservationStatusItem(
                          machineType: LaundryMachineType.dryer,
                          floor: 3,
                          side: 'R',
                          number: 1,
                          isUsed: false,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => _showStatusDialog(
                          context,
                          LaundryMachineType.dryer,
                          3,
                          'R',
                          2,
                          true,
                          machineState: MachineState.aIDrying,
                          roomNumber: '401호',
                        ),
                        child: LaundryReservationStatusItem(
                          machineType: LaundryMachineType.dryer,
                          floor: 3,
                          side: 'R',
                          number: 2,
                          isUsed: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              '액션 다이얼로그 테스트',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showActionDialog(
                context,
                LaundryActionType.reserve,
              ),
              child: const Text('예약 다이얼로그'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _showActionDialog(
                context,
                LaundryActionType.reportBroken,
              ),
              child: const Text('고장신고 다이얼로그'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _showActionDialog(
                context,
                LaundryActionType.cancelReservation,
              ),
              child: const Text('예약 취소 다이얼로그'),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusDialog(
    BuildContext context,
    LaundryMachineType machineType,
    int floor,
    String side,
    int number,
    bool isUsed, {
    MachineState? machineState,
    String? roomNumber,
    String? expectedTime,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: LaundryStatusDialog(
          machineType: machineType,
          floor: floor,
          side: side,
          number: number,
          isUsed: isUsed,
          machineState: machineState,
          roomNumber: roomNumber,
          expectedTime: expectedTime,
        ),
      ),
    );
  }

  void _showActionDialog(BuildContext context, LaundryActionType actionType) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: LaundryActionDialog(
          actionType: actionType,
          deviceId: 'Washer-3F-L1',
        ),
      ),
    );
  }
}
