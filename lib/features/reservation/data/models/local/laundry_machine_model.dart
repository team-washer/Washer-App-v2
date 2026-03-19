import 'package:freezed_annotation/freezed_annotation.dart';

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

  bool get isAvailable => availability == 'AVAILABLE';
  bool get isUnavailable => status != 'NORMAL';
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
