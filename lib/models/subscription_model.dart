import 'package:intl/intl.dart';
import 'package:startwell/services/student_profile_service.dart';
import 'package:startwell/models/student_model.dart';
import 'package:startwell/utils/date_utils.dart';

enum SubscriptionStatus { active, paused, cancelled, expired }

enum SubscriptionDuration {
  singleDay,
  weekly,
  monthly,
  quarterly,
  halfYearly,
  annual
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
    final today = DateTime.now();
    final cutoffDate = DateTime(nextDeliveryDate.year, nextDeliveryDate.month,
            nextDeliveryDate.day, 23, 59 // 11:59 PM the day before
            )
        .subtract(const Duration(days: 1));

    // Cancel is allowed until 11:59 PM the day before delivery
    return today.isBefore(cutoffDate);
  }

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
}

class SubscriptionService {
  // Singleton pattern
  static final SubscriptionService _instance = SubscriptionService._internal();

  factory SubscriptionService() {
    return _instance;
  }

  SubscriptionService._internal();

  // Convert Duration to SubscriptionDuration enum based on end date
  SubscriptionDuration _getDurationFromEndDate(
      DateTime startDate, DateTime endDate) {
    final int days = endDate.difference(startDate).inDays;

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

  // Extract custom weekdays from the student model if available
  List<int> _getCustomWeekdaysFromStudent(Student student) {
    // If student has custom weekdays set, use them
    if (student.selectedWeekdays != null &&
        student.selectedWeekdays!.isNotEmpty) {
      return List<int>.from(student.selectedWeekdays!);
    }

    // If no custom weekdays are specified, default to Mon-Fri (1-5)
    // for standard meal plans
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

    // Create subscriptions based on actual student meal plans
    final now = DateTime.now();
    final List<Subscription> subscriptions = [];

    // Get custom weekdays if any
    final customWeekdays = _getCustomWeekdaysFromStudent(student);

    // Add breakfast subscription if active
    if (student.hasActiveBreakfast && student.breakfastPlanEndDate != null) {
      final duration =
          _getDurationFromEndDate(now, student.breakfastPlanEndDate!);

      // Use the explicit meal type if it's set, otherwise use a default
      String preferredMealStyle = student.breakfastPreference ?? 'Indian';

      final mealName =
          _getMealNameFromPlanType('breakfast', preferredMealStyle);

      subscriptions.add(Subscription(
        id: 'breakfast-${student.id}',
        studentId: student.id,
        planType: 'breakfast',
        mealName: mealName,
        startDate: now,
        endDate: student.breakfastPlanEndDate!,
        duration: duration,
        selectedWeekdays: customWeekdays,
      ));
    }

    // Add lunch or express subscription if active
    if (student.hasActiveLunch && student.lunchPlanEndDate != null) {
      final planType = student.mealPlanType == 'express' ? 'express' : 'lunch';
      final duration = _getDurationFromEndDate(now, student.lunchPlanEndDate!);

      // Use the explicit meal type if it's set, otherwise use a default
      String preferredMealStyle = student.lunchPreference ?? 'Indian';

      final mealName = _getMealNameFromPlanType(planType, preferredMealStyle);

      subscriptions.add(Subscription(
        id: '$planType-${student.id}',
        studentId: student.id,
        planType: planType,
        mealName: mealName,
        startDate: now,
        endDate: student.lunchPlanEndDate!,
        duration: duration,
        selectedWeekdays: customWeekdays,
      ));
    }

    // If no active subscriptions are found from the student model,
    // fall back to mock data for demo purposes
    if (subscriptions.isEmpty) {
      // Create meaningful demo subscriptions with realistic meal items
      _createDemoSubscriptions(studentId, subscriptions);
    }

    return subscriptions;
  }

  // Helper method to create demo subscriptions
  void _createDemoSubscriptions(
      String studentId, List<Subscription> subscriptions) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final oneMonthLater = DateTime(now.year, now.month + 1, now.day);
    final oneWeekLater = DateTime(now.year, now.month, now.day + 7);

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
        duration: SubscriptionDuration.monthly,
      ));

      subscriptions.add(Subscription(
        id: '2-${studentId}',
        studentId: studentId,
        planType: 'lunch',
        mealName: 'Jain Lunch',
        startDate: now,
        endDate: oneMonthLater,
        duration: SubscriptionDuration.monthly,
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
        duration: SubscriptionDuration.weekly,
        selectedWeekdays: [1, 3, 5], // Mon, Wed, Fri only
      ));
    }
  }

  // Swap a meal
  Future<bool> swapMeal(String subscriptionId, String newMealName) async {
    // In a real app, this would update the database
    await Future.delayed(
        const Duration(milliseconds: 500)); // Simulate network delay
    return true;
  }

  // Cancel a meal delivery for a specific date
  Future<bool> cancelMealDelivery(String subscriptionId, DateTime date) async {
    // In a real app, this would update the database
    await Future.delayed(
        const Duration(milliseconds: 500)); // Simulate network delay
    return true;
  }
}
