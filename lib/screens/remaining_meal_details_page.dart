import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:developer' as dev;
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:startwell/services/subscription_service.dart' as services;
import 'package:startwell/services/meal_service.dart';
import 'package:startwell/services/student_profile_service.dart';
import 'package:startwell/services/selected_student_service.dart';
import 'package:startwell/models/student_model.dart';
import 'package:startwell/models/subscription_model.dart';
import 'package:startwell/models/meal_model.dart';
import 'package:startwell/utils/meal_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:startwell/widgets/common/gradient_button.dart';
import 'package:startwell/widgets/common/student_selector_dropdown.dart';
import 'dart:convert';

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
  bool _isChangingStudent = false;
  List<Subscription> _activePlans = [];
  List<Map<String, dynamic>> _planSummaries = [];
  List<Map<String, dynamic>> _recentConsumption = [];
  Student? _student;
  String _currentStudentId = '';
  Set<String> _consumedMealDates = {};
  List<Student> _allStudents = [];

  @override
  void initState() {
    super.initState();
    _currentStudentId = widget.studentId;
    _loadStoredConsumedMeals();
    _loadData();
    _loadAllStudents();
  }

  Future<void> _loadAllStudents() async {
    try {
      final studentProfileService = StudentProfileService();
      final students = await studentProfileService.getStudentProfiles();

      if (mounted) {
        setState(() {
          _allStudents = students;
        });
      }

      // Also store the current selection in the global service
      SelectedStudentService().setSelectedStudent(_currentStudentId);
    } catch (e) {
      dev.log('Error loading all students: $e');
    }
  }

  void _onStudentChanged(String studentId) {
    if (studentId != _currentStudentId) {
      setState(() {
        _isChangingStudent = true;
        _currentStudentId = studentId;
        _planSummaries = [];
        _recentConsumption = [];
      });

      _loadStoredConsumedMeals();
      _loadData();
    }
  }

  Future<void> _loadStoredConsumedMeals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> storedDates =
          prefs.getStringList('consumed_meal_dates_${_currentStudentId}') ?? [];
      setState(() {
        _consumedMealDates = storedDates.toSet();
      });
    } catch (e) {
      // Handle error silently
      dev.log('Error loading stored consumed meals: $e');
    }
  }

  Future<void> _markMealAsConsumed(MealSchedule meal) async {
    // Create a normalized date string (YYYY-MM-DD format)
    final dateString = DateFormat('yyyy-MM-dd').format(meal.date);

    if (_consumedMealDates.contains(dateString)) {
      dev.log('Meal already marked as consumed: $dateString');
      return; // Already marked as consumed
    }

    try {
      // Add to local set
      setState(() {
        _consumedMealDates.add(dateString);
      });

      // Store in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('consumed_meal_dates_${_currentStudentId}',
          _consumedMealDates.toList());
      dev.log('Marked meal as consumed: $dateString');
    } catch (e) {
      dev.log('Error marking meal as consumed: $e');
    }
  }

  bool _isMealConsumed(DateTime date) {
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    final result = _consumedMealDates.contains(dateString);
    dev.log('Checking if meal consumed for date $dateString: $result');
    return result;
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
        (student) => student.id == _currentStudentId,
        orElse: () => throw Exception('Student not found'),
      );

      // Fetch active subscription for the student
      final subscriptionService = services.SubscriptionService();
      _activePlans = await subscriptionService
          .getActiveSubscriptionsForStudent(_currentStudentId);

      // Get stored plan details
      final prefs = await SharedPreferences.getInstance();
      final planDetailsKey = 'selected_plan_details';
      final String? storedPlanDetails = prefs.getString(planDetailsKey);
      Map<String, dynamic>? planDetails;
      if (storedPlanDetails != null) {
        planDetails = json.decode(storedPlanDetails);
      }

      // Fetch all meals for this student
      final mealService = MealService();
      final allMeals =
          await mealService.getUpcomingMealsForStudent(_currentStudentId);
      final now = DateTime.now();

      // Auto-mark today's and past meals as consumed
      for (final meal in allMeals) {
        if (meal.date.isBefore(now) || isSameDay(meal.date, now)) {
          await _markMealAsConsumed(meal);
        }
      }

      if (_activePlans.isNotEmpty) {
        // For each subscription, calculate meal summary
        for (var subscription in _activePlans) {
          // Get all cancelled meals
          final cancelledMeals =
              await subscriptionService.getCancelledMeals(_currentStudentId);
          final int cancelledCount = cancelledMeals.length;

          // Calculate meal summary based on the subscription
          final int totalMeals = _calculateTotalMeals(subscription);

          // Calculate consumed meals using stored data and cancellations
          final int consumedFromStorage =
              _calculateConsumedFromStorage(subscription);

          // Fixed calculation for consumed meals
          final int actualConsumedMeals = (subscription.planType == 'express')
              ? (consumedFromStorage > 0 ? 1 : 0)
              : math.max(0, consumedFromStorage - cancelledCount);

          // Get plan type and dates based on meal type
          String planType;
          DateTime? startDate;
          DateTime? endDate;

          if (subscription.planType == 'breakfast') {
            planType =
                planDetails?['breakfastPlanType'] ?? subscription.planType;
            startDate = planDetails?['breakfastStartDate'] != null
                ? DateTime.parse(planDetails!['breakfastStartDate'])
                : subscription.startDate;
            endDate = planDetails?['breakfastEndDate'] != null
                ? DateTime.parse(planDetails!['breakfastEndDate'])
                : subscription.endDate;
          } else {
            planType = planDetails?['lunchPlanType'] ?? subscription.planType;
            startDate = planDetails?['lunchStartDate'] != null
                ? DateTime.parse(planDetails!['lunchStartDate'])
                : subscription.startDate;
            endDate = planDetails?['lunchEndDate'] != null
                ? DateTime.parse(planDetails!['lunchEndDate'])
                : subscription.endDate;
          }

          _planSummaries.add({
            'subscription': subscription,
            'totalMeals': totalMeals,
            'consumed': actualConsumedMeals,
            'remaining': totalMeals - actualConsumedMeals,
            'planType': planType,
            'startDate': startDate,
            'endDate': endDate,
          });
        }

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
          // Build recent consumption history from all consumed meals
          final consumedMeals = allMeals
              .where((meal) =>
                  (meal.date.isAfter(earliestStartDate) ||
                      meal.date.isAtSameMomentAs(earliestStartDate)) &&
                  _isMealConsumed(meal.date))
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date)); // Sort descending

          // Take only the last 5 meals
          final recentMeals = consumedMeals.take(5).toList();

          dev.log(
              'Found ${consumedMeals.length} consumed meals, showing ${recentMeals.length}');

          _recentConsumption = recentMeals.map((meal) {
            return {
              'date': meal.date,
              'studentName': meal.studentName,
              'mealName': meal.title,
              'status': 'Consumed',
              'mealType': meal.planType == 'breakfast' ? 'Breakfast' : 'Lunch'
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
          _isChangingStudent = false;
        });
      }
    } catch (e) {
      dev.log('Error loading data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isChangingStudent = false;
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

  // Check if two dates are the same day
  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  int _calculateConsumedFromStorage(Subscription subscription) {
    final now = DateTime.now();
    if (now.isBefore(subscription.startDate)) {
      return 0; // Subscription hasn't started yet
    }

    final endDate =
        subscription.endDate.isAfter(now) ? now : subscription.endDate;
    final days = endDate.difference(subscription.startDate).inDays + 1;

    int count = 0;
    for (int i = 0; i < days; i++) {
      final date = subscription.startDate.add(Duration(days: i));
      final dateString = DateFormat('yyyy-MM-dd').format(date);

      // Check if this date falls on the subscription's selected weekdays
      final weekday = date.weekday;
      bool isScheduledDay = false;

      if (subscription.selectedWeekdays.isNotEmpty) {
        isScheduledDay = subscription.selectedWeekdays.contains(weekday);
      } else {
        // Default Mon-Fri plan
        isScheduledDay = [1, 2, 3, 4, 5].contains(weekday);
      }

      if (isScheduledDay && _consumedMealDates.contains(dateString)) {
        count++;
      }
    }

    dev.log('Consumed meals for ${subscription.id}: $count');
    return count;
  }

  int _calculateTotalMeals(Subscription subscription) {
    // For single day plan (start and end date are the same), always 1
    if (subscription.startDate.year == subscription.endDate.year &&
        subscription.startDate.month == subscription.endDate.month &&
        subscription.startDate.day == subscription.endDate.day) {
      return 1;
    }
    if (subscription.planType == 'express') {
      return 1; // Express plan is just one meal
    }

    final days =
        subscription.endDate.difference(subscription.startDate).inDays + 1;

    // Fixed meal counts for each plan type
    if (days <= 1) {
      return 1; // Single Day
    } else if (days <= 7) {
      return 5; // Weekly
    } else if (days <= 31) {
      return 20; // Monthly
    } else if (days <= 90) {
      return 60; // Quarterly
    } else if (days <= 180) {
      return 90; // Half-Yearly
    } else {
      return 200; // Annual
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
          'Remaining Meals',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.purpleToDeepPurple,
          ),
        ),
      ),
      body: Column(
        children: [
          // Student selector dropdown
          if (_allStudents.length > 1)
            StudentSelectorDropdown(
              students: _allStudents,
              selectedStudentId: _currentStudentId,
              onStudentSelected: _onStudentChanged,
              isLoading: _isChangingStudent,
            ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _activePlans.isEmpty
                    ? _buildNoPlanView()
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Display each plan summary
                            for (int i = 0; i < _planSummaries.length; i++)
                              _buildPlanSummaryCard(_planSummaries[i], i),

                            const SizedBox(height: 24),

                            // Recent Consumption History
                            _buildRecentConsumptionSection(),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSummaryCard(Map<String, dynamic> planSummary, int index) {
    // Calculate progress percentage for the progress bar
    final int total = planSummary['totalMeals'];
    final int consumed = planSummary['consumed'];
    // Clamp progress percentage between 0 and 1
    final double progressPercent =
        total > 0 ? (consumed / total).clamp(0.0, 1.0) : 0.0;

    final Subscription subscription = planSummary['subscription'];
    final bool isBreakfastPlan = subscription.planType == 'breakfast';

    // Use MealConstants for consistent styling with Plan Details page
    final Color planIconColor = isBreakfastPlan
        ? MealConstants.breakfastIconColor
        : MealConstants.lunchIconColor;
    final Color planBgColor = isBreakfastPlan
        ? MealConstants.breakfastBgColor
        : MealConstants.lunchBgColor;
    final Color planBorderColor = isBreakfastPlan
        ? MealConstants.breakfastIconColor.withOpacity(0.3)
        : MealConstants.lunchIconColor.withOpacity(0.3);
    final IconData planIcon =
        isBreakfastPlan ? MealConstants.breakfastIcon : MealConstants.lunchIcon;

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
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _getMealImageForPlan(subscription),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      planSummary['planType'],
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
                  // Section 2: Meal Statistics
                  // _buildSectionHeader('Meal Statistics'),
                  // const SizedBox(height: 16),

                  // Meal consumption metrics
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetric("Total", planSummary['totalMeals'],
                          Colors.green, Icons.calendar_month),
                      _buildMetric("Consumed", planSummary['consumed'],
                          Colors.orange, Icons.restaurant),
                      _buildMetric("Remaining", planSummary['remaining'],
                          Colors.blue, Icons.inventory),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Progress section
                  // _buildSectionHeader("Consumption Progress"),
                  // const SizedBox(height: 16),

                  // Progress bar with percentage
                  Column(
                    children: [
                      LinearProgressIndicator(
                        value: progressPercent,
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progressPercent > 0
                              ? Colors.orange
                              : Colors.redAccent,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (progressPercent <= 0)
                            Text(
                              "No meals consumed yet",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.redAccent,
                              ),
                            )
                          else
                            Text(
                              "${planSummary['consumed']} of ${planSummary['totalMeals']} meals consumed",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textMedium,
                              ),
                            ),
                          Text(
                            "${(progressPercent * 100).toInt()}% Consumed",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: progressPercent > 0
                                  ? Colors.green.shade700
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
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

  Widget _buildMetric(String title, int value, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(height: 4),
              Text(
                value.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
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

  Widget _buildNoPlanView() {
    return Center(
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'This student doesn\'t have an active subscription plan.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: AppTheme.textMedium,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.orange,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
    );
  }

  Widget _buildRecentConsumptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Recent Consumption History'),
        const SizedBox(height: 16),
        _recentConsumption.isEmpty
            ? Container(
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/empty_state.png',
                        height: 120,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.restaurant,
                          size: 70,
                          color: Colors.grey.shade300,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No Recent Consumption',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No meal consumption history yet',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppTheme.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: AppTheme.deepPurple.withOpacity(0.15),
                margin: const EdgeInsets.only(bottom: 8),
                child: Column(
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _recentConsumption.length,
                      itemBuilder: (context, index) {
                        final consumption = _recentConsumption[index];
                        final consumptionDate = consumption['date'] as DateTime;
                        final isConsumed = consumption['status'] == 'Consumed';

                        return Column(
                          children: [
                            if (index > 0)
                              Divider(
                                height: 1,
                                thickness: 1,
                                color: Colors.grey.shade100,
                                indent: 16,
                                endIndent: 16,
                              ),
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isConsumed
                                      ? Colors.green.withOpacity(0.1)
                                      : MealConstants.lunchBgColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  isConsumed
                                      ? Icons.check_circle_outline
                                      : MealConstants.lunchIcon,
                                  color: isConsumed
                                      ? Colors.green
                                      : MealConstants.lunchIconColor,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    consumption['mealName'],
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textDark,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color:
                                          consumption['mealType'] == 'Breakfast'
                                              ? MealConstants.breakfastIconColor
                                                  .withOpacity(0.1)
                                              : MealConstants.lunchIconColor
                                                  .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      consumption['mealType'] ?? 'Lunch',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: consumption['mealType'] ==
                                                'Breakfast'
                                            ? MealConstants.breakfastIconColor
                                            : MealConstants.lunchIconColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                DateFormat('MMM dd, yyyy')
                                    .format(consumptionDate),
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: AppTheme.textMedium,
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(consumption['status'])
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  consumption['status'],
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                    color:
                                        _getStatusColor(consumption['status']),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'consumed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Widget _getMealImageForPlan(Subscription plan) {
    final name = plan.mealName?.trim().toLowerCase() ?? '';
    if (name == 'breakfast of the day breakfast' ||
        name == 'breakfast of the day') {
      return Image.asset(
          'assets/images/breakfast/breakfast of the day (most recommended).png',
          fit: BoxFit.cover);
    }
    if (name == 'indian breakfast') {
      return Image.asset('assets/images/breakfast/Indian Breakfast.png',
          fit: BoxFit.cover);
    }
    if (name == 'international breakfast') {
      return Image.asset('assets/images/breakfast/International Breakfast.png',
          fit: BoxFit.cover);
    }
    if (name == 'jain breakfast') {
      return Image.asset('assets/images/breakfast/Jain Breakfast.png',
          fit: BoxFit.cover);
    }
    if (name == 'lunch of the day lunch' || name == 'lunch of the day') {
      return Image.asset(
          'assets/images/lunch/lunch of the day (most recommended).png',
          fit: BoxFit.cover);
    }
    if (name == 'indian lunch') {
      return Image.asset('assets/images/lunch/Indian Lunch.png',
          fit: BoxFit.cover);
    }
    if (name == 'international lunch') {
      return Image.asset('assets/images/lunch/International Lunch.png',
          fit: BoxFit.cover);
    }
    if (name == 'jain lunch') {
      return Image.asset('assets/images/lunch/Jain Lunch.png',
          fit: BoxFit.cover);
    }
    // fallback to icon
    return Icon(
      plan.planType == 'breakfast'
          ? MealConstants.breakfastIcon
          : MealConstants.lunchIcon,
      color: plan.planType == 'breakfast'
          ? MealConstants.breakfastIconColor
          : MealConstants.lunchIconColor,
      size: 24,
    );
  }
}
