import 'package:flutter_test/flutter_test.dart';
import 'package:washer/core/enums/machine_state.dart';
import 'package:washer/features/reservation/data/models/local/laundry_machine_model.dart';

void main() {
  group('MachineModel placement', () {
    test('parses floor side and number from machine name', () {
      const model = MachineModel(
        machineId: 1,
        name: 'Washer-3F-L1',
        type: 'WASHER',
        status: 'NORMAL',
        availability: 'AVAILABLE',
      );

      expect(model.placement, isNotNull);
      expect(model.placement!.floor, '3F');
      expect(model.placement!.side, MachineSide.left);
      expect(model.placement!.number, 1);
      expect(model.floorNumber, 3);
    });

    test('returns null placement for unexpected name', () {
      const model = MachineModel(
        machineId: 1,
        name: 'Laundry Room A',
        type: 'WASHER',
        status: 'NORMAL',
        availability: 'AVAILABLE',
      );

      expect(model.placement, isNull);
      expect(model.floorNumber, isNull);
    });
  });

  group('MachineModel state helpers', () {
    test('treats reserved machine as unavailable for use', () {
      const model = MachineModel(
        machineId: 1,
        name: 'Washer-3F-L1',
        type: 'WASHER',
        status: 'NORMAL',
        availability: 'RESERVED',
        reservationId: 100,
      );

      expect(model.hasReservation, isTrue);
      expect(model.isAvailable, isFalse);
      expect(model.isReserved, isTrue);
      expect(model.isInUse, isFalse);
    });

    test('treats running machine as in use', () {
      const model = MachineModel(
        machineId: 1,
        name: 'Dryer-4F-R2',
        type: 'DRYER',
        status: 'NORMAL',
        availability: 'UNAVAILABLE',
        operatingState: 'RUN',
      );

      expect(model.machineState, MachineState.run);
      expect(model.isUnavailable, isFalse);
      expect(model.isAvailable, isFalse);
      expect(model.isInUse, isTrue);
    });

    test('treats finished machine as not in use', () {
      const model = MachineModel(
        machineId: 1,
        name: 'Dryer-4F-R2',
        type: 'DRYER',
        status: 'NORMAL',
        availability: 'UNAVAILABLE',
        operatingState: 'FINISHED',
      );

      expect(model.machineState, MachineState.finished);
      expect(model.isInUse, isFalse);
    });

    test(
      'treats unavailable status as not in use even without operating state',
      () {
        const model = MachineModel(
          machineId: 1,
          name: 'Dryer-4F-R2',
          type: 'DRYER',
          status: 'ERROR',
          availability: 'UNAVAILABLE',
        );

        expect(model.isUnavailable, isTrue);
        expect(model.isInUse, isFalse);
      },
    );
  });
}
