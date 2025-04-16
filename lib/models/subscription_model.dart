import 'package:intl/intl.dart';
import 'package:startwell/services/student_profile_service.dart';
import 'package:startwell/models/student_model.dart';
import 'package:startwell/utils/date_utils.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math';

enum SubscriptionStatus { active, paused, cancelled, expired }

enum SubscriptionDuration {
  singleDay,
  weekly,
  monthly,
  quarterly,
  halfYearly,
  annual
}

// Helper class to store subscription with delivery data
class _SubscriptionWithDeliveryData {
  final String id;
  final List<DateTime> deliveryDates = [];
  final List<DateTime> cancelledDates = [];

  _SubscriptionWithDeliveryData(this.id);
}

class Subscription {
  final String id;
  final String studentId;
  final String planType; // 'breakfast', 'lunch', or 'express'
  final String mealName; // e.g., 'Breakfast of the Day', 'Indian Lunch', etc.
  final DateTime startDate;
  final DateTime endDate;
  final SubscriptionStatus status;
  final SubscriptionDuration duration;
  final List<int>
      selectedWeekdays; // 1-7 for Monday-Sunday, empty for daily delivery

  // Track cancelled dates - dates when meals were cancelled
  final List<DateTime> _cancelledDates = [];

  // Map to track swapped meals by date
  final Map<DateTime, String> _swappedMeals = {};

  Subscription({
    required this.id,
    required this.studentId,
    required this.planType,
    required this.mealName,
    required this.startDate,
    required this.endDate,
    this.status = SubscriptionStatus.active,
    this.duration = SubscriptionDuration.monthly,
    this.selectedWeekdays = const [], // Empty means all weekdays (Mon-Fri)
  });

  // Add a date to the cancelled dates list
  void addCancelledDate(DateTime date) {
    // Normalize the date to avoid time comparison issues
    final normalizedDate = DateTime(date.year, date.month, date.day);

    // Check if this date is already marked as cancelled
    if (!isCancelledForDate(normalizedDate)) {
      _cancelledDates.add(normalizedDate);
      dev.log(
          'Added cancelled date: ${DateFormat('yyyy-MM-dd').format(normalizedDate)} for subscription: $id');
    }
  }

  // Check if the subscription has a cancelled meal for a specific date
  bool isCancelledForDate(DateTime date) {
    // Normalize the date to avoid time comparison issues
    final normalizedDate = DateTime(date.year, date.month, date.day);

    // Check if this date exists in the cancelled dates list
    return _cancelledDates.any((d) =>
        d.year == normalizedDate.year &&
        d.month == normalizedDate.month &&
        d.day == normalizedDate.day);
  }

  // Get all cancelled dates
  List<DateTime> get cancelledDates => List.unmodifiable(_cancelledDates);

  // Calculate the next delivery date based on subscription plan
  DateTime get nextDeliveryDate {
    final today = DateTime.now();

    // If current date is after end date, there's no next delivery
    if (today.isAfter(endDate)) {
      return endDate; // Return end date to indicate subscription has ended
    }

    // If the start date is in the future, that's our next delivery date
    if (startDate.isAfter(today)) {
      return startDate;
    }

    // Use the date calculator for accurate delivery date calculation
    return DeliveryDateCalculator.getNextValidDeliveryDate(
      selectedWeekdays: selectedWeekdays,
      startDate:
          today, // Use today's date as the base, not the subscription start date
      isExpress: planType == 'express',
      isSingleDay: duration == SubscriptionDuration.singleDay,
    );
  }

  // Get items based on plan type
  List<String> getMealItems() {
    if (planType == 'breakfast') {
      return ['Breakfast Item 1', 'Breakfast Item 2', 'Seasonal Fruit'];
    }
    return ['Lunch Item 1', 'Lunch Item 2', 'Salad']; // lunch or express
  }

  // Determine if swap is enabled for this subscription
  bool get isSwapEnabled {
    // Express plans cannot be swapped
    if (planType == 'express') {
      return false;
    }

    final today = DateTime.now();
    final cutoffDate = DateTime(nextDeliveryDate.year, nextDeliveryDate.month,
            nextDeliveryDate.day, 23, 59 // 11:59 PM the day before
            )
        .subtract(const Duration(days: 1));

    // Swap is allowed until 11:59 PM the day before delivery
    return today.isBefore(cutoffDate);
  }

