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
import 'package:startwell/widgets/common/gradient_app_bar.dart';
import 'package:startwell/widgets/common/gradient_button.dart';
import 'package:startwell/utils/pre_order_date_calculator.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:startwell/utils/meal_names.dart';

// Extension to add capitalize method to String
extension StringExtension on String {
  String capitalize() {
    if (this.isEmpty) return this;
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}

class OrderSummaryScreen extends StatefulWidget {
  final String planType;
  final bool isCustomPlan;
  final List<bool> selectedWeekdays;
  final DateTime startDate;
  final DateTime endDate;
  final List<DateTime> mealDates;
  final double totalAmount;
  final List<Meal> selectedMeals;
  final bool isExpressOrder;
  final Student? selectedStudent;
  final String? mealType;
  final DateTime? breakfastPreOrderDate;
  final DateTime? lunchPreOrderDate;
  final bool isPreOrder;
  final String? selectedPlanType;
  final String? deliveryMode;

  // Add specific delivery modes for breakfast and lunch
  final String? breakfastDeliveryMode;
  final String? lunchDeliveryMode;

  // Breakfast specific data
  final DateTime? breakfastStartDate;
  final DateTime? breakfastEndDate;
  final List<DateTime>? breakfastMealDates;
  final List<Meal>? breakfastSelectedMeals;
  final double? breakfastAmount;
  final String? breakfastPlanType;
  final List<bool>? breakfastSelectedWeekdays;

  // Lunch specific data
  final DateTime? lunchStartDate;
  final DateTime? lunchEndDate;
  final List<DateTime>? lunchMealDates;
  final List<Meal>? lunchSelectedMeals;
  final double? lunchAmount;
  final String? lunchPlanType;
  final List<bool>? lunchSelectedWeekdays;

  final String? promoCode;
  final double? promoDiscount;

