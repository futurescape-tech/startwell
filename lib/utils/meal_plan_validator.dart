import 'package:startwell/models/student_model.dart';

/// Utility class for validating meal plan selections
class MealPlanValidator {
  /// Check if current time is within the Express order window (12:00 AM - 8:00 AM IST)
  static bool isWithinExpressWindow() {
    final now = DateTime.now()
        .toUtc()
        .add(const Duration(hours: 5, minutes: 30)); // Convert to IST
    return now.hour >= 0 && now.hour < 8;
  }

  /// Validate if a meal plan can be assigned to a student
  /// Returns null if valid, or an error message if invalid
  static String? validateMealPlan(Student student, String selectedPlanType,
      {bool isExpress = false}) {
    // Check if student has both active plans
    if (student.hasActiveBreakfast && student.hasActiveLunch) {
      return '${student.name} already has active breakfast and lunch meal plans. You can choose a new plan once the current ones end.';
    }

    // Check breakfast plan conflicts
    if (selectedPlanType == 'breakfast' && student.hasActiveBreakfast) {
      return '${student.name} already has an active breakfast meal plan. You can choose a new breakfast plan once the current one ends.';
    }

    // Check lunch plan conflicts
    if ((selectedPlanType == 'lunch' || isExpress) && student.hasActiveLunch) {
      return '${student.name} already has an active lunch meal plan. You can choose a new lunch plan once the current one ends.';
    }

    // Express order time window check
    if (isExpress) {
      if (!isWithinExpressWindow()) {
        return 'Express 1-Day plan can only be selected between 12:00 AM and 8:00 AM IST.';
      }
    }

    // Plan selection is valid
    return null;
  }

  /// Get formatted end date string for active plans
  static String getActivePlanEndDateInfo(Student student) {
    final List<String> activePlans = [];

    if (student.hasActiveBreakfast && student.breakfastPlanEndDate != null) {
      final endDateStr = _formatDate(student.breakfastPlanEndDate!);
      activePlans.add('Breakfast (ends $endDateStr)');
    }

    if (student.hasActiveLunch && student.lunchPlanEndDate != null) {
      final endDateStr = _formatDate(student.lunchPlanEndDate!);
      activePlans.add('Lunch (ends $endDateStr)');
    }

    if (activePlans.isEmpty) {
      return 'No active meal plans';
    }

    return 'Active plans: ${activePlans.join(', ')}';
  }

  /// Format date for display
  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
