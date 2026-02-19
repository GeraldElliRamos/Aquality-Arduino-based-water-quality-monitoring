import 'package:flutter/material.dart';
import '../models/water_quality_parameter.dart';
import '../models/alert.dart';

/// Utility functions for color management across the app
class ColorUtils {
  static const Map<ParameterColor, Color> parameterColors = {
    ParameterColor.orange: Color(0xFFFF9500),
    ParameterColor.purple: Color(0xFF7C3AED),
    ParameterColor.amber: Color(0xFFFCD34D),
    ParameterColor.blue: Color(0xFF3B82F6),
    ParameterColor.red: Color(0xFFEF4444),
    ParameterColor.teal: Color(0xFF14B8A6),
    ParameterColor.indigo: Color(0xFF6366F1),
    ParameterColor.green: Color(0xFF10B981),
  };

  static const Map<ParameterColor, Color> parameterColorsDark = {
    ParameterColor.orange: Color(0xFFFFB84D),
    ParameterColor.purple: Color(0xFFA78BFA),
    ParameterColor.amber: Color(0xFFFDE047),
    ParameterColor.blue: Color(0xFF60A5FA),
    ParameterColor.red: Color(0xFFF87171),
    ParameterColor.teal: Color(0xFF2DD4BF),
    ParameterColor.indigo: Color(0xFF818CF8),
    ParameterColor.green: Color(0xFF34D399),
  };

  /// Get color for parameter (light mode)
  static Color getParameterColor(ParameterColor color) {
    return parameterColors[color] ?? Colors.blue;
  }

  /// Get color for parameter (dark mode)
  static Color getParameterColorDark(ParameterColor color) {
    return parameterColorsDark[color] ?? Colors.lightBlue;
  }

  /// Get status color for optimal/warning/critical
  static Color getStatusColor(String status, {bool isDark = false}) {
    switch (status.toLowerCase()) {
      case 'optimal':
        return isDark ? const Color(0xFF86EFAC) : const Color(0xFF10B981);
      case 'warning':
        return isDark ? const Color(0xFFFCD34D) : const Color(0xFFF59E0B);
      case 'critical':
        return isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444);
      default:
        return isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    }
  }

  /// Get background color for status
  static Color getStatusBgColor(String status, {bool isDark = false}) {
    switch (status.toLowerCase()) {
      case 'optimal':
        return isDark
            ? const Color(0xFF10B981).withOpacity(0.2)
            : const Color(0xFFECFDF5);
      case 'warning':
        return isDark
            ? const Color(0xFFF59E0B).withOpacity(0.2)
            : const Color(0xFFFEF3C7);
      case 'critical':
        return isDark
            ? const Color(0xFFEF4444).withOpacity(0.2)
            : const Color(0xFFFEE2E2);
      default:
        return isDark ? Colors.grey.shade800 : Colors.grey.shade100;
    }
  }

  /// Get alert level color
  static Color getAlertLevelColor(AlertLevel level, {bool isDark = false}) {
    switch (level) {
      case AlertLevel.critical:
        return isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444);
      case AlertLevel.warning:
        return isDark ? const Color(0xFFFCD34D) : const Color(0xFFF59E0B);
      case AlertLevel.info:
        return isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6);
    }
  }

  /// Get background for alert badge
  static Color getAlertBgColor(AlertLevel level, {bool isDark = false}) {
    switch (level) {
      case AlertLevel.critical:
        return isDark
            ? const Color(0xFFEF4444).withOpacity(0.2)
            : const Color(0xFFFEE2E2);
      case AlertLevel.warning:
        return isDark
            ? const Color(0xFFF59E0B).withOpacity(0.2)
            : const Color(0xFFFEF3C7);
      case AlertLevel.info:
        return isDark
            ? const Color(0xFF3B82F6).withOpacity(0.2)
            : const Color(0xFFEFF6FF);
    }
  }

  /// Get text color for parameter card (light bg)
  static Color getCardTextColor(ParameterColor color) {
    // Return a darker shade for text on light backgrounds
    return parameterColors[color]?.withOpacity(0.8) ?? Colors.blue;
  }
}
