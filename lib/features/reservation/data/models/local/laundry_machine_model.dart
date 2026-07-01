import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:washer/core/enums/machine_state.dart';

part 'laundry_machine_model.freezed.dart';
part 'laundry_machine_model.g.dart';

enum MachineSide { left, right }

class MachinePlacement {
  const MachinePlacement({
    required this.floor,
    required this.side,
    required this.number,
  });

  final String floor;
  final MachineSide side;
  final int number;
}

@freezed
abstract class MachineModel with _$MachineModel {
  const MachineModel._();

  const factory MachineModel({
    required int machineId,
    required String name,
    required String type,
    required String status,
    required String availability,
    String? operatingState,
    String? jobState,
    String? switchStatus,
    String? expectedCompletionTime,
    int? remainingMinutes,
    int? reservationId,
    int? userId,
    String? userStudentId,
    String? userName,
    String? roomNumber,
    // 클라이언트가 SmartThings 상태를 직접 조회할 때 사용하는 기기 식별자.
    // 서버 `/machines/status` 응답에 포함되어 내려온다.
    String? smartThingsDeviceId,
  }) = _MachineModel;

  factory MachineModel.fromJson(Map<String, dynamic> json) =>
      _$MachineModelFromJson(json);

  /// "Washer-3F-L1" → 3
  static final RegExp _placementPattern = RegExp(
    r'^.+-(\d+F)-([LR])(\d+)$',
    caseSensitive: false,
  );

  MachinePlacement? get placement {
    final match = _placementPattern.firstMatch(name.trim());
    if (match == null) {
      return null;
    }

    final sideValue = match.group(2)?.toUpperCase();
    final number = int.tryParse(match.group(3) ?? '');
    if (sideValue == null || number == null) {
      return null;
    }

    return MachinePlacement(
      floor: match.group(1)!.toUpperCase(),
      side: sideValue == 'L' ? MachineSide.left : MachineSide.right,
      number: number,
    );
  }

  int? get floorNumber {
    final floor = placement?.floor;
    if (floor == null) {
      return null;
    }

    return int.tryParse(floor.replaceAll('F', ''));
  }

  String get normalizedAvailability => availability.trim().toUpperCase();

  String get normalizedStatus => status.trim().toUpperCase();

  String? get normalizedOperatingState {
    final value = operatingState?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }

    return value.toLowerCase().replaceAll('_', '');
  }

  MachineState? get machineState =>
      MachineStateExt.fromString(normalizedOperatingState);

  bool get hasReservation => (reservationId ?? 0) > 0;

  bool get isUnavailable => normalizedStatus != 'NORMAL';

  bool get isReserved => hasReservation || normalizedAvailability == 'RESERVED';

  // 운전중 판정은 서버 availability 기준. (#228: SmartThings operatingState 판정 제거)
  // AVAILABLE=미사용, RESERVED=예약, 그 외(UNAVAILABLE)=운전중.
  // 남은 시간 카운트다운은 계속 SmartThings expectedCompletionTime 오버레이를 사용한다.
  bool get isInUse {
    if (isUnavailable) {
      return false;
    }

    return normalizedAvailability != 'AVAILABLE' && !isReserved;
  }

  // 예약 가능 = 고장 아님 + 예약 안 됨 + 사용 중 아님.
  bool get isAvailable => !isUnavailable && !isReserved && !isInUse;
}

@freezed
abstract class MachineStatusResponse with _$MachineStatusResponse {
  const factory MachineStatusResponse({
    required List<MachineModel> machines,
    required int totalCount,
  }) = _MachineStatusResponse;

  factory MachineStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$MachineStatusResponseFromJson(json);
}
