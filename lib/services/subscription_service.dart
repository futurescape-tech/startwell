import 'dart:developer';
import 'package:intl/intl.dart';
import 'package:startwell/models/cancelled_meal.dart';
import 'package:startwell/services/event_bus_service.dart';
import 'package:startwell/services/student_profile_service.dart';
import 'package:startwell/models/student_model.dart';
import 'package:startwell/models/subscription_model.dart';
import 'dart:async';
import 'dart:developer' as dev;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service class to manage subscription-related operations.
class SubscriptionService {
  // Singleton instance
  static final SubscriptionService _instance = SubscriptionService._internal();

  // Factory constructor to return the same instance
  factory SubscriptionService() {
    return _instance;
  }

  // Private constructor
  SubscriptionService._internal() {
    // Initialize with empty cancellation history instead of adding sample data
    _cancellationHistory.clear();
    log('[cancelled meal flow] Initialized SubscriptionService with empty cancellation history');
    _loadCancelledMealsFromStorage(); // Load cancelled meals from storage on initialization
  }

  // Internal storage for active subscriptions
  final List<Subscription> _subscriptions = [];

  // SINGLE source of truth for cancelled meals
  final List<Map<String, dynamic>> _cancellationHistory = [];

  // Student profile service for name lookups
  final StudentProfileService _studentProfileService = StudentProfileService();

  // Storage key for cancelled meals
  static const String _storageKey = 'cancelled_meals_history';

  // Load cancelled meals from SharedPreferences
  Future<void> _loadCancelledMealsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? storedMeals = prefs.getString(_storageKey);

