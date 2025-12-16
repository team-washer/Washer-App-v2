import 'package:flutter/cupertino.dart';
import 'package:project_setting/presentation/common/circle_widget.dart';

enum LaundryAlarmStatus {
  washComplete, // 세탁 완료
  dryComplete, // 건조 완료
  washerError, // 세탁기 이상
  dryerError, // 건조기 이상
  usageWarning, // 사용 경고
}

extension LaundryAlarmStatusExt on LaundryAlarmStatus {
  String get text {
    switch (this) {
      case LaundryAlarmStatus.washComplete:
        return '세탁 완료';
      case LaundryAlarmStatus.dryComplete:
        return '건조 완료';
      case LaundryAlarmStatus.washerError:
        return '세탁기 이상';
      case LaundryAlarmStatus.dryerError:
        return '건조기 이상';
      case LaundryAlarmStatus.usageWarning:
        return '사용 경고';
    }
  }

  Widget get circle {
    switch (this) {
      case LaundryAlarmStatus.washComplete:
        return CircleWidget(color: CircleColor.blue);
      case LaundryAlarmStatus.dryComplete:
        return CircleWidget(color: CircleColor.blue);
      case LaundryAlarmStatus.washerError:
        return CircleWidget(color: CircleColor.red);
      case LaundryAlarmStatus.dryerError:
        return CircleWidget(color: CircleColor.red);
      case LaundryAlarmStatus.usageWarning:
        return CircleWidget(color: CircleColor.red);
    }
  }
}
