import 'package:flutter/cupertino.dart';
import 'package:project_setting/presentation/common/circle_widget.dart';

enum LaundryStatus {
  washComplete, // 세탁 완료
  dryComplete, // 건조 완료
  washerError, // 세탁기 이상
  dryerError, // 건조기 이상
  usageWarning, // 사용 경고
}

extension LaundryStatusExt on LaundryStatus {
  String get text {
    switch (this) {
      case LaundryStatus.washComplete:
        return '세탁 완료';
      case LaundryStatus.dryComplete:
        return '건조 완료';
      case LaundryStatus.washerError:
        return '세탁기 이상';
      case LaundryStatus.dryerError:
        return '건조기 이상';
      case LaundryStatus.usageWarning:
        return '사용 경고';
    }
  }

  Widget get circle {
    switch (this) {
      case LaundryStatus.washComplete:
        return CircleWidget(color: CircleColor.blue);
      case LaundryStatus.dryComplete:
        return CircleWidget(color: CircleColor.blue);
      case LaundryStatus.washerError:
        return CircleWidget(color: CircleColor.red);
      case LaundryStatus.dryerError:
        return CircleWidget(color: CircleColor.red);
      case LaundryStatus.usageWarning:
        return CircleWidget(color: CircleColor.red);
    }
  }
}
