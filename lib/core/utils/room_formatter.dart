class RoomFormatter {
  const RoomFormatter._();

  static const Set<int> supportedFloors = {3, 4, 5};

  static String formatRoomNumber(String? roomNumber) {
    final formattedRoom = formatRoom(roomNumber);
    if (formattedRoom == null || formattedRoom.isEmpty) {
      return '없음';
    }

    return formattedRoom;
  }

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
