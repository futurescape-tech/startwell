import 'dart:developer' as dev;

import 'package:intl/intl.dart';
import 'package:startwell/models/subscription_model.dart';

/// A utility class for debugging subscription plan type issues
/// This provides centralized logging and validation functions to help
/// identify issues with plan type calculations and display.
class PlanTypeDebugger {
  // Singleton pattern
  static final PlanTypeDebugger _instance = PlanTypeDebugger._internal();
  factory PlanTypeDebugger() => _instance;
  PlanTypeDebugger._internal();

  /// Track occurrences of each plan type for statistics
  final Map<String, int> _planTypeOccurrences = {
    'Single Day': 0,
    'Weekly': 0,
    'Monthly': 0,
    'Quarterly': 0,
    'Half-Yearly': 0,
    'Annual': 0,
    'Express': 0,
    'Unknown': 0,
  };

  /// Log subscription information with detailed context
  void logSubscription(Subscription subscription, {String? context}) {
    final int days =
        subscription.endDate.difference(subscription.startDate).inDays;
    final String prefix = context != null ? "[$context] " : "";

    dev.log('$prefix🔎 SUBSCRIPTION DETAILS:');
    dev.log('${prefix}ID: ${subscription.id}');
    dev.log('${prefix}Plan type: ${subscription.planType}');
    dev.log('${prefix}Plan display name: ${subscription.planDisplayName}');
    dev.log(
        '${prefix}Duration enum: ${subscription.duration} (index: ${subscription.duration.index})');
    dev.log(
        '${prefix}Start date: ${DateFormat('yyyy-MM-dd').format(subscription.startDate)}');
    dev.log(
        '${prefix}End date: ${DateFormat('yyyy-MM-dd').format(subscription.endDate)}');
    dev.log('${prefix}Days between: $days');

    // Track this occurrence for statistics
    _incrementPlanTypeOccurrence(subscription.durationDisplayName);
  }

  /// Validate if the subscription's duration matches its date range
  bool validateDuration(Subscription subscription) {
    final int days =
        subscription.endDate.difference(subscription.startDate).inDays;
    bool isValid = false;

    // Use the same logic as in _getDurationFromEndDate
    if (days <= 1 && subscription.duration == SubscriptionDuration.singleDay) {
      isValid = true;
    } else if (days <= 7 &&
        subscription.duration == SubscriptionDuration.weekly) {
      isValid = true;
    } else if (days <= 31 &&
        subscription.duration == SubscriptionDuration.monthly) {
      isValid = true;
    } else if (days <= 100 &&
        subscription.duration == SubscriptionDuration.quarterly) {
      isValid = true;
    } else if (days <= 190 &&
        subscription.duration == SubscriptionDuration.halfYearly) {
      isValid = true;
    } else if (days > 190 &&
        subscription.duration == SubscriptionDuration.annual) {
      isValid = true;
    }

    if (!isValid) {
      dev.log(
          '⚠️ INVALID DURATION: Subscription ${subscription.id} has ${subscription.duration} but date range is $days days');
    }

    return isValid;
  }

  /// Track statistics on plan type occurrences
  void _incrementPlanTypeOccurrence(String planType) {
    if (_planTypeOccurrences.containsKey(planType)) {
      _planTypeOccurrences[planType] =
          (_planTypeOccurrences[planType] ?? 0) + 1;
    } else {
      _planTypeOccurrences['Unknown'] =
          (_planTypeOccurrences['Unknown'] ?? 0) + 1;
    }
  }

  /// Print statistics about plan type occurrences
  void printPlanTypeStatistics() {
    dev.log('📊 PLAN TYPE STATISTICS:');
    _planTypeOccurrences.forEach((planType, count) {
      dev.log('📊 $planType: $count occurrences');
    });
  }

  /// Reset the statistics counter
  void resetStatistics() {
    _planTypeOccurrences.updateAll((key, value) => 0);
  }
}
