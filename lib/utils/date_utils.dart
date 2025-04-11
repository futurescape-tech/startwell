import 'package:intl/intl.dart';

class DeliveryDateCalculator {
  /// Calculate the next valid delivery date based on plan type and selected weekdays
  static DateTime getNextValidDeliveryDate({
    required List<int> selectedWeekdays,
    required DateTime startDate,
    bool isExpress = false,
    bool isSingleDay = false,
  }) {
    final today = DateTime.now();

    // Strip time part for consistent date comparison
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    final startDateOnly =
        DateTime(startDate.year, startDate.month, startDate.day);

    // 1. Single Day Plan - use exact selected date
    if (isSingleDay) {
      return startDateOnly;
    }

    // 2. Express 1-Day Plan - delivery is on the specified date (usually same day)
    if (isExpress) {
      // For express plans, only deliver today if ordered before cutoff time (usually 8 AM)
      if (todayDateOnly.isAtSameMomentAs(startDateOnly) && today.hour >= 8) {
        // Too late for today, return tomorrow
        return todayDateOnly.add(const Duration(days: 1));
      }
      return startDateOnly;
    }

    // 3. Regular or Custom Plan
    // If startDate is in the future, use it as the base
    final baseDate =
        todayDateOnly.isAfter(startDateOnly) ? todayDateOnly : startDateOnly;

    // Check if we're past cutoff time for ordering (5:00 PM) for today's orders
    final isAfterCutoff =
        todayDateOnly.isAtSameMomentAs(baseDate) && today.hour >= 17;
    final adjustedBaseDate =
        isAfterCutoff ? baseDate.add(const Duration(days: 1)) : baseDate;

    // 4. Custom Plan with specific weekdays
    if (selectedWeekdays.isNotEmpty) {
      return getNextCustomWeekdayDate(adjustedBaseDate, selectedWeekdays);
    }

    // 5. Regular Plan (Mon-Fri)
    return getNextWeekdayFromMonToFri(adjustedBaseDate);
  }

  /// Find the next regular weekday (Mon-Fri) from the base date
  static DateTime getNextWeekdayFromMonToFri(DateTime baseDate) {
    // For regular plans, only deliver on weekdays (1-5, Monday to Friday)
    DateTime checkDate = baseDate;

    // If weekend, advance to Monday
    while (checkDate.weekday > 5) {
      checkDate = checkDate.add(const Duration(days: 1));
    }

    return checkDate;
  }

  /// Find next date matching one of the selected weekdays
  static DateTime getNextCustomWeekdayDate(
      DateTime baseDate, List<int> selectedWeekdays) {
    // Sort weekdays to find the earliest next one
    final sortedWeekdays = [...selectedWeekdays]..sort();

    // First try to find a match in the current week
    for (int i = 0; i < 7; i++) {
      final checkDate = baseDate.add(Duration(days: i));

      // If this day's weekday is in our selected list
      if (sortedWeekdays.contains(checkDate.weekday)) {
        return checkDate;
      }
    }

    // If we couldn't find a match in the next 7 days,
    // find the first selected weekday in the following week
    int daysUntilFirstDay = (sortedWeekdays.first - baseDate.weekday + 7) % 7;
    if (daysUntilFirstDay == 0)
      daysUntilFirstDay = 7; // Ensure we go to next week

    return baseDate.add(Duration(days: daysUntilFirstDay));
  }

  /// Format a date as a readable string (e.g., "Thu 11, Apr 2025")
  static String formatDate(DateTime date) {
    return DateFormat('EEE dd, MMM yyyy').format(date);
  }
}
