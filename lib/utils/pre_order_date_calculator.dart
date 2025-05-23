import 'package:intl/intl.dart';

/// Utility class for calculating pre-order dates based on subscription details
class PreOrderDateCalculator {
  /// Calculates the pre-order start date based on the active plan's end date
  /// Returns the first valid delivery day after the active plan's end date
  static DateTime calculatePreOrderStartDate(
    DateTime activePlanEndDate,
    List<bool> selectedWeekdays,
  ) {
    // Start from the day after the active plan ends
    DateTime startDate = activePlanEndDate.add(const Duration(days: 1));

    // Keep incrementing the date until we find a valid delivery day
    while (!isValidDeliveryDay(startDate, selectedWeekdays)) {
      startDate = startDate.add(const Duration(days: 1));
    }

    return startDate;
  }

  /// Calculates the pre-order end date based on the start date and plan type
  static DateTime calculatePreOrderEndDate(
    DateTime preOrderStartDate,
    String planType,
    List<bool> selectedWeekdays,
  ) {
    DateTime endDate;

    switch (planType) {
      case 'Single Day':
        // For single day, end date is same as start date
        endDate = preOrderStartDate;
        break;

      case 'Weekly':
        // Get date 7 days after start
        endDate = _calculateEndDateWithDeliveryDays(
          preOrderStartDate,
          7,
          selectedWeekdays,
        );
        break;

      case 'Monthly':
        // Calculate approximately 20 delivery days for a month
        endDate = _calculateEndDateWithValidDeliveryDays(
          preOrderStartDate,
          20,
          selectedWeekdays,
        );
        break;

      case 'Quarterly':
        // 3 months from start date
        endDate = DateTime(
          preOrderStartDate.year,
          preOrderStartDate.month + 3,
          preOrderStartDate.day,
        );
        // Adjust to the last valid delivery day in that range
        endDate = _adjustToLastValidDeliveryDay(endDate, selectedWeekdays);
        break;

      case 'Half-Yearly':
        // 6 months from start date
        endDate = DateTime(
          preOrderStartDate.year,
          preOrderStartDate.month + 6,
          preOrderStartDate.day,
        );
        // Adjust to the last valid delivery day in that range
        endDate = _adjustToLastValidDeliveryDay(endDate, selectedWeekdays);
        break;

      case 'Annual':
        // 12 months from start date
        endDate = DateTime(
          preOrderStartDate.year + 1,
          preOrderStartDate.month,
          preOrderStartDate.day,
        );
        // Adjust to the last valid delivery day in that range
        endDate = _adjustToLastValidDeliveryDay(endDate, selectedWeekdays);
        break;

      default:
        // Default to monthly
        endDate = _calculateEndDateWithValidDeliveryDays(
          preOrderStartDate,
          20,
          selectedWeekdays,
        );
    }

    return endDate;
  }

  /// Determines if a given date is a valid delivery day based on selected weekdays
  static bool isValidDeliveryDay(DateTime date, List<bool> selectedWeekdays) {
    // Skip weekends (0 is Monday in our app, 6 is Sunday)
    if (date.weekday > 5) {
      return false;
    }

    // Check if this weekday is selected (0-based index for selectedWeekdays)
    int weekdayIndex = date.weekday - 1; // Convert to 0-based index
    if (weekdayIndex >= 0 && weekdayIndex < selectedWeekdays.length) {
      return selectedWeekdays[weekdayIndex];
    }

    // For custom plans with no selected days, default to true
    if (selectedWeekdays.every((selected) => selected == false)) {
      return date.weekday <= 5; // Default to weekdays only
    }

    return false;
  }

  /// Calculates an end date with a specific number of valid delivery days
  static DateTime _calculateEndDateWithValidDeliveryDays(
    DateTime startDate,
    int numberOfDeliveryDays,
    List<bool> selectedWeekdays,
  ) {
    DateTime currentDate = startDate;
    int deliveryDaysCount = 0;

    // Keep incrementing until we reach the required number of delivery days
    while (deliveryDaysCount < numberOfDeliveryDays) {
      currentDate = currentDate.add(const Duration(days: 1));
      if (isValidDeliveryDay(currentDate, selectedWeekdays)) {
        deliveryDaysCount++;
      }
    }

    return currentDate;
  }

  /// Calculates an end date with a specific number of calendar days,
  /// ensuring the end date falls on a valid delivery day
  static DateTime _calculateEndDateWithDeliveryDays(
    DateTime startDate,
    int numberOfDays,
    List<bool> selectedWeekdays,
  ) {
    DateTime endDate = startDate.add(Duration(days: numberOfDays));

    // Adjust to ensure it's a valid delivery day
    while (!isValidDeliveryDay(endDate, selectedWeekdays)) {
      endDate = endDate.add(const Duration(days: 1));
    }

    return endDate;
  }

