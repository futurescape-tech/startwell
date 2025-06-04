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
  final DateTime? breakfastPreOrderDate;
  final DateTime? lunchPreOrderDate;
  final bool isPreOrder;
  final String? selectedPlanType;
  final String? deliveryMode;
  final String? promoCode;
  final double? promoDiscount;
  final String? breakfastDeliveryMode;
  final String? lunchDeliveryMode;
  final List<bool>? breakfastSelectedWeekdays;
  final List<bool>? lunchSelectedWeekdays;
  final DateTime? preOrderStartDate;
  final DateTime? preOrderEndDate;

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
    this.breakfastPreOrderDate,
    this.lunchPreOrderDate,
    this.isPreOrder = false,
    this.selectedPlanType,
    this.deliveryMode,
    this.promoCode,
    this.promoDiscount,
    this.breakfastDeliveryMode,
    this.lunchDeliveryMode,
    this.breakfastSelectedWeekdays,
    this.lunchSelectedWeekdays,
    this.preOrderStartDate,
    this.preOrderEndDate,
  }) : super(key: key);

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  int _selectedPaymentMethod =
      0; // 0: PhonePe, 1: Razorpay, 2: Startwell Wallet

  // Add state variables for promo code functionality
  final TextEditingController _promoController = TextEditingController();
  String? _appliedPromoCode;
  double _discountPercentage = 0.0;
  String? _promoMessage;
  bool _isPromoValid = false;

  // Flag to track whether both meal types are selected
  bool _hasBothMealTypes = false;

  // Define valid promo codes
  final Map<String, double> _validPromoCodes = {
    "STARTWELL10": 0.10, // 10% discount
    "LUNCH20": 0.20, // 20% discount
    "WELCOME25": 0.25, // 25% discount
  };

  @override
  void initState() {
    super.initState();
    _storeOrderSummary();

    // Determine if both meal types are selected
    _hasBothMealTypes = (widget.mealType == 'both') ||
        (widget.breakfastPreOrderDate != null &&
            widget.lunchPreOrderDate != null);
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  // Apply promo code and calculate discount
  void _applyPromoCode() {
    final code = _promoController.text.trim().toUpperCase();

    if (code.isEmpty) {
      setState(() {
        _promoMessage = "Please enter a promo code";
        _isPromoValid = false;
        _appliedPromoCode = null;
        _discountPercentage = 0.0;
      });
      return;
    }

    if (_validPromoCodes.containsKey(code)) {
      setState(() {
        _appliedPromoCode = code;
        _discountPercentage = _validPromoCodes[code]!;
        _promoMessage = "Promo applied successfully!";
        _isPromoValid = true;
      });
    } else {
      setState(() {
        _promoMessage = "Invalid promo code";
        _isPromoValid = false;
        _appliedPromoCode = null;
        _discountPercentage = 0.0;
      });
    }
  }

  // Calculate final price after promo code
  double _calculateFinalPrice() {
    // Start with the original total amount
    double finalPrice = widget.totalAmount;

    // Apply promo discount if valid
    if (_appliedPromoCode != null && _discountPercentage > 0) {
      finalPrice = finalPrice * (1 - _discountPercentage);
    }

    return finalPrice;
  }

  // Store order summary in SharedPreferences for use in Plan Details page
  Future<void> _storeOrderSummary() async {
    try {
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
                ? widget.selectedMeals.first.categories.first ==
                        MealCategory.breakfast
                    ? 'breakfast'
                    : 'lunch'
                : 'lunch'),
        'timestamp': DateTime.now().toIso8601String(),
        'isPreOrder': widget.isPreOrder,
      };

      // Add pre-order start and end dates if provided
      if (widget.preOrderStartDate != null) {
        orderSummary['preOrderStartDate'] =
            widget.preOrderStartDate!.toIso8601String();
      }

      if (widget.preOrderEndDate != null) {
        orderSummary['preOrderEndDate'] =
            widget.preOrderEndDate!.toIso8601String();
      }

      // Add pre-order dates if provided
      if (widget.breakfastPreOrderDate != null) {
        orderSummary['breakfastPreOrderDate'] =
            widget.breakfastPreOrderDate!.toIso8601String();
      }

      if (widget.lunchPreOrderDate != null) {
        orderSummary['lunchPreOrderDate'] =
            widget.lunchPreOrderDate!.toIso8601String();
      }

      // Add selected plan type and delivery mode if provided
      if (widget.selectedPlanType != null) {
        orderSummary['selectedPlanType'] = widget.selectedPlanType;
      }

      // Store specific delivery modes for breakfast and lunch
      if (widget.breakfastDeliveryMode != null) {
        orderSummary['breakfastDeliveryMode'] = widget.breakfastDeliveryMode;
      }

      if (widget.lunchDeliveryMode != null) {
        orderSummary['lunchDeliveryMode'] = widget.lunchDeliveryMode;
      }

      // Store specific weekday selections for breakfast and lunch
      if (widget.breakfastSelectedWeekdays != null) {
        // Convert boolean list to a serializable format (list of integers)
        List<int> breakfastWeekdaysInt = widget.breakfastSelectedWeekdays!
            .map((value) => value ? 1 : 0)
            .toList();
        orderSummary['breakfastSelectedWeekdays'] = breakfastWeekdaysInt;
      }

      if (widget.lunchSelectedWeekdays != null) {
        // Convert boolean list to a serializable format (list of integers)
        List<int> lunchWeekdaysInt = widget.lunchSelectedWeekdays!
            .map((value) => value ? 1 : 0)
            .toList();
        orderSummary['lunchSelectedWeekdays'] = lunchWeekdaysInt;
      }

      // For backwards compatibility
      if (widget.deliveryMode != null) {
        orderSummary['deliveryMode'] = widget.deliveryMode;
      }

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
    // Calculate if discount applies
    bool hasDiscount =
        widget.planType != 'Single Day' && widget.mealDates.length > 7;

    return Scaffold(
      appBar: GradientAppBar(
        titleText: 'Payment Method',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selected Delivery Address Section - Compact Version
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.purple.withOpacity(0.15),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.deepPurple.withOpacity(0.1),
                    spreadRadius: 0,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with location icon, title and check icon - more compact
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.purple.withOpacity(0.8),
                              AppTheme.deepPurple.withOpacity(0.9),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.location_on_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Delivery Address',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: AppTheme.success,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // School and student info - combined in a more compact layout
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // School icon
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.purple.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.school_rounded,
                          size: 16,
                          color: AppTheme.purple,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // School and student details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // School name
                            Text(
                              widget.selectedStudent.schoolName,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppTheme.textDark,
                              ),
                            ),

                            const SizedBox(height: 14),

                            // Student name and class in a row
                            Row(
                              children: [
                                // Student name badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.purple.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.person,
                                        size: 12,
                                        color: AppTheme.purple,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        widget.selectedStudent.name,
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.purple,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 6),

                                // Class badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.deepPurple.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.class_,
                                        size: 12,
                                        color: AppTheme.deepPurple,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        "${widget.selectedStudent.className} ${widget.selectedStudent.section}",
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.deepPurple,
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
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Payment Method Section
            _buildCardSection(
              title: 'Select Payment Mode',
              icon: Icons.payments_rounded,
              children: [
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

            const SizedBox(height: 32),

            // Continue button
            SizedBox(
              width: double.infinity,
              height: 60,
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

  Widget _buildPaymentMethodTile(
      int index, String title, String subtitle, String imagePath) {
    final bool isSelected = _selectedPaymentMethod == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: isSelected ? AppTheme.purple : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
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
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppTheme.purple : Colors.grey.shade400,
                    width: 2,
                  ),
                  color: Colors.white,
                  boxShadow: null,
                ),
                child: isSelected
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
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? AppTheme.purple : AppTheme.textDark,
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
              Stack(
                alignment: Alignment.center,
                children: [
                  if (isSelected)
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.purple.withOpacity(0.05),
                      ),
                    ),
                  Image.asset(
                    imagePath,
                    width: 36,
                    height: 36,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 20,
                          color: Colors.deepPurple,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentInfoRow({
    required IconData icon,
    required String label,
    required String value,
    TextStyle? valueStyle,
    bool isLast = false,
    bool isAlert = false,
    Color? iconColor,
    Color? backgroundColor,
  }) {
    final iconColorValue = iconColor ?? AppTheme.textMedium;
    final backgroundColorValue = backgroundColor ??
        (isAlert ? Colors.red.withOpacity(0.08) : Colors.transparent);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: backgroundColorValue,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: iconColorValue.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 18,
              color: iconColorValue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppTheme.textMedium,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: valueStyle ??
                      GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textDark,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    bool withoutPadding = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepPurple.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
        ],
      ),
      // Using Stack to create gradient border effect
      child: Stack(
        children: [
          // Gradient background for border effect
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.purple.withOpacity(0.7),
                  AppTheme.deepPurple.withOpacity(0.7),
                ],
              ),
            ),
            margin: EdgeInsets.zero,
          ),
          // White card with small margin to show gradient border
          Card(
            margin: const EdgeInsets.all(2), // This creates the border effect
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(18), // Slightly smaller to fit inside
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.white,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.purple.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.deepPurple.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            icon,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (withoutPadding)
                    ...children
                  else
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 24, right: 24, bottom: 24),
                      child: Column(
                        children: children,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealPlanOptions() {
    // Determine meal type - breakfast, lunch or express
    final String mealType = widget.mealType ??
        (widget.selectedMeals.isNotEmpty &&
                widget.selectedMeals.first.categories
                    .contains(MealCategory.breakfast)
            ? 'breakfast'
            : widget.isExpressOrder
                ? 'express'
                : 'lunch');

    // Get meal name and image
    final String mealName = widget.selectedMeals.isNotEmpty
        ? widget.selectedMeals.first.name
        : mealType == 'breakfast'
            ? 'Breakfast of the Day'
            : mealType == 'express'
                ? 'Express Lunch'
                : 'Lunch of the Day';

    final String imageUrl = widget.selectedMeals.isNotEmpty &&
            widget.selectedMeals.first.imageUrl.isNotEmpty
        ? widget.selectedMeals.first.imageUrl
        : mealType == 'breakfast'
            ? 'assets/images/breakfast/breakfast of the day (most recommended).png'
            : 'assets/images/lunch/lunch of the day (most recommended).png';

    // Tab view for Breakfast, Lunch, Express options
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.purple.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.07),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header text
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              "Selected meal type",
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
          ),

          // Meal plan tabs
          Container(
            height: 54,
            decoration: BoxDecoration(
              //color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(color: Colors.purple.shade50),
            ),
            child: Row(
              children: [
                _buildMealPlanTab(
                  'Breakfast',
                  mealType == 'breakfast',
                  Icons.ramen_dining,
                  Colors.pink,
                ),
                _buildMealPlanTab(
                  'Lunch',
                  mealType == 'lunch',
                  Icons.flatware_rounded,
                  AppTheme.success,
                ),
                _buildMealPlanTab(
                  'Express',
                  mealType == 'express',
                  Icons.local_shipping_rounded,
                  Colors.orange,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Brief explanation text based on meal type
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getMealTypeColor(mealType).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _getMealTypeColor(mealType).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getMealTypeIcon(mealType),
                  color: _getMealTypeColor(mealType),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getMealTypeDescription(mealType),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppTheme.textMedium,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Meal card
          _buildSelectedMealCard(mealName, imageUrl, mealType),
        ],
      ),
    );
  }

  Widget _buildMealPlanTab(
      String title, bool isSelected, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 12,
        ),
        // margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    color.withOpacity(0.1),
                    color.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? color : color.withOpacity(0.7),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? color : AppTheme.textMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getMealTypeColor(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return Colors.pink;
      case 'express':
        return Colors.blue;
      case 'lunch':
      default:
        return AppTheme.success;
    }
  }

  IconData _getMealTypeIcon(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return Icons.ramen_dining;
      case 'express':
        return Icons.local_shipping_rounded;
      case 'lunch':
      default:
        return Icons.flatware_rounded;
    }
  }

  String _getMealTypeDescription(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return 'Fresh breakfast delivered to your child at school in the morning hours.';
      case 'express':
        return 'Same-day lunch delivery with express service (additional fee applies).';
      case 'lunch':
      default:
        return 'Nutritious lunch delivered to your child during school lunch hours.';
    }
  }

  Widget _buildSelectedMealCard(String name, String imageUrl, String mealType) {
    // Determine if we should show express fee
    final bool isExpress = mealType == 'express';
    final double mealPrice = widget.totalAmount / widget.mealDates.length;
    final Color typeColor = _getMealTypeColor(mealType);

    return Card(
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: typeColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      elevation: 4,
      shadowColor: typeColor.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meal image with gradient overlay for better text visibility
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  children: [
                    Image.asset(
                      imageUrl,
                      width: double.infinity,
                      height: 160,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 160,
                          width: double.infinity,
                          color: typeColor.withOpacity(0.1),
                          child: Icon(
                            _getMealTypeIcon(mealType),
                            size: 60,
                            color: typeColor.withOpacity(0.3),
                          ),
                        );
                      },
                    ),
                    // Gradient overlay for better text visibility
                    // Positioned.fill(
                    //   child: Container(
                    //     decoration: BoxDecoration(
                    //       gradient: LinearGradient(
                    //         begin: Alignment.bottomCenter,
                    //         end: Alignment.center,
                    //         colors: [
                    //           Colors.black.withOpacity(0.5),
                    //           Colors.transparent,
                    //         ],
                    //       ),
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),

              // Selected badge
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Colors.orange,
                        Colors.deepPurple, // orangeToYellow
                        // Color.fromARGB(255, 239, 243, 31), // success
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Top Pick',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Meal type badge
              // Positioned(
              //   bottom: 12,
              //   left: 12,
              //   child: Container(
              //     padding: const EdgeInsets.symmetric(
              //       horizontal: 12,
              //       vertical: 6,
              //     ),
              //     decoration: BoxDecoration(
              //       color: Colors.black.withOpacity(0.6),
              //       borderRadius: BorderRadius.circular(8),
              //     ),
              //     child: Row(
              //       children: [
              //         Icon(
              //           _getMealTypeIcon(mealType),
              //           color: typeColor,
              //           size: 16,
              //         ),
              //         const SizedBox(width: 6),
              //         Text(
              //           mealType.substring(0, 1).toUpperCase() +
              //               mealType.substring(1),
              //           style: GoogleFonts.poppins(
              //             color: Colors.white,
              //             fontSize: 12,
              //             fontWeight: FontWeight.w600,
              //           ),
              //         ),
              //       ],
              //     ),
              //   ),
              // ),
            ],
          ),

          // Meal details
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Meal name with veg icon
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(1.0),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.green,
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.circle,
                        size: 10,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Price and details row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          mealType == 'breakfast'
                              ? Icons.ramen_dining
                              : Icons.flatware,
                          size: 16,
                          color: mealType == 'breakfast'
                              ? Colors.pink
                              : AppTheme.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          mealType == 'breakfast'
                              ? 'Breakfast Meal'
                              : mealType == 'express'
                                  ? 'Express Lunch Meal'
                                  : 'Lunch Meal',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppTheme.textMedium,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.withOpacity(0.2),
                            Colors.purple.withOpacity(0.2),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '₹${mealPrice.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ),
                  ],
                ),

                // Express fee info
                if (isExpress) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delivery_dining_outlined,
                          size: 18,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Express Fee: ₹50 for same-day delivery',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Payment Details Section - Updated to show combined details for both plans
  Widget _buildPaymentDetails() {
    // Calculate if discount applies
    bool hasDiscount =
        widget.planType != 'Single Day' && widget.mealDates.length > 7;

    // If both meal types selected, we'll show different layout
    if (_hasBothMealTypes) {
      // For two plans, we'll calculate per-plan price as 50% of total for simplicity
      // In a real app, you would use actual separate prices for each meal type
      final double breakfastAmount = widget.totalAmount / 2;
      final double lunchAmount = widget.totalAmount / 2;
      final int breakfastMeals = widget.mealDates.length;
      final int lunchMeals = widget.mealDates.length;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.purple.withOpacity(0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.07),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HIDE Combined Subscription Plans section
            if (false) ...[
              // Header
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  "Combined Subscription Plans",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
              ),

              // Breakfast Plan Details
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amber.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.wb_sunny_outlined,
                          size: 18,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Breakfast Plan",
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildStudentInfoRow(
                      icon: Icons.flatware_rounded,
                      label: 'Meal Price',
                      value:
                          '₹${(breakfastAmount / breakfastMeals).toStringAsFixed(0)} per meal',
                      iconColor: Colors.amber,
                      backgroundColor: Colors.amber.withOpacity(0.1),
                    ),
                    _buildStudentInfoRow(
                      icon: Icons.list_alt_rounded,
                      label: 'Number of Meals',
                      value: '$breakfastMeals',
                      iconColor: Colors.amber,
                      backgroundColor: Colors.amber.withOpacity(0.1),
                      isLast: true,
                    ),
                  ],
                ),
              ),

              // Lunch Plan Details
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.purple.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.purple.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.restaurant_outlined,
                          size: 18,
                          color: AppTheme.purple,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Lunch Plan",
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildStudentInfoRow(
                      icon: Icons.flatware_rounded,
                      label: 'Meal Price',
                      value:
                          '₹${(lunchAmount / lunchMeals).toStringAsFixed(0)} per meal',
                      iconColor: AppTheme.purple,
                      backgroundColor: AppTheme.purple.withOpacity(0.1),
                    ),
                    _buildStudentInfoRow(
                      icon: Icons.list_alt_rounded,
                      label: 'Number of Meals',
                      value: '$lunchMeals',
                      iconColor: AppTheme.purple,
                      backgroundColor: AppTheme.purple.withOpacity(0.1),
                      isLast: true,
                    ),
                  ],
                ),
              ),

              // Divider
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(
                  color: Colors.grey.shade200,
                  height: 1,
                ),
              ),
            ],

            // HIDE Promo Code Section
            if (false) ...[
              // Promo Code Section
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4),
                      child: Text(
                        "Have a promo code?",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(left: 8, right: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextField(
                              controller: _promoController,
                              textCapitalization: TextCapitalization.characters,
                              decoration: InputDecoration(
                                hintText: "Enter Promo Code",
                                hintStyle: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                                border: InputBorder.none,
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                prefixIcon: const Icon(
                                  Icons.discount_outlined,
                                  size: 18,
                                ),
                                suffixIcon: _promoController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 16),
                                        onPressed: () {
                                          setState(() {
                                            _promoController.clear();
                                            _promoMessage = null;
                                            _isPromoValid = false;
                                            _appliedPromoCode = null;
                                            _discountPercentage = 0.0;
                                          });
                                        },
                                      )
                                    : null,
                              ),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  // Clear message when typing
                                  if (_promoMessage != null) {
                                    _promoMessage = null;
                                  }
                                });
                              },
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: ElevatedButton(
                            onPressed: _applyPromoCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.purple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 14),
                              elevation: 0,
                            ),
                            child: Text(
                              "Apply",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_promoMessage != null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Icon(
                              _isPromoValid
                                  ? Icons.check_circle
                                  : Icons.error_outline,
                              size: 14,
                              color: _isPromoValid
                                  ? AppTheme.success
                                  : Colors.red.shade700,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _promoMessage!,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _isPromoValid
                                      ? AppTheme.success
                                      : Colors.red.shade700,
                                ),
                              ),
                            ),
                            if (_isPromoValid)
                              Text(
                                "${(_discountPercentage * 100).toInt()}% OFF",
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.success,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Summary Section
            // For combined plans, we show subtotals for each plan type
            if (_hasBothMealTypes) ...[
              // Breakfast Subtotal
              _buildStudentInfoRow(
                icon: Icons.breakfast_dining_outlined,
                label: 'Breakfast Subtotal',
                value: '₹${(breakfastAmount).toStringAsFixed(0)}',
                iconColor: Colors.amber,
                backgroundColor: Colors.amber.withOpacity(0.1),
              ),

              // Lunch Subtotal
              _buildStudentInfoRow(
                icon: Icons.restaurant_outlined,
                label: 'Lunch Subtotal',
                value: '₹${(lunchAmount).toStringAsFixed(0)}',
                iconColor: AppTheme.purple,
                backgroundColor: AppTheme.purple.withOpacity(0.1),
              ),
            ],

            // Plan Discount
            if (hasDiscount)
              _buildStudentInfoRow(
                icon: Icons.shopping_cart_outlined,
                label: 'Subtotal',
                value: '₹${(widget.totalAmount * 1.25).toStringAsFixed(0)}',
                valueStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  decoration: TextDecoration.lineThrough,
                  color: AppTheme.textMedium,
                ),
                iconColor: AppTheme.purple,
                backgroundColor: AppTheme.purple.withOpacity(0.1),
              ),

            if (hasDiscount)
              _buildStudentInfoRow(
                icon: Icons.discount_rounded,
                label: 'Plan Discount (${(0.25 * 100).toInt()}%)',
                value:
                    '-₹${((widget.totalAmount * 1.25) - widget.totalAmount).toStringAsFixed(0)}',
                valueStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.success,
                ),
                isAlert: false,
                iconColor: AppTheme.success,
                backgroundColor: AppTheme.success.withOpacity(0.1),
              ),

            // Add promo discount row if a valid promo is applied
            if (_appliedPromoCode != null && _isPromoValid)
              _buildStudentInfoRow(
                icon: Icons.local_offer_rounded,
                label: 'Promo Discount (${_appliedPromoCode})',
                value:
                    '-₹${(widget.totalAmount * _discountPercentage).toStringAsFixed(0)}',
                valueStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.success,
                ),
                isAlert: false,
                iconColor: AppTheme.success,
                backgroundColor: AppTheme.success.withOpacity(0.1),
              ),

            // Total Amount
            _buildStudentInfoRow(
              icon: Icons.payments_rounded,
              label: 'Total Amount',
              value: '₹${_calculateFinalPrice().toStringAsFixed(0)}',
              valueStyle: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.deepPurple,
              ),
              iconColor: AppTheme.deepPurple,
              backgroundColor: AppTheme.deepPurple.withOpacity(0.1),
              isLast: true,
            ),
          ],
        ),
      );
    } else {
      // Original payment details for single plan
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.purple.withOpacity(0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.07),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Hide Meal Price and Number of Meals
            if (false) ...[
              _buildStudentInfoRow(
                icon: Icons.flatware_rounded,
                label: 'Meal Price',
                value:
                    '₹${(widget.totalAmount / widget.mealDates.length).toStringAsFixed(0)} per meal',
                iconColor: AppTheme.purple,
                backgroundColor: AppTheme.purple.withOpacity(0.1),
              ),
              _buildStudentInfoRow(
                icon: Icons.list_alt_rounded,
                label: 'Number of Meals',
                value: '${widget.mealDates.length}',
                iconColor: AppTheme.purple,
                backgroundColor: AppTheme.purple.withOpacity(0.1),
              ),
            ],

            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(
                color: Colors.grey.shade200,
                height: 1,
              ),
            ),

            // Promo Code Section - existing implementation...
            // ... existing promo code section ...

            // Existing price calculation with any discounts...
          ],
        ),
      );
    }
  }

  void _navigateToPaymentScreen() {
    final double finalAmount = _calculateFinalPrice();

    switch (_selectedPaymentMethod) {
      case 0:
        log("PhonePe");
        log("endDate: \\${widget.endDate}");
        log("startDate: \\${widget.startDate}");
        log("Applied promo: \\${_appliedPromoCode ?? 'None'}, Final amount: ₹$finalAmount");
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
              totalAmount: finalAmount,
              selectedMeals: widget.selectedMeals,
              isExpressOrder: widget.isExpressOrder,
              selectedStudent: widget.selectedStudent,
              mealType: widget.mealType,
              breakfastPreOrderDate: widget.breakfastPreOrderDate,
              lunchPreOrderDate: widget.lunchPreOrderDate,
              breakfastDeliveryMode: widget.breakfastDeliveryMode,
              lunchDeliveryMode: widget.lunchDeliveryMode,
              breakfastSelectedWeekdays: widget.breakfastSelectedWeekdays,
              lunchSelectedWeekdays: widget.lunchSelectedWeekdays,
              preOrderStartDate: widget.preOrderStartDate,
              preOrderEndDate: widget.preOrderEndDate,
            ),
          ),
        );
        break;
      case 1:
        log("Razorpay");
        log("endDate: \\${widget.endDate}");
        log("startDate: \\${widget.startDate}");
        log("Applied promo: \\${_appliedPromoCode ?? 'None'}, Final amount: ₹$finalAmount");
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
              totalAmount: finalAmount,
              selectedMeals: widget.selectedMeals,
              isExpressOrder: widget.isExpressOrder,
              selectedStudent: widget.selectedStudent,
              mealType: widget.mealType,
              breakfastPreOrderDate: widget.breakfastPreOrderDate,
              lunchPreOrderDate: widget.lunchPreOrderDate,
              breakfastDeliveryMode: widget.breakfastDeliveryMode,
              lunchDeliveryMode: widget.lunchDeliveryMode,
              breakfastSelectedWeekdays: widget.breakfastSelectedWeekdays,
              lunchSelectedWeekdays: widget.lunchSelectedWeekdays,
              preOrderStartDate: widget.preOrderStartDate,
              preOrderEndDate: widget.preOrderEndDate,
            ),
          ),
        );
        break;
      case 2:
        log("Startwell Wallet");
        log("endDate: \\${widget.endDate}");
        log("startDate: \\${widget.startDate}");
        log("Applied promo: \\${_appliedPromoCode ?? 'None'}, Final amount: ₹$finalAmount");
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
              totalAmount: finalAmount,
              selectedMeals: widget.selectedMeals,
              isExpressOrder: widget.isExpressOrder,
              selectedStudent: widget.selectedStudent,
              mealType: widget.mealType,
              breakfastPreOrderDate: widget.breakfastPreOrderDate,
              lunchPreOrderDate: widget.lunchPreOrderDate,
              breakfastDeliveryMode: widget.breakfastDeliveryMode,
              lunchDeliveryMode: widget.lunchDeliveryMode,
              breakfastSelectedWeekdays: widget.breakfastSelectedWeekdays,
              lunchSelectedWeekdays: widget.lunchSelectedWeekdays,
              preOrderStartDate: widget.preOrderStartDate,
              preOrderEndDate: widget.preOrderEndDate,
            ),
          ),
        );
        break;
    }
  }
}
