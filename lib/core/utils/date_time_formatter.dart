class DateTimeFormatter {
  static String formatToShortDate(String? isoString) {
    if (isoString == null) {
      return '';
    }

    final parsed = DateTime.tryParse(isoString);
    if (parsed == null) {
      return '';
    }

    return formatDateToShort(parsed);
  }

  static String formatToShortWithTime(String? isoString) {
    if (isoString == null) {
      return '';
    }
    final parsed = DateTime.tryParse(isoString);
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
    final targetTime = DateTime.tryParse(trimmed);
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
