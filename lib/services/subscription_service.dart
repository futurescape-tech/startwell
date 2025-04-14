import 'dart:developer';
import 'package:intl/intl.dart';
import 'package:startwell/models/cancelled_meal.dart';

class SubscriptionService {
  // Static list to store cancellation history
  static final List<Map<String, dynamic>> _cancelledMealsHistory = [];

  Future<bool> cancelMealDelivery(String subscriptionId, DateTime date,
      {String? reason}) async {
    try {
      log("meal delete flow: starting cancelMealDelivery for $subscriptionId");

      // Normalize the date to avoid time issues
      final normalizedDate = DateTime(date.year, date.month, date.day);

      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 800));

      // Log the cancellation details
      log('meal delete flow: Cancelling meal delivery:');
      log('meal delete flow: Subscription ID: $subscriptionId');
      log('meal delete flow: Date: ${DateFormat('yyyy-MM-dd').format(normalizedDate)}');
      log('meal delete flow: Reason: ${reason ?? "Not specified"}');

      // In a real implementation, this would:
      // 1. Mark the meal as cancelled in the database
      // 2. Add to cancellation history with reason
      // 3. Update next delivery date if needed
      // 4. Handle any notifications/emails

      // Extract info from the subscription ID (usually format: planType-studentId)
      List<String> parts = subscriptionId.split('-');
      String planType = parts.isNotEmpty ? parts[0] : 'unknown';
      String studentId =
          parts.length > 1 ? parts.sublist(1).join('-') : 'unknown-student';

      log("meal delete flow: Extracted planType=$planType, studentId=$studentId");

      // Create cancellation record
      final cancellationRecord = {
        'id': '${subscriptionId}_${normalizedDate.millisecondsSinceEpoch}',
        'subscriptionId': subscriptionId,
        'studentId': studentId,
        'studentName':
            'Student Name', // Would come from real student data in production
        'planType': planType,
        'name': planType == 'breakfast' ? 'Breakfast' : 'Lunch',
        'date': normalizedDate,
        'cancelledAt': DateTime.now(),
        'cancelledBy': 'user',
        'reason': reason ?? 'Cancelled by Parent',
      };

      // Add to cancellation history
      _cancelledMealsHistory.add(cancellationRecord);

      log("meal delete flow: Added cancellation record to history");
      log("meal delete flow: Total cancellation records: ${_cancelledMealsHistory.length}");

      // For debugging, print all cancellation records
      int count = 0;
      for (var record in _cancelledMealsHistory) {
        log("meal delete flow: Record #${++count}: ${record['subscriptionId']} on ${DateFormat('yyyy-MM-dd').format(record['date'] as DateTime)}");
      }

      log("meal delete flow: cancelMealDelivery completed successfully");
      return true;
    } catch (e) {
      log('meal delete flow: Error cancelling meal delivery: $e');
      return false;
    }
  }

  // Get cancelled meals for a student
  Future<List<CancelledMeal>> getCancelledMeals(String? studentId) async {
    log("meal delete flow: getCancelledMeals called for studentId: ${studentId ?? 'ALL'}");
    log("meal delete flow: Total records in history: ${_cancelledMealsHistory.length}");

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    List<Map<String, dynamic>> result;

    // Filter by student if ID is provided
    if (studentId != null) {
      log("meal delete flow: Filtering by studentId: $studentId");

      result = _cancelledMealsHistory
          .where((meal) => meal['studentId'] == studentId)
          .toList();

      log("meal delete flow: Found ${result.length} cancelled meals for student");
    } else {
      // Return all cancelled meals
      result = List<Map<String, dynamic>>.from(_cancelledMealsHistory);
      log("meal delete flow: Returning all ${result.length} cancelled meals");
    }

    // Sort by cancellation date (most recent first)
    result.sort((a, b) =>
        (b['cancelledAt'] as DateTime).compareTo(a['cancelledAt'] as DateTime));

    // Convert the Map<String, dynamic> to CancelledMeal objects
    final cancelledMeals =
        result.map((map) => CancelledMeal.fromMap(map)).toList();

    return cancelledMeals;
  }
}
