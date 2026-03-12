import 'package:freezed_annotation/freezed_annotation.dart';

part 'laundry_machine_model.freezed.dart';
part 'laundry_machine_model.g.dart';

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
  int? get floorNumber {
    final match = RegExp(r'(\d+)F').firstMatch(name);
    return match != null ? int.tryParse(match.group(1)!) : null;
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
