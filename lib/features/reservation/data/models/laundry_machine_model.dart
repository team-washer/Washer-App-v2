class LaundrymachineModel {
  final String id;
  final String machineType; // "washer" | "dryer"
  final int floor;
  final int number;
  final String side;
  final String
  state; // "inUse" | "available" | "reservedByMe" | "reservedByOther" | "unavailable"
  final String? room;
  final String? reservedAt;
  final String? remainDuration;
  final String? finishedAt;

  const LaundrymachineModel({
    required this.id,
    required this.machineType,
    required this.floor,
    required this.number,
    required this.side,
    required this.state,
    this.room,
    this.reservedAt,
    this.remainDuration,
    this.finishedAt,
  });

  factory LaundrymachineModel.fromJson(Map<String, dynamic> json) =>
      LaundrymachineModel(
        id: json['id'] as String,
        machineType: json['machineType'] as String,
        floor: json['floor'] as int,
        number: json['number'] as int,
        side: json['side'] as String? ?? '',
        state: json['state'] as String,
        room: json['room'] as String?,
        reservedAt: json['reservedAt'] as String?,
        remainDuration: json['remainDuration'] as String?,
        finishedAt: json['finishedAt'] as String?,
      );
}
