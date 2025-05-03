import 'package:intl/intl.dart';

/// Utility class for formatting dates throughout the application
class DateFormatter {
  /// Format a single date in a readable format: dd MMM yyyy
  static String format(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  /// Format a date range into a readable format
  /// If start and end dates are the same day, returns a single date
  /// Otherwise returns a range in format: dd MMM - dd MMM yyyy or dd MMM yyyy - dd MMM yyyy
  static String formatRange(DateTime startDate, DateTime endDate) {
    final DateFormat dayMonthFormat = DateFormat('dd MMM');
    final DateFormat fullFormat = DateFormat('dd MMM yyyy');

    // Same year
    if (startDate.year == endDate.year) {
      // Same month
      if (startDate.month == endDate.month) {
        // Same day
        if (startDate.day == endDate.day) {
          return fullFormat.format(startDate);
        }
        // Same month, different days
        return '${DateFormat('dd').format(startDate)} - ${fullFormat.format(endDate)}';
      }
      // Different months, same year
      return '${dayMonthFormat.format(startDate)} - ${fullFormat.format(endDate)}';
    }
    // Different years
    return '${fullFormat.format(startDate)} - ${fullFormat.format(endDate)}';
  }

  /// Check if a date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  /// Check if a date is in the past
  static bool isPast(DateTime date) {
    final now = DateTime.now();
    return date.isBefore(now);
  }

  /// Check if a date is in the future
  static bool isFuture(DateTime date) {
    final now = DateTime.now();
    return date.isAfter(now);
  }
}