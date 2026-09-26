import 'package:washer/shared/theme/washer_icon.dart';

/// 하단 네비게이션 바의 탭 종류. 선언 순서가 곧 shell 브랜치 인덱스다.
enum NavTabType {
  dryer,
  home,
  washer,
}

/// 탭의 표시 라벨과 아이콘을 제공하는 확장.
extension NavTabTypeExtension on NavTabType {
  String get label {
    switch (this) {
      case NavTabType.dryer:
        return '건조기';
      case NavTabType.home:
        return '홈';
      case NavTabType.washer:
        return '세탁기';
    }
  }

  WasherIconType get iconType {
    switch (this) {
      case NavTabType.dryer:
        return WasherIconType.dry;
      case NavTabType.home:
        return WasherIconType.home;
      case NavTabType.washer:
        return WasherIconType.water;
    }
  }
}
