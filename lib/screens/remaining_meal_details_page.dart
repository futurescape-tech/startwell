import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:startwell/services/subscription_service.dart' as services;
import 'package:startwell/services/meal_service.dart';
import 'package:startwell/services/student_profile_service.dart';
import 'package:startwell/models/student_model.dart';
import 'package:startwell/models/subscription_model.dart';
import 'package:startwell/models/meal_model.dart';

class RemainingMealDetailsPage extends StatefulWidget {
  final String studentId;

  const RemainingMealDetailsPage({
    Key? key,
    required this.studentId,
  }) : super(key: key);

  @override
  State<RemainingMealDetailsPage> createState() =>
      _RemainingMealDetailsPageState();
}

class _RemainingMealDetailsPageState extends State<RemainingMealDetailsPage> {
  bool _isLoading = true;
  List<Subscription> _activePlans = [];
  List<Map<String, dynamic>> _planSummaries = [];
  List<Map<String, dynamic>> _recentConsumption = [];
  Student? _student;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Fetch student profile
      final studentProfileService = StudentProfileService();
      final List<Student> students =
          await studentProfileService.getStudentProfiles();
      _student = students.firstWhere(
        (student) => student.id == widget.studentId,
        orElse: () => throw Exception('Student not found'),
      );

      // Fetch active subscription for the student
      final subscriptionService = services.SubscriptionService();
      _activePlans = await subscriptionService
          .getActiveSubscriptionsForStudent(widget.studentId);

      if (_activePlans.isNotEmpty) {
        // For each subscription, calculate meal summary
        for (var subscription in _activePlans) {
          // Get all cancelled meals
          final cancelledMeals =
              await subscriptionService.getCancelledMeals(widget.studentId);
          final int cancelledCount = cancelledMeals.length;

          // Calculate meal summary based on the subscription
          final int totalMeals = _calculateTotalMeals(subscription);
          final int consumedMeals = (subscription.planType == 'express')
              ? 0
              : _calculateConsumedMeals(subscription, cancelledCount);

          _planSummaries.add({
            'subscription': subscription,
            'totalMeals': totalMeals,
            'consumed': consumedMeals,
            'remaining': totalMeals - consumedMeals,
            'planType': _getPlanTypeDisplay(subscription),
            'startDate': subscription.startDate,
            'endDate': subscription.endDate,
          });
        }

        // Fetch recent meal consumption
        final mealService = MealService();
        // Use getUpcomingMealsForStudent and filter for past meals
        final allMeals =
            await mealService.getUpcomingMealsForStudent(widget.studentId);
        final now = DateTime.now();

        // Check if any subscription has started
        bool anySubscriptionStarted = false;
        DateTime earliestStartDate = DateTime(9999); // Far future date

        for (var subscription in _activePlans) {
          if (now.isAfter(subscription.startDate)) {
            anySubscriptionStarted = true;
            if (subscription.startDate.isBefore(earliestStartDate)) {
              earliestStartDate = subscription.startDate;
            }
          }
        }

        if (anySubscriptionStarted) {
          // Only show meals that occurred after the earliest subscription start date
          final pastMeals = allMeals
              .where((meal) =>
                  meal.date.isBefore(now) &&
                      meal.date.isAfter(earliestStartDate) ||
                  meal.date.isAtSameMomentAs(earliestStartDate))
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date)); // Sort descending

          // Take only the last 5 meals
          final recentMeals = pastMeals.take(5).toList();

