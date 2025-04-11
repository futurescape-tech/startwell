import 'package:flutter/material.dart';
import 'package:startwell/themes/app_theme.dart';

/// Legacy AppColors class that references the centralized theme
/// This class exists for backward compatibility with existing code
class AppColors {
  // Primary Colors
  static const Color primary = AppTheme.purple;
  static const Color deepPurple = AppTheme.deepPurple;
  static const Color lightPurple =
      Color(0xFF9B7AFF); // Light Purple (kept for compatibility)
  static const Color orange = AppTheme.orange;
  static const Color yellow = AppTheme.yellow;
  static const Color teal =
      Color(0xFF45CFD0); // Teal accent (kept for compatibility)

  // Background and UI Colors
  static const Color background = AppTheme.offWhite;
  static const Color cardBackground = AppTheme.white;
  static const Color textPrimary = AppTheme.textDark;
  static const Color textSecondary = AppTheme.textMedium;
  static const Color textLight = AppTheme.textLight;

  // Functional colors
  static const Color success = AppTheme.success;
  static const Color error = AppTheme.error;
  static const Color info =
      Color(0xFF2196F3); // Blue for information (kept for compatibility)

  // Gradients
  static const Gradient primaryToDeepPurple = AppTheme.purpleToDeepPurple;
  static const Gradient purpleToLightPurple = LinearGradient(
    colors: [deepPurple, lightPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Gradient purpleToOrange = AppTheme.purpleToOrange;
  static const Gradient purpleToYellow = LinearGradient(
    colors: [primary, yellow],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Gradient orangeToYellow = AppTheme.orangeToYellow;
  static const Gradient purpleToTeal = LinearGradient(
    colors: [primary, teal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Button gradients
  static const Gradient primaryButtonGradient = purpleToOrange;
  static const Gradient secondaryButtonGradient = purpleToLightPurple;
  static const Gradient successButtonGradient = LinearGradient(
    colors: [success, Color(0xFF81C784)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Decoration methods
  static BoxDecoration gradientBoxDecoration({
    required Gradient gradient,
    double borderRadius = 12,
    BoxBorder? border,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      gradient: gradient,
      borderRadius: BorderRadius.circular(borderRadius),
      border: border,
      boxShadow: boxShadow,
    );
  }

  // Shadow styles
  static List<BoxShadow> get softShadow => AppTheme.softShadow;
  static List<BoxShadow> get mediumShadow => AppTheme.mediumShadow;
}