  // Determine if cancel is enabled for this subscription
  bool get isCancelEnabled {
    // Express plans cannot be cancelled
    if (planType == 'express') {
      return false;
    }

    final today = DateTime.now();
    final cutoffDate = DateTime(nextDeliveryDate.year, nextDeliveryDate.month,
            nextDeliveryDate.day, 23, 59 // 11:59 PM the day before
            )
        .subtract(const Duration(days: 1));

    // Cancel is allowed until 11:59 PM the day before delivery
    return today.isBefore(cutoffDate);
  }

  // Check if this is an express plan
  bool get isExpressPlan => planType == 'express';

  // Format the next delivery date
  String get formattedNextDeliveryDate {
    return DateFormat('EEE, MMM dd, yyyy').format(nextDeliveryDate);
  }

  // Get a display name for the subscription duration
  String get durationDisplayName {
    switch (duration) {
      case SubscriptionDuration.singleDay:
        return 'Single Day';
      case SubscriptionDuration.weekly:
        return 'Weekly';
      case SubscriptionDuration.monthly:
        return 'Monthly';
      case SubscriptionDuration.quarterly:
        return 'Quarterly';
      case SubscriptionDuration.halfYearly:
        return 'Half-Yearly';
      case SubscriptionDuration.annual:
        return 'Annual';
    }
  }

  // Get a display name for the plan type and duration
  String get planDisplayName {
    // For Express 1-Day plans, always display a specific name
    if (planType == 'express') {
      return 'Express 1-Day Plan';
    }

    // Get the meal type display name (Breakfast or Lunch)
    String planTypeDisplay = '';
    switch (planType) {
      case 'breakfast':
        planTypeDisplay = 'Breakfast';
        break;
      case 'lunch':
        planTypeDisplay = 'Lunch';
        break;
      default:
        planTypeDisplay = 'Meal';
    }

    // For custom delivery plans with specific weekdays, mention it's a custom plan
    if (selectedWeekdays.isNotEmpty && selectedWeekdays.length < 5) {
      return 'Custom $durationDisplayName $planTypeDisplay Plan';
    }

    // Standard format: "Monthly Breakfast Plan", "Weekly Lunch Plan", etc.
    return '$durationDisplayName $planTypeDisplay Plan';
  }

  // Get the subscription type (duration) for display
  String get subscriptionType {
    // Return just the duration part (Single Day, Weekly, Monthly, etc.)
    if (planType == 'express') {
      return 'Express 1-Day';
    }

    return durationDisplayName;
  }

  // Get the meal item name for display (without additional text)
  String get mealItemName {
    return mealName;
  }

  // Get the meal name for a specific date, considering swaps
  String getMealNameForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return _swappedMeals[normalizedDate] ?? mealName;
  }

  // Create a copy with updated properties
  Subscription copyWith({
    String? id,
    String? studentId,
    String? planType,
    String? mealName,
    DateTime? startDate,
    DateTime? endDate,
    SubscriptionStatus? status,
    SubscriptionDuration? duration,
    List<int>? selectedWeekdays,
  }) {
    return Subscription(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      planType: planType ?? this.planType,
      mealName: mealName ?? this.mealName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      duration: duration ?? this.duration,
      selectedWeekdays: selectedWeekdays ?? this.selectedWeekdays,
    );
  }

  // Override toString for better logging
  @override
  String toString() {
    final String dateFormat = 'MM/dd';
    final String formattedStart = DateFormat(dateFormat).format(startDate);
    final String formattedEnd = DateFormat(dateFormat).format(endDate);
    final String weekdays = selectedWeekdays.isEmpty
        ? 'M-F'
        : selectedWeekdays.map((day) {
            switch (day) {
              case 1:
                return 'M';
              case 2:
                return 'T';
              case 3:
                return 'W';
              case 4:
                return 'T';
              case 5:
                return 'F';
              default:
                return day.toString();
            }
          }).join(',');

    return 'Subscription(id: $id, studentId: $studentId, plan: $planType, meal: $mealName, period: $formattedStart-$formattedEnd, days: $weekdays)';
  }

  // Swap a meal for a specific date
  Future<bool> swapMeal(
      String subscriptionId, String newMealName, DateTime date) async {
    try {
      dev.log(
          "[meal swap logic] Starting meal swap for subscription ID: $subscriptionId");
      dev.log("[meal swap logic] New meal name: $newMealName");
      dev.log(
          "[meal swap logic] Date: ${DateFormat('yyyy-MM-dd').format(date)}");

      // Normalize the date to avoid time issues
      final normalizedDate = DateTime(date.year, date.month, date.day);

      // In a real app, this would update the database
      await Future.delayed(
          const Duration(milliseconds: 500)); // Simulate network delay

      // Find the student ID from the subscription ID
      String? studentId;
      if (subscriptionId.contains('-')) {
        studentId = subscriptionId.split('-').sublist(1).join('-');
        dev.log("[meal swap logic] Extracted student ID: $studentId");

        if (studentId != null) {
          // Store the swapped meal for this specific date
          _swappedMeals[normalizedDate] = newMealName;

          dev.log(
              "[meal swap logic] Stored swapped meal for date ${DateFormat('yyyy-MM-dd').format(normalizedDate)}: $newMealName");

          // In a real implementation, you would save this to the database
          // For now, return true to indicate success
          return true;
        }
      }

      dev.log("[meal swap logic] Meal swap completed successfully");
      return true;
    } catch (e) {
      dev.log("[meal swap logic] Error swapping meal: $e");
      return false;
    }
  }
}

