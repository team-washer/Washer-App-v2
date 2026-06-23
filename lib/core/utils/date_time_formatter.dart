class DateTimeFormatter {
  /// 한국 표준시 오프셋(UTC+9, 서머타임 없음).
  static const Duration _kstOffset = Duration(hours: 9);

  /// 서버는 타임존 표기가 없는 KST(`LocalDateTime`) 문자열을 보낸다.
  /// (예: `2026-01-27T21:33:00` — `Z`도 `+09:00`도 없음)
  ///
  /// 오프셋이 없으면 `DateTime.parse`가 이를 기기 로컬 시간으로 해석해
  /// KST가 아닌 기기에서 남은 시간이 어긋난다. 그래서 오프셋 표기가 없는
  /// 문자열은 벽시계 숫자를 KST로 간주해 올바른 절대시각으로 변환한다.
  /// 이미 오프셋이 있으면(SmartThings의 `...Z` 등) 그대로 신뢰한다.
  static DateTime? parseServerDateTime(String? value) {
    if (value == null) {
      return null;
    }
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final parsed = DateTime.tryParse(trimmed);
    // parsed.isUtc == true 이면 문자열에 오프셋 표기(Z 또는 ±hh:mm)가 있었던 것이므로
    // 절대시각이 이미 정확하다. null(파싱 실패)도 그대로 넘긴다.
    if (parsed == null || parsed.isUtc) {
      return parsed;
    }
    // isUtc == false → 오프셋 표기 없음 → 벽시계 숫자를 KST로 해석한다.
    return DateTime.utc(
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
      parsed.millisecond,
      parsed.microsecond,
    ).subtract(_kstOffset);
  }

  static String formatToShortDate(String? isoString) {
    final parsed = parseServerDateTime(isoString);
    if (parsed == null) {
      return '';
    }

    return formatDateToShort(parsed);
  }

  static String formatToShortWithTime(String? isoString) {
    final parsed = parseServerDateTime(isoString);
    if (parsed == null) {
      return '';
    }
    final localTime = parsed.toLocal();
    final hour = localTime.hour.toString().padLeft(2, '0');
    final minute = localTime.minute.toString().padLeft(2, '0');
    final second = localTime.second.toString().padLeft(2, '0');
    return '${formatDateToShort(localTime)} $hour:$minute:$second';
  }

  static String formatDurationToKorean(String? value) {
    if (value == null) {
      return '';
    }

    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final duration =
        _parseIsoDuration(trimmed) ??
        _parseClockDuration(trimmed) ??
        _parseSecondDuration(trimmed);

    if (duration == null) {
      return trimmed;
    }

    if (duration.isNegative) {
      return '만료됨';
    }

    return formatDurationParts(duration);
  }

  static String formatRemainingTimeToKorean(
    String? value, {
    DateTime? now,
    String expiredText = '만료됨',
    bool includeHours = true,
  }) {
    if (value == null) {
      return '';
    }

    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final currentTime = now ?? DateTime.now();
    final targetTime = parseServerDateTime(trimmed);
    final duration =
        targetTime?.difference(currentTime) ??
        _parseIsoDuration(trimmed) ??
        _parseClockDuration(trimmed) ??
        _parseSecondDuration(trimmed);

    if (duration == null) {
      return trimmed;
    }

    if (duration.isNegative) {
      return expiredText;
    }

    return formatDurationParts(duration, includeHours: includeHours);
  }

  static String formatDurationParts(
    Duration duration, {
    bool includeHours = true,
  }) {
    final safeDuration = duration.isNegative ? Duration.zero : duration;
    final hours = safeDuration.inHours;
    final minutes = safeDuration.inMinutes % 60;
    final seconds = safeDuration.inSeconds % 60;

    if (includeHours && hours > 0) {
      return '${hours.toString().padLeft(2, '0')}시간 '
          '${minutes.toString().padLeft(2, '0')}분 '
          '${seconds.toString().padLeft(2, '0')}초';
    }

    return '${safeDuration.inMinutes.toString().padLeft(2, '0')}분 '
        '${seconds.toString().padLeft(2, '0')}초';
  }

  static Duration? _parseIsoDuration(String value) {
    final match = RegExp(
      r'^P(?:\d+D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?)?$',
      caseSensitive: false,
    ).firstMatch(value);
    if (match == null) {
      return null;
    }

    final hours = int.tryParse(match.group(1) ?? '') ?? 0;
    final minutes = int.tryParse(match.group(2) ?? '') ?? 0;
    final seconds = int.tryParse(match.group(3) ?? '') ?? 0;
    return Duration(hours: hours, minutes: minutes, seconds: seconds);
  }

  static Duration? _parseClockDuration(String value) {
    final parts = value.split(':');
    if (parts.length < 2 || parts.length > 3) {
      return null;
    }

    final numbers = parts.map(int.tryParse).toList();
    if (numbers.any((part) => part == null)) {
      return null;
    }

    if (parts.length == 2) {
      return Duration(minutes: numbers[0]!, seconds: numbers[1]!);
    }

    return Duration(
      hours: numbers[0]!,
      minutes: numbers[1]!,
      seconds: numbers[2]!,
    );
  }

  static Duration? _parseSecondDuration(String value) {
    final seconds = int.tryParse(value);
    if (seconds == null) {
      return null;
    }

    return Duration(seconds: seconds);
  }

  static String formatDateToShort(DateTime value) {
    final localTime = value.toLocal();
    final year = (localTime.year % 100).toString().padLeft(2, '0');
    final month = localTime.month.toString().padLeft(2, '0');
    final day = localTime.day.toString().padLeft(2, '0');
    return '$year.$month.$day';
  }
}
