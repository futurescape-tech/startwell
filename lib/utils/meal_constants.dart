import 'package:flutter/material.dart';

/// Utility class that holds constants for meal styling throughout the app
class MealConstants {
  // Breakfast styling
  static const Color breakfastIconColor = Colors.pink;
  static Color breakfastBgColor = Colors.pink.withOpacity(0.1);
  static Color breakfastBorderColor = Colors.pink.withOpacity(0.2);
  static const IconData breakfastIcon = Icons.ramen_dining;

  // Lunch styling
  static const Color lunchIconColor = Colors.green;
  static Color lunchBgColor = Colors.green.withOpacity(0.1);
  static Color lunchBorderColor = Colors.green.withOpacity(0.2);
  static const IconData lunchIcon = Icons.lunch_dining;

  // Express order styling
  static const Color expressIconColor = Colors.orange;
  static Color expressBgColor = Colors.orange.withOpacity(0.1);
  static Color expressBorderColor = Colors.orange.withOpacity(0.2);
  static const IconData expressIcon = Icons.delivery_dining;

  /// Returns the appropriate icon color based on meal type
  static Color getIconColor(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return breakfastIconColor;
      case 'express':
        return expressIconColor;
      case 'lunch':
      default:
        return lunchIconColor;
    }
  }

  /// Returns the appropriate background color based on meal type
  static Color getBgColor(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return breakfastBgColor;
      case 'express':
        return expressBgColor;
      case 'lunch':
      default:
        return lunchBgColor;
    }
  }

  /// Returns the appropriate border color based on meal type
  static Color getBorderColor(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return breakfastBorderColor;
      case 'express':
        return expressBorderColor;
      case 'lunch':
      default:
        return lunchBorderColor;
    }
  }

  /// Returns the appropriate icon based on meal type
  static IconData getIcon(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return breakfastIcon;
      case 'express':
        return expressIcon;
      case 'lunch':
      default:
        return lunchIcon;
    }
  }
}