class SubscriptionService {
  // Singleton pattern
  static final SubscriptionService _instance = SubscriptionService._internal();

  factory SubscriptionService() {
    return _instance;
  }

  SubscriptionService._internal() {
    // Initialize with empty subscriptions list to avoid null issues
    _subscriptions.clear();
  }

  // A temporary storage for cancelled meals - in a real app this would be in a database
  static final List<Map<String, dynamic>> _cancelledMealsHistory = [];

  // A temporary storage for subscriptions with delivery dates and cancelled dates
  static final List<_SubscriptionWithDeliveryData> _subscriptions = [];

  // Convert Duration to SubscriptionDuration enum based on end date
  SubscriptionDuration _getDurationFromEndDate(
      DateTime startDate, DateTime endDate) {
    final int days = endDate.difference(startDate).inDays;

    // Log for debugging purposes
    dev.log('Calculating duration: days between start and end: $days');

    if (days <= 1) {
      return SubscriptionDuration.singleDay;
    } else if (days <= 7) {
      return SubscriptionDuration.weekly;
    } else if (days <= 31) {
      return SubscriptionDuration.monthly;
    } else if (days <= 90) {
      return SubscriptionDuration.quarterly;
    } else if (days <= 180) {
      return SubscriptionDuration.halfYearly;
    } else {
      return SubscriptionDuration.annual;
    }
  }

  // Get meal name based on plan type and preferences with more detailed options
  String _getMealNameFromPlanType(String planType, String? preferredStyle) {
    // If a specific preferred style is provided, use it
    if (preferredStyle != null && preferredStyle.isNotEmpty) {
      switch (planType) {
        case 'breakfast':
          return '$preferredStyle Breakfast';
        case 'lunch':
          return '$preferredStyle Lunch';
        case 'express':
          return '$preferredStyle Lunch'; // Express is a lunch option
        default:
          return 'Standard Meal';
      }
    }

    // If no preference is specified, use default meal types
    // Note: We should NEVER use random selection for meal names as it creates inconsistency
    switch (planType) {
      case 'breakfast':
        return 'Breakfast of the Day';
      case 'lunch':
        return 'Lunch of the Day';
      case 'express':
        return 'Express Lunch';
      default:
        return 'Meal of the Day';
    }
  }

  // Extract custom weekdays from the student model if available based on meal type
  List<int> _getCustomWeekdaysFromStudent(Student student, String planType) {
    // Use the proper weekday selection based on plan type
    if (planType == 'breakfast') {
      if (student.breakfastSelectedWeekdays != null &&
          student.breakfastSelectedWeekdays!.isNotEmpty) {
        // Use breakfast-specific weekdays
        dev.log(
            'Using breakfast-specific weekdays: ${student.breakfastSelectedWeekdays}');
        return List<int>.from(student.breakfastSelectedWeekdays!);
      }
    } else if (planType == 'lunch' || planType == 'express') {
      if (student.lunchSelectedWeekdays != null &&
          student.lunchSelectedWeekdays!.isNotEmpty) {
        // Use lunch-specific weekdays
        dev.log(
            'Using lunch-specific weekdays: ${student.lunchSelectedWeekdays}');
        return List<int>.from(student.lunchSelectedWeekdays!);
      }
    }

    // Only fall back to the deprecated field for students created before the meal-specific fields
    // Only if the meal-specific fields don't exist (not just empty)
    if ((planType == 'breakfast' &&
            student.breakfastSelectedWeekdays == null) ||
        ((planType == 'lunch' || planType == 'express') &&
            student.lunchSelectedWeekdays == null)) {
      if (student.selectedWeekdays != null &&
          student.selectedWeekdays!.isNotEmpty) {
        // For backward compatibility, use the generic field
        dev.log(
            'Using generic weekdays (backward compatibility): ${student.selectedWeekdays}');
        return List<int>.from(student.selectedWeekdays!);
      }
    }

    // If no custom weekdays are specified, default to Mon-Fri (1-5)
    // for standard meal plans
    dev.log(
        'No custom weekdays found, using empty list (all weekdays Monday-Friday)');
    return []; // Empty list indicates standard weekday delivery (Mon-Fri)
  }