  /// Adjusts a date to be the last valid delivery day before or on that date
  static DateTime _adjustToLastValidDeliveryDay(
    DateTime date,
    List<bool> selectedWeekdays,
  ) {
    // If the date is already a valid delivery day, return it
    if (isValidDeliveryDay(date, selectedWeekdays)) {
      return date;
    }

    // Otherwise, go backwards until we find a valid delivery day
    DateTime currentDate = date;
    while (!isValidDeliveryDay(currentDate, selectedWeekdays)) {
      currentDate = currentDate.subtract(const Duration(days: 1));
    }

    return currentDate;
  }

  /// Generate a list of valid delivery dates between start and end dates
  static List<DateTime> generateValidDeliveryDates(
    DateTime startDate,
    DateTime endDate,
    List<bool> selectedWeekdays,
  ) {
    List<DateTime> validDates = [];
    DateTime currentDate = startDate;

    while (!currentDate.isAfter(endDate)) {
      if (isValidDeliveryDay(currentDate, selectedWeekdays)) {
        validDates.add(currentDate);
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return validDates;
  }

  /// Format a date to a readable string
  static String formatDate(DateTime date) {
    return DateFormat('d MMMM yyyy').format(date);
  }

  /// Calculate pre-order date range
  static Map<String, DateTime> calculatePreOrderDateRange(
    DateTime activePlanEndDate,
    String newPlanType,
    List<bool> selectedWeekdays,
  ) {
    // Calculate start date (first valid day after active plan ends)
    final startDate =
        calculatePreOrderStartDate(activePlanEndDate, selectedWeekdays);

    // Calculate end date based on plan type
    final endDate =
        calculatePreOrderEndDate(startDate, newPlanType, selectedWeekdays);

    return {
      'startDate': startDate,
      'endDate': endDate,
    };
  }

  /// Calculate pre-order date range for both meal types independently
  /// Returns a map with separate breakfast and lunch pre-order date ranges
  static Map<String, Map<String, DateTime>> calculateMealPreOrderDateRanges({
    required DateTime? breakfastPlanEndDate,
    required DateTime? lunchPlanEndDate,
    required String? breakfastPlanType,
    required String? lunchPlanType,
    required List<bool>? breakfastSelectedWeekdays,
    required List<bool>? lunchSelectedWeekdays,
  }) {
    Map<String, Map<String, DateTime>> result = {
      'breakfast': {},
      'lunch': {},
    };

    // Calculate breakfast pre-order date range if needed
    if (breakfastPlanEndDate != null &&
        breakfastPlanType != null &&
        breakfastSelectedWeekdays != null) {
      result['breakfast'] = calculatePreOrderDateRange(
        breakfastPlanEndDate,
        breakfastPlanType,
        breakfastSelectedWeekdays,
      );
    }

    // Calculate lunch pre-order date range if needed
    if (lunchPlanEndDate != null &&
        lunchPlanType != null &&
        lunchSelectedWeekdays != null) {
      result['lunch'] = calculatePreOrderDateRange(
        lunchPlanEndDate,
        lunchPlanType,
        lunchSelectedWeekdays,
      );
    }

    return result;
  }

  /// Get a formatted string of selected weekdays for display
  static String getDeliveryModeText(List<bool> selectedWeekdays) {
    final List<String> weekdayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday'
    ];

    // Short day names for more compact display
    final List<String> shortWeekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

    List<String> selectedDays = [];
    List<String> shortSelectedDays = [];

    // Add debugging
    print('DEBUG: getDeliveryModeText called with weekdays: $selectedWeekdays');

    for (int i = 0; i < selectedWeekdays.length; i++) {
      if (selectedWeekdays[i]) {
        selectedDays.add(weekdayNames[i]);
        shortSelectedDays.add(shortWeekdayNames[i]);
      }
    }

    String result;
    if (selectedDays.isEmpty) {
      result = "None";
    } else if (selectedDays.length == 5) {
      result = "Monday to Friday";
    } else if (selectedDays.length == 1) {
      // For single day, show the full day name
      result = selectedDays.first + " only";
    } else {
      // For multiple selected days, show a comma-separated list of day names
      result = "Custom: " + selectedDays.join(", ");
    }

    print('DEBUG: getDeliveryModeText result: $result');
    return result;
  }

  /// Find out if a date is within a valid pre-order range for a meal type
  static bool isInPreOrderRange({
    required DateTime date,
    required DateTime? startDate,
    required DateTime? endDate,
    required List<bool>? selectedWeekdays,
  }) {
    if (startDate == null || endDate == null || selectedWeekdays == null) {
      return false;
    }

    // Check if date is within the range
    if (date.isBefore(startDate) || date.isAfter(endDate)) {
      return false;
    }

    // Check if this is a valid delivery day based on selected weekdays
    return isValidDeliveryDay(date, selectedWeekdays);
  }
}
