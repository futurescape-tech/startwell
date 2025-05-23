import 'package:startwell/models/student_model.dart';
import 'package:intl/intl.dart';

/// Utility class for validating meal plan selections
class MealPlanValidator {
  /// Check if current time is within the Express order window (12:00 AM - 8:00 AM IST)
  static bool isWithinExpressWindow() {
    // Temporarily disabled Express ordering
    return false;

    // Original implementation:
    // final now = DateTime.now().toLocal();
    // return now.hour >= 0 && now.hour < 8;
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
    // Get the current date
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    // Check for active breakfast plan
    if (selectedPlanType == 'breakfast' && student.hasActiveBreakfast) {
      if (student.breakfastPlanEndDate == null) {
        return 'Student ${student.name} has an active breakfast plan with no end date. Please contact support.';
      }

      // Format the end date for display
      final endDateStr =
          DateFormat('dd/MM/yyyy').format(student.breakfastPlanEndDate!);

      // Check if the end date is in the future
      if (student.breakfastPlanEndDate!.isAfter(now)) {
        return 'Student ${student.name} has an active breakfast plan ending on $endDateStr. You can place a pre-order for dates after this end date.';
      }
    }

    // Check for active lunch plan
    if (selectedPlanType == 'lunch' && student.hasActiveLunch) {
      if (student.lunchPlanEndDate == null) {
        return 'Student ${student.name} has an active lunch plan with no end date. Please contact support.';
      }

      // Format the end date for display
      final endDateStr =
          DateFormat('dd/MM/yyyy').format(student.lunchPlanEndDate!);

      // Check if the end date is in the future
      if (student.lunchPlanEndDate!.isAfter(now)) {
        return 'Student ${student.name} has an active lunch plan ending on $endDateStr. You can place a pre-order for dates after this end date.';
      }
    }

    // Express plan validation
    if (selectedPlanType == 'express') {
      if (!isWithinExpressWindow()) {
        return 'Express 1-Day plan can only be selected between 12:00 AM and 8:00 AM IST.';
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
