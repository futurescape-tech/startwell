import 'dart:convert';
import 'dart:developer';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:startwell/models/cancelled_meal.dart';

/// Service class to handle cancelled meals storage and retrieval
class CancelledMealService {
  // Singleton instance
  static final CancelledMealService _instance =
      CancelledMealService._internal();

  // Factory constructor to return the same instance
  factory CancelledMealService() {
    return _instance;
  }

  // Private constructor
  CancelledMealService._internal() {
    log('[cancelled_meal_service] Initialized CancelledMealService');
    _loadFromSharedPreferences();
  }

  // Storage key for all cancelled meals
  static const String _storageKey = 'all_cancelled_meals';

  // In-memory cache of cancelled meals
  final List<Map<String, dynamic>> _cancelledMeals = [];

  // Load all cancelled meals from SharedPreferences
  Future<void> _loadFromSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? storedData = prefs.getString(_storageKey);

      if (storedData != null && storedData.isNotEmpty) {
        final List<dynamic> mealsData = jsonDecode(storedData);

        _cancelledMeals.clear();
        for (var mealData in mealsData) {
          _cancelledMeals.add(Map<String, dynamic>.from(mealData));
        }

        log('[cancelled_meal_service] Loaded ${_cancelledMeals.length} cancelled meals from SharedPreferences');
      } else {
        log('[cancelled_meal_service] No cancelled meals found in SharedPreferences');
      }
    } catch (e) {
      log('[cancelled_meal_service] Error loading cancelled meals: $e');
    }
  }

  // Save all cancelled meals to SharedPreferences
  Future<void> _saveToSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = jsonEncode(_cancelledMeals);
      await prefs.setString(_storageKey, jsonData);
      log('[cancelled_meal_service] Saved ${_cancelledMeals.length} cancelled meals to SharedPreferences');
    } catch (e) {
      log('[cancelled_meal_service] Error saving cancelled meals: $e');
    }
  }

  // Add a new cancelled meal
  Future<bool> addCancelledMeal({
    required String subscriptionId,
    required String studentId,
    required String studentName,
    required String planType,
    required String mealName,
    required DateTime cancellationDate,
    required String cancelledBy,
    String? reason,
  }) async {
    try {
      final String id =
          'cancelled_${subscriptionId}_${cancellationDate.millisecondsSinceEpoch}';

      // Check if this meal is already cancelled
      bool alreadyCancelled = _cancelledMeals.any((meal) =>
          meal['subscriptionId'] == subscriptionId &&
          _isSameDay(DateTime.parse(meal['date']), cancellationDate));

      if (alreadyCancelled) {
        log('[cancelled_meal_service] Meal already cancelled, skipping');
        return true;
      }

      // Create cancellation record
      final Map<String, dynamic> cancelledMeal = {
        'id': id,
        'subscriptionId': subscriptionId,
        'studentId': studentId,
        'studentName': studentName,
        'planType': planType,
        'mealName': mealName,
        'date': cancellationDate.toIso8601String(),
        'cancelledAt': DateTime.now().toIso8601String(),
        'cancelledBy': cancelledBy,
        'reason': reason ?? 'Cancelled by $cancelledBy',
      };

      // Log meal plan type for debugging
      log('[cancelled_meal_service] Adding cancelled meal with planType: $planType, will display as: ${planType == 'breakfast' ? 'Breakfast' : 'Lunch'}');

      // Add to in-memory list
      _cancelledMeals.add(cancelledMeal);

      // Save to SharedPreferences
      await _saveToSharedPreferences();

      // Also save individual entry for quick lookup
      final prefs = await SharedPreferences.getInstance();
      final cancelKey =
          'cancelledMeal_${studentId}_${subscriptionId}_${DateFormat('yyyy-MM-dd').format(cancellationDate)}';
      await prefs.setString(cancelKey, jsonEncode(cancelledMeal));

      log('[cancelled_meal_service] Successfully cancelled meal: $mealName for $studentName on ${DateFormat('yyyy-MM-dd').format(cancellationDate)}');

      return true;
    } catch (e) {
      log('[cancelled_meal_service] Error cancelling meal: $e');
      return false;
    }
  }

  // Get all cancelled meals
  Future<List<CancelledMeal>> getAllCancelledMeals() async {
    await _loadFromSharedPreferences();

    final List<CancelledMeal> meals = [];

    for (var mealData in _cancelledMeals) {
      try {
        // Create copy to avoid modifying the original
        final Map<String, dynamic> copy = Map<String, dynamic>.from(mealData);

        // Convert string dates to DateTime objects if needed
        if (copy['date'] is String) {
          copy['date'] = DateTime.parse(copy['date']);
        }
        if (copy['cancelledAt'] is String) {
          copy['cancelledAt'] = DateTime.parse(copy['cancelledAt']);
        }

        meals.add(CancelledMeal.fromMap(copy));
      } catch (e) {
        log('[cancelled_meal_service] Error converting meal data: $e');
      }
    }

    return meals;
  }

  // Get cancelled meals for a specific student
  Future<List<CancelledMeal>> getCancelledMealsForStudent(
      String studentId) async {
    final allMeals = await getAllCancelledMeals();
    return allMeals.where((meal) => meal.studentId == studentId).toList();
  }

  // Check if a meal is cancelled
  Future<bool> isMealCancelled(String subscriptionId, DateTime date) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);

    return _cancelledMeals.any((meal) =>
        meal['subscriptionId'] == subscriptionId &&
        _isSameDay(DateTime.parse(meal['date']), normalizedDate));
  }

  // Delete all cancelled meals for testing
  Future<void> clearAllCancelledMeals() async {
    _cancelledMeals.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);

    // Also clear individual meal entries
    final keys = prefs
        .getKeys()
        .where((key) => key.startsWith('cancelledMeal_'))
        .toList();
    for (var key in keys) {
      await prefs.remove(key);
    }

    log('[cancelled_meal_service] Cleared all cancelled meals');
  }

  // Helper to check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
