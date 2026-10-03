/// 사용자가 기기에 대해 수행할 수 있는 동작 종류.
enum LaundryActionType {
  reserve,
  reportBroken,
  cancelReservation,
}

extension LaundryActionTypeExtension on LaundryActionType {
  /// 화면에 표시할 동작 이름.
  String get text {
    switch (this) {
      case LaundryActionType.reserve:
        return '예약';
      case LaundryActionType.reportBroken:
        return '고장 신고';
      case LaundryActionType.cancelReservation:
        return '예약 취소';
    }
  }
}
