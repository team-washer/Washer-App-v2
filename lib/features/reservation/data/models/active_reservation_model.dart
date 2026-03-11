import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:washer/core/enums/laundry_machine_type.dart';
import 'package:washer/core/enums/laundry_status.dart';

part 'active_reservation_model.freezed.dart';
part 'active_reservation_model.g.dart';

@freezed
abstract class ActiveReservationModel with _$ActiveReservationModel {
  const ActiveReservationModel._();

  const factory ActiveReservationModel({
    required int id,
    required int userId,
    required String userName,
    required String userRoomNumber,
    required int machineId,
    required String machineName,
    String? reservedAt,
    String? startTime,
    String? expectedCompletionTime,
    String? actualCompletionTime,
    required String status,
  }) = _ActiveReservationModel;

  factory ActiveReservationModel.fromJson(Map<String, dynamic> json) =>
      _$ActiveReservationModelFromJson(json);

  LaundryMachineType get machineType => machineName.contains('세탁')
      ? LaundryMachineType.washer
      : LaundryMachineType.dryer;

  LaundryStatus get laundryStatus {
    switch (status) {
      case 'WAITING':
        return LaundryStatus.waiting;
      case 'RESERVED':
        return LaundryStatus.reserved;
      case 'NEED_CONFIRM':
        return LaundryStatus.needConfirm;
      case 'IN_USE':
        return LaundryStatus.inUse;
      case 'COMPLETED':
        return LaundryStatus.completed;
      default:
        return LaundryStatus.inUse;
    }
  }
}
