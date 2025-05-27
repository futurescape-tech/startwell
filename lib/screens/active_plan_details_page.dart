import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:startwell/services/subscription_service.dart' as services;
import 'package:startwell/services/meal_service.dart';
import 'package:startwell/services/student_profile_service.dart';
import 'package:startwell/services/selected_student_service.dart';
import 'package:startwell/models/student_model.dart';
import 'package:startwell/models/subscription_model.dart';
import 'package:startwell/widgets/common/gradient_app_bar.dart';
import 'package:startwell/widgets/common/gradient_button.dart';
import 'package:startwell/widgets/common/student_selector_dropdown.dart';
import 'package:startwell/utils/meal_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:startwell/utils/meal_names.dart';

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
  bool _isChangingStudent = false;
  List<Subscription> _activePlans = [];
  Student? _student;
  List<Map<String, dynamic>> _planSummaries = [];
  List<Student> _associatedStudents = [];
  List<Student> _allStudents = [];
  String _currentStudentId = '';
  Map<String, String> _deliveryModes = {};
  Map<String, Map<String, dynamic>> _orderSummaryData = {};
  Map<String, double> _storedTotals = {}; // planId -> total
  Map<String, Map<String, dynamic>> _storedPlanDates = {};

  @override
  void initState() {
    super.initState();
    _currentStudentId = widget.studentId;
    _loadStoredOrderSummary();
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
      print('Error loading all students: $e');
    }
  }

  void _onStudentChanged(String studentId) {
    if (studentId != _currentStudentId) {
      setState(() {
        _isChangingStudent = true;
        _currentStudentId = studentId;
        _planSummaries = [];
        _associatedStudents = [];
      });

      _loadStoredOrderSummary();
      _loadData();
    }
  }

  // Load stored order summary data from SharedPreferences
  Future<void> _loadStoredOrderSummary() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Get all keys that start with "order_summary_"
      final keys = prefs
          .getKeys()
          .where((key) => key.startsWith('order_summary_${_currentStudentId}_'))
          .toList();

      for (final key in keys) {
        final String? jsonData = prefs.getString(key);
        if (jsonData != null) {
          final Map<String, dynamic> data = json.decode(jsonData);
          final String planId =
              key.replaceFirst('order_summary_${_currentStudentId}_', '');
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

  Future<void> _loadStoredTotals() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, double> totals = {};
    for (final plan in _activePlans) {
      final key = 'order_total_${plan.studentId}_${plan.id}';
      if (prefs.containsKey(key)) {
        final val = prefs.getDouble(key) ?? prefs.getInt(key)?.toDouble();
        if (val != null) totals[plan.id] = val;
      }
    }
    setState(() {
      _storedTotals = totals;
    });
  }

  // Helper to load stored plan dates and weekdays from SharedPreferences
  Future<Map<String, dynamic>?> _getStoredPlanDates(
      String studentId, String planId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'order_dates_${studentId}_$planId';
    if (prefs.containsKey(key)) {
      final data = jsonDecode(prefs.getString(key)!);
      return {
        'startDate': DateTime.parse(data['startDate']),
        'endDate': DateTime.parse(data['endDate']),
        'selectedWeekdays':
            (data['selectedWeekdays'] as List).map((e) => e as int).toList(),
      };
    }
    return null;
  }

  // Prefetch stored plan dates for all plans in _loadData
  Future<void> _loadStoredPlanDates() async {
    final Map<String, Map<String, dynamic>> result = {};
    for (final plan in _activePlans) {
      final stored = await _getStoredPlanDates(plan.studentId, plan.id);
      if (stored != null) {
        result[plan.id] = stored;
      }
    }
    setState(() {
      _storedPlanDates = result;
    });
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
        (student) => student.id == _currentStudentId,
        orElse: () => throw Exception('Student not found'),
      );

      // Fetch active subscriptions for the student
      final subscriptionService = services.SubscriptionService();
      _activePlans = await subscriptionService
          .getActiveSubscriptionsForStudent(_currentStudentId);

      // Load stored totals for these plans
      await _loadStoredTotals();

      // Load stored plan dates for these plans
      await _loadStoredPlanDates();

      if (_activePlans.isNotEmpty) {
        // Process each active plan
        for (var plan in _activePlans) {
          // Calculate meal summary based on the subscription
          final int totalMeals = _calculateTotalMeals(plan);

          // Get all cancelled meals to calculate consumed
          final cancelledMeals =
              await subscriptionService.getCancelledMeals(_currentStudentId);
          final int cancelledCount = cancelledMeals.length;

          // Calculate consumed meals
          final int consumedMeals =
              _calculateConsumedMeals(plan, cancelledCount);

          // Determine and store delivery mode
          final deliveryMode = _determineDeliveryMode(plan);
          await _storeDeliveryMode(_currentStudentId, plan.id, deliveryMode);
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
          _isChangingStudent = false;
        });
      }
    } catch (e) {
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
      appBar: GradientAppBar(
        titleText: 'Active Plan Details',
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
                            // Display each plan card
                            for (int i = 0; i < _planSummaries.length; i++)
                              _buildPlanCard(_planSummaries[i], i),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> planSummary, int index) {
    final Subscription plan = planSummary['plan'];
    final bool isBreakfastPlan = plan.planType == 'breakfast';
    final bool hasStoredSummary = planSummary['hasStoredSummary'] ?? false;

    // Use stored plan dates if available
    final stored = _storedPlanDates[plan.id];
    final DateTime startDate = stored?['startDate'] ?? plan.startDate;
    final DateTime endDate = stored?['endDate'] ?? plan.endDate;
    final List<int> selectedWeekdays =
        stored?['selectedWeekdays'] ?? plan.selectedWeekdays;
    final String deliveryMode = _getDeliveryDaysText(plan);

    // Ensure consumed meals is never negative
    final int consumed =
        planSummary['consumed'] < 0 ? 0 : planSummary['consumed'];
    final int remaining = planSummary['totalMeals'] - consumed;

    // Get plan period description
    final String planPeriod = _getPlanPeriodDescription(plan);

    // Format the price per meal
    final String pricePerMeal = '₹${planSummary['pricePerMeal']}';

    // Calculate total price
    final num totalPrice = _storedTotals[plan.id] ??
        (hasStoredSummary && planSummary['totalAmount'] != null
            ? planSummary['totalAmount']
            : planSummary['totalMeals'] * planSummary['pricePerMeal']);

    // Use MealConstants for consistent styling
    final Color planIconColor = MealConstants.getIconColor(plan.planType);
    final Color planBgColor = MealConstants.getBgColor(plan.planType);
    final Color planBorderColor = MealConstants.getBorderColor(plan.planType);
    final IconData planIcon = MealConstants.getIcon(plan.planType);

    // Helper to clean up meal name
    String _strictMealName(String name, String planType) {
      return normalizeMealName(name, planType);
    }

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
                      child: _getMealImageForPlan(plan),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      // Include meal type in the plan display name for clarity
                      '${isBreakfastPlan ? 'Breakfast' : 'Lunch'} Plan - ${_getPlanTypeDisplay(plan)}',
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
                  // HIDE Section 1: Subscription Details label
                  // _buildSectionHeader('Subscription Details'),
                  // const SizedBox(height: 8),
                  Column(
                    children: [
                      _buildDetailRow(
                        'Meal Name',
                        plan.mealName.isNotEmpty
                            ? _strictMealName(plan.mealName, plan.planType)[0]
                                    .toUpperCase() +
                                _strictMealName(plan.mealName, plan.planType)
                                    .substring(1)
                            : '',
                      ),
                      _buildDetailRow(
                        'Start Date',
                        DateFormat('dd MMM yyyy').format(startDate),
                      ),
                      _buildDetailRow(
                        'End Date',
                        DateFormat('dd MMM yyyy').format(endDate),
                      ),
                    ],
                  ),
                  // const SizedBox(height: 0),

                  // Section 2: Meals & Pricing
                  // HIDE Meals & Pricing section header and spacing
                  Column(
                    children: [
                      _buildDetailRow(
                        'Delivery Mode',
                        deliveryMode,
                      ),
                      // _buildDetailRow(
                      //   'Price Per Meal',
                      //   pricePerMeal,
                      // ),
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
      return "Mon to Fri"; // Default for non-custom plans
    }

    final weekdayShortNames = [
      '',
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun'
    ];

    final List<String> selectedDays = [];
    for (int day in plan.selectedWeekdays) {
      if (day >= 1 && day <= 7) {
        selectedDays.add(weekdayShortNames[day]);
      }
    }

    if (selectedDays.isEmpty) {
      return "Mon to Fri"; // Fallback if custom days are somehow empty
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

  Widget _buildStudentInfoCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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
    );
  }

  Widget _buildAssociatedStudentsSection() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
        border: Border.all(
          color: AppTheme.purple.withOpacity(0.1),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Associated Students'),
          const SizedBox(height: 8),
          for (Student student in _associatedStudents)
            _buildStatusRow(student.name, 'Active'),
        ],
      ),
    );
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

  // Helper to cast dynamic list to List<int>
  List<int> _castToIntList(dynamic list) {
    if (list == null) return <int>[];
    return (list as List).map((e) => e as int).toList();
  }
}
