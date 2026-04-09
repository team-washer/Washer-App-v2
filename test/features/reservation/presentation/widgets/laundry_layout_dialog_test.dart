import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:washer/core/enums/laundry_machine_type.dart';
import 'package:washer/features/reservation/data/models/local/laundry_machine_model.dart';
import 'package:washer/features/reservation/presentation/widgets/laundry_layout_dialog.dart';

void main() {
  testWidgets(
    'LaundryLayoutDialog renders floor layout in descending row order',
    (WidgetTester tester) async {
      final machines = [
        const MachineModel(
          machineId: 1,
          name: 'Washer-3F-L1',
          type: 'WASHER',
          status: 'NORMAL',
          availability: 'AVAILABLE',
        ),
        const MachineModel(
          machineId: 2,
          name: 'Washer-3F-L2',
          type: 'WASHER',
          status: 'NORMAL',
          availability: 'RESERVED',
        ),
        const MachineModel(
          machineId: 3,
          name: 'Washer-3F-L3',
          type: 'WASHER',
          status: 'NORMAL',
          availability: 'IN_USE',
        ),
        const MachineModel(
          machineId: 4,
          name: 'Washer-3F-R1',
          type: 'WASHER',
          status: 'NORMAL',
          availability: 'AVAILABLE',
        ),
        const MachineModel(
          machineId: 5,
          name: 'Washer-3F-R2',
          type: 'WASHER',
          status: 'NORMAL',
          availability: 'RESERVED',
        ),
        const MachineModel(
          machineId: 6,
          name: 'Washer-3F-R3',
          type: 'WASHER',
          status: 'NORMAL',
          availability: 'AVAILABLE',
        ),
      ];

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(393, 852),
          builder: (_, __) => MaterialApp(
            home: Scaffold(
              body: LaundryLayoutDialog(
                laundryMachineType: LaundryMachineType.washer,
                floor: 3,
                machines: machines,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('세탁 배치도'), findsOneWidget);
      expect(find.text('창문'), findsOneWidget);
      expect(find.text('출입문'), findsOneWidget);

      final leftTop = tester.getTopLeft(find.text('Washer-3F-L3'));
      final leftBottom = tester.getTopLeft(find.text('Washer-3F-L1'));
      final rightTop = tester.getTopLeft(find.text('Washer-3F-R3'));
      final rightBottom = tester.getTopLeft(find.text('Washer-3F-R1'));

      expect(leftTop.dy, lessThan(leftBottom.dy));
      expect(rightTop.dy, lessThan(rightBottom.dy));
    },
  );
}
