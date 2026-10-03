/// 호실 번호 표기/층 계산 유틸.
class RoomFormatter {
  const RoomFormatter._();

  /// 세탁실이 있는 층.
  static const Set<int> supportedFloors = {3, 4, 5};

  /// 표시용 호실 문자열. 값이 없으면 '없음'.
  static String formatRoomNumber(String? roomNumber) {
    final formattedRoom = formatRoom(roomNumber);
    if (formattedRoom == null || formattedRoom.isEmpty) {
      return '없음';
    }

    return formattedRoom;
  }

  /// 호실 뒤에 '호'를 붙인다. 값이 비어 있으면 null.
  static String? formatRoom(String? roomNumber) {
    if (roomNumber == null) {
      return null;
    }

    final normalized = roomNumber.trim();
    if (normalized.isEmpty) {
      return null;
    }

    if (normalized.endsWith('호')) {
      return normalized;
    }

    return '$normalized호';
  }

  /// 호실 번호에서 층을 추정한다(예: 412 -> 4). 지원하지 않는 층이면 null.
  static int? floorFromRoomNumber(String? roomNumber) {
    if (roomNumber == null) {
      return null;
    }

    final normalized = roomNumber.trim();
    if (normalized.isEmpty) {
      return null;
    }

    final match = RegExp(r'\d+').firstMatch(normalized);
    if (match == null) {
      return null;
    }
    final digitsOnly = match.group(0)!;

    final int? floor;
    if (digitsOnly.length < 3) {
      floor = int.tryParse(digitsOnly);
    } else {
      floor = int.tryParse(digitsOnly.substring(0, digitsOnly.length - 2));
    }

    if (floor == null || !supportedFloors.contains(floor)) {
      return null;
    }
    return floor;
  }
}
