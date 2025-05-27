import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionPlanStorageService {
  static const String planDetailsKey = 'selected_plan_details';
  static const String mealTypeKey = 'selected_meal_type';
  static const String preOrderDatesKey = 'pre_order_dates';

  // Save plan details to shared preferences
  static Future<void> savePlanDetails({
    required String selectedPlanType,
    required String deliveryMode,
    String? mealType,
    bool hasBreakfastInCart = false,
    bool hasLunchInCart = false,
    String? breakfastDeliveryMode,
    String? lunchDeliveryMode,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final planDetails = {
      'selectedPlanType': selectedPlanType,
      'deliveryMode': deliveryMode,
      'mealType': mealType,
      'hasBreakfastInCart': hasBreakfastInCart,
      'hasLunchInCart': hasLunchInCart,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'breakfastDeliveryMode': breakfastDeliveryMode,
      'lunchDeliveryMode': lunchDeliveryMode,
    };

    // Save as JSON string
    await prefs.setString(planDetailsKey, jsonEncode(planDetails));
    print('DEBUG: Saved plan details to SharedPreferences: $planDetails');
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

  // Load plan details from shared preferences
  static Future<Map<String, dynamic>?> loadPlanDetails() async {
    final prefs = await SharedPreferences.getInstance();

    final String? planDetailsJson = prefs.getString(planDetailsKey);

    if (planDetailsJson == null || planDetailsJson.isEmpty) {
      return null;
    }

    // Parse JSON string to Map
    try {
      final Map<String, dynamic> decodedDetails = jsonDecode(planDetailsJson);
      print(
          'DEBUG: Loaded plan details from SharedPreferences: $decodedDetails');

      return {
        'selectedPlanType': decodedDetails['selectedPlanType'],
        'deliveryMode': decodedDetails['deliveryMode'],
        'mealType': decodedDetails['mealType'],
        'hasBreakfastInCart': decodedDetails['hasBreakfastInCart'] ?? false,
        'hasLunchInCart': decodedDetails['hasLunchInCart'] ?? false,
        'breakfastDeliveryMode': decodedDetails['breakfastDeliveryMode'],
        'lunchDeliveryMode': decodedDetails['lunchDeliveryMode'],
      };
    } catch (e) {
      print('ERROR: Failed to parse plan details: $e');
      return null;
    }
  }

  // Clear plan details
  static Future<void> clearPlanDetails() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(planDetailsKey);
    print('DEBUG: Cleared plan details from SharedPreferences');
  }

  // Clear pre-order dates
  static Future<void> clearPreOrderDates() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(preOrderDatesKey);
    print('DEBUG: Cleared pre-order dates from SharedPreferences');
  }

  // Clear all storage
  static Future<void> clearAll() async {
    await clearPlanDetails();
    await clearPreOrderDates();
  }
}