      if (storedMeals != null && storedMeals.isNotEmpty) {
        final List<dynamic> mealsJson = jsonDecode(storedMeals);

        // Convert dates stored as strings back to DateTime objects
        for (var mealJson in mealsJson) {
          try {
            // Convert date strings to DateTime objects
            if (mealJson['date'] is String) {
              mealJson['date'] = DateTime.parse(mealJson['date']);
            }
            if (mealJson['cancelledAt'] is String) {
              mealJson['cancelledAt'] = DateTime.parse(mealJson['cancelledAt']);
            }

            _cancellationHistory.add(Map<String, dynamic>.from(mealJson));
          } catch (e) {
            log('[cancelled meal flow] Error parsing meal date: $e');
          }
        }

        log('[cancelled meal flow] Loaded ${_cancellationHistory.length} cancelled meals from storage');
        _logAllCancellationRecords();
      } else {
        log('[cancelled meal flow] No cancelled meals found in storage');
      }
    } catch (e) {
      log('[cancelled meal flow] Error loading cancelled meals from storage: $e');
    }
  }

  // Save cancelled meals to SharedPreferences
  Future<void> _saveCancelledMealsToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Need to convert DateTime objects to strings before saving
      final List<Map<String, dynamic>> serializableMeals = [];

      for (var meal in _cancellationHistory) {
        final Map<String, dynamic> serializedMeal = Map.from(meal);

        // Convert DateTime objects to ISO strings
        if (serializedMeal['date'] is DateTime) {
          serializedMeal['date'] =
              (serializedMeal['date'] as DateTime).toIso8601String();
        }
        if (serializedMeal['cancelledAt'] is DateTime) {
          serializedMeal['cancelledAt'] =
              (serializedMeal['cancelledAt'] as DateTime).toIso8601String();
        }

        serializableMeals.add(serializedMeal);
      }

      final String jsonString = jsonEncode(serializableMeals);
      await prefs.setString(_storageKey, jsonString);

      log('[cancelled meal flow] Saved ${_cancellationHistory.length} cancelled meals to storage');
    } catch (e) {
      log('[cancelled meal flow] Error saving cancelled meals to storage: $e');
    }
  }

  // Get a subscription by ID
  Future<Subscription?> getSubscriptionById(String subscriptionId) async {
    try {
      return _subscriptions.firstWhere(
        (s) => s.id == subscriptionId,
        orElse: () => throw Exception('Subscription not found'),
      );
    } catch (e) {
      log('[cancelled meal flow] Error finding subscription: $e');
      // Return a default subscription if not found
      return Subscription(
        id: subscriptionId,
        studentId: 'unknown',
        planType: 'lunch',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        selectedWeekdays: [1, 2, 3, 4, 5],
        mealName: 'Standard Meal',
      );
    }
  }

  // Cancel a meal for a specific date and subscription
  Future<bool> cancelMealDelivery(String subscriptionId, DateTime date,
      {required String studentId}) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);

    log('[cancelled_meal_data_flow] Cancelling meal for subscription: $subscriptionId, date: ${DateFormat('yyyy-MM-dd').format(normalizedDate)}, student: $studentId');

    try {
      // Generate a unique ID for this cancellation
      final cancelId =
          'cancelled_${subscriptionId}_${normalizedDate.millisecondsSinceEpoch}';

      // Check if the meal was already cancelled
      final alreadyCancelled = _cancellationHistory.any((meal) =>
          meal['subscriptionId'] == subscriptionId &&
          _isSameDay(meal['date'] as DateTime, normalizedDate));

      if (alreadyCancelled) {
        log('[cancelled_meal_data_flow] Meal already cancelled, skipping');
        return true; // Already cancelled, so consider it a success
      }

      // Get the subscription object
      final subscription = await getSubscriptionById(subscriptionId);
      if (subscription == null) {
        log('[cancelled_meal_data_flow] ERROR: Subscription not found: $subscriptionId');
        return false;
      }

      // Get student name for the cancellation record
      final studentName = await _getStudentName(studentId);
      log('[cancelled_meal_data_flow] Retrieved student name for cancellation: $studentName');

      // Create cancellation record
      final cancellation = {
        'id': cancelId,
        'subscriptionId': subscriptionId,
        'studentId': studentId,
        'studentName': studentName,
        'planType': subscription.planType,
        'mealName': subscription.getMealNameForDate(
            normalizedDate), // Use the meal name from subscription
        'date': normalizedDate,
        'cancelledAt': DateTime.now(),
        'cancelledBy': 'parent',
        'reason': 'Cancelled by parent',
      };

      // Add to cancellation history
      _cancellationHistory.add(cancellation);

      // Save the updated cancellation history to SharedPreferences
      await _saveCancelledMealsToStorage();

      // Also save this specific cancellation to SharedPreferences for fast local lookup
      final prefs = await SharedPreferences.getInstance();
      final localKey =
          'cancelledMeal_${studentId}_${subscriptionId}_${DateFormat('yyyy-MM-dd').format(normalizedDate)}';
      await prefs.setBool(localKey, true);

      log('[cancelled_meal_data_flow] Successfully cancelled meal, added to history. Total cancelled: ${_cancellationHistory.length}');
      log('[cancelled_meal_data_flow] Cancellation details - ID: ${cancellation['id']}, Student: ${cancellation['studentName']}, Meal: ${cancellation['mealName']}');

      // Also mark as cancelled in the subscription model
      if (subscription != null) {
        subscription.addCancelledDate(normalizedDate);
        log('[cancelled_meal_data_flow] Marked date as cancelled in subscription model');
      }

      // Log all cancellations for debugging
      _logAllCancellationRecords();

      return true;
    } catch (e) {
      log('[cancelled_meal_data_flow] Error cancelling meal: $e');
      return false;
    }
  }

  // Get all cancelled meals for a student
  Future<List<CancelledMeal>> getCancelledMeals(String? studentId) async {
    log('[cancelled meal flow] Getting cancelled meals for student: ${studentId ?? "all"}');

    // Simulate network delay (reduced for faster response)
    await Future.delayed(const Duration(milliseconds: 200));

    _logAllCancellationRecords();

    try {
      if (studentId == null) {
        log('[cancelled meal flow] Returning all ${_cancellationHistory.length} cancelled meals');
        final allMeals = _cancellationHistory
            .map((map) => CancelledMeal.fromMap(map))
            .toList();
        return allMeals;
      }

      final filteredMeals = _cancellationHistory
          .where((meal) => meal['studentId'] == studentId)
          .toList();

      log('[cancelled meal flow] Found ${filteredMeals.length} cancelled meals for student: $studentId');

      // Log each cancelled meal for debugging
      for (var meal in filteredMeals) {
        log('[cancelled meal flow] Found meal: ${meal['name']} on ${DateFormat('yyyy-MM-dd').format(meal['date'] as DateTime)}');
      }

      final cancelledMeals =
          filteredMeals.map((map) => CancelledMeal.fromMap(map)).toList();

      // Sort by timestamp, newest first
      cancelledMeals.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return cancelledMeals;
    } catch (e) {
      log('[cancelled meal flow] Error getting cancelled meals: $e');
      return [];
    }
  }

  // Get student name helper
  Future<String> _getStudentName(String studentId) async {
    try {
      final students = await _studentProfileService.getStudentProfiles();
      final student = students.firstWhere(
        (s) => s.id == studentId,
        orElse: () => Student(
          id: studentId,
          name: 'Unknown Student',
          schoolName: 'Unknown School',
          className: 'Unknown Class',
          division: 'Unknown Division',
          floor: 'Unknown Floor',
          allergies: 'None',
          // schoolAddress: 'Unknown Address',
          grade: 'Unknown Grade',
          section: 'Unknown Section',
          profileImageUrl: '',
        ),
      );
      return student.name;
    } catch (e) {
      log('[cancelled meal flow] Error getting student name: $e');
      return 'Unknown Student';
    }
  }

  // Helper method to log all cancellation records for debugging
  void _logAllCancellationRecords() {
    log("[cancelled_meal_data_flow] === LOGGING ALL CANCELLATION RECORDS ===");
    log("[cancelled_meal_data_flow] Total records: ${_cancellationHistory.length}");

    for (var record in _cancellationHistory) {
      log("[cancelled_meal_data_flow] === RECORD START ===");
      log("[cancelled_meal_data_flow] ID: ${record['id']}");
      log("[cancelled_meal_data_flow] Subscription ID: ${record['subscriptionId']}");
      log("[cancelled_meal_data_flow] Student ID: ${record['studentId']}");
      log("[cancelled_meal_data_flow] Student Name: ${record['studentName']}");
      log("[cancelled_meal_data_flow] Date: ${DateFormat('yyyy-MM-dd').format(record['date'] as DateTime)}");
      log("[cancelled_meal_data_flow] Cancelled At: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(record['cancelledAt'] as DateTime)}");
      log("[cancelled_meal_data_flow] === RECORD END ===");
    }

    log("[cancelled_meal_data_flow] === END OF RECORDS ===");
  }

  // Helper method to check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Update the status of a meal in the service
  Future<bool> updateMealStatus(String subscriptionId, DateTime date,
      String status, String studentId) async {
    try {
      log("cancel meal flow: Updating meal status in service");
      log("cancel meal flow: Subscription ID: $subscriptionId, Date: ${DateFormat('yyyy-MM-dd').format(date)}, Status: $status, Student ID: $studentId");

      // If status is "Cancelled", ensure there's a cancellation record
      if (status == "Cancelled") {
        // Create a unique record ID
        final recordId = '${subscriptionId}_${date.millisecondsSinceEpoch}';

        // Check if we already have this record using the instance list
        bool alreadyExists =
            _cancellationHistory.any((record) => record['id'] == recordId);

        if (!alreadyExists) {
          log("cancel meal flow: Creating cancellation record as part of status update");

          // Create a cancellation record directly using the instance method
          await cancelMealDelivery(subscriptionId, date, studentId: studentId);
        } else {
          log("cancel meal flow: Cancellation record already exists, not creating duplicate");
        }
      }

      // Note: In a real app, this would update the database record
      // For the demo, we'll just log it
      log("cancel meal flow: Meal status updated successfully to: $status");
      return true;
    } catch (e) {
      log("cancel meal flow: Error updating meal status: $e");
      return false;
    }
  }

  // Swap a meal for a specific date
  Future<bool> swapMeal(String subscriptionId, String newMealName,
      [DateTime? date]) async {
    try {
      // If no date provided, use tomorrow as default
      final targetDate = date ?? DateTime.now().add(const Duration(days: 1));

      log("swap flow: Starting meal swap for subscription ID: $subscriptionId");
      log("swap flow: New meal name: $newMealName");
      log("swap flow: Target date: ${DateFormat('yyyy-MM-dd').format(targetDate)}");

      // Create a temporary subscription to handle the swap
      final subscription = Subscription(
        id: subscriptionId,
        studentId: subscriptionId.contains('-')
            ? subscriptionId.split('-').sublist(1).join('-')
            : 'unknown',
        planType:
            subscriptionId.startsWith('breakfast') ? 'breakfast' : 'lunch',
        mealName: 'Standard Meal',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
      );

      // Call the subscription model's swapMeal method
      return await subscription.swapMeal(
          subscriptionId, newMealName, targetDate);
    } catch (e) {
      log('swap flow: Error in subscription service swapMeal: $e');
      return false;
    }
  }

  // Get active subscriptions for a student by delegating to the model's implementation
  Future<List<Subscription>> getActiveSubscriptionsForStudent(
      String studentId) async {
    log('Getting active subscriptions for student: $studentId');
    try {
      // In a real app, this would fetch from a database or API
      // Here we'll use the existing StudentProfileService to get student data
      // This is a simplified version of the model's implementation
      final studentProfileService = StudentProfileService();
      final students = await studentProfileService.getStudentProfiles();
      final student = students.firstWhere(
        (student) => student.id == studentId,
        orElse: () => throw Exception('Student not found'),
      );

      // Create subscriptions based on actual student meal plans
      final List<Subscription> subscriptions = [];

      // Add breakfast subscription if active
      if (student.hasActiveBreakfast && student.breakfastPlanEndDate != null) {
        final DateTime subscriptionStartDate =
            student.breakfastPlanStartDate ?? DateTime.now();

        final subscription = Subscription(
          id: 'breakfast-${student.id}',
          studentId: student.id,
          planType: 'breakfast',
          mealName: 'Indian Breakfast',
          startDate: subscriptionStartDate,
          endDate: student.breakfastPlanEndDate!,
        );

        subscriptions.add(subscription);
      }

      // Add lunch or express subscription if active
      if (student.hasActiveLunch && student.lunchPlanEndDate != null) {
        final planType =
            student.mealPlanType == 'express' ? 'express' : 'lunch';
        final DateTime subscriptionStartDate =
            student.lunchPlanStartDate ?? DateTime.now();

        final subscription = Subscription(
          id: '$planType-${student.id}',
          studentId: student.id,
          planType: planType,
          mealName: 'Indian Lunch',
          startDate: subscriptionStartDate,
          endDate: student.lunchPlanEndDate!,
        );

        subscriptions.add(subscription);
      }

      // If no active subscriptions are found from the student model, return demo data
      if (subscriptions.isEmpty) {
        log('No active subscriptions found, returning demo subscriptions');

        final now = DateTime.now();
        final oneMonthLater = DateTime(now.year, now.month + 1, now.day);

        subscriptions.add(Subscription(
          id: '1-${studentId}',
          studentId: studentId,
          planType: 'breakfast',
          mealName: 'Indian Breakfast',
          startDate: now,
          endDate: oneMonthLater,
        ));

        subscriptions.add(Subscription(
          id: '2-${studentId}',
          studentId: studentId,
          planType: 'lunch',
          mealName: 'Standard Lunch',
          startDate: now,
          endDate: oneMonthLater,
        ));
      }

      return subscriptions;
    } catch (e) {
      log('Error getting active subscriptions: $e');
      return [];
    }
  }
}
