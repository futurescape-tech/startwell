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

  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

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

    _animationController.forward();
  }

  @override
  void dispose() {
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
  void _navigateToPaymentMethods(BuildContext context, String planType) {
    print("Navigating to payment screen for $planType...");
    log("endDate: ${widget.endDate}");
    log("startDate: ${widget.startDate}");

    // Use the existing payment simulation logic inside a new PaymentMethodScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentMethodScreen(
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
                            : "Subscription Order",
                        message: widget.isExpressOrder
                            ? "Your express order is ready for processing."
                            : "Your subscription plan is ready for payment.",
                        type: widget.isExpressOrder
                            ? InfoBannerType.success
                            : InfoBannerType.info,
                      ),

                      const SizedBox(height: 16),

                      // Header Text
                      Container(
                        margin: const EdgeInsets.only(bottom: 4, left: 4),
                        child: Row(
                          children: [
                            Container(
                              height: 20,
                              width: 4,
                              decoration: BoxDecoration(
                                gradient: AppTheme.purpleToDeepPurple,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Order Details",
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Plan details section
                      _buildCardSection(
                        title: 'Plan Details',
                        icon: Icons.calendar_today_rounded,
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
                                  icon: Icons.card_membership_rounded,
                                  label: 'Plan Type',
                                  value:
                                      '${widget.planType} ${widget.isCustomPlan ? "(Custom)" : "(Regular)"}',
                                ),
                                _buildStudentInfoRow(
                                  icon: Icons.timelapse_rounded,
                                  label: 'Duration',
                                  value: widget.planType == 'Single Day'
                                      ? '1 Day'
                                      : '${widget.planType} Subscription',
                                ),
                                if (widget.isCustomPlan)
                                  _buildStudentInfoRow(
                                    icon: Icons.view_week_rounded,
                                    label: 'Selected Days',
                                    value: _getSelectedWeekdaysText(),
                                  ),
                                _buildStudentInfoRow(
                                  icon: Icons.restaurant_rounded,
                                  label: 'Total Meals',
                                  value: '${widget.mealDates.length} meals',
                                ),
                                _buildStudentInfoRow(
                                  icon: Icons.play_circle_outline_rounded,
                                  label: 'Start Date',
                                  value: DateFormat('MMM d, yyyy')
                                      .format(widget.startDate),
                                ),
                                _buildStudentInfoRow(
                                  icon: Icons.event_available_rounded,
                                  label: 'End Date',
                                  value: DateFormat('MMM d, yyyy')
                                      .format(widget.endDate),
                                  isLast: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Selected meals section
                      _buildCardSection(
                        title: 'Selected Meal',
                        icon: Icons.restaurant_menu_rounded,
                        withoutPadding: true,
                        children: [
                          for (var meal in widget.selectedMeals)
                            _buildEnhancedMealCard(meal),
                        ],
                      ),

                      const SizedBox(height: 16),

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

                      // Student information section
                      _buildCardSection(
                        title: 'Student Information',
                        icon: Icons.person_rounded,
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
                                  icon: Icons.person_outline_rounded,
                                  label: 'Student Name',
                                  value: widget.selectedStudent.name,
                                ),
                                _buildStudentInfoRow(
                                  icon: Icons.school_rounded,
                                  label: 'Class',
                                  value: widget.selectedStudent.className,
                                ),
                                _buildStudentInfoRow(
                                  icon: Icons.book_rounded,
                                  label: 'Section',
                                  value: widget.selectedStudent.section,
                                ),
                                _buildStudentInfoRow(
                                  icon: Icons.domain_rounded,
                                  label: 'Floor',
                                  value: widget.selectedStudent.floor,
                                ),
                                if (widget.selectedStudent.allergies.isNotEmpty)
                                  _buildStudentInfoRow(
                                    icon: Icons.medical_services_rounded,
                                    label: 'Medical Allergies',
                                    value: widget.selectedStudent.allergies,
                                    valueStyle: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.red[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                    isAlert: true,
                                  ),
                                _buildStudentInfoRow(
                                  icon: Icons.location_on_rounded,
                                  label: 'School Address',
                                  value: widget.selectedStudent.schoolAddress,
                                  isLast: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Payment summary section
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
                                  icon: Icons.lunch_dining_rounded,
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
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
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
                                  icon: Icons.payments_rounded,
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

                      const SizedBox(height: 32),

                      // Payment button - Exact match with enhanced Subscription Plan page
                      Hero(
                        tag: 'paymentButton',
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 24),
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
                              borderRadius: BorderRadius.circular(18),
                              onTap: () {
                                // Determine the meal plan type from the mealType parameter or from the selected meals
                                final String planType = widget.mealType ??
                                    (widget.selectedMeals.first.categories
                                                .first ==
                                            MealCategory.breakfast
                                        ? 'breakfast'
                                        : widget.selectedMeals.first.categories
                                                    .first ==
                                                MealCategory.expressOneDay
                                            ? 'express'
                                            : 'lunch');

                                // Validate the meal plan before proceeding
                                final String? validationError =
                                    MealPlanValidator.validateMealPlan(
                                        widget.selectedStudent, planType);

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
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.payment_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Proceed to Payment',
                                      style: GoogleFonts.poppins(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build card section with title and icon - Exact match with Subscription Plan style
  Widget _buildCardSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    bool withoutPadding = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepPurple.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 5),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            // gradient: LinearGradient(
            //   begin: Alignment.topLeft,
            //   end: Alignment.bottomRight,
            //   colors: [
            //     Colors.white,
            //     AppTheme.purple.withOpacity(0.03),
            //   ],
            // ),
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
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.purple.withOpacity(0.8),
                            AppTheme.deepPurple.withOpacity(0.9),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
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
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              withoutPadding
                  ? Column(children: children)
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: children,
                      ),
                    ),
            ],
          ),
        ),
      ),
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
                            end: Alignment.bottomRight,
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
}
