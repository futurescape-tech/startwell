import 'package:startwell/models/student_model.dart';

/// Utility class for validating meal plan selections
class MealPlanValidator {
  /// Check if current time is within the Express order window (12:00 AM - 8:00 AM IST)
  static bool isWithinExpressWindow() {
    final now = DateTime.now().toLocal();
    return now.hour >= 0 && now.hour < 8;
  }

  /// Get the appropriate Active Plan label for display on student profile cards
  static String getActivePlanLabel(Student student) {
    if (student.hasActiveBreakfast && student.hasActiveLunch) {
      return "Active Plan: Lunch + Breakfast";
    }
    if (student.hasActiveLunch) {
      return "Active Plan: Lunch";
    }
    if (student.hasActiveBreakfast) {
      return "Active Plan: Breakfast";
    }
    return "";
  }

  /// Validate if a meal plan can be assigned to a student
  /// Returns null if valid, or an error message if invalid
  static String? validateMealPlan(Student student, String selectedPlanType) {
    // Rule: Students can't have both breakfast and lunch plans simultaneously
    final bool hasBothPlans =
        student.hasActiveBreakfast && student.hasActiveLunch;

    // If student already has both plans, don't allow a new plan
    if (hasBothPlans) {
      return 'Student ${student.name} already has an active breakfast and lunch meal plan. You can choose a new plan once the current one ends.';
    }

    // Rule: Students with active breakfast plans can only select lunch plans
    // If selecting breakfast and student already has breakfast plan
    if (selectedPlanType == 'breakfast' && student.hasActiveBreakfast) {
      return 'Student ${student.name} already has an active breakfast meal plan. You can choose a new breakfast plan once the current one ends. You can still select a lunch plan for this student.';
    }

    // Rule: Students with active lunch plans can only select breakfast plans
    // If selecting lunch and student already has lunch plan
    if (selectedPlanType == 'lunch' && student.hasActiveLunch) {
      return 'Student ${student.name} already has an active lunch meal plan. You can choose a new lunch plan once the current one ends. You can still select a breakfast plan for this student.';
    }

    // Rule: Express 1-Day plans can only be selected between 12:00 AM and 8:00 AM
    // Rule: Express plans can't be selected if a student already has an active lunch plan
    if (selectedPlanType == 'express') {
      // Check time restriction
      if (!isWithinExpressWindow()) {
        return 'Express 1-Day plan can only be selected between 12:00 AM and 8:00 AM IST.';
      }

      // Check active lunch plan restriction
      if (student.hasActiveLunch) {
        return 'Student ${student.name} already has an active lunch meal plan. You cannot select an Express 1-Day plan until the current one ends.';
      }
    }

    return null; // ✅ Plan allowed
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
