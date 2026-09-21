import 'package:flutter_test/flutter_test.dart';
import 'package:washer/core/enums/reservation_state.dart';
import 'package:washer/features/reservation/data/models/local/machine_model.dart';

MachineModel _machine({
  required String availability,
  String status = 'NORMAL',
  int? reservationId,
}) {
  return MachineModel(
    machineId: 1,
    name: 'Washer-3F-L1',
    type: 'WASHER',
    status: status,
    availability: availability,
    reservationId: reservationId,
  );
}

void main() {
  group('MachineModel availability=CLEANING', () {
    test('청소중이면 예약 가능도 운전중도 아니다', () {
      final machine = _machine(availability: 'CLEANING');

      expect(machine.isCleaning, isTrue);
      expect(machine.isAvailable, isFalse);
      expect(machine.isInUse, isFalse);
      expect(machine.isReserved, isFalse);
      expect(machine.isUnavailable, isFalse);
    });

    test('reservationId가 남아 있어도 예약 상태가 아니라 청소중으로 본다', () {
      final machine = _machine(availability: 'CLEANING', reservationId: 10);

      expect(machine.isCleaning, isTrue);
      expect(machine.isReserved, isFalse);
    });

    test('대소문자·공백이 달라도 청소중으로 본다', () {
      expect(_machine(availability: ' cleaning ').isCleaning, isTrue);
    });

    test('고장(status != NORMAL)이면 청소중보다 고장이 우선한다', () {
      final machine = _machine(availability: 'CLEANING', status: 'MALFUNCTION');

      expect(machine.isUnavailable, isTrue);
      expect(machine.isCleaning, isFalse);
    });

    test('다른 availability 판정은 그대로다', () {
      expect(_machine(availability: 'AVAILABLE').isAvailable, isTrue);
      expect(_machine(availability: 'RESERVED').isReserved, isTrue);
      expect(_machine(availability: 'IN_USE').isInUse, isTrue);
      expect(_machine(availability: 'UNAVAILABLE').isInUse, isTrue);
    });
  });

  group('ReservationState.cleaning', () {
    test('문구와 색상이 정의돼 있다', () {
      expect(ReservationState.cleaning.label, '청소중');
      expect(
        ReservationState.cleaning.color,
        ReservationState.available.color,
      );
    });
  });
}
