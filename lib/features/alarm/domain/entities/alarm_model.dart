class AlarmModel {
  final String id;
  final String
  status; // "washComplete" | "dryComplete" | "washerError" | "dryerError" | "usageWarning"
  final String time;
  final String description;
  final String? reason;

  const AlarmModel({
    required this.id,
    required this.status,
    required this.time,
    required this.description,
    this.reason,
  });

  factory AlarmModel.fromJson(Map<String, dynamic> json) => AlarmModel(
    id: json['id'] as String,
    status: json['status'] as String,
    time: json['time'] as String,
    description: json['description'] as String,
    reason: json['reason'] as String?,
  );
}
