// helpers.dart
// General utility/helper functions used across PsyCare.

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

/// Collection of stateless helper utilities.
class Helpers {
  Helpers._();

  /// Formats a [DateTime] to a readable string like "Apr 15, 2026".
  static String formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  /// Formats a [DateTime] to include time, e.g. "Apr 15, 2026 • 3:00 PM".
  static String formatDateTime(DateTime date) {
    return DateFormat('MMM d, yyyy • h:mm a').format(date);
  }

  /// Returns initials from a full name string (e.g. "John Doe" → "JD").
  static String getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  /// Shows a styled SnackBar with an error message.
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Shows a styled SnackBar with a success message.
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Converts a score out of 120 (30 questions × 4 options 0–3) to a
  /// simple severity label.
  static String scoreSeverity(int totalScore) {
    if (totalScore <= 30) return 'Minimal';
    if (totalScore <= 60) return 'Mild';
    if (totalScore <= 90) return 'Moderate';
    return 'Severe';
  }
}
