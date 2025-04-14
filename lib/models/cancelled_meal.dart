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
    return CancelledMeal(
      id: map['id'] as String,
      subscriptionId: map['subscriptionId'] as String,
      studentId: map['studentId'] as String,
      studentName: map['studentName'] as String,
      planType: map['planType'] as String,
      mealName: map['name'] as String,
      cancellationDate: map['date'] as DateTime,
      timestamp: map['cancelledAt'] as DateTime,
      cancelledBy: map['cancelledBy'] as String,
      reason: map['reason'] as String?,
    );
  }

  /// Convert this CancelledMeal instance to a map (JSON data)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subscriptionId': subscriptionId,
      'studentId': studentId,
      'studentName': studentName,
      'planType': planType,
      'name': mealName,
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
