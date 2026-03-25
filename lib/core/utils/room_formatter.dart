class RoomFormatter {
  const RoomFormatter._();

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
}
