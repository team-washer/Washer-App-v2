class DateTimeFormatter {
  /// 서버는 타임존 표기가 없는 KST(`LocalDateTime`) 문자열을 보낸다.
  /// (예: `2026-01-27T21:33:00` — `Z`도 `+09:00`도 없음)
  ///
  /// 오프셋이 없으면 `DateTime.parse`가 이를 기기 로컬 시간으로 해석해
  /// KST가 아닌 기기에서 남은 시간이 어긋난다. 그래서 오프셋 표기가 없으면
  /// 문자열에 KST 오프셋(`+09:00`)을 붙여 파싱한다. 이러면 기기 로컬
  /// 타임존이나 DST(서머타임) 여부와 무관하게 항상 올바른 절대시각을 얻는다.
  /// 이미 오프셋이 있으면(SmartThings의 `...Z` 등) 그대로 신뢰한다.
  static DateTime? parseServerDateTime(String? value) {
    if (value == null) {
      return null;
    }
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    // 시간 성분(T) 뒤에 오프셋(Z 또는 ±hh:mm)이 붙어 있는지로 판단한다.
    // (날짜의 `-`를 오프셋으로 오인하지 않도록 T 뒤만 본다.)
    final hasTimeZone =
        trimmed.endsWith('Z') ||
        RegExp(r'T.*[+-]\d{2}(?::?\d{2})?$').hasMatch(trimmed);
    return DateTime.tryParse(hasTimeZone ? trimmed : '$trimmed+09:00');
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