          _recentConsumption = recentMeals.map((meal) {
            return {
              'date': meal.date,
              'studentName': meal.studentName,
              'mealName': meal.title,
              'status':
                  'Consumed', // We're assuming all past meals were consumed
            };
          }).toList();
        } else {
          // No subscriptions have started yet
          _recentConsumption = [];
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to load meal consumption details: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  int _calculateTotalMeals(Subscription subscription) {
    if (subscription.planType == 'express') {
      return 1; // Express plan is just one meal
    }

    // Calculate days between start and end date
    final days =
        subscription.endDate.difference(subscription.startDate).inDays + 1;

    // If using custom weekdays
    if (subscription.selectedWeekdays.isNotEmpty) {
      // Calculate how many of each weekday falls within the date range
      final weekdayCounts = <int, int>{};
      for (int i = 0; i < days; i++) {
        final date = subscription.startDate.add(Duration(days: i));
        final weekday = date.weekday;
        if (subscription.selectedWeekdays.contains(weekday)) {
          weekdayCounts[weekday] = (weekdayCounts[weekday] ?? 0) + 1;
        }
      }

      // Sum all weekday counts
      return weekdayCounts.values.fold(0, (sum, count) => sum + count);
    } else {
      // Default Mon-Fri plan
      final weekdays = [1, 2, 3, 4, 5]; // Monday to Friday

      // Calculate how many weekdays fall within the date range
      int count = 0;
      for (int i = 0; i < days; i++) {
        final date = subscription.startDate.add(Duration(days: i));
        if (weekdays.contains(date.weekday)) {
          count++;
        }
      }

      return count;
    }
  }

  int _calculateConsumedMeals(Subscription subscription, int cancelledCount) {
    // Calculate days passed since subscription start
    final today = DateTime.now();
    if (today.isBefore(subscription.startDate)) {
      return 0; // Subscription hasn't started yet
    }

    final endDate =
        subscription.endDate.isAfter(today) ? today : subscription.endDate;
    final daysPassed = endDate.difference(subscription.startDate).inDays + 1;

    // If using custom weekdays
    if (subscription.selectedWeekdays.isNotEmpty) {
      // Calculate how many of each weekday has passed
      final weekdayCounts = <int, int>{};
      for (int i = 0; i < daysPassed; i++) {
        final date = subscription.startDate.add(Duration(days: i));
        final weekday = date.weekday;
        if (subscription.selectedWeekdays.contains(weekday)) {
          weekdayCounts[weekday] = (weekdayCounts[weekday] ?? 0) + 1;
        }
      }

      // Sum all weekday counts and subtract cancelled meals
      final totalPassed =
          weekdayCounts.values.fold(0, (sum, count) => sum + count);
      return totalPassed - cancelledCount;
    } else {
      // Default Mon-Fri plan
      final weekdays = [1, 2, 3, 4, 5]; // Monday to Friday

      // Calculate how many weekdays have passed
      int count = 0;
      for (int i = 0; i < daysPassed; i++) {
        final date = subscription.startDate.add(Duration(days: i));
        if (weekdays.contains(date.weekday)) {
          count++;
        }
      }

      return count - cancelledCount;
    }
  }

  String _getPlanTypeDisplay(Subscription plan) {
    String planPeriod;
    final days = plan.endDate.difference(plan.startDate).inDays;

    if (days <= 1) {
      planPeriod = "Single Day";
    } else if (days <= 7) {
      planPeriod = "Weekly";
    } else if (days <= 31) {
      planPeriod = "Monthly";
    } else if (days <= 90) {
      planPeriod = "Quarterly";
    } else if (days <= 180) {
      planPeriod = "Half-Yearly";
    } else {
      planPeriod = "Annual";
    }

    final mealType = plan.planType == 'breakfast' ? 'Breakfast' : 'Lunch';
    return "$planPeriod $mealType Plan";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Meal Consumption',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.orange,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _activePlans.isEmpty
              ? _buildNoPlanView()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Student Name (if available)
                      if (_student != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            _student!.name,
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ),

                      // Display each plan summary
                      for (int i = 0; i < _planSummaries.length; i++)
                        _buildPlanSummaryCard(_planSummaries[i], i),

                      const SizedBox(height: 24),

                      // Recent Consumption History
                      Text(
                        'Recent Consumption History',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Empty state if no recent consumption
                      if (_recentConsumption.isEmpty)
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.restaurant_outlined,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _activePlans.every((plan) => DateTime.now()
                                            .isBefore(plan.startDate))
                                        ? 'No consumption history yet - subscription hasn\'t started'
                                        : 'No meal consumption history yet',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // Recent Meal Consumption List
                      ..._recentConsumption
                          .map((meal) => Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 1,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color:
                                              AppTheme.orange.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.restaurant,
                                          color: AppTheme.orange,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              meal['mealName'],
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.textDark,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              meal['studentName'],
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: AppTheme.textMedium,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            DateFormat('dd MMM yyyy')
                                                .format(meal['date']),
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: AppTheme.textDark,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color:
                                                  meal['status'] == 'Consumed'
                                                      ? Colors.green
                                                          .withOpacity(0.1)
                                                      : Colors.orange
                                                          .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              meal['status'],
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color:
                                                    meal['status'] == 'Consumed'
                                                        ? Colors.green
                                                        : AppTheme.orange,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ))
                          .toList(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildPlanSummaryCard(Map<String, dynamic> planSummary, int index) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              planSummary['planType'],
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${DateFormat('dd MMM').format(planSummary['startDate'])} - ${DateFormat('dd MMM yyyy').format(planSummary['endDate'])}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textMedium,
              ),
            ),
            const SizedBox(height: 24),

            // Meal Consumption Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                    'Total', planSummary['totalMeals'], Colors.blue),
                _buildStatColumn(
                    'Consumed', planSummary['consumed'], Colors.orange),
                _buildStatColumn(
                    'Remaining', planSummary['remaining'], Colors.green),
              ],
            ),
            const SizedBox(height: 24),

            // Progress Indicator
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Consumption Progress',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textMedium,
                      ),
                    ),
                    Text(
                      planSummary['totalMeals'] > 0
                          ? '${(planSummary['consumed'] / planSummary['totalMeals'] * 100).toInt()}%'
                          : '0%',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: planSummary['totalMeals'] > 0
                      ? planSummary['consumed'] / planSummary['totalMeals']
                      : 0.0,
                  backgroundColor: Colors.grey[200],
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppTheme.orange),
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoPlanView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_outlined,
              size: 72,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No Active Plan',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This student doesn\'t have an active subscription plan.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: AppTheme.textMedium,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.orange,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Go Back',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String title, int value, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              value.toString(),
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textMedium,
          ),
        ),
      ],
    );
  }
}