  // Get active subscriptions for a student
  Future<List<Subscription>> getActiveSubscriptionsForStudent(
      String studentId) async {
    // In a real app, this would fetch from a database or API
    // Here we'll connect to the StudentProfileService to get actual student data
    final studentProfileService = StudentProfileService();
    await Future.delayed(
        const Duration(milliseconds: 300)); // Simulate network delay

    final students = await studentProfileService.getStudentProfiles();
    final student = students.firstWhere(
      (student) => student.id == studentId,
      orElse: () => throw Exception('Student not found'),
    );

    dev.log('Student: ${student.name}, ID: ${student.id}');
    dev.log(
        'Student has breakfast plan: ${student.hasActiveBreakfast}, breakfast end date: ${student.breakfastPlanEndDate}');
    dev.log(
        'Student has lunch plan: ${student.hasActiveLunch}, lunch end date: ${student.lunchPlanEndDate}');

    // Create subscriptions based on actual student meal plans
    final List<Subscription> subscriptions = [];

    // Add breakfast subscription if active
    if (student.hasActiveBreakfast && student.breakfastPlanEndDate != null) {
      // Try to use the stored start date if available, otherwise use current date
      final DateTime subscriptionStartDate =
          student.breakfastPlanStartDate ?? DateTime.now();

      final duration = _getDurationFromEndDate(
          subscriptionStartDate, student.breakfastPlanEndDate!);

      // Use the explicit meal type if it's set, otherwise use a default
      String preferredMealStyle = student.breakfastPreference ?? 'Indian';

      final mealName =
          _getMealNameFromPlanType('breakfast', preferredMealStyle);

      // Get breakfast-specific weekdays
      final breakfastWeekdays =
          _getCustomWeekdaysFromStudent(student, 'breakfast');
      dev.log('Breakfast weekdays: $breakfastWeekdays');

      dev.log(
          'Breakfast Subscription Start Date: $subscriptionStartDate, End Date: ${student.breakfastPlanEndDate}, Duration: $duration');

      final subscription = Subscription(
        id: 'breakfast-${student.id}',
        studentId: student.id,
        planType: 'breakfast',
        mealName: mealName,
        startDate: subscriptionStartDate,
        endDate: student.breakfastPlanEndDate!,
        duration: duration,
        selectedWeekdays: breakfastWeekdays,
      );

      dev.log(
          'Adding breakfast subscription: ${subscription.id}, start: ${subscription.startDate}, end: ${subscription.endDate}');
      subscriptions.add(subscription);
    }

    // Add lunch or express subscription if active
    if (student.hasActiveLunch && student.lunchPlanEndDate != null) {
      final planType = student.mealPlanType == 'express' ? 'express' : 'lunch';

      // Try to use the stored start date if available, otherwise use current date
      DateTime subscriptionStartDate =
          student.lunchPlanStartDate ?? DateTime.now();

      final duration = _getDurationFromEndDate(
          subscriptionStartDate, student.lunchPlanEndDate!);

      // Use the explicit meal type if it's set, otherwise use a default
      String preferredMealStyle = student.lunchPreference ?? 'Indian';

      final mealName = _getMealNameFromPlanType(planType, preferredMealStyle);

      // Get lunch-specific weekdays
      final lunchWeekdays = _getCustomWeekdaysFromStudent(student, planType);
      dev.log('Lunch/Express weekdays: $lunchWeekdays');

      dev.log(
          '${planType} Subscription Start Date: $subscriptionStartDate, End Date: ${student.lunchPlanEndDate}, Duration: $duration');

      final subscription = Subscription(
        id: '$planType-${student.id}',
        studentId: student.id,
        planType: planType,
        mealName: mealName,
        startDate: subscriptionStartDate,
        endDate: student.lunchPlanEndDate!,
        duration: duration,
        selectedWeekdays: lunchWeekdays,
      );

      dev.log(
          'Adding ${planType} subscription: ${subscription.id}, start: ${subscription.startDate}, end: ${subscription.endDate}');
      subscriptions.add(subscription);
    }

    // If no active subscriptions are found from the student model,
    // fall back to mock data for demo purposes
    if (subscriptions.isEmpty) {
      dev.log('No active subscriptions found, creating demo subscriptions');
      // Create meaningful demo subscriptions with realistic meal items
      _createDemoSubscriptions(studentId, subscriptions);
    } else {
      dev.log('Total active subscriptions: ${subscriptions.length}');
      for (final sub in subscriptions) {
        dev.log(
            'Subscription: ID=${sub.id}, startDate=${sub.startDate}, planType=${sub.planType}');
      }
    }

    // Fix any subscriptions with incorrect duration values
    _fixSubscriptionDurations(subscriptions);

    return subscriptions;
  }

