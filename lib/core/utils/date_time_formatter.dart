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
}