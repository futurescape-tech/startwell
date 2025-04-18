import 'package:startwell/models/student_model.dart';
import 'package:startwell/models/subscription_model.dart';

/// Represents subscription plan data for a student
/// This is used for displaying subscription information in the UI
class SubscriptionPlanData {
  final Student student;
  final Subscription subscription;
  final String planType;
  final int totalMeals;
  final int remainingMeals;
  final String nextRenewalDate;

  SubscriptionPlanData({
    required this.student,
    required this.subscription,
    required this.planType,
    required this.totalMeals,
    required this.remainingMeals,
    required this.nextRenewalDate,
  });

  @override
  String toString() {
    return 'SubscriptionPlanData(student: ${student.name}, planType: $planType, totalMeals: $totalMeals, remainingMeals: $remainingMeals)';
  }
}
