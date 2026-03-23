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
    String? roomNumber,
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

  bool get isAvailable =>
      normalizedAvailability == 'AVAILABLE' && !hasReservation;

  bool get isUnavailable => normalizedStatus != 'NORMAL';

  bool get isReserved => hasReservation || normalizedAvailability == 'RESERVED';

  bool get isInUse {
    if (isUnavailable || isAvailable) {
      return false;
    }

    final currentState = machineState;
    if (currentState != null) {
      return currentState != MachineState.delayWash &&
          currentState != MachineState.none &&
          currentState != MachineState.stop &&
          currentState != MachineState.finished;
    }

    // 서버가 operatingState 없이 예약 불가 상태만 내려주는 경우가 있습니다.
    // 이때 reservationId도 없으면 "예약 중"이 아니라 실제 "사용 중"으로 간주합니다.
    return !hasReservation;
  }
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
