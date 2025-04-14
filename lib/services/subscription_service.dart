import 'dart:developer';
import 'package:intl/intl.dart';
import 'package:startwell/models/cancelled_meal.dart';
import 'package:startwell/services/event_bus_service.dart';

class SubscriptionService {
  // Static list to store cancellation history
  static final List<Map<String, dynamic>> _cancelledMealsHistory = [];

  Future<bool> cancelMealDelivery(String subscriptionId, DateTime date,
      {String? reason, String? studentId}) async {
    try {
      log("cancel meal flow: starting cancelMealDelivery for $subscriptionId");

      // Normalize the date to avoid time issues
      final normalizedDate = DateTime(date.year, date.month, date.day);

      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 800));

      // Log the cancellation details
      log('cancel meal flow: Cancelling meal delivery:');
      log('cancel meal flow: Subscription ID: $subscriptionId');
      log('cancel meal flow: Date: ${DateFormat('yyyy-MM-dd').format(normalizedDate)}');
      log('cancel meal flow: Reason: ${reason ?? "Not specified"}');
      log('cancel meal flow: Student ID: ${studentId ?? "Not specified directly"}');

      // In a real implementation, this would:
      // 1. Mark the meal as cancelled in the database
      // 2. Add to cancellation history with reason
      // 3. Update next delivery date if needed
      // 4. Handle any notifications/emails

      // Extract info from the subscription ID (usually format: planType-studentId)
      List<String> parts = subscriptionId.split('-');
      String planType = parts.isNotEmpty ? parts[0] : 'unknown';
      String extractedStudentId =
          parts.length > 1 ? parts.sublist(1).join('-') : 'unknown-student';

      // Use provided student ID if available, otherwise use extracted one
      String finalStudentId = studentId ?? extractedStudentId;

      log("cancel meal flow: Extracted planType=$planType, extracted studentId=$extractedStudentId");
      log("cancel meal flow: Using finalStudentId=$finalStudentId for cancellation record");

      // Create cancellation record with unique ID based on subscription and date
      final recordId =
          '${subscriptionId}_${normalizedDate.millisecondsSinceEpoch}';

      // Check if we already have this cancellation in history
      bool alreadyCancelled = false;
      for (var existingRecord in _cancelledMealsHistory) {
        if (existingRecord['id'] == recordId) {
          log("cancel meal flow: Meal already cancelled in history, skipping duplicate record");
          alreadyCancelled = true;
          break;
        }
      }

      if (!alreadyCancelled) {
        // Create cancellation record
        final cancellationRecord = {
          'id': recordId,
          'subscriptionId': subscriptionId,
          'studentId': finalStudentId,
          'studentName':
              'Student Name', // Would come from real student data in production
          'planType': planType,
          'name': planType == 'breakfast' ? 'Breakfast' : 'Lunch',
          'date': normalizedDate,
          'cancelledAt': DateTime.now(),
          'cancelledBy': 'user',
          'reason': reason ?? 'Cancelled by Parent',
          'status': 'Cancelled', // Explicitly set status
        };

        // Add to cancellation history
        _cancelledMealsHistory.add(cancellationRecord);

        log("cancel meal flow: Added cancellation record to history");
        log("cancel meal flow: Total cancellation records: ${_cancelledMealsHistory.length}");
      }

      // For debugging, print all cancellation records
      _logAllCancellationRecords();

      // Fire event to notify other components of the cancellation
      log("cancel meal flow: Firing meal cancelled event");
      eventBus.fireMealCancelled(MealCancelledEvent(
        subscriptionId,
        normalizedDate,
        studentId: finalStudentId,
        shouldNavigateToTab: true,
      ));
      log("cancel meal flow: Event dispatched");

      log("cancel meal flow: cancelMealDelivery completed successfully");
      return true;
    } catch (e) {
      log('cancel meal flow: Error cancelling meal delivery: $e');
      return false;
    }
  }

  // Helper method to log all cancellation records for debugging
  void _logAllCancellationRecords() {
    int count = 0;
    log("cancel meal flow: === ALL CANCELLATION RECORDS ===");
    for (var record in _cancelledMealsHistory) {
      log("cancel meal flow: Record #${++count}: ${record['subscriptionId']} on ${DateFormat('yyyy-MM-dd').format(record['date'] as DateTime)}");
    }
    log("cancel meal flow: === END OF RECORDS ===");
  }

  // Get cancelled meals for a student
  Future<List<CancelledMeal>> getCancelledMeals(String? studentId) async {
    log("cancel meal flow: getCancelledMeals called for studentId: ${studentId ?? 'ALL'}");
    log("cancel meal flow: Total records in history: ${_cancelledMealsHistory.length}");

    // Log all records available for debugging
    _logAllCancellationRecords();

    // Simulate network delay - slightly longer to ensure all processing is complete
    await Future.delayed(const Duration(milliseconds: 500));

    List<Map<String, dynamic>> result;

    // Filter by student if ID is provided
    if (studentId != null) {
      log("cancel meal flow: Filtering by studentId: $studentId");

      result = _cancelledMealsHistory
          .where((meal) => meal['studentId'] == studentId)
          .toList();

      log("cancel meal flow: Found ${result.length} cancelled meals for student");

      // Log each meal details
      for (var meal in result) {
        log("cancel meal flow: Meal - Name: ${meal['name']}, Date: ${DateFormat('yyyy-MM-dd').format(meal['date'] as DateTime)}, Student: ${meal['studentName']}");
      }
    } else {
      // Return all cancelled meals
      result = List<Map<String, dynamic>>.from(_cancelledMealsHistory);
      log("cancel meal flow: Returning all ${result.length} cancelled meals");
    }

    // If no results were found, this is unusual - log additional information
    if (result.isEmpty) {
      log("cancel meal flow: WARNING - No cancelled meals found");
      if (studentId != null) {
        log("cancel meal flow: Checking if any records exist for the student ID in any field");
        // Check if the student ID appears in any record at all
        final anyMatches = _cancelledMealsHistory.where((meal) {
          return meal.values
              .any((value) => value is String && value.contains(studentId));
        }).toList();

        if (anyMatches.isNotEmpty) {
          log("cancel meal flow: Found ${anyMatches.length} records containing the student ID somewhere");
          for (var match in anyMatches) {
            log("cancel meal flow: Potential match: ${match.toString()}");
          }
        }
      }
    }

    // Sort by cancellation date (most recent first)
    result.sort((a, b) =>
        (b['cancelledAt'] as DateTime).compareTo(a['cancelledAt'] as DateTime));

    // Convert the Map<String, dynamic> to CancelledMeal objects
    final cancelledMeals =
        result.map((map) => CancelledMeal.fromMap(map)).toList();

    log("cancel meal flow: Converted ${cancelledMeals.length} records to CancelledMeal objects");
    return cancelledMeals;
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

        // Check if we already have this record
        bool alreadyExists =
            _cancelledMealsHistory.any((record) => record['id'] == recordId);

        if (!alreadyExists) {
          log("cancel meal flow: Creating cancellation record as part of status update");

          // Create a cancellation record directly
          await cancelMealDelivery(subscriptionId, date,
              reason: "Cancelled via status update");
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
}
