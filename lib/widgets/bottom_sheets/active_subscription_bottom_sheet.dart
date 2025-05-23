import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:startwell/models/student_model.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:startwell/utils/pre_order_date_calculator.dart';

class ActiveSubscriptionBottomSheet extends StatefulWidget {
  final Student student;
  final Function(DateTime? breakfastPreorderDate, DateTime? lunchPreorderDate,
      String? breakfastDeliveryMode, String? lunchDeliveryMode) onContinue;
  final bool showBreakfastPreorder;
  final bool showLunchPreorder;
  // Additional parameters for new plan settings
  final String? breakfastPlanType;
  final String? lunchPlanType;
  final List<bool>? breakfastSelectedWeekdays;
  final List<bool>? lunchSelectedWeekdays;

  const ActiveSubscriptionBottomSheet({
    Key? key,
    required this.student,
    required this.onContinue,
    this.showBreakfastPreorder = true,
    this.showLunchPreorder = true,
    this.breakfastPlanType,
    this.lunchPlanType,
    this.breakfastSelectedWeekdays,
    this.lunchSelectedWeekdays,
  }) : super(key: key);

  @override
  State<ActiveSubscriptionBottomSheet> createState() =>
      _ActiveSubscriptionBottomSheetState();
}

class _ActiveSubscriptionBottomSheetState
    extends State<ActiveSubscriptionBottomSheet> {
  DateTime? _selectedBreakfastDate;
  DateTime? _selectedLunchDate;

  DateTime? _breakfastStartDate;
  DateTime? _breakfastEndDate;
  DateTime? _lunchStartDate;
  DateTime? _lunchEndDate;

  // Store delivery modes
  String? _breakfastDeliveryMode;
  String? _lunchDeliveryMode;

  // Store the weekday selections to ensure they remain separate
  List<bool>? _breakfastSelectedWeekdays;
  List<bool>? _lunchSelectedWeekdays;

  // Flags to determine which scenario we're in
  bool _needsBreakfastPreorder = false;
  bool _needsLunchPreorder = false;

  @override
  void initState() {
    super.initState();

    // Create completely independent arrays for breakfast and lunch weekdays
    // Deep copy the breakfast weekdays (never share the same array between meal types)
    _breakfastSelectedWeekdays = List<bool>.filled(5, false);
    _lunchSelectedWeekdays = List<bool>.filled(5, false);

    // Copy values from widget parameters to ensure they're completely separate objects
    if (widget.breakfastSelectedWeekdays != null) {
      for (int i = 0;
          i < widget.breakfastSelectedWeekdays!.length && i < 5;
          i++) {
        _breakfastSelectedWeekdays![i] = widget.breakfastSelectedWeekdays![i];
      }
      print(
          'DEBUG: Copied breakfast weekdays: $_breakfastSelectedWeekdays from ${widget.breakfastSelectedWeekdays}');
    } else {
      // Default to Mon-Fri for breakfast
      for (int i = 0; i < 5; i++) {
        _breakfastSelectedWeekdays![i] = true;
      }
      print('DEBUG: Using default Mon-Fri for breakfast');
    }

    // Completely separate copy for lunch weekdays
    if (widget.lunchSelectedWeekdays != null) {
      for (int i = 0; i < widget.lunchSelectedWeekdays!.length && i < 5; i++) {
        _lunchSelectedWeekdays![i] = widget.lunchSelectedWeekdays![i];
      }
      print(
          'DEBUG: Copied lunch weekdays: $_lunchSelectedWeekdays from ${widget.lunchSelectedWeekdays}');
    } else {
      // Default to Mon-Fri for lunch
      for (int i = 0; i < 5; i++) {
        _lunchSelectedWeekdays![i] = true;
      }
      print('DEBUG: Using default Mon-Fri for lunch');
    }

    // Set the flags based on active subscriptions and passed parameters
    _needsBreakfastPreorder = widget.student.hasActiveBreakfast &&
        widget.student.breakfastPlanEndDate != null &&
        widget.showBreakfastPreorder;

    _needsLunchPreorder = widget.student.hasActiveLunch &&
        widget.student.lunchPlanEndDate != null &&
        widget.showLunchPreorder;

    print(
        'DEBUG: =============== ACTIVE SUBSCRIPTION BOTTOM SHEET ===============');
    print('DEBUG: Student: ${widget.student.name} (ID: ${widget.student.id})');
    print('DEBUG: Has active breakfast: ${widget.student.hasActiveBreakfast}');
    print('DEBUG: Has active lunch: ${widget.student.hasActiveLunch}');
    print(
        'DEBUG: Breakfast plan end date: ${widget.student.breakfastPlanEndDate}');
    print('DEBUG: Lunch plan end date: ${widget.student.lunchPlanEndDate}');
    print(
        'DEBUG: New breakfast plan type: ${widget.breakfastPlanType ?? "Not specified"}');
    print(
        'DEBUG: New lunch plan type: ${widget.lunchPlanType ?? "Not specified"}');
    print('DEBUG: BREAKFAST selected weekdays: $_breakfastSelectedWeekdays');
    print('DEBUG: LUNCH selected weekdays: $_lunchSelectedWeekdays');
    print(
        'DEBUG: showBreakfastPreorder parameter: ${widget.showBreakfastPreorder}');
    print('DEBUG: showLunchPreorder parameter: ${widget.showLunchPreorder}');
    print(
        'DEBUG: _needsBreakfastPreorder calculated result: $_needsBreakfastPreorder');
    print('DEBUG: _needsLunchPreorder calculated result: $_needsLunchPreorder');
    print(
        'DEBUG: =============================================================');

    // Calculate the pre-order dates using the enhanced PreOrderDateCalculator
    _calculatePreOrderDates();
  }

  // Calculate pre-order dates for both meal types independently
  void _calculatePreOrderDates() {
    print(
        'DEBUG: Calculating pre-order dates for both meal types independently');

    // Get the pre-order date ranges for both meal types using the enhanced calculator
    final preOrderDateRanges =
        PreOrderDateCalculator.calculateMealPreOrderDateRanges(
      breakfastPlanEndDate:
          _needsBreakfastPreorder ? widget.student.breakfastPlanEndDate : null,
      lunchPlanEndDate:
          _needsLunchPreorder ? widget.student.lunchPlanEndDate : null,
      breakfastPlanType: widget.breakfastPlanType,
      lunchPlanType: widget.lunchPlanType,
      breakfastSelectedWeekdays: _breakfastSelectedWeekdays,
      lunchSelectedWeekdays: _lunchSelectedWeekdays,
    );

    // Handle breakfast pre-order dates if needed
    if (_needsBreakfastPreorder &&
        preOrderDateRanges['breakfast']!.isNotEmpty) {
      _breakfastStartDate = preOrderDateRanges['breakfast']!['startDate'];
      _breakfastEndDate = preOrderDateRanges['breakfast']!['endDate'];
      _selectedBreakfastDate = _breakfastStartDate;

      // Calculate delivery mode for breakfast
      if (_breakfastSelectedWeekdays != null) {
        _breakfastDeliveryMode = PreOrderDateCalculator.getDeliveryModeText(
            _breakfastSelectedWeekdays!);
      }

      print(
          'DEBUG: Calculated breakfast pre-order start: ${_breakfastStartDate != null ? PreOrderDateCalculator.formatDate(_breakfastStartDate!) : "N/A"}');
      print(
          'DEBUG: Calculated breakfast pre-order end: ${_breakfastEndDate != null ? PreOrderDateCalculator.formatDate(_breakfastEndDate!) : "N/A"}');
      print('DEBUG: Breakfast delivery mode: $_breakfastDeliveryMode');
    }

    // Handle lunch pre-order dates if needed
    if (_needsLunchPreorder && preOrderDateRanges['lunch']!.isNotEmpty) {
      _lunchStartDate = preOrderDateRanges['lunch']!['startDate'];
      _lunchEndDate = preOrderDateRanges['lunch']!['endDate'];
      _selectedLunchDate = _lunchStartDate;

      // Calculate delivery mode for lunch
      if (_lunchSelectedWeekdays != null) {
        _lunchDeliveryMode =
            PreOrderDateCalculator.getDeliveryModeText(_lunchSelectedWeekdays!);
      }

      print(
          'DEBUG: Calculated lunch pre-order start: ${_lunchStartDate != null ? PreOrderDateCalculator.formatDate(_lunchStartDate!) : "N/A"}');
      print(
          'DEBUG: Calculated lunch pre-order end: ${_lunchEndDate != null ? PreOrderDateCalculator.formatDate(_lunchEndDate!) : "N/A"}');
      print('DEBUG: Lunch delivery mode: $_lunchDeliveryMode');
    }
  }

  // Format date nicely
  String _formatDate(DateTime date) {
    return DateFormat('d MMM yyyy').format(date);
  }

  // Check if a date is valid for selection based on plan settings
  bool _isDateSelectable(DateTime date, String mealType) {
    // Use the enhanced PreOrderDateCalculator to check if the date is in range
    if (mealType == 'breakfast') {
      return PreOrderDateCalculator.isInPreOrderRange(
        date: date,
        startDate: _breakfastStartDate,
        endDate: _breakfastEndDate,
        selectedWeekdays: _breakfastSelectedWeekdays,
      );
    } else {
      return PreOrderDateCalculator.isInPreOrderRange(
        date: date,
        startDate: _lunchStartDate,
        endDate: _lunchEndDate,
        selectedWeekdays: _lunchSelectedWeekdays,
      );
    }
  }

  // Select a date for breakfast pre-order
  Future<void> _selectBreakfastDate() async {
    if (widget.student.breakfastPlanEndDate == null ||
        _breakfastStartDate == null ||
        _breakfastEndDate == null) return;

    final DateTime initialDate = _selectedBreakfastDate ?? _breakfastStartDate!;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: _breakfastStartDate!,
      lastDate: _breakfastEndDate!,
      selectableDayPredicate: (DateTime date) {
        return _isDateSelectable(date, 'breakfast');
      },
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.purple,
              onPrimary: Colors.white,
              onSurface: AppTheme.textDark,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.purple,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedBreakfastDate = pickedDate;
      });
    }
  }

  // Select a date for lunch pre-order
  Future<void> _selectLunchDate() async {
    if (widget.student.lunchPlanEndDate == null ||
        _lunchStartDate == null ||
        _lunchEndDate == null) return;

    final DateTime initialDate = _selectedLunchDate ?? _lunchStartDate!;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: _lunchStartDate!,
      lastDate: _lunchEndDate!,
      selectableDayPredicate: (DateTime date) {
        return _isDateSelectable(date, 'lunch');
      },
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.purple,
              onPrimary: Colors.white,
              onSurface: AppTheme.textDark,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.purple,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedLunchDate = pickedDate;
      });
    }
  }

  // Continue button action
  void _handleContinueAction() {
    // Log the delivery modes that are being passed back
    print('DEBUG: ======== CONTINUING WITH DELIVERY MODES ========');
    print('DEBUG: BREAKFAST selected weekdays: $_breakfastSelectedWeekdays');
    print('DEBUG: LUNCH selected weekdays: $_lunchSelectedWeekdays');
    print(
        'DEBUG: Breakfast delivery mode: ${_needsBreakfastPreorder ? _breakfastDeliveryMode : "Not needed"}');
    print(
        'DEBUG: Lunch delivery mode: ${_needsLunchPreorder ? _lunchDeliveryMode : "Not needed"}');

    // Ensure we're passing back the correct, separate delivery modes
    String? breakfastDelivery =
        _needsBreakfastPreorder ? _breakfastDeliveryMode : null;
    String? lunchDelivery = _needsLunchPreorder ? _lunchDeliveryMode : null;

    print('DEBUG: Final breakfast delivery mode: $breakfastDelivery');
    print('DEBUG: Final lunch delivery mode: $lunchDelivery');
    print('DEBUG: =================================================');

    // Close the bottom sheet and call the callback with the selected dates and delivery modes
    Navigator.of(context).pop();
    widget.onContinue(
      _needsBreakfastPreorder ? _selectedBreakfastDate : null,
      _needsLunchPreorder ? _selectedLunchDate : null,
      breakfastDelivery,
      lunchDelivery,
    );
  }

  // Check if the continue button should be enabled
  bool _isContinueEnabled() {
    bool breakfastReady =
        !_needsBreakfastPreorder || _selectedBreakfastDate != null;
    bool lunchReady = !_needsLunchPreorder || _selectedLunchDate != null;
    return breakfastReady && lunchReady;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 24,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bottom sheet header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Subscription Found',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Pre-order message
          _buildPreorderMessage(),

          const SizedBox(height: 16),

          // Active Plan Details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Breakfast Plan
                if (_needsBreakfastPreorder)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.ramen_dining,
                            size: 16,
                            color: Colors.pink,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Breakfast Plan',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Start: ${_formatDate(widget.student.breakfastPlanStartDate ?? DateTime.now())}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppTheme.textMedium,
                        ),
                      ),
                      Text(
                        'End: ${_formatDate(widget.student.breakfastPlanEndDate!)}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppTheme.textMedium,
                        ),
                      ),

                      // Add a highlighted delivery mode section for breakfast
                      if (false && _breakfastDeliveryMode != null)
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.amber.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_view_week,
                                size: 16,
                                color: Colors.amber.shade800,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Delivery: $_breakfastDeliveryMode',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.amber.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (false && widget.breakfastPlanType != null)
                        Text(
                          'New Plan Type: ${widget.breakfastPlanType}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppTheme.purple,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      const SizedBox(height: 12),
                    ],
                  ),

                // Divider between plans if both are shown
                if (_needsBreakfastPreorder && _needsLunchPreorder)
                  Divider(
                    color: Colors.grey.shade300,
                    height: 24,
                  ),

                // Lunch Plan
                if (_needsLunchPreorder)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.flatware,
                            size: 16,
                            color: AppTheme.success,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Lunch Plan',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Start: ${_formatDate(widget.student.lunchPlanStartDate ?? DateTime.now())}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppTheme.textMedium,
                        ),
                      ),
                      Text(
                        'End: ${_formatDate(widget.student.lunchPlanEndDate!)}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppTheme.textMedium,
                        ),
                      ),

                      // Add a highlighted delivery mode section for lunch
                      if (false && _lunchDeliveryMode != null)
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.purple.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_view_week,
                                size: 16,
                                color: AppTheme.purple,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Delivery: $_lunchDeliveryMode',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.purple,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (false && widget.lunchPlanType != null)
                        Text(
                          'New Plan Type: ${widget.lunchPlanType}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppTheme.purple,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Pre-order Section
          Text(
            'Pre-order Available From:',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),

          // Breakfast Pre-order Date
          if (_needsBreakfastPreorder)
            _buildDateSelection(
              title: 'Select Breakfast Pre-order Date',
              selectedDate: _selectedBreakfastDate,
              startDate: _breakfastStartDate,
              endDate: _breakfastEndDate,
              onTap: _selectBreakfastDate,
              planType: widget.breakfastPlanType,
              deliveryMode: _breakfastDeliveryMode,
            ),

          if (_needsBreakfastPreorder && _needsLunchPreorder)
            const SizedBox(height: 12),

          // Lunch Pre-order Date
          if (_needsLunchPreorder)
            _buildDateSelection(
              title: 'Select Lunch Pre-order Date',
              selectedDate: _selectedLunchDate,
              startDate: _lunchStartDate,
              endDate: _lunchEndDate,
              onTap: _selectLunchDate,
              planType: widget.lunchPlanType,
              deliveryMode: _lunchDeliveryMode,
            ),

          const SizedBox(height: 24),

          // Continue Button
          Container(
            width: double.infinity,
            height: 54,
            decoration: _isContinueEnabled()
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    gradient: AppTheme.purpleToDeepPurple,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.deepPurple.withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                        spreadRadius: -4,
                      ),
                    ],
                  )
                : BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    color: Colors.grey.shade300,
                  ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(50),
                onTap: _isContinueEnabled() ? _handleContinueAction : null,
                child: Center(
                  child: Text(
                    'Continue',
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
        ],
      ),
    );
  }

  // Helper to build date selection field
  Widget _buildDateSelection({
    required String title,
    required DateTime? selectedDate,
    required DateTime? startDate,
    required DateTime? endDate,
    required VoidCallback onTap,
    String? planType,
    String? deliveryMode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppTheme.textMedium,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedDate != null
                        ? _formatDate(selectedDate)
                        : 'Select a date',
                    style: GoogleFonts.poppins(
                      color: selectedDate != null
                          ? AppTheme.textDark
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today_outlined,
                  size: 20,
                  color: AppTheme.purple,
                ),
              ],
            ),
          ),
        ),
        if (selectedDate != null && startDate != null && endDate != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pre-order from: ${_formatDate(startDate)} to ${_formatDate(endDate)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textMedium,
                  ),
                ),
                if (false && planType != null)
                  Text(
                    'Plan type: $planType',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.purple,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (false && deliveryMode != null)
                  Text(
                    'Delivery mode: $deliveryMode',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.deepPurple,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  // Method to build the preorder availability message
  Widget _buildPreorderMessage() {
    String message = "";

    if (_needsBreakfastPreorder && _needsLunchPreorder) {
      message = "Pre-order available for breakfast and lunch";
    } else if (_needsBreakfastPreorder) {
      message = "Pre-order available for breakfast only";
    } else if (_needsLunchPreorder) {
      message = "Pre-order available for lunch only";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.purple.withOpacity(0.2),
        ),
      ),
      child: Text(
        message,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppTheme.purple,
        ),
      ),
    );
  }
}
