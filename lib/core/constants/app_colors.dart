// app_colors.dart
// PsyCare brand color palette.
// Dark: #1F6F5F  |  Primary: #2FA084  |  Light/Accent: #6FCF97  |  Neutral: #EEEEEE

import 'package:flutter/material.dart';

/// Central color constants for the PsyCare app.
class AppColors {
  AppColors._(); // Prevent instantiation

  // --- Brand Palette ---
  static const Color dark = Color(0xFF1F6F5F);       // Headers, primary actions
  static const Color primary = Color(0xFF2FA084);    // Interactive elements, highlights
  static const Color accent = Color(0xFF6FCF97);     // Hover states, accents
  static const Color accentLight = Color(0xFFB7E8CB); // Soft accent tint

  // Aliases for backward compatibility
  static const Color primaryDark = dark;
  static const Color primaryLight = accent;

  // --- Backgrounds ---
  static const Color background = Color(0xFFEEEEEE); // Neutral background
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFF7F7F7);

  // --- Text ---
  static const Color textPrimary = Color(0xFF1A2E2B);
  static const Color textSecondary = Color(0xFF4A6B63);
  static const Color textHint = Color(0xFF9AB5AF);

  // --- Status ---
  static const Color success = Color(0xFF6FCF97);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFFBBF24);

  // --- Divider / Border ---
  static const Color divider = Color(0xFFD6E8E4);
  static const Color border = Color(0xFFCCDEDA);

  // --- Gradients ---
  /// Dark → Primary gradient for buttons, headers, hero cards
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [dark, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Subtle neutral background gradient
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFEEEEEE), Color(0xFFE0EDEA)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
