import 'package:flutter/material.dart';
import 'package:washer/core/theme/color.dart';

enum HistoryStatus {
  reserved,
  confirmed,
  running,
  completed,
  cancelled,
}

extension HistoryStatusX on HistoryStatus {
  static HistoryStatus fromString(String status) {
    switch (status) {
      case 'RESERVED':
        return HistoryStatus.reserved;
      case 'CONFIRMED':
        return HistoryStatus.confirmed;
      case 'RUNNING':
        return HistoryStatus.running;
      case 'COMPLETED':
        return HistoryStatus.completed;
      case 'CANCELLED':
        return HistoryStatus.cancelled;
      default:
        return HistoryStatus.reserved;
    }
  }

  Color get color {
    switch (this) {
      case HistoryStatus.completed:
        return WasherColor.mainColor400;

      case HistoryStatus.cancelled:
        return WasherColor.errorColor;

      case HistoryStatus.running:
        return WasherColor.mainColor500;

      case HistoryStatus.confirmed:
        return WasherColor.mainColor300;

      case HistoryStatus.reserved:
        return WasherColor.baseGray500;
    }
  }

  String get label {
    switch (this) {
      case HistoryStatus.completed:
        return '사용 완료';

      case HistoryStatus.cancelled:
        return '취소됨';

      case HistoryStatus.running:
        return '사용 중';

      case HistoryStatus.confirmed:
        return '확정됨';

      case HistoryStatus.reserved:
        return '예약됨';
    }
  }

  String get timeLabel {
    switch (this) {
      case HistoryStatus.completed:
        return '완료 시간';

      case HistoryStatus.cancelled:
        return '취소 시간';

      case HistoryStatus.running:
      case HistoryStatus.confirmed:
      case HistoryStatus.reserved:
        return '예정 시간';
    }
  }
}
