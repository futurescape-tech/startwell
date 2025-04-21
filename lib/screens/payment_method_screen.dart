import 'dart:developer';
import 'dart:convert'; // Add import for json encode/decode

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/models/meal_model.dart';
import 'package:startwell/models/student_model.dart';
import 'package:startwell/services/student_profile_service.dart';
import 'package:startwell/utils/meal_plan_validator.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:startwell/screens/payment_dummy_screens.dart';
import 'package:intl/intl.dart';
import 'package:startwell/widgets/common/gradient_app_bar.dart';
import 'package:startwell/widgets/common/gradient_button.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Add SharedPreferences

class PaymentMethodScreen extends StatefulWidget {
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

  const PaymentMethodScreen({
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
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  int _selectedPaymentMethod =
      0; // 0: PhonePe, 1: Razorpay, 2: Startwell Wallet

  @override
  void initState() {
    super.initState();
    _storeOrderSummary();
  }

  // Store order summary in SharedPreferences for use in Plan Details page
  Future<void> _storeOrderSummary() async {
    try {
      // Only proceed if we have a selected student
      if (widget.selectedStudent.id.isEmpty) {
        return;
      }

      // Create a map with order summary data
      final Map<String, dynamic> orderSummary = {
        'planType': widget.planType,
        'isCustomPlan': widget.isCustomPlan,
        'startDate': widget.startDate.toIso8601String(),
        'endDate': widget.endDate.toIso8601String(),
        'totalMeals': widget.mealDates.length,
        'totalAmount': widget.totalAmount,
        'pricePerMeal': widget.totalAmount / widget.mealDates.length,
        'mealType': widget.mealType ??
            (widget.selectedMeals.isNotEmpty
                ? widget.selectedMeals.first.categories
                        .contains(MealCategory.breakfast)
                    ? 'breakfast'
                    : 'lunch'
                : 'lunch'),
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Generate a unique ID for this subscription
      final String planId = 'plan_${DateTime.now().millisecondsSinceEpoch}';

      // Store in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final key = 'order_summary_${widget.selectedStudent.id}_$planId';
      await prefs.setString(key, jsonEncode(orderSummary));

      log('Order summary stored in SharedPreferences with key: $key');
    } catch (e) {
      log('Error storing order summary: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        titleText: 'Payment Method',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selected Delivery Address Section
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Selected Delivery Address',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Default',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppTheme.textMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: true,
                        onChanged: null, // non-editable
                        activeColor: AppTheme.purple,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.selectedStudent.schoolName,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.selectedStudent.schoolAddress,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppTheme.textMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue.shade200,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Meals will be provided to your child at school during breakfast and lunch hours.',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Payment Method Selection
            _buildPaymentMethodSection(),

            const SizedBox(height: 24),

            // Order Summary
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Summary',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryItem('Plan Type', widget.planType.toUpperCase()),
                  _buildSummaryItem(
                      'Duration',
                      widget.isCustomPlan
                          ? '${widget.mealDates.length} days custom plan'
                          : '${widget.endDate.difference(widget.startDate).inDays + 1} days'),
                  _buildSummaryItem('Student', widget.selectedStudent.name),
                  _buildSummaryItem(
                      'School', widget.selectedStudent.schoolName),
                  _buildSummaryItem(
                      'Meal Plan',
                      widget.selectedMeals.isNotEmpty
                          ? widget.selectedMeals.first.name
                          : '${widget.mealType?.toUpperCase() ?? "Standard"} Meal Plan'),
                  _buildSummaryItem(
                      'Total Meals', '${widget.mealDates.length} meals'),
                  _buildSummaryItem('Start Date',
                      '${DateFormat('dd MMM yyyy').format(widget.startDate)}'),
                  _buildSummaryItem('End Date',
                      '${DateFormat('dd MMM yyyy').format(widget.endDate)}'),

                  const Divider(height: 32),

                  // Total amount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Text(
                        '₹${widget.totalAmount.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.purple,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Continue button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: GradientButton(
                text: 'Continue',
                isFullWidth: true,
                onPressed: () => _navigateToPaymentScreen(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Select Payment Mode',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 24),

          // PhonePe
          _buildPaymentMethodTile(
            0,
            'PhonePe',
            'Pay using UPI with PhonePe',
            'assets/images/payment/phonepe.png',
          ),

          // Razorpay
          _buildPaymentMethodTile(
            1,
            'Razorpay',
            'Pay using Credit/Debit Card, UPI, Netbanking',
            'assets/images/payment/razorpay.png',
          ),

          // Startwell Wallet
          _buildPaymentMethodTile(
            2,
            'Startwell Wallet',
            'Use your Startwell wallet balance',
            'assets/images/payment/wallet.png',
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile(
      int index, String title, String subtitle, String imagePath) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: _selectedPaymentMethod == index
              ? AppTheme.purple
              : Colors.grey.shade300,
          width: _selectedPaymentMethod == index ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPaymentMethod = index;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _selectedPaymentMethod == index
                        ? AppTheme.purple
                        : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: _selectedPaymentMethod == index
                    ? Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.purple,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textMedium,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Image.asset(
                imagePath,
                width: 36,
                height: 36,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      index == 0
                          ? Icons.phone_android
                          : index == 1
                              ? Icons.payment
                              : Icons.account_balance_wallet,
                      color: AppTheme.textMedium,
                      size: 20,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: AppTheme.textMedium,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToPaymentScreen() {
    switch (_selectedPaymentMethod) {
      case 0:
        log("PhonePe");
        log("endDate: ${widget.endDate}");
        log("startDate: ${widget.startDate}");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PhonePeDummyScreen(
              planType: widget.planType,
              isCustomPlan: widget.isCustomPlan,
              selectedWeekdays: widget.selectedWeekdays,
              startDate: widget.startDate,
              endDate: widget.endDate,
              mealDates: widget.mealDates,
              totalAmount: widget.totalAmount,
              selectedMeals: widget.selectedMeals,
              isExpressOrder: widget.isExpressOrder,
              selectedStudent: widget.selectedStudent,
              mealType: widget.mealType,
            ),
          ),
        );
        break;
      case 1:
        log("Razorpay");
        log("endDate: ${widget.endDate}");
        log("startDate: ${widget.startDate}");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RazorpayDummyScreen(
              planType: widget.planType,
              isCustomPlan: widget.isCustomPlan,
              selectedWeekdays: widget.selectedWeekdays,
              startDate: widget.startDate,
              endDate: widget.endDate,
              mealDates: widget.mealDates,
              totalAmount: widget.totalAmount,
              selectedMeals: widget.selectedMeals,
              isExpressOrder: widget.isExpressOrder,
              selectedStudent: widget.selectedStudent,
              mealType: widget.mealType,
            ),
          ),
        );
        break;
      case 2:
        log("Startwell Wallet");
        log("endDate: ${widget.endDate}");
        log("startDate: ${widget.startDate}");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StartwellWalletDummyScreen(
              planType: widget.planType,
              isCustomPlan: widget.isCustomPlan,
              selectedWeekdays: widget.selectedWeekdays,
              startDate: widget.startDate,
              endDate: widget.endDate,
              mealDates: widget.mealDates,
              totalAmount: widget.totalAmount,
              selectedMeals: widget.selectedMeals,
              isExpressOrder: widget.isExpressOrder,
              selectedStudent: widget.selectedStudent,
              mealType: widget.mealType,
            ),
          ),
        );
        break;
    }
  }
}
