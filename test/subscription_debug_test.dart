import 'package:flutter_test/flutter_test.dart';
import 'package:startwell/models/subscription_model.dart';

void main() {
  group('Subscription Duration Tests', () {
    test('Test different duration calculations', () {
      final subscriptionService = SubscriptionService();
      final now = DateTime.now();

      // Test Single Day
      final oneDayLater = now.add(const Duration(days: 1));
      final singleDayDuration =
          subscriptionService._getDurationFromEndDate(now, oneDayLater);
      expect(singleDayDuration, equals(SubscriptionDuration.singleDay));

      // Test Weekly
      final oneWeekLater = now.add(const Duration(days: 7));
      final weeklyDuration =
          subscriptionService._getDurationFromEndDate(now, oneWeekLater);
      expect(weeklyDuration, equals(SubscriptionDuration.weekly));

      // Test Monthly
      final oneMonthLater = now.add(const Duration(days: 30));
      final monthlyDuration =
          subscriptionService._getDurationFromEndDate(now, oneMonthLater);
      expect(monthlyDuration, equals(SubscriptionDuration.monthly));

      // Test Quarterly
      final threeMonthsLater = now.add(const Duration(days: 90));
      final quarterlyDuration =
          subscriptionService._getDurationFromEndDate(now, threeMonthsLater);
      expect(quarterlyDuration, equals(SubscriptionDuration.quarterly));

      // Test Half-Yearly
      final sixMonthsLater = now.add(const Duration(days: 180));
      final halfYearlyDuration =
          subscriptionService._getDurationFromEndDate(now, sixMonthsLater);
      expect(halfYearlyDuration, equals(SubscriptionDuration.halfYearly));

      // Test Annual
      final oneYearLater = now.add(const Duration(days: 365));
      final annualDuration =
          subscriptionService._getDurationFromEndDate(now, oneYearLater);
      expect(annualDuration, equals(SubscriptionDuration.annual));
    });

    test('Test plan display name generation', () {
      // Test various combinations of subscriptions and their display names
      final now = DateTime.now();

      // Test Express Plan
      final expressSub = Subscription(
        id: 'express-test',
        studentId: 'student1',
        planType: 'express',
        startDate: now,
        endDate: now.add(const Duration(days: 1)),
        duration: SubscriptionDuration.singleDay,
      );
      expect(expressSub.planDisplayName, equals('Express 1-Day Plan'));

      // Test Monthly Breakfast
      final monthlyBreakfast = Subscription(
        id: 'breakfast-monthly',
        studentId: 'student1',
        planType: 'breakfast',
        startDate: now,
        endDate: now.add(const Duration(days: 30)),
        duration: SubscriptionDuration.monthly,
      );
      expect(
          monthlyBreakfast.planDisplayName, equals('Monthly Breakfast Plan'));

      // Test Quarterly Lunch Plan
      final quarterlyLunch = Subscription(
        id: 'lunch-quarterly',
        studentId: 'student1',
        planType: 'lunch',
        startDate: now,
        endDate: now.add(const Duration(days: 90)),
        duration: SubscriptionDuration.quarterly,
      );
      expect(quarterlyLunch.planDisplayName, equals('Quarterly Lunch Plan'));

      // Test Custom Weekly Plan
      final customWeeklyLunch = Subscription(
        id: 'lunch-custom-weekly',
        studentId: 'student1',
        planType: 'lunch',
        startDate: now,
        endDate: now.add(const Duration(days: 7)),
        duration: SubscriptionDuration.weekly,
        selectedWeekdays: [1, 3, 5], // Mon, Wed, Fri
      );
      expect(customWeeklyLunch.planDisplayName,
          equals('Custom Weekly Lunch Plan'));
    });

    test('Test fixing subscription durations', () {
      final subscriptionService = SubscriptionService();
      final now = DateTime.now();

      // Create a subscription with incorrect duration
      final incorrectSub = Subscription(
        id: 'incorrect-duration',
        studentId: 'student1',
        planType: 'lunch',
        startDate: now,
        endDate: now.add(const Duration(days: 30)),
        duration: SubscriptionDuration.annual, // Intentionally incorrect
      );

      final subscriptions = [incorrectSub];

      // Fix durations
      subscriptionService._fixSubscriptionDurations(subscriptions);

      // Check if duration was fixed
      expect(subscriptions[0].duration, equals(SubscriptionDuration.monthly));
      expect(subscriptions[0].planDisplayName, equals('Monthly Lunch Plan'));
    });
  });
}
