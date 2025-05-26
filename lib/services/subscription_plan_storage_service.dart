import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionPlanStorageService {
  // Renamed to avoid conflict and indicate it's no longer the primary key for new plan details.
  static const String _legacyPlanDetailsKey = 'selected_plan_details';
  static const String _studentPlansKeyPrefix =
      'student_plans_'; // New prefix for student-specific plans

  static const String mealTypeKey =
      'selected_meal_type'; // Remains as is, if used independently
  static const String preOrderDatesKey = 'pre_order_dates'; // Remains as is

  // Save plan details to shared preferences, now per student
  static Future<void> savePlanDetails({
    String? studentId, // New required parameter
    required String selectedPlanType,
    required String deliveryMode,
    String? mealType,
    bool hasBreakfastInCart = false,
    bool hasLunchInCart = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final studentKey = '$_studentPlansKeyPrefix$studentId';

    List<Map<String, dynamic>> studentPlans = [];
    final String? existingPlansJson = prefs.getString(studentKey);

    if (existingPlansJson != null && existingPlansJson.isNotEmpty) {
      try {
        final List<dynamic> decodedList = jsonDecode(existingPlansJson);
        // Ensure all items in the list are correctly cast to Map<String, dynamic>
        studentPlans = decodedList
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      } catch (e) {
        print('Error decoding existing student plans for $studentId: $e');
        // Decide on error handling: clear corrupted data or start fresh
        studentPlans = []; // Starting fresh if decoding fails
      }
    }

    final newPlanDetails = {
      'selectedPlanType': selectedPlanType,
      'deliveryMode': deliveryMode,
      'mealType': mealType,
      'hasBreakfastInCart': hasBreakfastInCart,
      'hasLunchInCart': hasLunchInCart,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      // Consider adding a unique ID to each plan if needed for updates/deletions later
      // 'planId': UniqueKey().toString(),
    };

    studentPlans.add(newPlanDetails);

    await prefs.setString(studentKey, jsonEncode(studentPlans));
    print(
        'DEBUG: Saved plan details for student $studentId. Plan added: $newPlanDetails. Total plans now: ${studentPlans.length}');
  }

  // Save pre-order dates separately (useful for going back to modify)
  static Future<void> savePreOrderDates({
    DateTime? breakfastPreOrderDate,
    DateTime? lunchPreOrderDate,
    String? planType,
    String? deliveryMode,
  }) async {
    print('DEBUG: ========= SAVING PRE-ORDER DATES =========');
    print('DEBUG: Breakfast pre-order date: $breakfastPreOrderDate');
    print('DEBUG: Lunch pre-order date: $lunchPreOrderDate');
    print('DEBUG: Plan type: $planType');
    print('DEBUG: Delivery mode: $deliveryMode');

    final prefs = await SharedPreferences.getInstance();

    final datesMap = {
      'breakfastPreOrderDate': breakfastPreOrderDate?.toIso8601String(),
      'lunchPreOrderDate': lunchPreOrderDate?.toIso8601String(),
      'planType': planType,
      'deliveryMode': deliveryMode,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    final encodedJson = jsonEncode(datesMap);
    print('DEBUG: Encoded JSON to save: $encodedJson');

    await prefs.setString(preOrderDatesKey, encodedJson);
    print('DEBUG: Saved pre-order dates to SharedPreferences: $datesMap');
    print('DEBUG: =========================================');
  }

  // Load pre-order dates from shared preferences
  static Future<Map<String, dynamic>?> loadPreOrderDates() async {
    print('DEBUG: ========= LOADING PRE-ORDER DATES =========');
    final prefs = await SharedPreferences.getInstance();
    final String? datesJson = prefs.getString(preOrderDatesKey);

    print('DEBUG: Raw JSON from storage: $datesJson');

    if (datesJson == null || datesJson.isEmpty) {
      print('DEBUG: No pre-order dates found in storage');
      return null;
    }

    try {
      final Map<String, dynamic> decodedDates = jsonDecode(datesJson);
      print(
          'DEBUG: Loaded pre-order dates from SharedPreferences: $decodedDates');

      Map<String, dynamic> result = {};

      if (decodedDates['breakfastPreOrderDate'] != null) {
        final breakfastDate =
            DateTime.parse(decodedDates['breakfastPreOrderDate']);
        result['breakfastPreOrderDate'] = breakfastDate;
        print('DEBUG: Parsed breakfast date: $breakfastDate');
      } else {
        print('DEBUG: No breakfast pre-order date found in storage');
      }

      if (decodedDates['lunchPreOrderDate'] != null) {
        final lunchDate = DateTime.parse(decodedDates['lunchPreOrderDate']);
        result['lunchPreOrderDate'] = lunchDate;
        print('DEBUG: Parsed lunch date: $lunchDate');
      } else {
        print('DEBUG: No lunch pre-order date found in storage');
      }

      // Load plan details if available
      if (decodedDates['planType'] != null) {
        result['planType'] = decodedDates['planType'];
        print('DEBUG: Loaded plan type: ${decodedDates['planType']}');
      }

      if (decodedDates['deliveryMode'] != null) {
        result['deliveryMode'] = decodedDates['deliveryMode'];
        print('DEBUG: Loaded delivery mode: ${decodedDates['deliveryMode']}');
      }

      print('DEBUG: Final result map: $result');
      print('DEBUG: =========================================');
      return result;
    } catch (e) {
      print('ERROR: Failed to parse pre-order dates: $e');
      print('DEBUG: =========================================');
      return null;
    }
  }

  // Load plan details from shared preferences for a specific student
  static Future<List<Map<String, dynamic>>?> loadPlanDetails(
      {required String studentId} // New required parameter
      ) async {
    final prefs = await SharedPreferences.getInstance();
    final studentKey = '$_studentPlansKeyPrefix$studentId';
    final String? plansJson = prefs.getString(studentKey);

    if (plansJson == null || plansJson.isEmpty) {
      print(
          'DEBUG: No plan details found for student $studentId in SharedPreferences using key $studentKey');
      return null;
    }

    try {
      final List<dynamic> decodedList = jsonDecode(plansJson);
      // Ensure all items in the list are correctly cast to Map<String, dynamic>
      final List<Map<String, dynamic>> studentPlans = decodedList
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      print(
          'DEBUG: Loaded ${studentPlans.length} plan details for student $studentId from SharedPreferences: $studentPlans');
      return studentPlans;
    } catch (e) {
      print(
          'ERROR: Failed to parse plan details for student $studentId: $e. Raw JSON: $plansJson');
      return null;
    }
  }

  // Clear plan details for a specific student
  static Future<void> clearPlanDetails(
      {required String studentId} // New required parameter
      ) async {
    final prefs = await SharedPreferences.getInstance();
    final studentKey = '$_studentPlansKeyPrefix$studentId';
    await prefs.remove(studentKey);
    print(
        'DEBUG: Cleared plan details for student $studentId from SharedPreferences using key $studentKey');
  }

  // Clear pre-order dates (remains unchanged)
  static Future<void> clearPreOrderDates() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(preOrderDatesKey);
    print('DEBUG: Cleared pre-order dates from SharedPreferences');
  }

  // Clear all storage
  // Note: This method currently only clears preOrderDatesKey.
  // If it should clear all student plans, it needs to iterate through all student keys or have a list of them.
  // For now, its specific action is limited to preOrderDatesKey and the legacy key if desired.
  static Future<void> clearAll({bool clearLegacyGlobalPlan = false}) async {
    await clearPreOrderDates();
    if (clearLegacyGlobalPlan) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_legacyPlanDetailsKey);
      print(
          'DEBUG: Cleared legacy global plan details from SharedPreferences.');
    }
    // To clear all student-specific plans, you would need to discover all keys matching _studentPlansKeyPrefix
    // or maintain a list of student IDs who have plans. This is a more complex operation.
    print(
        'DEBUG: Cleared pre-order dates. Student-specific plans require targeted clearing or a more advanced clearAll strategy.');
  }
}
