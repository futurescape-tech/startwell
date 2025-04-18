import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:startwell/services/subscription_service.dart' as services;
import 'package:startwell/services/meal_service.dart';
import 'package:startwell/services/student_profile_service.dart';
import 'package:startwell/models/student_model.dart';
import 'package:startwell/models/subscription_model.dart';

class ActivePlanDetailsPage extends StatefulWidget {
  final String studentId;

  const ActivePlanDetailsPage({
    Key? key,
    required this.studentId,
  }) : super(key: key);

  @override
  State<ActivePlanDetailsPage> createState() => _ActivePlanDetailsPageState();
}

class _ActivePlanDetailsPageState extends State<ActivePlanDetailsPage> {
  bool _isLoading = true;
  List<Subscription> _activePlans = [];
  Student? _student;
  List<Map<String, dynamic>> _planSummaries = [];
  List<Student> _associatedStudents = [];

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

      // Fetch the student profile
      final studentProfileService = StudentProfileService();
      final List<Student> students =
          await studentProfileService.getStudentProfiles();
      _student = students.firstWhere(
        (student) => student.id == widget.studentId,
        orElse: () => throw Exception('Student not found'),
      );

      // Fetch active subscriptions for the student
      final subscriptionService = services.SubscriptionService();
      _activePlans = await subscriptionService
          .getActiveSubscriptionsForStudent(widget.studentId);

      if (_activePlans.isNotEmpty) {
        // Process each active plan
        for (var plan in _activePlans) {
          // Calculate meal summary based on the subscription
          final int totalMeals = _calculateTotalMeals(plan);

          // Get all cancelled meals to calculate consumed
          final cancelledMeals =
              await subscriptionService.getCancelledMeals(widget.studentId);
          final int cancelledCount = cancelledMeals.length;

          // Calculate consumed meals
          final int consumedMeals = (plan.planType == 'express')
              ? 0
              : _calculateConsumedMeals(plan, cancelledCount);

          _planSummaries.add({
            'plan': plan,
            'totalMeals': totalMeals,
            'consumed': consumedMeals,
            'remaining': totalMeals - consumedMeals,
            'pricePerMeal': 60, // This could be fetched from a pricing service
          });
        }

        // Fetch associated students (students on the same subscription)
        _associatedStudents = students
            .where((s) =>
                // Only show students who have active plans
                (s.hasActiveBreakfast &&
                    _activePlans.any((p) => p.planType == 'breakfast')) ||
                (s.hasActiveLunch &&
                    _activePlans.any((p) =>
                        p.planType == 'lunch' || p.planType == 'express')))
            .toList();
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
            content: Text('Failed to load plan details: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Plan Details',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.purple,
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

                      // Show each active plan in a separate card
                      for (int i = 0; i < _planSummaries.length; i++)
                        _buildPlanCard(_planSummaries[i], i),

                      const SizedBox(height: 24),

                      // Associated Students section has been removed
                    ],
                  ),
                ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> planSummary, int index) {
    final Subscription plan = planSummary['plan'];

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plan Type Header
            Text(
              _getPlanTypeDisplay(plan),
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 16),

            // Section 1: Subscription Details
            _buildSectionHeader('Subscription Details'),
            Column(
              children: [
                _buildDetailRow(
                  'Start Date',
                  DateFormat('dd MMM yyyy').format(plan.startDate),
                ),
                _buildDetailRow(
                  'End Date',
                  DateFormat('dd MMM yyyy').format(plan.endDate),
                ),
                _buildDetailRow(
                  'Auto Renew',
                  'Enabled', // This would come from a real setting in the full app
                ),
                _buildStatusRow(
                  'Status',
                  'Active', // We're only showing active plans here
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Section 2: Meals & Pricing
            _buildSectionHeader('Meals & Pricing'),
            Column(
              children: [
                _buildDetailRow(
                  'Meals Per Day',
                  '1 meal (${plan.planType == 'breakfast' ? 'Breakfast' : 'Lunch'})',
                ),
                _buildDetailRow(
                  'Delivery Days',
                  _getDeliveryDaysText(plan),
                ),
                _buildDetailRow(
                  'Total Meals',
                  '${planSummary['totalMeals']} meals',
                ),
                _buildDetailRow(
                  'Consumed Meals',
                  '${planSummary['consumed']} meals',
                ),
                _buildDetailRow(
                  'Remaining Meals',
                  '${planSummary['remaining']} meals',
                ),
                _buildDetailRow(
                  'Price Per Meal',
                  '₹${planSummary['pricePerMeal']}',
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Price',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Text(
                        '₹${planSummary['totalMeals'] * planSummary['pricePerMeal']}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
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
              Icons.calendar_today_outlined,
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
                backgroundColor: AppTheme.purple,
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

  String _getDeliveryDaysText(Subscription plan) {
    if (plan.selectedWeekdays.isEmpty) {
      return "Monday to Friday";
    }

    final weekdayNames = [
      '',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final selectedDays =
        plan.selectedWeekdays.map((day) => weekdayNames[day]).toList();

    return selectedDays.join(', ');
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppTheme.textDark,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: AppTheme.textMedium,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: AppTheme.textMedium,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: status == 'Active'
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: status == 'Active' ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  status,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: status == 'Active' ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
