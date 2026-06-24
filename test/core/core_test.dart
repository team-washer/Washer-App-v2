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

  group('DateTimeFormatter.parseServerDateTime', () {
    test('treats offset-less server time as KST (UTC+9)', () {
      // 서버 LocalDateTime: 오프셋 없음 → KST 벽시계로 해석 → UTC instant는 -9h
      final parsed = DateTimeFormatter.parseServerDateTime(
        '2026-01-27T21:33:00',
      );
      expect(parsed!.toUtc().toIso8601String(), '2026-01-27T12:33:00.000Z');
    });

    test('keeps absolute instant when offset/Z is present (SmartThings)', () {
      final utc = DateTimeFormatter.parseServerDateTime(
        '2026-01-27T21:33:00Z',
      );
      expect(utc!.toUtc().toIso8601String(), '2026-01-27T21:33:00.000Z');

      final kst = DateTimeFormatter.parseServerDateTime(
        '2026-01-27T21:33:00+09:00',
      );
      expect(kst!.toUtc().toIso8601String(), '2026-01-27T12:33:00.000Z');
    });

    test('remaining time uses absolute instant, not device wall clock', () {
      // now = 12:00Z(= 21:00 KST), 완료예정 = 21:40 KST(오프셋 없는 서버 값) → 40분
      final now = DateTime.utc(2026, 1, 27, 12, 0, 0);
      expect(
        DateTimeFormatter.formatRemainingTimeToKorean(
          '2026-01-27T21:40:00',
          now: now,
        ),
        '40분 00초',
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
