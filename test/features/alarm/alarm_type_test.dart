import 'package:flutter_test/flutter_test.dart';
import 'package:washer/features/alarm/data/models/alarm_type.dart';
import 'package:washer/features/alarm/data/models/response/alarm_list_response.dart';

Map<String, dynamic> _notification(String type) => {
  'id': 1,
  'type': type,
  'message': '메시지',
  'createdAt': '2026-09-21T10:00:00',
};

void main() {
  group('AlarmType 서버 스펙 대응', () {
    // 서버 스펙(NotificationResDto.type)의 12종이 모두 unknown이 아닌 값으로 파싱돼야 한다.
    const specTypes = [
      'COMPLETION',
      'MALFUNCTION',
      'WARNING',
      'INTERRUPTION',
      'AUTO_CANCELLED',
      'PAUSE_TIMEOUT',
      'STARTED',
      'TIMEOUT_WARNING',
      'CANCELLATION_BLOCKED',
      'CANCELLATION_BLOCK_EXTENDED',
      'FORCE_STOPPED',
      'ADMIN_PENALTY_BLOCKED',
    ];

    for (final type in specTypes) {
      test('$type 은 unknown이 아니다', () {
        final notification = Notifications.fromJson(_notification(type));

        expect(notification.type, isNot(AlarmType.unknown));
        expect(notification.type.name, type);
      });
    }

    test('FORCE_STOPPED / ADMIN_PENALTY_BLOCKED 를 파싱한다', () {
      expect(
        Notifications.fromJson(_notification('FORCE_STOPPED')).type,
        AlarmType.FORCE_STOPPED,
      );
      expect(
        Notifications.fromJson(_notification('ADMIN_PENALTY_BLOCKED')).type,
        AlarmType.ADMIN_PENALTY_BLOCKED,
      );
    });

    test('알 수 없는 타입은 목록 전체를 깨지 않고 unknown으로 폴백한다', () {
      final response = AlarmListResponse.fromJson({
        'notifications': [
          _notification('FORCE_STOPPED'),
          _notification('SOME_FUTURE_TYPE'),
        ],
      });

      expect(response.data.map((item) => item.type), [
        AlarmType.FORCE_STOPPED,
        AlarmType.unknown,
      ]);
    });
  });
}