  // Add pre-order start and end dates
  final DateTime? preOrderStartDate;
  final DateTime? preOrderEndDate;

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
    this.selectedStudent,
    this.mealType,
    this.breakfastPreOrderDate,
    this.lunchPreOrderDate,
    this.isPreOrder = false,
    this.selectedPlanType,
    this.deliveryMode,
    // Add specific delivery modes for breakfast and lunch
    this.breakfastDeliveryMode,
    this.lunchDeliveryMode,
    // New parameters for specific breakfast and lunch data
    this.breakfastStartDate,
    this.breakfastEndDate,
    this.breakfastMealDates,
    this.breakfastSelectedMeals,
    this.breakfastAmount,
    this.breakfastPlanType,
    this.breakfastSelectedWeekdays,
    this.lunchStartDate,
    this.lunchEndDate,
    this.lunchMealDates,
    this.lunchSelectedMeals,
    this.lunchAmount,
    this.lunchPlanType,
    this.lunchSelectedWeekdays,
    this.promoCode,
    this.promoDiscount,
    // Add pre-order start and end dates
    this.preOrderStartDate,
    this.preOrderEndDate,
  }) : super(key: key);

  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  // Flag to track whether both meal types are selected
  bool _hasBothMealTypes = false;

  // Promo code related state
  final TextEditingController _promoController = TextEditingController();
  String? _appliedPromoCode;
  bool _isValidatingPromo = false;
  bool _isPromoValid = false;
  String _promoErrorMessage = '';
  double _promoDiscount = 0.0;
  final double _gstPercentage = 0.05; // 5% GST
  final double _deliveryCharges = 0.0; // Free delivery for now

  // Define valid promo codes
  final Map<String, double> _validPromoCodes = {
    "WELCOME10": 0.10, // 10% discount
    "SUMMER20": 0.20, // 20% discount
    "STARTWELL25": 0.25, // 25% discount
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    // Initialize promo code state if passed from a previous screen
    if (widget.promoCode != null && widget.promoDiscount != null) {
      _isPromoValid = true;
      _appliedPromoCode = widget.promoCode;
      _promoDiscount = widget.promoDiscount!;
    }

    // Determine if both meal types are selected
    _hasBothMealTypes = (widget.mealType == 'both') ||
        (widget.breakfastPreOrderDate != null &&
            widget.lunchPreOrderDate != null);

    _animationController.forward();
  }

  @override
  void dispose() {
    _promoController.dispose();
    _animationController.dispose();
    super.dispose();
  }

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
    for (int i = 0; i < widget.selectedWeekdays.length; i++) {
      if (widget.selectedWeekdays[i]) {
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
  void _navigateToPaymentMethods(BuildContext context, String planType) async {
    print("Navigating to payment screen for $planType...");
    log("endDate: \\${widget.endDate}");
    log("startDate: \\${widget.startDate}");

    // Create a default student if none is selected
    final student = widget.selectedStudent ??
        Student(
          id: 'default_\${DateTime.now().millisecondsSinceEpoch}',
          name: 'Guest Student',
          schoolName: 'Not Specified',
          className: 'Not Specified',
          division: 'Not Specified',
          floor: 'Not Specified',
          allergies: '',
          grade: 'Not Specified',
          section: 'Not Specified',
          profileImageUrl: '',
        );

    // Store order summary data in SharedPreferences for each plan
    final prefs = await SharedPreferences.getInstance();
    if (_hasBothMealTypes) {
      // Store breakfast
      if (widget.breakfastStartDate != null &&
          widget.breakfastEndDate != null) {
        await prefs.setString(
          'order_summary_${student.id}_breakfast-${student.id}',
          jsonEncode({
            'startDate': widget.breakfastStartDate!.toIso8601String(),
            'endDate': widget.breakfastEndDate!.toIso8601String(),
            'deliveryMode': widget.breakfastDeliveryMode ?? 'Mon to Fri',
          }),
        );
      }
      // Store lunch
      if (widget.lunchStartDate != null && widget.lunchEndDate != null) {
        await prefs.setString(
          'order_summary_${student.id}_lunch-${student.id}',
          jsonEncode({
            'startDate': widget.lunchStartDate!.toIso8601String(),
            'endDate': widget.lunchEndDate!.toIso8601String(),
            'deliveryMode': widget.lunchDeliveryMode ?? 'Mon to Fri',
          }),
        );
      }
    } else {
      // Single plan
      await prefs.setString(
        'order_summary_${student.id}_${planType}-${student.id}',
        jsonEncode({
          'startDate': widget.startDate.toIso8601String(),
          'endDate': widget.endDate.toIso8601String(),
          'deliveryMode': widget.deliveryMode ?? 'Mon to Fri',
        }),
      );
    }

    // Calculate final amount after promo discount, GST, and delivery charges
    double finalAmount = widget.totalAmount;
    if (_promoDiscount > 0) {
      finalAmount -= _promoDiscount;
    }

    finalAmount += finalAmount * _gstPercentage; // Add GST
    finalAmount += _deliveryCharges; // Add delivery charges

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentMethodScreen(
          planType: planType,
          isCustomPlan: widget.isCustomPlan,
          selectedWeekdays: widget.selectedWeekdays,
          startDate: widget.startDate,
          endDate: widget.endDate,
          mealDates: widget.mealDates,
          totalAmount: finalAmount, // Pass the calculated final amount
          selectedMeals: widget.selectedMeals,
          isExpressOrder: widget.isExpressOrder,
          selectedStudent: student,
          mealType: widget.mealType,
          breakfastPreOrderDate: widget.breakfastPreOrderDate,
          lunchPreOrderDate: widget.lunchPreOrderDate,
          isPreOrder: widget.isPreOrder,
          selectedPlanType: widget.selectedPlanType,
          deliveryMode: widget.deliveryMode,
          promoCode: _appliedPromoCode, // Pass the applied promo code
          promoDiscount: _promoDiscount, // Pass the promo discount amount
          // Pass specific delivery modes for breakfast and lunch
          breakfastDeliveryMode: widget.breakfastDeliveryMode,
          lunchDeliveryMode: widget.lunchDeliveryMode,
          // Pass pre-order start and end dates
          preOrderStartDate: widget.preOrderStartDate,
          preOrderEndDate: widget.preOrderEndDate,
          // Pass specific weekday selections for both meal types
          breakfastSelectedWeekdays: widget.breakfastSelectedWeekdays,
          lunchSelectedWeekdays: widget.lunchSelectedWeekdays,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasDiscount = widget.planType == 'Quarterly' ||
        widget.planType == 'Half-Yearly' ||
        widget.planType == 'Annual';

    return Scaffold(
      appBar: GradientAppBar(
        titleText: 'Order Summary',
      ),
      backgroundColor: AppTheme.offWhite,
      body: Column(
        children: [
          // Gradient top decoration
          Container(
            height: 4,
            decoration: const BoxDecoration(
              gradient: AppTheme.purpleToDeepPurple,
            ),
          ),
          // Main scrollable content
          Expanded(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: child,
                  ),
                );
              },
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order status banner - Matching InfoBanner style from Subscription Plan
                      InfoBanner(
                        title: widget.isExpressOrder
                            ? "Express Order"
                            : (_hasBothMealTypes
                                ? "Multiple Subscription Plans"
                                : "Subscription Order"),
                        message: widget.isExpressOrder
                            ? "Your express order is ready for processing."
                            : (_hasBothMealTypes
                                ? "Your breakfast and lunch subscription plans are ready for payment."
                                : "Your subscription plan is ready for payment."),
                        type: widget.isExpressOrder
                            ? InfoBannerType.success
                            : InfoBannerType.info,
                      ),

                      const SizedBox(height: 16),

                      // Header Text
                      // Container(
                      //   margin: const EdgeInsets.only(bottom: 4, left: 4),
                      //   child: Row(
                      //     children: [
                      //       Container(
                      //         height: 20,
                      //         width: 4,
                      //         decoration: BoxDecoration(
                      //           gradient: AppTheme.purpleToDeepPurple,
                      //           borderRadius: BorderRadius.circular(2),
                      //         ),
                      //       ),
                      //       const SizedBox(width: 8),
                      //       Text(
                      //         "Order Details",
                      //         style: GoogleFonts.poppins(
                      //           fontSize: 20,
                      //           fontWeight: FontWeight.w600,
                      //           color: AppTheme.textDark,
                      //         ),
                      //       ),
                      //     ],
                      //   ),
                      // ),

                      const SizedBox(height: 0),

                      // Student details card - HIDDEN
                      if (false && widget.selectedStudent != null) ...[
                        _buildStudentDetailsCard(),
                        const SizedBox(height: 16),
                      ],

                      // Subscription plan or Express delivery details
                      _buildPlanSection(),

                      //const SizedBox(height: 0),

                      // Meal Plan Section (if it still exists) - HIDDEN
                      if (false)
                        _buildCardSection(
                          title: 'Meal Plan',
                          icon: Icons.restaurant_menu_rounded,
                          children: [
                            _buildMealPlanSection(),
                          ],
                        ),

                      // Single Day Plan Info Banner (if applicable)
                      if (widget.planType == 'Single Day')
                        Column(
                          children: [
                            InfoBanner(
                              title: "Single Day Plan",
                              message:
                                  "This plan does not repeat. It is meant for one-time delivery on your selected date.",
                              type: InfoBannerType.info,
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),

                      // Student information section - HIDDEN
                      if (false) _buildStudentInfoSection(),

                      // Add a small spacing after hiding the Student Information section
                      const SizedBox(height: 0),

                      // Payment summary section
                      if (false) // Hide Payment Details section as it's moved to Payment Method screen
                        _buildCardSection(
                          title: 'Payment Details',
                          icon: Icons.receipt_long_rounded,
                          children: [
                            Container(
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
                                  _buildStudentInfoRow(
                                    icon: Icons.flatware_rounded,
                                    label: 'Meal Price',
                                    value:
                                        '₹${(widget.totalAmount / widget.mealDates.length).toStringAsFixed(0)} per meal',
                                  ),
                                  _buildStudentInfoRow(
                                    icon: Icons.list_alt_rounded,
                                    label: 'Number of Meals',
                                    value: '${widget.mealDates.length}',
                                  ),

                                  // Divider
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    child: Divider(
                                      color: Colors.grey.shade200,
                                      height: 1,
                                    ),
                                  ),

                                  if (hasDiscount)
                                    _buildStudentInfoRow(
                                      icon: Icons.shopping_cart_outlined,
                                      label: 'Subtotal',
                                      value:
                                          '₹${(widget.totalAmount * 1.25).toStringAsFixed(0)}',
                                      valueStyle: GoogleFonts.poppins(
                                        fontSize: 14,
                                        decoration: TextDecoration.lineThrough,
                                        color: AppTheme.textMedium,
                                      ),
                                    ),
                                  if (hasDiscount)
                                    _buildStudentInfoRow(
                                      icon: Icons.discount_rounded,
                                      label:
                                          'Discount (${(0.25 * 100).toInt()}%)',
                                      value:
                                          '-₹${((widget.totalAmount * 1.25) - widget.totalAmount).toStringAsFixed(0)}',
                                      valueStyle: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.success,
                                      ),
                                      isAlert: false,
                                      iconColor: AppTheme.success,
                                      backgroundColor:
                                          AppTheme.success.withOpacity(0.1),
                                    ),
                                  _buildStudentInfoRow(
                                    icon: Icons.currency_rupee,
                                    label: 'Total Amount',
                                    value:
                                        '₹${widget.totalAmount.toStringAsFixed(0)}',
                                    valueStyle: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      foreground: Paint()
                                        ..shader = LinearGradient(
                                          colors: [
                                            AppTheme.purple,
                                            AppTheme.deepPurple,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ).createShader(const Rect.fromLTWH(
                                            0.0, 0.0, 200.0, 70.0)),
                                    ),
                                    isLast: true,
                                    backgroundColor:
                                        AppTheme.purple.withOpacity(0.05),
                                    iconColor: AppTheme.purple,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 0),

                      // Promo Code Section - Added below order details
                      _buildPromoCodeSection(),

                      const SizedBox(height: 16),

                      // Payment button - REMOVED
                      // Hero(
                      //   tag: 'paymentButton',
                      //   child: Container(
                      //     margin: const EdgeInsets.symmetric(vertical: 24),
                      //     width: double.infinity,
                      //     height: 60,
                      //     decoration: BoxDecoration(
                      //       borderRadius: BorderRadius.circular(50),
                      //       gradient: AppTheme.purpleToDeepPurple,
                      //       boxShadow: [
                      //         BoxShadow(
                      //           color: AppTheme.deepPurple.withOpacity(0.25),
                      //           blurRadius: 15,
                      //           offset: const Offset(0, 6),
                      //           spreadRadius: 0,
                      //         ),
                      //       ],
                      //     ),
                      //     child: Material(
                      //       color: Colors.transparent,
                      //       child: InkWell(
                      //         borderRadius: BorderRadius.circular(18),
                      //         onTap: () {
                      //           // Button logic removed
                      //         },
                      //         child: Center(
                      //           child: Text(
                      //             'Continue to Payment',
                      //             style: GoogleFonts.poppins(
                      //               fontSize: 16,
                      //               fontWeight: FontWeight.w600,
                      //               color: Colors.white,
                      //             ),
                      //           ),
                      //         ),
                      //       ),
                      //     ),
                      //   ),
                      // ),

                      // Order Information Section - HIDDEN
                      if (false)
                        _buildSectionWithTitle(
                          context: context,
                          title: 'Order Information',
                          icon: Icons.restaurant_menu,
                          withoutPadding: false,
                          children: [
                            _buildOrderInformationRow(
                              'Plan Type',
                              widget.planType +
                                  (widget.isCustomPlan ? ' (Custom)' : ''),
                            ),
                            _buildOrderInformationRow(
                              'Meal Type',
                              widget.mealType?.capitalize() ?? 'Not Specified',
                            ),
                            _buildOrderInformationRow(
                              'Selected Days',
                              widget.isCustomPlan
                                  ? _getSelectedWeekdaysText()
                                  : 'Monday to Friday',
                            ),
                            _buildOrderInformationRow(
                              'Start Date',
                              DateFormat('dd MMM yyyy')
                                  .format(widget.startDate),
                            ),
                            _buildOrderInformationRow(
                              'End Date',
                              DateFormat('dd MMM yyyy').format(widget.endDate),
                            ),
                            _buildOrderInformationRow(
                              'Total Meals',
                              widget.mealDates.length.toString(),
                            ),

                            // Add Pre-order Information
                            if (widget.isPreOrder) ...[
                              const SizedBox(height: 8),
                              const Divider(),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Text(
                                  'Pre-order Information',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                              ),
                              if (widget.breakfastPreOrderDate != null)
                                _buildOrderInformationRow(
                                  'Breakfast Pre-order Start',
                                  DateFormat('dd MMM yyyy')
                                      .format(widget.breakfastPreOrderDate!),
                                ),
                              if (widget.lunchPreOrderDate != null)
                                _buildOrderInformationRow(
                                  'Lunch Pre-order Start',
                                  DateFormat('dd MMM yyyy')
                                      .format(widget.lunchPreOrderDate!),
                                ),
                            ],
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Fixed bottom button
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Hero(
              tag: 'paymentButton',
              child: Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  gradient: AppTheme.purpleToDeepPurple,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.deepPurple.withOpacity(0.25),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(50),
                    onTap: () {
                      // Determine the meal plan type from the mealType parameter or from the selected meals
                      final String planType;
                      if (widget.mealType != null) {
                        planType = widget.mealType!;
                      } else if (widget.selectedMeals.isNotEmpty) {
                        if (widget.selectedMeals.first.categories.first ==
                            MealCategory.breakfast) {
                          planType = 'breakfast';
                        } else if (widget
                                .selectedMeals.first.categories.first ==
                            MealCategory.expressOneDay) {
                          planType = 'express';
                        } else {
                          planType = 'lunch';
                        }
                      } else {
                        planType =
                            'lunch'; // Default to lunch if no info available
                      }

                      // If there's no student selected, just navigate to payment (skip validation)
                      if (widget.selectedStudent == null) {
                        _navigateToPaymentMethods(context, planType);
                        return;
                      }

                      // Validate the meal plan before proceeding
                      final String? validationError =
                          MealPlanValidator.validateMealPlan(
                              widget.selectedStudent!, planType);

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
                    child: Center(
                      child: Text(
                        'Continue to Payment',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Method to build student details card
  Widget _buildStudentDetailsCard() {
    // Get the student
    final student = widget.selectedStudent!;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section title with icon
            Row(
              children: [
                const Icon(
                  Icons.person,
                  size: 20,
                  color: AppTheme.purple,
                ),
                const SizedBox(width: 8),
                Text(
                  "Student Information",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Student Name
            _buildDetailRow(
              "Name",
              student.name,
              Icons.person_outline,
            ),

            // School
            _buildDetailRow(
              "School",
              student.schoolName,
              Icons.school_outlined,
            ),

            // Class and Division
            _buildDetailRow(
              "Class",
              "${student.className} - ${student.division}",
              Icons.class_outlined,
            ),

            // Floor
            _buildDetailRow(
              "Floor",
              student.floor,
              Icons.apartment_outlined,
            ),

            // Allergies (if any)
            if (student.allergies.isNotEmpty)
              _buildDetailRow(
                "Allergies",
                student.allergies,
                Icons.healing_outlined,
                color: Colors.orange,
              ),
          ],
        ),
      ),
    );
  }

  // Build the plan section - first try combined breakast/lunch display if both are present
  Widget _buildPlanSection() {
    // If we have both breakfast and lunch data, create a combined view
    if (widget.breakfastStartDate != null && widget.lunchStartDate != null) {
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section title with icon
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: AppTheme.purple,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Subscription Plan",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              // Student Badge below title
              if (widget.selectedStudent != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: AppTheme.purpleToDeepPurple,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.deepPurple.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.selectedStudent!.name,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
              Divider(height: 24, color: Colors.grey.withOpacity(0.2)),

              // Breakfast Plan
              _buildMealPlanDetailsSection(
                title: "Breakfast Plan",
                isPreOrder: widget.isPreOrder,
                preOrderDate: widget.breakfastPreOrderDate,
                icon: Icons.breakfast_dining_outlined,
                iconColor: Colors.amber,
                specificStartDate: widget.breakfastStartDate,
                specificEndDate: widget.breakfastEndDate,
                specificMealDates: widget.breakfastMealDates,
                specificAmount: widget.breakfastAmount,
                specificPlanType: widget.breakfastPlanType,
                specificDeliveryMode: widget.breakfastDeliveryMode,
                specificSelectedWeekdays: widget.breakfastSelectedWeekdays,
                hideMealTitle: true,
              ),

              const SizedBox(height: 24),
              Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
              const SizedBox(height: 24),

              // Lunch Plan
              _buildMealPlanDetailsSection(
                title: "Lunch Plan",
                isPreOrder: widget.isPreOrder,
                preOrderDate: widget.lunchPreOrderDate,
                icon: Icons.lunch_dining_outlined,
                iconColor: AppTheme.purple,
                specificStartDate: widget.lunchStartDate,
                specificEndDate: widget.lunchEndDate,
                specificMealDates: widget.lunchMealDates,
                specificAmount: widget.lunchAmount,
                specificPlanType: widget.lunchPlanType,
                specificDeliveryMode: widget.lunchDeliveryMode,
                specificSelectedWeekdays: widget.lunchSelectedWeekdays,
                hideMealTitle: true,
              ),

              // Total combined price
              Container(
                margin: const EdgeInsets.only(top: 24),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.purple.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.purple.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total Price",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    Text(
                      "₹${widget.totalAmount.toStringAsFixed(0)}",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        foreground: Paint()
                          ..shader = LinearGradient(
                            colors: [
                              AppTheme.purple,
                              AppTheme.deepPurple,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(
                              const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Original single plan display
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section title with icon
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: AppTheme.purple,
                  ),
                  const SizedBox(width: 8, height: 26),
                  Text(
                    widget.isExpressOrder
                        ? "Express Delivery"
                        : "Subscription Plan",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
              // Student Badge below title
              if (widget.selectedStudent != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: AppTheme.purpleToDeepPurple,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.deepPurple.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.selectedStudent!.name,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Divider(height: 32, color: Colors.grey.withOpacity(0.2)),

              // Get meal name
              _buildDetailRow(
                "Selected Meal",
                widget.selectedMeals.isNotEmpty
                    ? widget.selectedMeals.first.name
                    : widget.mealType == 'breakfast'
                        ? "Breakfast of the Day"
                        : "Lunch of the Day",
                Icons.restaurant_menu_outlined,
              ),

              // Delivery Mode (if custom plan)
              if (widget.isCustomPlan)
                _buildDetailRow(
                  "Delivery Mode",
                  widget.mealType == 'breakfast'
                      ? (widget.breakfastDeliveryMode ??
                          _getSelectedWeekdaysText())
                      : widget.mealType == 'lunch'
                          ? (widget.lunchDeliveryMode ??
                              _getSelectedWeekdaysText())
                          : _getSelectedWeekdaysText(),
                  Icons.calendar_view_week_outlined,
                ),

              // Start and End Dates side by side
              if (!widget.isPreOrder ||
                  (widget.isPreOrder && widget.preOrderStartDate == null))
                Padding(
                  padding: EdgeInsets.only(
                    bottom: 12,
                    left: 8,
                  ),
                  child: Row(
                    children: [
                      // Start Date
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.date_range_outlined,
                              size: 18,
                              color: AppTheme.purple.withOpacity(0.7),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Start Date",
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: AppTheme.textMedium,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('d MMM yyyy')
                                        .format(widget.startDate),
                                    style: GoogleFonts.poppins(
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
                      ),

                      const SizedBox(width: 12),

                      // End Date
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.event_outlined,
                              size: 18,
                              color: AppTheme.purple.withOpacity(0.7),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "End Date",
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: AppTheme.textMedium,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('d MMM yyyy')
                                        .format(widget.endDate),
                                    style: GoogleFonts.poppins(
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
                      ),
                    ],
                  ),
                ),

              // Pre-order start and end dates (if applicable)
              if (widget.isPreOrder && widget.preOrderStartDate != null)
                _buildDetailRow(
                  "Pre-order Start Date",
                  DateFormat('d MMMM yyyy').format(widget.preOrderStartDate!),
                  Icons.event_available_outlined,
                  color: AppTheme.purple,
                ),

              if (widget.isPreOrder && widget.preOrderEndDate != null)
                _buildDetailRow(
                  "Pre-order End Date",
                  DateFormat('d MMMM yyyy').format(widget.preOrderEndDate!),
                  Icons.event_available_outlined,
                  color: AppTheme.purple,
                ),

              // Pre-order date (if applicable)
              if (widget.isPreOrder &&
                  widget.breakfastPreOrderDate != null &&
                  widget.preOrderStartDate == null)
                _buildDetailRow(
                  "Start Pre-order Date",
                  DateFormat('d MMMM yyyy')
                      .format(widget.breakfastPreOrderDate!),
                  Icons.breakfast_dining_outlined,
                  color: Colors.amber,
                ),

              if (widget.isPreOrder &&
                  widget.lunchPreOrderDate != null &&
                  widget.preOrderStartDate == null)
                _buildDetailRow(
                  "Start Pre-order Date",
                  DateFormat('d MMMM yyyy').format(widget.lunchPreOrderDate!),
                  Icons.lunch_dining_outlined,
                  color: AppTheme.purple,
                ),

              // Total price
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.purple.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.purple.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total Price",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    Text(
                      "₹${widget.totalAmount.toStringAsFixed(0)}",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        foreground: Paint()
                          ..shader = LinearGradient(
                            colors: [
                              AppTheme.purple,
                              AppTheme.deepPurple,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(
                              const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  // Helper method to build individual meal plan sections
  Widget _buildMealPlanDetailsSection({
    required String title,
    required bool isPreOrder,
    required DateTime? preOrderDate,
    required IconData icon,
    required Color iconColor,
    DateTime? specificStartDate,
    DateTime? specificEndDate,
    List<DateTime>? specificMealDates,
    double? specificAmount,
    String? specificPlanType,
    String? specificDeliveryMode,
    List<bool>? specificSelectedWeekdays,
    bool hideMealTitle = false,
  }) {
    // Use specific dates if provided, otherwise use generic ones
    final startDate = specificStartDate ?? widget.startDate;
    final endDate = specificEndDate ?? widget.endDate;
    final mealDates = specificMealDates?.length ?? widget.mealDates.length;
    final totalAmount = specificAmount ?? widget.totalAmount;
    final planType =
        specificPlanType ?? widget.selectedPlanType ?? widget.planType;

    // Get meal name and determine which meal selection to use
    final String mealName;
    final mealType = title == "Breakfast Plan" ? 'breakfast' : 'lunch';
    if (title == "Breakfast Plan" &&
        widget.breakfastSelectedMeals != null &&
        widget.breakfastSelectedMeals!.isNotEmpty) {
      mealName = normalizeMealName(
          widget.breakfastSelectedMeals!.first.name, mealType);
    } else if (title == "Lunch Plan" &&
        widget.lunchSelectedMeals != null &&
        widget.lunchSelectedMeals!.isNotEmpty) {
      mealName =
          normalizeMealName(widget.lunchSelectedMeals!.first.name, mealType);
    } else if (widget.selectedMeals.isNotEmpty) {
      mealName = normalizeMealName(widget.selectedMeals.first.name, mealType);
    } else {
      mealName = mealType == 'breakfast'
          ? MealNames.breakfastOfTheDay
          : MealNames.lunchOfTheDay;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        if (!hideMealTitle)
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: iconColor,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
        const SizedBox(height: 12),

        // Strict meal image for this plan
        Row(
          children: [
            Image.asset(
              getMealImageAsset(mealName, mealType),
              width: 48,
              height: 48,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hideMealTitle
                        ? (title == "Breakfast Plan" ? "Breakfast" : "Lunch")
                        : "Selected Meal",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textDark,
                    ),
                  ),
                  Text(
                    mealName,
                    style: GoogleFonts.poppins(
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
        const SizedBox(height: 12),

        // Delivery Mode (if custom plan)
        if (widget.isCustomPlan)
          _buildDetailRow(
            "Delivery Mode",
            // Always use the specific delivery mode passed to this section,
            // only fall back to calculating from weekdays if needed
            specificDeliveryMode ??
                _getDeliveryModeForWeekdays(specificSelectedWeekdays),
            Icons.calendar_view_week_outlined,
            indent: true,
          ),

        // Start and End Dates side by side
        if (!isPreOrder || (isPreOrder && widget.preOrderStartDate == null))
          Padding(
            padding: EdgeInsets.only(
              bottom: 12,
              left: 8,
            ),
            child: Row(
              children: [
                // Start Date
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.date_range_outlined,
                        size: 18,
                        color: Colors.purple,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Start Date",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppTheme.textMedium,
                              ),
                            ),
                            Text(
                              DateFormat('d MMM yyyy').format(startDate),
                              style: GoogleFonts.poppins(
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
                ),

                const SizedBox(width: 12),

                // End Date
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.event_outlined,
                        size: 18,
                        color: Colors.purple,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "End Date",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppTheme.textMedium,
                              ),
                            ),
                            Text(
                              DateFormat('d MMM yyyy').format(endDate),
                              style: GoogleFonts.poppins(
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
                ),
              ],
            ),
          ),

        // Pre-order start and end dates (if applicable)
        if (isPreOrder && widget.preOrderStartDate != null)
          _buildDetailRow(
            "Pre-order Start Date",
            DateFormat('d MMMM yyyy').format(widget.preOrderStartDate!),
            Icons.event_available_outlined,
            indent: true,
            color: iconColor,
          ),

        if (isPreOrder && widget.preOrderEndDate != null)
          _buildDetailRow(
            "Pre-order End Date",
            DateFormat('d MMMM yyyy').format(widget.preOrderEndDate!),
            Icons.event_available_outlined,
            indent: true,
            color: iconColor,
          ),

        // Amount (if provided)
        if (specificAmount != null)
          _buildDetailRow(
            "Amount",
            "₹${specificAmount.toStringAsFixed(0)}",
            Icons.currency_rupee,
            indent: true,
            color: AppTheme.purple,
          ),

        // Pre-order date (if applicable)
        if (isPreOrder &&
            preOrderDate != null &&
            widget.preOrderStartDate == null)
          _buildDetailRow(
            "Start Pre-order Date",
            DateFormat('d MMMM yyyy').format(preOrderDate),
            Icons.event_available_outlined,
            indent: true,
            color: iconColor,
          ),
      ],
    );
  }

  // Helper method to get delivery mode text for specific weekdays
  String _getDeliveryModeForWeekdays(List<bool>? selectedWeekdays) {
    if (selectedWeekdays == null) {
      return _getSelectedWeekdaysText();
    }

    return PreOrderDateCalculator.getDeliveryModeText(selectedWeekdays);
  }

  // Helper method to build detail rows with optional indentation
  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    Color color = AppTheme.purple,
    bool indent = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 12,
        left: indent ? 8 : 0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: Colors.purple,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppTheme.textMedium,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
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

  Color _getMealTypeColor(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return Colors.pink;
      case 'express':
        return Colors.orange;
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
        return 'Healthy breakfast options delivered to your child at school.';
      case 'express':
        return 'Same-day lunch delivery with express service (additional fee applies).';
      case 'lunch':
      default:
        return 'Nutritious lunch delivered to your child during school lunch hours.';
    }
  }

  Widget _buildMealPlanTab(
      String title, bool isSelected, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 12,
        ),
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
                color: isSelected ? color : AppTheme.textMedium,
              ),
              const SizedBox(width: 8),
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

  // Apply promo code
  void _applyPromoCode() {
    final promoCode = _promoController.text.trim().toUpperCase();
    if (promoCode.isEmpty) {
      setState(() {
        _promoErrorMessage = 'Please enter a promo code';
        _isPromoValid = false;
      });
      return;
    }

    setState(() {
      _isValidatingPromo = true;
      _promoErrorMessage = '';
    });

    // Process promo code validation
    Future.delayed(const Duration(milliseconds: 800), () {
      if (_validPromoCodes.containsKey(promoCode)) {
        setState(() {
          _isPromoValid = true;
          _appliedPromoCode = promoCode;
          _promoDiscount = widget.totalAmount * _validPromoCodes[promoCode]!;
          _isValidatingPromo = false;
          _promoErrorMessage = '';
        });
      } else {
        setState(() {
          _isPromoValid = false;
          _promoErrorMessage = 'Invalid promo code';
          _isValidatingPromo = false;
          _appliedPromoCode = null;
          _promoDiscount = 0.0;
        });
      }
    });
  }

  // Remove applied promo code
  void _removePromoCode() {
    setState(() {
      _isPromoValid = false;
      _appliedPromoCode = null;
      _promoDiscount = 0.0;
      _promoController.clear();
      _promoErrorMessage = '';
    });
  }

  // Calculate GST amount
  double get _gstAmount {
    double amountAfterDiscount = widget.totalAmount - _promoDiscount;
    return amountAfterDiscount * _gstPercentage;
  }

  // Calculate final amount after promo code discount, GST, and delivery charges
  double get _finalAmount {
    double amountAfterDiscount = widget.totalAmount - _promoDiscount;
    return amountAfterDiscount + _gstAmount + _deliveryCharges;
  }

  // Build promo code section
  Widget _buildPromoCodeSection() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section title with icon
            Row(
              children: [
                const Icon(
                  Icons.discount_outlined,
                  size: 20,
                  color: AppTheme.purple,
                ),
                const SizedBox(width: 8),
                Text(
                  "Promo Code",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
            Divider(height: 24, color: Colors.grey.withOpacity(0.2)),

            // Promo code input field with container styling
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
                                    _promoErrorMessage = '';
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
                        if (_promoErrorMessage.isNotEmpty) {
                          setState(() {
                            _promoErrorMessage = '';
                          });
                        }
                      },
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppTheme.purpleToDeepPurple,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: ElevatedButton(
                    onPressed: _isValidatingPromo ? null : _applyPromoCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 14),
                      elevation: 0,
                    ),
                    child: _isValidatingPromo
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            "Apply",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Applied promo code section
            if (_isPromoValid && _appliedPromoCode != null) ...[
              Container(
                height: 65,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Promo applied: $_appliedPromoCode",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            "You saved ₹${_promoDiscount.toStringAsFixed(0)}",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _removePromoCode,
                      icon: const Icon(Icons.close, size: 18),
                      color: Colors.grey.shade700,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ],

            if (_promoErrorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 14,
                      color: Colors.red.shade700,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _promoErrorMessage,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Price summary
            Container(
              padding: const EdgeInsets.all(12),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Subtotal",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Text(
                        "₹${widget.totalAmount.toStringAsFixed(0)}",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),

                  if (_promoDiscount > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              "Promo Discount ",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              "($_appliedPromoCode)",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.green,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "-₹${_promoDiscount.toStringAsFixed(0)}",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 8),

                  // GST
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "GST (5%)",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textMedium,
                        ),
                      ),
                      Text(
                        "+₹${_gstAmount.toStringAsFixed(0)}",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textMedium,
                        ),
                      ),
                    ],
                  ),

                  // Delivery Charges
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Delivery Charges",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textMedium,
                        ),
                      ),
                      Text(
                        _deliveryCharges > 0
                            ? "+₹${_deliveryCharges.toStringAsFixed(0)}"
                            : "FREE",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _deliveryCharges > 0
                              ? AppTheme.textMedium
                              : Colors.green,
                        ),
                      ),
                    ],
                  ),

                  // const Divider(height: 16),
                  Divider(height: 24, color: Colors.grey.withOpacity(0.2)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Payable Amount",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Text(
                        "₹${_finalAmount.toStringAsFixed(0)}",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          foreground: Paint()
                            ..shader = LinearGradient(
                              colors: [
                                AppTheme.purple,
                                AppTheme.deepPurple,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(
                                const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
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

  // Build section with title
  Widget _buildSectionWithTitle({
    required BuildContext context,
    required String title,
    required IconData icon,
    required bool withoutPadding,
    required List<Widget> children,
  }) {
    return _buildCardSection(
      title: title,
      icon: icon,
      children: children,
    );
  }

  // Build order information row
  Widget _buildOrderInformationRow(String label, String value) {
    return _buildStudentInfoRow(
      icon: Icons.info_outline_rounded,
      label: label,
      value: value,
    );
  }

  // Build student info row with icon
  Widget _buildStudentInfoRow({
    required IconData icon,
    required String label,
    required String value,
    TextStyle? valueStyle,
    bool isAlert = false,
    bool isLast = false,
    Color? iconColor,
    Color? backgroundColor,
  }) {
    final iconColorValue =
        iconColor ?? (isAlert ? Colors.red.shade700 : AppTheme.purple);
    final backgroundColorValue = backgroundColor ??
        (isAlert ? Colors.red.shade50 : AppTheme.purple.withOpacity(0.08));

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

  // Build enhanced meal card - Matching row style from Subscription Plan
  Widget _buildEnhancedMealCard(Meal meal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.15),
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meal image with radio-button style circle when selected
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.deepPurple.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 90,
                    width: 90,
                    decoration: BoxDecoration(
                      color: Colors.white,
                    ),
                    child: meal.imageUrl.isNotEmpty
                        ? Image.asset(
                            meal.imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildMealPlaceholder();
                            },
                          )
                        : _buildMealPlaceholder(),
                  ),
                ),
              ),
              // Selected indicator circle in upper left
            ],
          ),

          const SizedBox(width: 12),

          // Meal details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Meal name with veg icon
                Row(
                  children: [
                    const VegIcon(),
                    const SizedBox(width: 6),
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
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Colors.green, Colors.green.withOpacity(1)],
                            begin: Alignment.topLeft,
                            end: Alignment.centerRight,
                          ),
                          // boxShadow: [
                          //   BoxShadow(
                          //     color: AppTheme.purple.withOpacity(0.3),
                          //     blurRadius: 4,
                          //     offset: const Offset(0, 1),
                          //   ),
                          // ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Meal type
                Row(
                  children: [
                    Icon(
                      Icons.restaurant,
                      size: 14,
                      color: AppTheme.purple,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${meal.categories.first.toString().split('.').last} Meal',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppTheme.textMedium,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Price tag - Matching subscription plan tag style
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: AppTheme.purpleToDeepPurple,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.deepPurple.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '₹${meal.price.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build meal placeholder
  Widget _buildMealPlaceholder() {
    return Container(
      height: 70,
      width: 70,
      color: Colors.grey[100],
      child: Icon(
        Icons.restaurant_rounded,
        size: 24,
        color: AppTheme.purple.withOpacity(0.7),
      ),
    );
  }

  // Meal Plan implementation - added from PaymentMethodScreen
  Widget _buildSelectedMealCard(String name, String imageUrl, String mealType) {
    // Determine if we should show express fee
    final bool isExpress = mealType == 'express';
    final double mealPrice = widget.totalAmount / widget.mealDates.length;
    final Color typeColor = _getMealTypeColor(mealType);

    // Use strict asset mapping for meal image
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
          // Strict meal image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.asset(
              getMealImageAsset(name, mealType),
              width: double.infinity,
              height: 160,
              fit: BoxFit.contain,
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
                          mealType == 'lunch'
                              ? Icons.flatware
                              : Icons.ramen_dining,
                          size: 18,
                          color: mealType == 'lunch'
                              ? AppTheme.success
                              : Colors.pink,
                        ),
                        const SizedBox(width: 8),
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
                          color: AppTheme.purple,
                        ),
                      ),
                    ),
                  ],
                ),
                if (isExpress) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time_filled_rounded,
                          size: 16,
                          color: Colors.orange.shade800,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Express delivery includes priority handling for same-day orders',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.orange.shade800,
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

  // Update the student info section to handle null student
  Widget _buildStudentInfoSection() {
    if (widget.selectedStudent == null) {
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
            _buildStudentInfoRow(
              icon: Icons.info_outline_rounded,
              label: 'Student Profile',
              value: 'No student profile selected',
              isAlert: true,
            ),
          ],
        ),
      );
    }

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
          _buildStudentInfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Student Name',
            value: widget.selectedStudent!.name,
          ),
          _buildStudentInfoRow(
            icon: Icons.school_rounded,
            label: 'Class',
            value: widget.selectedStudent!.className,
          ),
          _buildStudentInfoRow(
            icon: Icons.book_rounded,
            label: 'Section',
            value: widget.selectedStudent!.section,
          ),
          _buildStudentInfoRow(
            icon: Icons.domain_rounded,
            label: 'Floor',
            value: widget.selectedStudent!.floor,
          ),
          if (widget.selectedStudent!.allergies.isNotEmpty)
            _buildStudentInfoRow(
              icon: Icons.healing_rounded,
              label: 'Allergies',
              value: widget.selectedStudent!.allergies,
              isAlert: true,
            ),
        ],
      ),
    );
  }

  // Build card section with title
  Widget _buildCardSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section title with icon
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: AppTheme.purple,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
            Divider(height: 24, color: Colors.grey.withOpacity(0.2)),
            ...children,
          ],
        ),
      ),
    );
  }

  // Build normal meal plan section - this is for the _buildMealPlanSection() referenced on line 366
  Widget _buildMealPlanSection() {
    // Determine meal type - breakfast, lunch or express
    final String mealType = widget.mealType ??
        (widget.selectedMeals.isNotEmpty &&
                widget.selectedMeals.first.categories
                    .contains(MealCategory.breakfast)
            ? 'breakfast'
            : widget.isExpressOrder
                ? 'express'
                : 'lunch');

    final String mealName = widget.selectedMeals.isNotEmpty
        ? normalizeMealName(widget.selectedMeals.first.name, mealType)
        : (mealType == 'breakfast'
            ? MealNames.breakfastOfTheDay
            : mealType == 'express'
                ? MealNames.lunchOfTheDay
                : MealNames.lunchOfTheDay);
    return _buildSelectedMealCard(
      mealName,
      widget.selectedMeals.isNotEmpty &&
              widget.selectedMeals.first.imageUrl.isNotEmpty
          ? widget.selectedMeals.first.imageUrl
          : mealType == 'breakfast'
              ? 'assets/images/breakfast/breakfast of the day (most recommended).png'
              : 'assets/images/lunch/lunch of the day (most recommended).png',
      mealType,
    );
  }

  // Helper to strictly map meal names to allowed asset images
  String getMealImageAsset(String mealName, String mealType) {
    final name = mealName.trim().toLowerCase();
    if (mealType == 'breakfast') {
      if (name == 'breakfast of the day')
        return 'assets/images/breakfast/breakfast of the day (most recommended).png';
      if (name == 'indian breakfast')
        return 'assets/images/breakfast/Indian Breakfast.png';
      if (name == 'international breakfast')
        return 'assets/images/breakfast/International Breakfast.png';
      if (name == 'jain breakfast')
        return 'assets/images/breakfast/Jain Breakfast.png';
    } else if (mealType == 'lunch') {
      if (name == 'lunch of the day')
        return 'assets/images/lunch/lunch of the day (most recommended).png';
      if (name == 'indian lunch') return 'assets/images/lunch/Indian Lunch.png';
      if (name == 'international lunch')
        return 'assets/images/lunch/International Lunch.png';
      if (name == 'jain lunch') return 'assets/images/lunch/Jain Lunch.png';
    }
    // fallback
    return mealType == 'breakfast'
        ? 'assets/images/breakfast/breakfast of the day (most recommended).png'
        : 'assets/images/lunch/lunch of the day (most recommended).png';
  }
}
