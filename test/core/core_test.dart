import 'package:flutter_test/flutter_test.dart';
import 'package:washer/core/utils/date_time_formatter.dart';

void main() {
  group('DateTimeFormatter.formatDurationToKorean', () {
    test('formats ISO-8601 duration with hours', () {
      expect(
        DateTimeFormatter.formatDurationToKorean('PT1H2M3S'),
        '01시간 02분 03초',
      );
    });

    test('formats clock duration without hours', () {
      expect(
        DateTimeFormatter.formatDurationToKorean('12:34'),
        '12분 34초',
      );
    });

    test('returns input when duration cannot be parsed', () {
      expect(
        DateTimeFormatter.formatDurationToKorean('not-a-duration'),
        'not-a-duration',
      );
    });
  });

  group('DateTimeFormatter.formatRemainingTimeToKorean', () {
    test('formats future ISO datetime relative to now', () {
      final now = DateTime.utc(2026, 3, 26, 12, 0, 0);
      final future = now.add(const Duration(minutes: 5, seconds: 7));

      expect(
        DateTimeFormatter.formatRemainingTimeToKorean(
          future.toIso8601String(),
          now: now,
          includeHours: false,
        ),
        '05분 07초',
      );
    });

    test('returns expired text for negative duration', () {
      final now = DateTime.utc(2026, 3, 26, 12, 0, 0);
      final past = now.subtract(const Duration(seconds: 1));

      expect(
        DateTimeFormatter.formatRemainingTimeToKorean(
          past.toIso8601String(),
          now: now,
          expiredText: '종료됨',
        ),
        '종료됨',
      );
    });
  });
}
