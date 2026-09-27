abstract final class HomeDateTimeFormatter {
  static const _months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String featuredSchedule(DateTime value) {
    final day = _relativeDay(value);
    return '$day, ${time(value)}';
  }

  static String formDate(DateTime value) {
    return '${_months[value.month - 1]} ${value.day}, ${value.year}';
  }

  static String compactDate(DateTime value) {
    final relative = _relativeDay(value);
    if (relative == 'Tomorrow' || relative == 'Today') {
      return '$relative, ${_months[value.month - 1]} ${value.day}';
    }
    return '${_months[value.month - 1]} ${value.day}';
  }

  static String time(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  static String _relativeDay(DateTime value) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(value.year, value.month, value.day);
    final days = target.difference(today).inDays;

    if (days == 0) return 'Today';
    if (days == 1) return 'Tomorrow';
    return _months[value.month - 1];
  }
}
