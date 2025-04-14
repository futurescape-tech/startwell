import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/models/meal_model.dart';
import 'package:startwell/models/student_model.dart';
import 'package:startwell/services/student_profile_service.dart';
import 'package:startwell/utils/meal_plan_validator.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:startwell/screens/main_screen.dart';
import 'package:startwell/screens/my_subscription_screen.dart';
import 'package:intl/intl.dart';

class PhonePeDummyScreen extends StatefulWidget {
  final String planType;
  final bool isCustomPlan;
  final List<bool> selectedWeekdays;
  final DateTime startDate;
  final DateTime endDate;
  final List<DateTime> mealDates;
  final double totalAmount;
  final List<Meal> selectedMeals;
  final bool isExpressOrder;
  final Student selectedStudent;
  final String? mealType;

  const PhonePeDummyScreen({
    Key? key,
    required this.planType,
    required this.isCustomPlan,
    required this.selectedWeekdays,
    required this.startDate,
    required this.endDate,
    required this.mealDates,
    required this.totalAmount,
    required this.selectedMeals,
    required this.isExpressOrder,
    required this.selectedStudent,
    this.mealType,
  }) : super(key: key);

  @override
  State<PhonePeDummyScreen> createState() => _PhonePeDummyScreenState();
}

class _PhonePeDummyScreenState extends State<PhonePeDummyScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'PhonePe Payment',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.purple,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.payment,
                    size: 64,
                    color: AppTheme.purple,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'PhonePe Payment Screen',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This is a dummy screen for PhonePe payment integration',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: AppTheme.textMedium,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Amount to Pay: ₹${widget.totalAmount.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.purple,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _processPayment(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.purple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Pay Now',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _processPayment(BuildContext context) async {
    // Determine the meal plan type from the mealType parameter or from the selected meals
    final String planType = widget.mealType ??
        (widget.selectedMeals.first.categories.first == MealCategory.breakfast
            ? 'breakfast'
            : widget.selectedMeals.first.categories.first ==
                    MealCategory.expressOneDay
                ? 'express'
                : 'lunch');

    // Validate one last time
    final String? validationError =
        MealPlanValidator.validateMealPlan(widget.selectedStudent, planType);

    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            validationError,
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Process payment (simulated for demo)
      await Future.delayed(const Duration(seconds: 2));

      // Get the selected meal preference from the meal name
      String? mealPreference;
      if (widget.selectedMeals.isNotEmpty) {
        final mealName = widget.selectedMeals.first.name;
        // Extract the meal preference from the name (e.g. "Indian Breakfast" -> "Indian")
        if (mealName.contains("Indian")) {
          mealPreference = "Indian";
        } else if (mealName.contains("Jain")) {
          mealPreference = "Jain";
        } else if (mealName.contains("International")) {
          mealPreference = "International";
        } else if (mealName.contains("Express")) {
          mealPreference = "Express";
        } else {
          // Default to the most specific name we have
          mealPreference = mealName;
        }
      }

      // Assign the meal plan to the student
      final StudentProfileService profileService = StudentProfileService();

      // If this is a breakfast or lunch plan (not express), use April 14, 2025 as start date
      DateTime actualStartDate = widget.startDate;
      // No longer override the start date - use the date selected by the user
      // if (planType == 'breakfast' || planType == 'lunch') {
      //   // Set standardized plan start date to April 14, 2025
      //   actualStartDate = DateTime(2025, 4, 14);
      // }

      log('[DEBUG] Using actual start date in payment screen: ${DateFormat('yyyy-MM-dd').format(actualStartDate)}');
      log('[DEBUG] Meal plan type: $planType');

      final success = await profileService.assignMealPlan(
        actualStartDate,
        widget.selectedStudent.id,
        planType,
        widget.endDate,
        mealPreference: mealPreference,
        selectedWeekdays: widget.isCustomPlan
            ? widget.selectedWeekdays
                .asMap()
                .entries
                .where((entry) => entry.value)
                .map((entry) => entry.key + 1) // Convert to 1-7 for Mon-Sun
                .toList()
            : null,
      );

      // Close loading dialog
      Navigator.pop(context);

      if (success) {
        // Show success message dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text(
              'Payment Successful',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  widget.isExpressOrder
                      ? 'Your express order has been placed successfully! Your meal will be delivered to ${widget.selectedStudent.name} today.'
                      : 'Your subscription has been activated! Meals will be delivered to ${widget.selectedStudent.name} according to the schedule.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Close dialog
                    Navigator.pop(context);
                    log("PhonePeDummyScreen startDate: ${widget.startDate}");
                    log("PhonePeDummyScreen endDate: ${widget.endDate}");

                    // If this is a breakfast or lunch plan (not express), ensure startDate is April 14, 2025
                    DateTime actualStartDate = widget.startDate;
                    // No longer override start date - use what was selected by the user
                    // if (planType == 'breakfast' || planType == 'lunch') {
                    //   // Set standardized plan start date to April 14, 2025
                    //   actualStartDate = DateTime(2025, 4, 14);
                    // }

                    // Navigate directly to MySubscriptionScreen with Upcoming Meals tab (index 0)
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MySubscriptionScreen(
                          defaultTabIndex: 0,
                          selectedStudentId: widget.selectedStudent.id,
                          startDate: actualStartDate,
                          endDate: widget.endDate,
                        ),
                      ),
                      (route) => false, // Remove all previous routes
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Manage Subscription',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'There was an error processing your payment. Please try again.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment error: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class RazorpayDummyScreen extends StatefulWidget {
  final String planType;
  final bool isCustomPlan;
  final List<bool> selectedWeekdays;
  final DateTime startDate;
  final DateTime endDate;
  final List<DateTime> mealDates;
  final double totalAmount;
  final List<Meal> selectedMeals;
  final bool isExpressOrder;
  final Student selectedStudent;
  final String? mealType;

  const RazorpayDummyScreen({
    Key? key,
    required this.planType,
    required this.isCustomPlan,
    required this.selectedWeekdays,
    required this.startDate,
    required this.endDate,
    required this.mealDates,
    required this.totalAmount,
    required this.selectedMeals,
    required this.isExpressOrder,
    required this.selectedStudent,
    this.mealType,
  }) : super(key: key);

  @override
  State<RazorpayDummyScreen> createState() => _RazorpayDummyScreenState();
}

class _RazorpayDummyScreenState extends State<RazorpayDummyScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Razorpay Payment',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.purple,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.payment,
                    size: 64,
                    color: AppTheme.purple,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Razorpay Payment Screen',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This is a dummy screen for Razorpay payment integration',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: AppTheme.textMedium,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Amount to Pay: ₹${widget.totalAmount.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.purple,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _processPayment(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.purple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Pay Now',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _processPayment(BuildContext context) async {
    // Determine the meal plan type from the mealType parameter or from the selected meals
    final String planType = widget.mealType ??
        (widget.selectedMeals.first.categories.first == MealCategory.breakfast
            ? 'breakfast'
            : widget.selectedMeals.first.categories.first ==
                    MealCategory.expressOneDay
                ? 'express'
                : 'lunch');

    // Validate one last time
    final String? validationError =
        MealPlanValidator.validateMealPlan(widget.selectedStudent, planType);

    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            validationError,
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Process payment (simulated for demo)
      await Future.delayed(const Duration(seconds: 2));

      // Get the selected meal preference from the meal name
      String? mealPreference;
      if (widget.selectedMeals.isNotEmpty) {
        final mealName = widget.selectedMeals.first.name;
        // Extract the meal preference from the name (e.g. "Indian Breakfast" -> "Indian")
        if (mealName.contains("Indian")) {
          mealPreference = "Indian";
        } else if (mealName.contains("Jain")) {
          mealPreference = "Jain";
        } else if (mealName.contains("International")) {
          mealPreference = "International";
        } else if (mealName.contains("Express")) {
          mealPreference = "Express";
        } else {
          // Default to the most specific name we have
          mealPreference = mealName;
        }
      }

      // Assign the meal plan to the student
      final StudentProfileService profileService = StudentProfileService();

      // If this is a breakfast or lunch plan (not express), use April 14, 2025 as start date
      DateTime actualStartDate = widget.startDate;
      // No longer override the start date - use the date selected by the user
      // if (planType == 'breakfast' || planType == 'lunch') {
      //   // Set standardized plan start date to April 14, 2025
      //   actualStartDate = DateTime(2025, 4, 14);
      // }

      log('[DEBUG] Using actual start date in payment screen: ${DateFormat('yyyy-MM-dd').format(actualStartDate)}');
      log('[DEBUG] Meal plan type: $planType');

      final success = await profileService.assignMealPlan(
        actualStartDate,
        widget.selectedStudent.id,
        planType,
        widget.endDate,
        mealPreference: mealPreference,
        selectedWeekdays: widget.isCustomPlan
            ? widget.selectedWeekdays
                .asMap()
                .entries
                .where((entry) => entry.value)
                .map((entry) => entry.key + 1) // Convert to 1-7 for Mon-Sun
                .toList()
            : null,
      );

      // Close loading dialog
      Navigator.pop(context);

      if (success) {
        // Show success message dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text(
              'Payment Successful',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  widget.isExpressOrder
                      ? 'Your express order has been placed successfully! Your meal will be delivered to ${widget.selectedStudent.name} today.'
                      : 'Your subscription has been activated! Meals will be delivered to ${widget.selectedStudent.name} according to the schedule.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Close dialog
                    Navigator.pop(context);

                    // If this is a breakfast or lunch plan (not express), ensure startDate is April 14, 2025
                    DateTime actualStartDate = widget.startDate;
                    // No longer override start date - use what was selected by the user
                    // if (planType == 'breakfast' || planType == 'lunch') {
                    //   // Set standardized plan start date to April 14, 2025
                    //   actualStartDate = DateTime(2025, 4, 14);
                    // }

                    // Navigate directly to MySubscriptionScreen with Upcoming Meals tab (index 0)
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MySubscriptionScreen(
                          defaultTabIndex: 0,
                          selectedStudentId: widget.selectedStudent.id,
                          startDate: actualStartDate,
                          endDate: widget.endDate,
                        ),
                      ),
                      (route) => false, // Remove all previous routes
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Manage Subscription',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'There was an error processing your payment. Please try again.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment error: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class StartwellWalletDummyScreen extends StatefulWidget {
  final String planType;
  final bool isCustomPlan;
  final List<bool> selectedWeekdays;
  final DateTime startDate;
  final DateTime endDate;
  final List<DateTime> mealDates;
  final double totalAmount;
  final List<Meal> selectedMeals;
  final bool isExpressOrder;
  final Student selectedStudent;
  final String? mealType;

  const StartwellWalletDummyScreen({
    Key? key,
    required this.planType,
    required this.isCustomPlan,
    required this.selectedWeekdays,
    required this.startDate,
    required this.endDate,
    required this.mealDates,
    required this.totalAmount,
    required this.selectedMeals,
    required this.isExpressOrder,
    required this.selectedStudent,
    this.mealType,
  }) : super(key: key);

  @override
  State<StartwellWalletDummyScreen> createState() =>
      _StartwellWalletDummyScreenState();
}

class _StartwellWalletDummyScreenState
    extends State<StartwellWalletDummyScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Startwell Wallet',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.purple,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    size: 64,
                    color: AppTheme.purple,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Startwell Wallet Screen',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This is a dummy screen for Startwell Wallet payment',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: AppTheme.textMedium,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Amount to Pay: ₹${widget.totalAmount.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.purple,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _processPayment(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.purple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Pay Now',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _processPayment(BuildContext context) async {
    // Determine the meal plan type from the mealType parameter or from the selected meals
    final String planType = widget.mealType ??
        (widget.selectedMeals.first.categories.first == MealCategory.breakfast
            ? 'breakfast'
            : widget.selectedMeals.first.categories.first ==
                    MealCategory.expressOneDay
                ? 'express'
                : 'lunch');

    // Validate one last time
    final String? validationError =
        MealPlanValidator.validateMealPlan(widget.selectedStudent, planType);

    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            validationError,
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Process payment (simulated for demo)
      await Future.delayed(const Duration(seconds: 2));

      // Get the selected meal preference from the meal name
      String? mealPreference;
      if (widget.selectedMeals.isNotEmpty) {
        final mealName = widget.selectedMeals.first.name;
        // Extract the meal preference from the name (e.g. "Indian Breakfast" -> "Indian")
        if (mealName.contains("Indian")) {
          mealPreference = "Indian";
        } else if (mealName.contains("Jain")) {
          mealPreference = "Jain";
        } else if (mealName.contains("International")) {
          mealPreference = "International";
        } else if (mealName.contains("Express")) {
          mealPreference = "Express";
        } else {
          // Default to the most specific name we have
          mealPreference = mealName;
        }
      }

      // Assign the meal plan to the student
      final StudentProfileService profileService = StudentProfileService();

      // If this is a breakfast or lunch plan (not express), use April 14, 2025 as start date
      DateTime actualStartDate = widget.startDate;
      // No longer override the start date - use the date selected by the user
      // if (planType == 'breakfast' || planType == 'lunch') {
      //   // Set standardized plan start date to April 14, 2025
      //   actualStartDate = DateTime(2025, 4, 14);
      // }

      log('[DEBUG] Using actual start date in payment screen: ${DateFormat('yyyy-MM-dd').format(actualStartDate)}');
      log('[DEBUG] Meal plan type: $planType');

      final success = await profileService.assignMealPlan(
        actualStartDate,
        widget.selectedStudent.id,
        planType,
        widget.endDate,
        mealPreference: mealPreference,
        selectedWeekdays: widget.isCustomPlan
            ? widget.selectedWeekdays
                .asMap()
                .entries
                .where((entry) => entry.value)
                .map((entry) => entry.key + 1) // Convert to 1-7 for Mon-Sun
                .toList()
            : null,
      );

      // Close loading dialog
      Navigator.pop(context);

      if (success) {
        // Show success message dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text(
              'Payment Successful',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  widget.isExpressOrder
                      ? 'Your express order has been placed successfully! Your meal will be delivered to ${widget.selectedStudent.name} today.'
                      : 'Your subscription has been activated! Meals will be delivered to ${widget.selectedStudent.name} according to the schedule.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Close dialog
                    Navigator.pop(context);

                    // If this is a breakfast or lunch plan (not express), ensure startDate is April 14, 2025
                    DateTime actualStartDate = widget.startDate;
                    // No longer override start date - use what was selected by the user
                    // if (planType == 'breakfast' || planType == 'lunch') {
                    //   // Set standardized plan start date to April 14, 2025
                    //   actualStartDate = DateTime(2025, 4, 14);
                    // }

                    // Navigate directly to MySubscriptionScreen with Upcoming Meals tab (index 0)
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MySubscriptionScreen(
                          startDate: actualStartDate,
                          endDate: widget.endDate,
                          defaultTabIndex: 0,
                          selectedStudentId: widget.selectedStudent.id,
                        ),
                      ),
                      (route) => false, // Remove all previous routes
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Manage Subscription',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'There was an error processing your payment. Please try again.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment error: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
