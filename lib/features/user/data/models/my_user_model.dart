/// 로그인한 사용자 정보 (id, 이름, 호실).
///
/// 서버 응답의 키 이름이 일정하지 않아 여러 후보 키에서 값을 찾아 채운다.
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

  /// int/num/String 어느 형태로 와도 int로 변환하고, 불가능하면 null을 반환한다.
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

  /// 후보 값 중 공백 제거 후 비어 있지 않은 첫 문자열을 반환한다.
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