  // Helper method to fix any incorrect durations in subscriptions
  void _fixSubscriptionDurations(List<Subscription> subscriptions) {
    for (int i = 0; i < subscriptions.length; i++) {
      final subscription = subscriptions[i];

      // Recalculate the correct duration based on actual dates
      final int days =
          subscription.endDate.difference(subscription.startDate).inDays;
      SubscriptionDuration correctDuration;

      if (days <= 1) {
        correctDuration = SubscriptionDuration.singleDay;
      } else if (days <= 7) {
        correctDuration = SubscriptionDuration.weekly;
      } else if (days <= 31) {
        correctDuration = SubscriptionDuration.monthly;
      } else if (days <= 90) {
        correctDuration = SubscriptionDuration.quarterly;
      } else if (days <= 180) {
        correctDuration = SubscriptionDuration.halfYearly;
      } else {
        correctDuration = SubscriptionDuration.annual;
      }

      // If duration is wrong, fix it by creating a new subscription
      if (subscription.duration != correctDuration) {
        dev.log(
            '🔄 Fixing incorrect duration for subscription ${subscription.id}');
        dev.log(
            '🔄 Original duration: ${subscription.duration}, Correct duration: $correctDuration');

        // Create copy with corrected duration
        subscriptions[i] = subscription.copyWith(duration: correctDuration);
      }
    }
  }

  // Helper method to create demo subscriptions
  void _createDemoSubscriptions(
      String studentId, List<Subscription> subscriptions) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final oneMonthLater = DateTime(now.year, now.month + 1, now.day);
    final oneWeekLater = DateTime(now.year, now.month, now.day + 7);

    // Explicitly calculate the correct duration based on days
    final weeklyDuration = _getDurationFromEndDate(now, oneWeekLater);
    final monthlyDuration = _getDurationFromEndDate(now, oneMonthLater);

    // Create different combinations of subscriptions for demo purposes
    // Format: studentId ending with:
    // 1 => Breakfast + Lunch plans
    // 2 => Only Express plan
    // 3 => Only Breakfast plan
    // Any other => Breakfast + Lunch plans (default)

