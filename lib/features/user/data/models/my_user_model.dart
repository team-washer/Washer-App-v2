class MyUserModel {
  const MyUserModel({
    this.id,
    this.name,
    this.roomNumber,
  });

  final int? id;
  final String? name;
  final String? roomNumber;

  factory MyUserModel.fromJson(Map<String, dynamic> json) {
    final room = json['room'];

    return MyUserModel(
      id: _toInt(json['id'] ?? json['userId']),
      name: _firstNonEmptyString([
        json['name'],
        json['userName'],
        json['nickname'],
      ]),
      roomNumber: _firstNonEmptyString([
        json['roomNumber'],
        json['userRoomNumber'],
        json['roomNo'],
        json['dormRoomNumber'],
        json['dormitoryRoomNumber'],
        if (room is Map<String, dynamic>) room['roomNumber'],
        if (room is Map<String, dynamic>) room['number'],
        if (room is String) room,
      ]),
    );
  }

  static int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value);
    }

    return null;
  }

  static String? _firstNonEmptyString(List<dynamic> values) {
    for (final value in values) {
      if (value == null) {
        continue;
      }

      final stringValue = value.toString().trim();
      if (stringValue.isNotEmpty) {
        return stringValue;
      }
    }

    return null;
  }
}
