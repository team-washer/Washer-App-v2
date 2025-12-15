enum LaundryActionType {
  reserve,
  reportBroken,
}

extension LaundryActionTypeExtension on LaundryActionType {
  String get text {
    switch (this) {
      case LaundryActionType.reserve:
        return '예약';
      case LaundryActionType.reportBroken:
        return '고장 신고';
    }
  }
}
