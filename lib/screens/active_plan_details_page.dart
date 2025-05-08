import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:startwell/services/subscription_service.dart' as services;
import 'package:startwell/services/meal_service.dart';
import 'package:startwell/services/student_profile_service.dart';
import 'package:startwell/models/student_model.dart';
import 'package:startwell/models/subscription_model.dart';
import 'package:startwell/widgets/common/gradient_app_bar.dart';
import 'package:startwell/widgets/common/gradient_button.dart';
import 'package:startwell/utils/meal_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
  Map<String, String> _deliveryModes = {};
  Map<String, Map<String, dynamic>> _orderSummaryData = {};

  @override
  void initState() {
    super.initState();
    _loadStoredOrderSummary();
    _loadData();
  }

  // Load stored order summary data from SharedPreferences
  Future<void> _loadStoredOrderSummary() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Get all keys that start with "order_summary_"
      final keys = prefs
          .getKeys()
          .where((key) => key.startsWith('order_summary_${widget.studentId}_'))
          .toList();

      for (final key in keys) {
        final String? jsonData = prefs.getString(key);
        if (jsonData != null) {
          final Map<String, dynamic> data = json.decode(jsonData);
          final String planId =
              key.replaceFirst('order_summary_${widget.studentId}_', '');
          _orderSummaryData[planId] = data;
        }
      }

      if (_orderSummaryData.isNotEmpty) {
        print('Loaded ${_orderSummaryData.length} stored order summaries');
      }
    } catch (e) {
      print('Error loading stored order summary: $e');
    }
  }

  // Store delivery mode in SharedPreferences
  Future<void> _storeDeliveryMode(
      String studentId, String planId, String deliveryMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'deliveryMode_${studentId}_${planId}', deliveryMode);
    } catch (e) {
      print('Error storing delivery mode: $e');
    }
  }

  // Get delivery mode from SharedPreferences
  Future<String?> _getDeliveryMode(String studentId, String planId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('deliveryMode_${studentId}_${planId}');
    } catch (e) {
      print('Error getting delivery mode: $e');
      return null;
    }
  }

  // Determine delivery mode based on plan's selected weekdays
  String _determineDeliveryMode(Subscription plan) {
    return plan.selectedWeekdays.isEmpty ? 'Mon to Fri' : 'Custom Plan';
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
          final int consumedMeals =
              _calculateConsumedMeals(plan, cancelledCount);

          // Determine and store delivery mode
          final deliveryMode = _determineDeliveryMode(plan);
          await _storeDeliveryMode(widget.studentId, plan.id, deliveryMode);
          _deliveryModes[plan.id] = deliveryMode;

          // Look for stored order summary
          Map<String, dynamic> summaryData = {};
          if (_orderSummaryData.containsKey(plan.id)) {
            summaryData = _orderSummaryData[plan.id]!;
            print('Found stored order summary for plan ${plan.id}');
          }

          _planSummaries.add({
            'plan': plan,
            'totalMeals': summaryData['totalMeals'] ?? totalMeals,
            'consumed': consumedMeals,
            'remaining':
                (summaryData['totalMeals'] ?? totalMeals) - consumedMeals,
            'pricePerMeal': summaryData['pricePerMeal'] ?? 60,
            'deliveryMode': deliveryMode,
            'totalAmount': summaryData['totalAmount'],
            'hasStoredSummary': summaryData.isNotEmpty,
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
      int consumed = totalPassed - cancelledCount;

      // Prevent negative values
      return consumed < 0 ? 0 : consumed;
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

      int consumed = count - cancelledCount;

      // Prevent negative values
      return consumed < 0 ? 0 : consumed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: GradientAppBar(
        titleText: 'Plan Details',
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
                      // Enhanced Student Header with Avatar
                      if (_student != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: AppTheme.softShadow,
                            border: Border.all(
                              color: AppTheme.purple.withOpacity(0.1),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.red.shade100,
                                child: const Icon(
                                  Icons.person_outline,
                                  color: Colors.red,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _student!.name,
                                      style: GoogleFonts.poppins(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                    Text(
                                      _student!.schoolName,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: AppTheme.textMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Show each active plan in a separate card
                      for (int i = 0; i < _planSummaries.length; i++)
                        _buildPlanCard(_planSummaries[i], i),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> planSummary, int index) {
    final Subscription plan = planSummary['plan'];
    final bool isBreakfastPlan = plan.planType == 'breakfast';
    final bool hasStoredSummary = planSummary['hasStoredSummary'] ?? false;

    // Ensure consumed meals is never negative
    final int consumed =
        planSummary['consumed'] < 0 ? 0 : planSummary['consumed'];
    final int remaining = planSummary['totalMeals'] - consumed;

    // Get delivery mode
    final String deliveryMode = planSummary['deliveryMode'] ?? 'Loading...';

    // Get plan period description
    final String planPeriod = _getPlanPeriodDescription(plan);

    // Format the price per meal
    final String pricePerMeal = '₹${planSummary['pricePerMeal']}';

    // Calculate total price
    final num totalPrice =
        hasStoredSummary && planSummary['totalAmount'] != null
            ? planSummary['totalAmount']
            : planSummary['totalMeals'] * planSummary['pricePerMeal'];

    // Use MealConstants for consistent styling
    final Color planIconColor = MealConstants.getIconColor(plan.planType);
    final Color planBgColor = MealConstants.getBgColor(plan.planType);
    final Color planBorderColor = MealConstants.getBorderColor(plan.planType);
    final IconData planIcon = MealConstants.getIcon(plan.planType);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      shadowColor: AppTheme.deepPurple.withOpacity(0.15),
      margin: const EdgeInsets.only(bottom: 24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          // Soft border with gradient-like effect
          border: Border.all(
            color: planBorderColor,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plan Type Header (Enhanced with icon)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: planBgColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      planIcon,
                      color: planIconColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getPlanTypeDisplay(plan),
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Active',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Container for the main content
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section 1: Subscription Details
                  _buildSectionHeader('Subscription Details'),
                  const SizedBox(height: 8),
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
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Section 2: Meals & Pricing
                  _buildSectionHeader('Meals & Pricing'),
                  const SizedBox(height: 8),
                  Column(
                    children: [
                      _buildDetailRow(
                        'Plan Type',
                        '${_getPlanTypeDisplay(plan)} ${plan.selectedWeekdays.isEmpty ? "(Regular)" : "(Custom)"}',
                      ),
                      _buildDetailRow(
                        'Duration',
                        planPeriod,
                      ),
                      _buildDetailRow(
                        'Meals Per Day',
                        '1 meal (${plan.planType == 'breakfast' ? 'Breakfast' : 'Lunch'})',
                      ),
                      _buildDetailRow(
                        'Delivery Mode',
                        deliveryMode,
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
                        '$consumed meals',
                      ),
                      _buildDetailRow(
                        'Remaining Meals',
                        '$remaining meals',
                        valueStyle: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      _buildDetailRow(
                        'Price Per Meal',
                        pricePerMeal,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.purple.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                              '₹${totalPrice.toInt()}',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (hasStoredSummary)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline,
                                    size: 16, color: Colors.blue.shade800),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Order summary synced from payment details',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.blue.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
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
            GradientButton(
              text: 'Go Back',
              onPressed: () => Navigator.pop(context),
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

    final List<String> selectedDays = [];
    for (int day in plan.selectedWeekdays) {
      if (day >= 1 && day <= 7) {
        selectedDays.add(weekdayNames[day]);
      }
    }

    if (selectedDays.isEmpty) {
      return "Monday to Friday"; // Fallback
    }

    return selectedDays.join(', ');
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: AppTheme.deepPurple,
            width: 3,
          ),
        ),
      ),
      padding: const EdgeInsets.only(left: 8),
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

  Widget _buildDetailRow(String label, String value, {TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: valueStyle ??
                GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
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

  // New helper method for calculating plan period description
  String _getPlanPeriodDescription(Subscription plan) {
    final int days = plan.endDate.difference(plan.startDate).inDays + 1;

    if (plan.selectedWeekdays.isNotEmpty) {
      // If it's a custom plan
      return '${_calculateTotalMeals(plan)} days custom plan';
    } else {
      // If it's a regular plan
      return '$days days';
    }
  }
}
