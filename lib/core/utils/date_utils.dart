import 'package:intl/intl.dart';

class DateUtils {
  DateUtils._();

  static String formatDuration(int seconds) {
    if (seconds < 0) seconds = 0;
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  static String getTodayDateString() {
    return formatDate(DateTime.now());
  }

  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  static int getDaysBetween(DateTime from, DateTime to) {
    return (to.difference(from).inMilliseconds / (1000 * 60 * 60 * 24)).round();
  }

  static List<DateTime> getDaysInRange(DateTime start, DateTime end) {
    final List<DateTime> days = [];
    var current = start;
    while (current.isBefore(end) || isSameDay(current, end)) {
      days.add(current);
      current = current.add(const Duration(days: 1));
    }
    return days;
  }
}
