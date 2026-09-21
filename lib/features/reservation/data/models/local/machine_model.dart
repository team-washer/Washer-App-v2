import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:washer/core/enums/machine_state.dart';

part 'machine_model.freezed.dart';
part 'machine_model.g.dart';

/// 기기 배치도상의 좌/우 위치.
enum MachineSide { left, right }

/// 기기 이름(예: Washer-3F-L1)에서 파싱한 층/좌우/번호 정보.
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

/// 서버가 내려주는 세탁기/건조기 한 대의 상태.
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

  // 운전 중이면 reservationId가 남아있어도 예약이 아니라 사용 중으로 본다.
  bool get isReserved =>
      !isUnavailable &&
      !isInUse &&
      (hasReservation || normalizedAvailability == 'RESERVED');

  // 운전중 판정은 서버 availability 기준. (#228: SmartThings operatingState 판정 제거)
  // AVAILABLE=미사용, RESERVED=예약, 그 외(UNAVAILABLE)=운전중.
  // 남은 시간 카운트다운은 서버가 내려주는 expectedCompletionTime을 그대로 사용한다.
  bool get isInUse =>
      !isUnavailable &&
      normalizedAvailability != 'AVAILABLE' &&
      normalizedAvailability != 'RESERVED';

  // 예약 가능 = 고장 아님 + 예약 안 됨 + 사용 중 아님.
  bool get isAvailable => !isUnavailable && !isReserved && !isInUse;
}

/// `machines/status` 응답. 전체 기기 목록과 개수.
@freezed
abstract class MachineStatusResponse with _$MachineStatusResponse {
  const factory MachineStatusResponse({
    required List<MachineModel> machines,
    required int totalCount,
  }) = _MachineStatusResponse;

  factory MachineStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$MachineStatusResponseFromJson(json);
}
