import 'package:freezed_annotation/freezed_annotation.dart';

part 'reservation_model.freezed.dart';
part 'reservation_model.g.dart';

@freezed
abstract class ReservationModel with _$ReservationModel {
  const factory ReservationModel({
    required String id,
    required String machineId,
    required String machineType, // "washer" | "dryer"
    required int floor,
    required String room,
    required String reservedAt,
    String? remainDuration,
  }) = _ReservationModel;

  factory ReservationModel.fromJson(Map<String, dynamic> json) =>
      _$ReservationModelFromJson(json);
}
