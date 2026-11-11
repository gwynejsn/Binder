class FormatUtils {
  static const List<String> _months = [
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

  static const List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  // something like "Nov 11"
  static String formatDate(DateTime dt) {
    return '${_months[dt.month - 1]} ${dt.day}';
  }

  // something like "Nov 11, 2026"
  static String formatDateWithYear(DateTime dt) {
    return '${_months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  // something like "Wednesday • Nov 11"
  static String formatDateToday(DateTime dt) {
    return '${_days[dt.weekday - 1]} • ${_months[dt.month - 1]} ${dt.day}';
  }
}
