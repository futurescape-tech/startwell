import 'package:flutter/material.dart';
import 'package:startwell/models/subscription_model.dart';
import 'dart:developer' as dev;
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Subscription Debug Tool')),
        body: const SubscriptionDebugScreen(),
      ),
    );
  }
}

class SubscriptionDebugScreen extends StatefulWidget {
  const SubscriptionDebugScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionDebugScreen> createState() =>
      _SubscriptionDebugScreenState();
}

class _SubscriptionDebugScreenState extends State<SubscriptionDebugScreen> {
  final _subscriptionService = SubscriptionService();
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _runTests();
  }

  void _addLog(String log) {
    setState(() {
      _logs.add(log);
    });
  }

  void _runTests() {
    _addLog('Starting subscription tests');

    // Test different subscription durations and display names
    _testDurations();
    _testPlanDisplayNames();
    _testFixingDurations();
  }

  void _testDurations() {
    _addLog('\n--- Testing Duration Calculations ---');
    final now = DateTime.now();

    // Test different duration periods
    _testDurationPeriod(now, 1, 'Single Day');
    _testDurationPeriod(now, 7, 'Weekly');
    _testDurationPeriod(now, 30, 'Monthly');
    _testDurationPeriod(now, 90, 'Quarterly');
    _testDurationPeriod(now, 180, 'Half-Yearly');
    _testDurationPeriod(now, 365, 'Annual');
  }

  void _testDurationPeriod(DateTime startDate, int days, String expectedType) {
    final endDate = startDate.add(Duration(days: days));
    final duration =
        _subscriptionService._getDurationFromEndDate(startDate, endDate);

    _addLog(
        'Period: $days days, Got: ${_durationToString(duration)}, Expected: $expectedType');
  }

  String _durationToString(SubscriptionDuration duration) {
    switch (duration) {
      case SubscriptionDuration.singleDay:
        return 'Single Day';
      case SubscriptionDuration.weekly:
        return 'Weekly';
      case SubscriptionDuration.monthly:
        return 'Monthly';
      case SubscriptionDuration.quarterly:
        return 'Quarterly';
      case SubscriptionDuration.halfYearly:
        return 'Half-Yearly';
      case SubscriptionDuration.annual:
        return 'Annual';
    }
  }

  void _testPlanDisplayNames() {
    _addLog('\n--- Testing Plan Display Names ---');
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
    _addLog('Express Plan Display Name: ${expressSub.planDisplayName}');

    // Test Monthly Breakfast
    final monthlyBreakfast = Subscription(
      id: 'breakfast-monthly',
      studentId: 'student1',
      planType: 'breakfast',
      startDate: now,
      endDate: now.add(const Duration(days: 30)),
      duration: SubscriptionDuration.monthly,
    );
    _addLog(
        'Monthly Breakfast Display Name: ${monthlyBreakfast.planDisplayName}');

    // Test Quarterly Lunch Plan
    final quarterlyLunch = Subscription(
      id: 'lunch-quarterly',
      studentId: 'student1',
      planType: 'lunch',
      startDate: now,
      endDate: now.add(const Duration(days: 90)),
      duration: SubscriptionDuration.quarterly,
    );
    _addLog('Quarterly Lunch Display Name: ${quarterlyLunch.planDisplayName}');

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
    _addLog(
        'Custom Weekly Lunch Display Name: ${customWeeklyLunch.planDisplayName}');
  }

  void _testFixingDurations() {
    _addLog('\n--- Testing Fixing Subscription Durations ---');
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

    _addLog(
        'Before fix - Duration: ${_durationToString(incorrectSub.duration)}, Display: ${incorrectSub.planDisplayName}');

    final subscriptions = [incorrectSub];

    // Fix durations
    _subscriptionService._fixSubscriptionDurations(subscriptions);

    // Check if duration was fixed
    _addLog(
        'After fix - Duration: ${_durationToString(subscriptions[0].duration)}, Display: ${subscriptions[0].planDisplayName}');
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _logs.length,
      padding: const EdgeInsets.all(16.0),
      itemBuilder: (context, index) {
        return Text(
          _logs[index],
          style: TextStyle(
            fontFamily: 'Courier',
            fontSize: 14,
            color: _logs[index].startsWith('---') ? Colors.blue : Colors.black,
            fontWeight: _logs[index].startsWith('---')
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        );
      },
    );
  }
}
