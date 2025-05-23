import 'dart:developer';
import 'package:intl/intl.dart';

/// Model class for representing a cancelled meal in the system.
class CancelledMeal {
  final String id;
  final String subscriptionId;
  final String studentId;
  final String studentName;
  final String planType;
  final String mealName;
  final DateTime cancellationDate;
  final DateTime timestamp;
  final String cancelledBy;
  final String? reason;

  CancelledMeal({
    required this.id,
    required this.subscriptionId,
    required this.studentId,
    required this.studentName,
    required this.planType,
    required this.mealName,
    required this.cancellationDate,
    required this.timestamp,
    required this.cancelledBy,
    this.reason,
  });

  /// Factory constructor to create a CancelledMeal from a map (JSON data)
  factory CancelledMeal.fromMap(Map<String, dynamic> map) {
    // Log conversion to help debug
    try {
      log('[cancelled meal flow] Converting map to CancelledMeal: ${map['id']}');

      // Handle date conversion, since date might come in different formats
      DateTime parseDate(dynamic dateValue) {
        if (dateValue is DateTime) {
          return dateValue;
        } else if (dateValue is String) {
          return DateTime.parse(dateValue);
        } else {
          throw FormatException('Invalid date format: $dateValue');
        }
      }

      final cancelledMeal = CancelledMeal(
        id: map['id'] as String,
        subscriptionId: map['subscriptionId'] as String,
        studentId: map['studentId'] as String,
        studentName: map['studentName'] as String,
        planType: map['planType'] as String,
        mealName: (map['mealName'] ?? map['name']) as String,
        cancellationDate: parseDate(map['date']),
        timestamp: parseDate(map['cancelledAt']),
        cancelledBy: map['cancelledBy'] as String,
        reason: map['reason'] as String?,
      );

      log('[cancelled meal flow] Successfully converted to CancelledMeal - ID: ${cancelledMeal.id}, Student: ${cancelledMeal.studentName}, Date: ${DateFormat('yyyy-MM-dd').format(cancelledMeal.cancellationDate)}');

      return cancelledMeal;
    } catch (e) {
      log('[cancelled meal flow] Error converting map to CancelledMeal: $e');
      log('[cancelled meal flow] Map contents: $map');
      rethrow;
    }
  }

  /// Convert this CancelledMeal instance to a map (JSON data)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subscriptionId': subscriptionId,
      'studentId': studentId,
      'studentName': studentName,
      'planType': planType,
      'mealName': mealName,
      'date': cancellationDate,
      'cancelledAt': timestamp,
      'cancelledBy': cancelledBy,
      'reason': reason,
    };
  }

  @override
  String toString() {
    return 'CancelledMeal(id: $id, subscription: $subscriptionId, student: $studentName, date: ${DateFormat('yyyy-MM-dd').format(cancellationDate)})';
  }
}
