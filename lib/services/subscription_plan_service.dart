import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:startwell/models/subscription_plan_model.dart';

class SubscriptionPlanService {
  static const String _storageKey = 'selected_subscription_plan';

  // Save subscription plan
  static Future<void> saveSubscriptionPlan(SubscriptionPlanModel plan) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(plan.toJson());
    await prefs.setString(_storageKey, jsonString);
  }

  // Get subscription plan
  static Future<SubscriptionPlanModel?> getSubscriptionPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString == null) {
      return null;
    }

    try {
      final json = jsonDecode(jsonString);
      return SubscriptionPlanModel.fromJson(json);
    } catch (e) {
      print('Error loading subscription plan: $e');
      return null;
    }
  }

  // Clear subscription plan
  static Future<void> clearSubscriptionPlan() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  // Calculate end date based on plan type and start date
  static DateTime calculateEndDate(String planType, DateTime startDate) {
    switch (planType) {
      case 'Single Day':
        return startDate; // Same day
      case 'Weekly':
        return startDate.add(const Duration(days: 6));
      case 'Monthly':
        return startDate.add(const Duration(days: 29));
      case 'Quarterly':
        return startDate.add(const Duration(days: 89));
      case 'Half-Yearly':
        return startDate.add(const Duration(days: 179));
      case 'Annual':
        return startDate.add(const Duration(days: 364));
      default:
        return startDate.add(const Duration(days: 29)); // Default to monthly
    }
  }

  // Convert weekday booleans to day names
  static List<String> weekdaysToNames(List<bool> selectedWeekdays) {
    final List<String> dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
    final List<String> result = [];

    for (int i = 0; i < selectedWeekdays.length && i < dayNames.length; i++) {
      if (selectedWeekdays[i]) {
        result.add(dayNames[i]);
      }
    }

    return result;
  }
}
