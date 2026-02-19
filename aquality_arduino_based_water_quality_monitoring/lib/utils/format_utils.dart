import 'package:intl/intl.dart';

/// Utility functions for formatting data consistently
class FormatUtils {
  /// Format a double value to a specific number of decimal places
  static String formatParamValue(double value, {int decimals = 2}) {
    return value.toStringAsFixed(decimals);
  }

  /// Format a value with its unit (e.g., "29.4°C")
  static String formatWithUnit(double value, String unit, {int decimals = 2}) {
    final formatted = formatParamValue(value, decimals: decimals);
    return unit.isEmpty ? formatted : '$formatted$unit';
  }

  /// Format time of day (e.g., "09:32 PM")
  static String formatTimeOfDay(DateTime dateTime) {
    return DateFormat('hh:mm a').format(dateTime);
  }

  /// Format date (e.g., "Feb 19, 2026")
  static String formatDate(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy').format(dateTime);
  }

  /// Format date and time (e.g., "Feb 19, 2026 09:32 PM")
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy hh:mm a').format(dateTime);
  }

  /// Format time ago (e.g., "2 mins ago", "3 hours ago")
  static String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return '$mins min${mins > 1 ? 's' : ''} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours hour${hours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days day${days > 1 ? 's' : ''} ago';
    } else {
      return formatDate(dateTime);
    }
  }

  /// Format a range (e.g., "6.5-9.0")
  static String formatRange(double min, double max, {int decimals = 2}) {
    final minStr = formatParamValue(min, decimals: decimals);
    final maxStr = formatParamValue(max, decimals: decimals);
    return '$minStr-$maxStr';
  }

  /// Format percentage (e.g., "85.2%")
  static String formatPercentage(double value, {int decimals = 1}) {
    return '${value.toStringAsFixed(decimals)}%';
  }

  /// Get status badge text
  static String getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'optimal':
        return '✓ Optimal';
      case 'warning':
        return '⚠ Warning';
      case 'critical':
        return '✕ Critical';
      default:
        return '';
    }
  }

  /// Truncate text to specified length
  static String truncate(String text, int length) {
    if (text.length <= length) return text;
    return '${text.substring(0, length - 3)}...';
  }

  /// Format number with thousands separator (e.g., "1,234.56")
  static String formatNumber(double value, {int decimals = 2}) {
    final formatter = NumberFormat('###,###.##', 'en_US');
    return formatter.format(value);
  }

  /// Get ordinal suffix (1st, 2nd, 3rd, etc.)
  static String getOrdinal(int number) {
    if (number >= 11 && number <= 13) return '${number}th';
    switch (number % 10) {
      case 1:
        return '${number}st';
      case 2:
        return '${number}nd';
      case 3:
        return '${number}rd';
      default:
        return '${number}th';
    }
  }
}
