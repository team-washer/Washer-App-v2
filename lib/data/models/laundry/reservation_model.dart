class ReservationModel {
  final String id;
  final String machineId;
  final String machineType; // "washer" | "dryer"
  final int floor;
  final String room;
  final String reservedAt;
  final String? remainDuration;

  const ReservationModel({
    required this.id,
    required this.machineId,
    required this.machineType,
    required this.floor,
    required this.room,
    required this.reservedAt,
    this.remainDuration,
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) =>
      ReservationModel(
        id: json['id'] as String,
        machineId: json['machineId'] as String,
        machineType: json['machineType'] as String,
        floor: json['floor'] as int,
        room: json['room'] as String,
        reservedAt: json['reservedAt'] as String,
        remainDuration: json['remainDuration'] as String?,
      );
}

class CreateReservationRequest {
  final String machineId;
  final String room;

  const CreateReservationRequest({
    required this.machineId,
    required this.room,
  });

  Map<String, dynamic> toJson() => {
        'machineId': machineId,
        'room': room,
      };
}
