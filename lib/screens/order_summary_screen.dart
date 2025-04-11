import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:startwell/models/meal_model.dart';
import 'package:startwell/models/student_model.dart';
import 'package:startwell/services/student_profile_service.dart';
import 'package:startwell/utils/meal_plan_validator.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:startwell/widgets/common/info_banner.dart';
import 'package:startwell/screens/payment_method_screen.dart';
import 'package:startwell/widgets/common/veg_icon.dart';

class OrderSummaryScreen extends StatelessWidget {
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

  const OrderSummaryScreen({
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

  // Get a formatted string of selected weekdays
  String _getSelectedWeekdaysText() {
    final List<String> weekdayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday'
    ];

    List<String> selectedDays = [];
    for (int i = 0; i < selectedWeekdays.length; i++) {
      if (selectedWeekdays[i]) {
        selectedDays.add(weekdayNames[i]);
      }
    }

    if (selectedDays.isEmpty) {
      return "None";
    } else if (selectedDays.length == 5) {
      return "All Weekdays";
    } else {
      return selectedDays.join(", ");
    }
  }

  // Navigate to Payment Methods screen
  void _navigateToPaymentMethods(BuildContext context, String planType) {
    print("Navigating to payment screen for $planType...");
    log("endDate: $endDate");
    log("startDate: $startDate");

    // Use the existing payment simulation logic inside a new PaymentMethodScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentMethodScreen(
          planType: this.planType,
          isCustomPlan: isCustomPlan,
          selectedWeekdays: selectedWeekdays,
          startDate: startDate,
          endDate: endDate,
          mealDates: mealDates,
          totalAmount: totalAmount,
          selectedMeals: selectedMeals,
          isExpressOrder: isExpressOrder,
          selectedStudent: selectedStudent,
          mealType: mealType,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasDiscount = planType == 'Quarterly' ||
        planType == 'Half-Yearly' ||
        planType == 'Annual';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Order Summary',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.purple,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order status banner
              InfoBanner(
                title: isExpressOrder ? "Express Order" : "Subscription Order",
                message: isExpressOrder
                    ? "Your express order is ready for processing."
                    : "Your subscription plan is ready for payment.",
                type: isExpressOrder
                    ? InfoBannerType.success
                    : InfoBannerType.info,
              ),

              const SizedBox(height: 24),

              // Plan details section
              _buildSectionTitle('Plan Details'),
              _buildDetailsCard([
                _buildDetailRow('Plan Type',
                    '$planType ${isCustomPlan ? "(Custom)" : "(Regular)"}'),
                _buildDetailRow(
                    'Duration',
                    planType == 'Single Day'
                        ? '1 Day'
                        : '$planType Subscription'),
                if (isCustomPlan)
                  _buildDetailRow('Selected Days', _getSelectedWeekdaysText()),
                _buildDetailRow('Total Meals', '${mealDates.length} meals'),
                _buildDetailRow('Start Date',
                    DateFormat('EEEE, MMMM d, yyyy').format(startDate)),
                _buildDetailRow('End Date',
                    DateFormat('EEEE, MMMM d, yyyy').format(endDate)),
              ]),

              const SizedBox(height: 24),

              // Selected meals section
              _buildSectionTitle('Selected Meal'),
              for (var meal in selectedMeals) _buildMealCard(meal),

              const SizedBox(height: 24),

              // Student information section
              _buildSectionTitle('Student Information'),
              _buildDetailsCard([
                _buildDetailRow('Student Name', selectedStudent.name),
                _buildDetailRow('School', selectedStudent.schoolName),
                _buildDetailRow('Class & Division',
                    'Class ${selectedStudent.className}, Division ${selectedStudent.division}'),
                _buildDetailRow('Floor', selectedStudent.floor),
                if (selectedStudent.allergies.isNotEmpty)
                  _buildDetailRow(
                    'Medical Allergies',
                    selectedStudent.allergies,
                    valueStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.red[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                _buildDetailRow(
                    'School Address', selectedStudent.schoolAddress),
              ]),

              const SizedBox(height: 24),

              // Payment summary section
              _buildSectionTitle('Payment Details'),
              _buildDetailsCard([
                _buildDetailRow('Meal Price',
                    '₹${(totalAmount / mealDates.length).toStringAsFixed(0)} per meal'),
                _buildDetailRow('Number of Meals', '${mealDates.length}'),
                if (hasDiscount)
                  _buildDetailRow(
                    'Subtotal',
                    '₹${(totalAmount * 1.25).toStringAsFixed(0)}',
                    valueStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      decoration: TextDecoration.lineThrough,
                      color: AppTheme.textMedium,
                    ),
                  ),
                if (hasDiscount)
                  _buildDetailRow(
                    'Discount',
                    '-₹${((totalAmount * 1.25) - totalAmount).toStringAsFixed(0)}',
                    valueStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.green,
                    ),
                  ),
                _buildDetailRow(
                  'Total Amount',
                  '₹${totalAmount.toStringAsFixed(0)}',
                  valueStyle: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.purple,
                  ),
                ),
              ]),

              const SizedBox(height: 32),

              // Payment button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    // Determine the meal plan type from the mealType parameter or from the selected meals
                    final String planType = mealType ??
                        (selectedMeals.first.categories.first ==
                                MealCategory.breakfast
                            ? 'breakfast'
                            : selectedMeals.first.categories.first ==
                                    MealCategory.expressOneDay
                                ? 'express'
                                : 'lunch');

                    // Validate the meal plan before proceeding
                    final String? validationError =
                        MealPlanValidator.validateMealPlan(
                            selectedStudent, planType);

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

                    // Proceed to payment method selection
                    _navigateToPaymentMethods(context, planType);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Proceed to Payment',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build section title
  Widget _buildSectionTitle(String title) {
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

  // Build details card
  Widget _buildDetailsCard(List<Widget> rows) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: rows,
        ),
      ),
    );
  }

  // Build a detail row
  Widget _buildDetailRow(String label, String value,
      {TextStyle? valueStyle, Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textMedium,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: valueStyle ??
                  GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppTheme.textDark,
                  ),
            ),
          ),
          if (trailing != null) const SizedBox(width: 8),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  // Build a meal card with enhanced display
  Widget _buildMealCard(Meal meal) {
    // Debug logging to help diagnose issues
    print('Building meal card for: ${meal.name}');
    print('Meal image URL: ${meal.imageUrl}');
    print('Meal price: ${meal.price}');
    print('Meal image URL type: ${meal.imageUrl.runtimeType}');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meal image with proper dimensions
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              color: Colors.white,
            ),
            child: meal.imageUrl.isNotEmpty
                ? Image.asset(
                    meal.imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      print('Error loading meal image: $error');
                      return Container(
                        height: 160,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.fastfood,
                              size: 40,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              meal.name,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textDark,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  )
                : Container(
                    height: 160,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.fastfood,
                          size: 40,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          meal.name,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textDark,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
          ),

          // Meal details
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Meal name with veg icon
                Row(
                  children: [
                    const VegIcon(),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        meal.name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Price
                Text(
                  '₹${meal.price.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.purple,
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