    if (studentId.endsWith('1') ||
        !studentId.endsWith('2') && !studentId.endsWith('3')) {
      // Scenario 1: Student has both Breakfast and Lunch plans
      subscriptions.add(Subscription(
        id: '1-${studentId}',
        studentId: studentId,
        planType: 'breakfast',
        mealName: 'Indian Breakfast',
        startDate: now,
        endDate: oneMonthLater,
        duration:
            monthlyDuration, // Use the calculated duration instead of hardcoded
      ));

      subscriptions.add(Subscription(
        id: '2-${studentId}',
        studentId: studentId,
        planType: 'lunch',
        mealName: 'Jain Lunch',
        startDate: now,
        endDate: oneMonthLater,
        duration:
            monthlyDuration, // Use the calculated duration instead of hardcoded
      ));
    } else if (studentId.endsWith('2')) {
      // Scenario 2: Student has only Express plan
      subscriptions.add(Subscription(
        id: '3-${studentId}',
        studentId: studentId,
        planType: 'express',
        mealName: 'Express Lunch',
        startDate: tomorrow,
        endDate: tomorrow,
        duration: SubscriptionDuration.singleDay,
      ));
    } else {
      // Scenario 3: Student has only Breakfast plan
      subscriptions.add(Subscription(
        id: '4-${studentId}',
        studentId: studentId,
        planType: 'breakfast',
        mealName: 'International Breakfast',
        startDate: now,
        endDate: oneWeekLater,
        duration:
            weeklyDuration, // Use the calculated duration instead of hardcoded
        selectedWeekdays: [1, 3, 5], // Mon, Wed, Fri only
      ));
    }
  }

  // Cancel a meal delivery for a specific date
  Future<bool> cancelMealDelivery(String subscriptionId, DateTime date,
      {String? reason, String? studentId}) async {
    try {
      // Normalize the date to avoid time issues (remove time component)
      final normalizedDate = DateTime(date.year, date.month, date.day);

      // Log detailed cancellation info
      dev.log('========== CANCELLING MEAL ==========');
      dev.log('Subscription ID: $subscriptionId');
      dev.log('Date: ${DateFormat('yyyy-MM-dd').format(normalizedDate)}');
      dev.log('Reason: ${reason ?? "Not specified"}');
      dev.log('Student ID: ${studentId ?? "Not specified directly"}');

      // Extract student ID directly from subscription ID format
      // Format is typically planType-studentId or planType-timestamp
      String extractedStudentId = 'unknown';
      String planType = 'lunch';
      String mealName = 'Standard Meal';

      try {
        final parts = subscriptionId.split('-');
        if (parts.length >= 2) {
          planType = parts[0]; // breakfast, lunch, express
          extractedStudentId = parts.sublist(1).join('-');
          mealName = planType == 'breakfast'
              ? 'Breakfast of the Day'
              : 'Standard Lunch';

          dev.log('Extracted from ID - Plan Type: $planType');
          dev.log('Extracted from ID - Student ID: $extractedStudentId');
        }
      } catch (e) {
        dev.log('Error parsing subscription ID format: $e');
      }

      // Use provided student ID if available, otherwise use the extracted one
      String finalStudentId = studentId ?? extractedStudentId;
      dev.log('Using final student ID for record: $finalStudentId');

      // Find the actual subscription details if available
      final actualSubscription = await _getSubscriptionById(subscriptionId);

      // Use extracted values from the subscription if available
      if (actualSubscription.studentId != 'unknown' &&
          finalStudentId == 'unknown') {
        finalStudentId = actualSubscription.studentId;
        dev.log('Updated student ID from subscription lookup: $finalStudentId');
      }

      planType = actualSubscription.planType;
      mealName = actualSubscription.mealName;

      // Try to get student profile information
      Student? studentProfile;
      try {
        studentProfile =
            await StudentProfileService().getStudentById(finalStudentId);
        dev.log(
            'Found student profile: ${studentProfile?.name ?? "Not found"}');
      } catch (e) {
        dev.log('Error getting student profile: $e');
      }

      // Create a unique record ID to prevent duplicates
      final recordId =
          '${subscriptionId}_${normalizedDate.millisecondsSinceEpoch}';

      // Check if this meal was already cancelled
      bool alreadyCancelled = false;
      for (var existingRecord in _cancelledMealsHistory) {
        if (existingRecord['id'] == recordId) {
          dev.log('This meal was already cancelled, skipping duplicate record');
          alreadyCancelled = true;
          break;
        }
      }

      if (!alreadyCancelled) {
        // Create a detailed cancellation record
        final cancellationRecord = {
          'id': recordId,
          'subscriptionId': subscriptionId,
          'studentId': finalStudentId,
          'studentName': studentProfile?.name ?? 'Unknown Student',
          'planType': planType,
          'name': mealName,
          'date': normalizedDate,
          'cancelledAt': DateTime.now(),
          'cancelledBy': 'user',
          'reason': reason ?? 'Cancelled by Parent',
          'status': 'Cancelled', // Explicitly set status field
        };

        // Add to the cancelled meals history
        _cancelledMealsHistory.add(cancellationRecord);

        dev.log(
            'Added to cancellation history: $finalStudentId on ${DateFormat('yyyy-MM-dd').format(normalizedDate)}');
        dev.log('Total cancellation records: ${_cancelledMealsHistory.length}');
      }

      // For debugging, show all cancellation records
      dev.log('--- All Cancellation Records ---');
      for (int i = 0; i < _cancelledMealsHistory.length; i++) {
        var record = _cancelledMealsHistory[i];
        dev.log(
            'Record #${i + 1}: ${record['studentId']} on ${DateFormat('yyyy-MM-dd').format(record['date'] as DateTime)}');
      }
      dev.log('-------------------------------');

      // Update the subscription to mark this date as cancelled
      for (var subscription in _subscriptions) {
        if (subscription.id == subscriptionId) {
          dev.log('Found matching subscription, marking date as cancelled');
          subscription.cancelledDates.add(normalizedDate);
          break;
        }
      }

      dev.log(
          'Cancelled meal delivery for $subscriptionId on ${normalizedDate.toString()}');
      dev.log('======================================');

      return true;
    } catch (e) {
      dev.log('Error cancelling meal delivery: $e');
      return false;
    }
  }

  // Helper method to get a subscription by ID
  Future<Subscription> _getSubscriptionById(String subscriptionId) async {
    // In a real app, this would fetch from the database
    await Future.delayed(const Duration(milliseconds: 300));

    // Extract student ID from the subscription ID if possible
    // Most subscription IDs are in the format 'planType-studentId'
    String studentId = 'unknown';
    String planType = 'lunch';

    try {
      // Parse subscription ID to get plan type and student ID
      final parts = subscriptionId.split('-');
      if (parts.length >= 2) {
        planType = parts[0]; // breakfast, lunch, express

        // The rest could be the student ID or a timestamp
        // Try to use the active subscriptions to find a match
        for (var subscription in _subscriptions) {
          if (subscription.id == subscriptionId) {
            studentId = subscription.id.split('-')[1];
            dev.log(
                "Found subscription in active subscriptions: studentId=$studentId");
            break;
          }
        }

        // If we still don't have a valid student ID, try to extract it from the subscription ID
        if (studentId == 'unknown') {
          // Join all parts after the first one to reconstruct the student ID
          studentId = parts.sublist(1).join('-');
          dev.log("Extracted studentId from subscription ID: $studentId");
        }
      }
    } catch (e) {
      dev.log("Error parsing subscription ID: $e");
    }

    // Create and return a subscription with the extracted details
    return Subscription(
      id: subscriptionId,
      studentId: studentId,
      planType: planType,
      mealName:
          planType == 'breakfast' ? 'Breakfast of the Day' : 'Standard Lunch',
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 30)),
    );
  }

  // Adjust delivery dates - remove cancelled date and add a new last delivery date
  Future<bool> adjustDeliveryDates(String subscriptionId,
      DateTime cancelledDate, DateTime newLastDeliveryDate) async {
    try {
      // Simulate database call
      await Future.delayed(const Duration(milliseconds: 800));

      // Find the subscription or create it if not found
      var subscription = _subscriptions.firstWhere(
        (s) => s.id == subscriptionId,
        orElse: () => _createSubscriptionRecord(subscriptionId),
      );

      // First cancel the meal on specified date
      final normalizedCancelDate =
          DateTime(cancelledDate.year, cancelledDate.month, cancelledDate.day);

      subscription.deliveryDates.removeWhere((d) =>
          d.year == normalizedCancelDate.year &&
          d.month == normalizedCancelDate.month &&
          d.day == normalizedCancelDate.day);

      // Add to cancelled dates history
      subscription.cancelledDates.add(normalizedCancelDate);

      // Now add the new delivery date at the end
      final normalizedNewDate = DateTime(newLastDeliveryDate.year,
          newLastDeliveryDate.month, newLastDeliveryDate.day);

      // Add only if it's not already in the delivery dates
      if (!subscription.deliveryDates.any((d) =>
          d.year == normalizedNewDate.year &&
          d.month == normalizedNewDate.month &&
          d.day == normalizedNewDate.day)) {
        subscription.deliveryDates.add(normalizedNewDate);

        // Sort delivery dates to maintain chronological order
        subscription.deliveryDates.sort((a, b) => a.compareTo(b));
      }

      dev.log(
          'Adjusted delivery dates for $subscriptionId: cancelled ${normalizedCancelDate.toString()}, added ${normalizedNewDate.toString()}');
      return true;
    } catch (e) {
      dev.log('Error adjusting delivery dates: $e');
      return false;
    }
  }

  // Helper method to create a new subscription record
  _SubscriptionWithDeliveryData _createSubscriptionRecord(
      String subscriptionId) {
    final newRecord = _SubscriptionWithDeliveryData(subscriptionId);
    _subscriptions.add(newRecord);
    return newRecord;
  }

  // Pause a meal delivery for a specific date
  Future<bool> pauseMealDelivery(String subscriptionId, DateTime date) async {
    // In a real app, this would update the database
    dev.log(
        '🔴 Pausing meal: $subscriptionId on ${DateFormat('yyyy-MM-dd').format(date)}');
    await Future.delayed(
        const Duration(milliseconds: 500)); // Simulate network delay
    return true;
  }

  // Resume a meal delivery for a specific date
  Future<bool> resumeMealDelivery(String subscriptionId, DateTime date) async {
    // In a real app, this would update the database
    dev.log(
        '🟢 Resuming meal: $subscriptionId on ${DateFormat('yyyy-MM-dd').format(date)}');
    await Future.delayed(
        const Duration(milliseconds: 500)); // Simulate network delay
    return true;
  }

  // Utility method for logging subscription details (helpful for debugging)
  static void logSubscriptionDetails(Subscription subscription) {
    dev.log('==== SUBSCRIPTION DETAILS ====');
    dev.log('ID: ${subscription.id}');
    dev.log('Student ID: ${subscription.studentId}');
    dev.log('Plan Type: ${subscription.planType}');
    dev.log(
        'Start Date: ${DateFormat('yyyy-MM-dd').format(subscription.startDate)}');
    dev.log(
        'End Date: ${DateFormat('yyyy-MM-dd').format(subscription.endDate)}');
    dev.log('Duration: ${subscription.duration}');
    dev.log('Selected Weekdays: ${subscription.selectedWeekdays}');
    dev.log('==============================');
  }

  // Get cancelled meals for a student
  Future<List<Map<String, dynamic>>> getCancelledMeals(
      String? studentId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    dev.log("Getting cancelled meals - studentId: ${studentId ?? 'ALL'}");
    dev.log(
        "Total cancelled meals in history: ${_cancelledMealsHistory.length}");

    // Show all records for debugging
    for (var meal in _cancelledMealsHistory) {
      dev.log(
          "Cancelled meal in history - Student: ${meal['studentId']}, Date: ${DateFormat('yyyy-MM-dd').format(meal['date'] as DateTime)}");
    }

    // Filter by student if ID is provided
    if (studentId != null) {
      dev.log("Filtering by studentId: $studentId");

      final filtered = _cancelledMealsHistory.where((meal) {
        final mealStudentId = meal['studentId'] as String;
        final matches = mealStudentId == studentId;
        dev.log(
            "Comparing meal studentId: $mealStudentId == $studentId = $matches");
        return matches;
      }).toList();

      // Sort by cancellation date (most recent first)
      filtered.sort((a, b) => (b['cancelledAt'] as DateTime)
          .compareTo(a['cancelledAt'] as DateTime));

      dev.log(
          "Found ${filtered.length} cancelled meals for student $studentId");

      return filtered;
    }

    // Return all cancelled meals sorted by cancellation date
    final allCancelled =
        List<Map<String, dynamic>>.from(_cancelledMealsHistory);
    allCancelled.sort((a, b) =>
        (b['cancelledAt'] as DateTime).compareTo(a['cancelledAt'] as DateTime));

    dev.log("Returning all ${allCancelled.length} cancelled meals");

    return allCancelled;
  }

  // Swap a meal for a specific date
  Future<bool> swapMeal(String subscriptionId, String newMealName,
      [DateTime? date]) async {
    try {
      // If no date provided, use tomorrow as default
      final targetDate = date ?? DateTime.now().add(const Duration(days: 1));

      dev.log(
          "swap flow: Starting meal swap for subscription ID: $subscriptionId");
      dev.log("swap flow: New meal name: $newMealName");
      dev.log(
          "swap flow: Target date: ${DateFormat('yyyy-MM-dd').format(targetDate)}");

      // Find the subscription
      String? studentId;
      if (subscriptionId.contains('-')) {
        studentId = subscriptionId.split('-').sublist(1).join('-');
        dev.log("swap flow: Extracted student ID: $studentId");
      }

      // Attempt to get the subscription from active subscriptions
      Subscription? subscription;

      if (studentId != null) {
        try {
          final subscriptions =
              await getActiveSubscriptionsForStudent(studentId);
          subscription = subscriptions.firstWhere(
            (sub) => sub.id == subscriptionId,
            orElse: () => throw Exception('Subscription not found'),
          );
        } catch (e) {
          dev.log("swap flow: Error finding active subscription: $e");
        }
      }

      // If we found the subscription, use it; otherwise create a temporary one
      if (subscription != null) {
        return await subscription.swapMeal(
            subscriptionId, newMealName, targetDate);
      } else {
        // Create a temporary subscription
        final tempSubscription = Subscription(
          id: subscriptionId,
          studentId: studentId ?? 'unknown',
          planType:
              subscriptionId.startsWith('breakfast') ? 'breakfast' : 'lunch',
          mealName: 'Standard Meal',
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 30)),
        );

        return await tempSubscription.swapMeal(
            subscriptionId, newMealName, targetDate);
      }
    } catch (e) {
      dev.log("swap flow: Error in subscription service swapMeal: $e");
      return false;
    }
  }
}
