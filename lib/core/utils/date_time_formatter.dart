class DateTimeFormatter {
  static String formatToShortWithTime(String? isoString) {
    if (isoString == null) {
      return '';
    }
    final parsed = DateTime.tryParse(isoString);
    if (parsed == null) {
      return '';
    }
    final localTime = parsed.toLocal();
    final year = localTime.year % 100;
    final month = localTime.month;
    final day = localTime.day;
    final hour = localTime.hour.toString().padLeft(2, '0');
    final minute = localTime.minute.toString().padLeft(2, '0');
    final second = localTime.second.toString().padLeft(2, '0');
    return '$year.$month.$day. $hour:$minute:$second';
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

    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '$hours시간 $minutes분 $seconds초';
    }
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}분 $seconds초';
    }
    return '$seconds초';
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

    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (includeHours && hours > 0) {
      return '$hours시간 ${minutes.toString().padLeft(2, '0')}분 ${seconds.toString().padLeft(2, '0')}초';
    }

    return '${duration.inMinutes.toString().padLeft(2, '0')}분 ${seconds.toString().padLeft(2, '0')}초';
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
}
