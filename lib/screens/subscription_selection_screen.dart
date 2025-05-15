import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:startwell/models/meal_model.dart';
import 'package:startwell/services/meal_selection_manager.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:startwell/utils/meal_plan_validator.dart';
import 'package:startwell/widgets/common/info_banner.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:startwell/screens/manage_student_profile_screen.dart';
import 'package:startwell/widgets/common/veg_icon.dart';
import 'package:startwell/widgets/common/gradient_app_bar.dart';
import 'package:startwell/widgets/common/gradient_button.dart';

class SubscriptionSelectionScreen extends StatefulWidget {
  final MealSelectionManager selectionManager;
  final List<Meal> selectedMeals;
  final double totalMealCost;
  final int initialPlanIndex;
  final bool isExpressOrder;
  final String mealType;

  const SubscriptionSelectionScreen({
    Key? key,
    required this.selectionManager,
    required this.selectedMeals,
    required this.totalMealCost,
    this.initialPlanIndex = 1,
    this.isExpressOrder = false,
    this.mealType = 'lunch',
  }) : super(key: key);

  @override
  State<SubscriptionSelectionScreen> createState() =>
      _SubscriptionSelectionScreenState();
}

class _SubscriptionSelectionScreenState
    extends State<SubscriptionSelectionScreen> {
  int _selectedPlanIndex = 0;
  bool _isCustomPlan = false;

  final List<bool> _selectedWeekdays = [true, true, true, true, true];
  final List<String> _weekdayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday'
  ];

  late DateTime _startDate;
  late DateTime _firstAvailableDate;
  DateTime? _endDate;

  List<DateTime> _mealDates = [];
  DateTime? _focusedCalendarDate;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  bool _isMealScheduleExpanded = false;

  final List<Map<String, dynamic>> _subscriptionPlans = [
    {
      'name': 'Single Day',
      'duration': '1 Day',
      'meals': 1,
      'discount': 0.0,
      'weeks': 0,
      'isSingleDay': true,
    },
    {
      'name': 'Weekly',
      'duration': '1 Week',
      'meals': 5,
      'discount': 0.0,
      'weeks': 1,
    },
    {
      'name': 'Monthly',
      'duration': '4 Weeks',
      'meals': 20,
      'discount': 0.0,
      'weeks': 4,
    },
    {
      'name': 'Quarterly',
      'duration': '3 Months',
      'meals': 60,
      'discount': 0.1,
      'weeks': 12,
    },
    {
      'name': 'Half-Yearly',
      'duration': '6 Months',
      'meals': 90,
      'discount': 0.15,
      'weeks': 24,
    },
    {
      'name': 'Annual',
      'duration': '12 Months',
      'meals': 200,
      'discount': 0.2,
      'weeks': 48,
    },
  ];

  @override
  void initState() {
    super.initState();

    _selectedPlanIndex = widget.initialPlanIndex;

    if (widget.isExpressOrder) {
      _selectedPlanIndex = 0;
      _selectedPlanIndex = 0; // Single Day plan
      _isCustomPlan = false; // Regular plan mode
    }

    // Set first available date
    final now = DateTime.now();
    _firstAvailableDate = _getNextWeekday(now);

    // For regular orders, use the next available weekday as start date
    if (!widget.isExpressOrder) {
      _startDate = _firstAvailableDate;
    } else {
      // For express orders, calculate the appropriate day based on express window
      final bool isExpressWindowOpen = isWithinExpressWindow();

      // If express window is open and it's a weekday, use today
      if (isExpressWindowOpen && now.weekday <= 5) {
        _firstAvailableDate = DateTime(now.year, now.month, now.day);
        _startDate = _firstAvailableDate;
      } else {
        // Otherwise use the next weekday
        _startDate = _firstAvailableDate;
      }
    }

    // Set focused date to start date
    _focusedCalendarDate = _startDate;

    // Calculate meal dates
    _calculateMealDates();

    // Print for debugging
    print('First Day: $_firstAvailableDate');
    print('Start Date: $_startDate');
    print('Focused Day: $_focusedCalendarDate');
  }

  // Get next two weekdays for Regular plan
  List<DateTime> _getNextTwoWeekdays(DateTime start) {
    final days = <DateTime>[];
    DateTime current = start;
    while (days.length < 2) {
      if (current.weekday <= 5) days.add(current);
      current = current.add(const Duration(days: 1));
    }
    return days;
  }

  // Get next two meal dates for Custom plan
  List<DateTime> _getCustomUpcomingDates(
      DateTime start, List<int> selectedWeekdays) {
    final result = <DateTime>[];
    DateTime current = start;

    // If no weekdays selected, return empty list
    if (selectedWeekdays.isEmpty) {
      return result;
    }

    // Try for up to 14 days to find 2 matching dates
    int daysChecked = 0;
    while (result.length < 2 && daysChecked < 14) {
      if (selectedWeekdays.contains(current.weekday)) {
        result.add(current);
      }
      current = current.add(const Duration(days: 1));
      daysChecked++;
    }
    return result;
  }

  // Get upcoming meal dates based on plan type
  List<DateTime> _getUpcomingMealDates() {
    // For Express 1-Day or Single Day plan, show only one date
    if (_selectedPlanIndex == 0 || widget.isExpressOrder) {
      return [_startDate];
    }

    // For Custom plan
    if (_isCustomPlan) {
      return _getCustomUpcomingDates(_startDate, _getSelectedWeekdayIndexes());
    }

    // For Regular plan (Weekly, Monthly, etc.)
    return _getNextTwoWeekdays(_startDate);
  }

  // Get meal item text based on meal type
  String _getMealItemsText() {
    return widget.mealType == 'breakfast'
        ? 'Breakfast Item 1, Breakfast Item 2, Seasonal Fruits'
        : 'Lunch Item 1, Lunch Item 2, Salad';
  }

  // Check if current time is within Express window (12:00 AM to 8:00 AM IST)
  bool isWithinExpressWindow() {
    // Convert to IST time (UTC + 5:30)
    DateTime now =
        DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    final nowHour = now.hour;
    return nowHour >= 0 && nowHour < 8;
  }

  // Find the next weekday (Mon-Fri) from a given date
  DateTime _getNextWeekday(DateTime date) {
    DateTime nextDate = date.add(const Duration(days: 1));
    while (nextDate.weekday > 5) {
      nextDate = nextDate.add(const Duration(days: 1));
    }
    return nextDate;
  }

  // Find the next occurrence of a specific weekday
  DateTime _getNextSpecificWeekday(int targetWeekday) {
    return getNextWeekdayDate(DateTime.now(), targetWeekday);
  }

  // Get the next date for a specific weekday
  DateTime getNextWeekdayDate(DateTime today, int weekday) {
    // Ensure weekday is 1-5 (Monday-Friday)
    if (weekday < 1 || weekday > 5) {
      throw ArgumentError(
          'Invalid weekday: $weekday. Must be 1-5 (Monday-Friday)');
    }

    // Calculate offset to next occurrence of the weekday
    int offset = (weekday - today.weekday + 7) % 7;

    // If the calculated day is today (offset == 0), return next week instead
    return today.add(Duration(days: offset == 0 ? 7 : offset));
  }

  // Get indexes of selected weekdays
  List<int> _getSelectedWeekdayIndexes() {
    List<int> selectedIndexes = [];
    for (int i = 0; i < _selectedWeekdays.length; i++) {
      if (_selectedWeekdays[i]) {
        // Add 1 to match DateTime.weekday (1-7) where 1 is Monday
        selectedIndexes.add(i + 1);
      }
    }
    return selectedIndexes;
  }

  // Find the earliest date based on selected weekdays
  DateTime _findEarliestDateFromSelectedWeekdays() {
    if (_selectedWeekdays.where((day) => day).isEmpty) {
      // If no weekdays selected, return the default next weekday
      return _getNextWeekday(DateTime.now());
    }

    // Get the list of selected weekday indices (1-based, Monday=1)
    final List<int> selectedWeekdayIndices = _getSelectedWeekdayIndexes();

    // Get all upcoming dates for selected weekdays
    final List<DateTime> upcomingDates = selectedWeekdayIndices
        .map((weekday) => getNextWeekdayDate(DateTime.now(), weekday))
        .toList();

    // Sort dates to find the earliest
    upcomingDates.sort();

    return upcomingDates.first;
  }

  // Calculate custom plan start date based on selected date and weekdays
  DateTime calculateCustomPlanStartDate({
    required DateTime selectedStartDate,
    required List<int> selectedWeekdays,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day); // Remove time

    final selectedStart = DateTime(
      selectedStartDate.year,
      selectedStartDate.month,
      selectedStartDate.day,
    );

    final difference = selectedStart.difference(today).inDays;
    final isInCurrentWeek = difference >= 0 && difference < 7;

    if (isInCurrentWeek) {
      final upcomingDates = selectedWeekdays
          .map((weekday) => getNextWeekdayDate(today, weekday))
          .where((date) => !date.isBefore(today))
          .toList()
        ..sort();

      return upcomingDates.isNotEmpty ? upcomingDates.first : selectedStart;
    }

    return selectedStart; // Respect manually selected date
  }

  // Calculate meal dates based on plan and preferences
  void _calculateMealDates() {
    if (widget.isExpressOrder) {
      _calculateExpressMealDates();
      return;
    }

    // For regular plans
    _mealDates.clear();

    if (_selectedPlanIndex == 0) {
      // Single Day - Add just the start date
      _mealDates.add(_startDate);
      _endDate = _startDate;
    } else {
      // Multi-day subscriptions
      if (_isCustomPlan) {
        // Custom plan with selected weekdays
        _calculateCustomPlanMealDates();
      } else {
        // Regular plan (Monday to Friday)
        _calculateRegularPlanMealDates();
      }
    }
  }

  // Calculate express meal dates for express 1-day orders
  void _calculateExpressMealDates() {
    _mealDates.clear();

    // For express orders, always use a fixed date - either today (if in express window)
    // or the next available weekday
    final now = DateTime.now();
    final bool isExpressWindowOpen = isWithinExpressWindow();

    // If express window is open and it's a weekday, use today
    if (isExpressWindowOpen && now.weekday <= 5) {
      _startDate = DateTime(now.year, now.month, now.day);
    } else {
      // Otherwise use the next weekday
      _startDate = _getNextWeekday(now);
    }

    // Always use just one date - the fixed express date
    _mealDates.add(_startDate);
    _endDate = _startDate;

    // Debug print
    print('Express meal date: $_startDate');
  }

  // Calculate custom plan meal dates
  void _calculateCustomPlanMealDates() {
    _mealDates = [];

    final selectedWeekdayIndexes = _getSelectedWeekdayIndexes();
    final totalMeals = _subscriptionPlans[_selectedPlanIndex]['meals'];

    // For custom plan, update the start date to the earliest selected weekday
    _startDate = calculateCustomPlanStartDate(
      selectedStartDate: _startDate,
      selectedWeekdays: selectedWeekdayIndexes,
    );
    _focusedCalendarDate = _startDate;

    // Generate meal dates
    _mealDates = _generateMealDates(
      startFrom: _startDate,
      selectedWeekdays: selectedWeekdayIndexes,
      totalMeals: totalMeals,
      isSingleDay: false,
    );

    // Set end date to the last meal date
    if (_mealDates.isNotEmpty) {
      setState(() {
        _endDate = _mealDates.last;
      });
    } else {
      setState(() {
        _endDate = null;
      });
    }

    // Debug log
    print(
        'Selected weekdays: ${selectedWeekdayIndexes.map((i) => _weekdayNames[i - 1]).toList()}');
    print('Start: $_startDate, End: $_endDate');
    print('Meal dates count: ${_mealDates.length}');
  }

  // Calculate regular plan meal dates
  void _calculateRegularPlanMealDates() {
    _mealDates = [];

    final selectedWeekdayIndexes = _getSelectedWeekdayIndexes();
    final totalMeals = _subscriptionPlans[_selectedPlanIndex]['meals'];

    // Generate meal dates
    _mealDates = _generateMealDates(
      startFrom: _startDate,
      selectedWeekdays: selectedWeekdayIndexes,
      totalMeals: totalMeals,
      isSingleDay: false,
    );

    // Set end date to the last meal date
    if (_mealDates.isNotEmpty) {
      setState(() {
        _endDate = _mealDates.last;
      });
    } else {
      setState(() {
        _endDate = null;
      });
    }

    // Debug log
    print(
        'Selected weekdays: ${selectedWeekdayIndexes.map((i) => _weekdayNames[i - 1]).toList()}');
    print('Start: $_startDate, End: $_endDate');
    print('Meal dates count: ${_mealDates.length}');
  }

  // Generate a list of meal dates based on selected weekdays and plan
  List<DateTime> _generateMealDates({
    required DateTime startFrom,
    required List<int> selectedWeekdays,
    required int totalMeals,
    bool isSingleDay = false,
  }) {
    if (selectedWeekdays.isEmpty) return [];

    // For single day plan, just return the start date
    if (isSingleDay) {
      return [startFrom];
    }

    List<DateTime> mealDates = [];
    DateTime current = startFrom;

    // Continue until we've collected all meal dates or reached a reasonable limit
    int safetyCounter = 0;
    while (mealDates.length < totalMeals && safetyCounter < 1000) {
      // Check if current date is a selected weekday (and not a weekend)
      if (selectedWeekdays.contains(current.weekday) && current.weekday <= 5) {
        mealDates.add(current);
      }

      // Move to next day
      current = current.add(const Duration(days: 1));
      safetyCounter++;
    }

    return mealDates;
  }

  // Check if a date has a meal scheduled
  bool _hasMealOnDate(DateTime date) {
    return _mealDates.any((mealDate) =>
        mealDate.year == date.year &&
        mealDate.month == date.month &&
        mealDate.day == date.day);
  }

  // Calculate end date based on selected plan and weekdays
  void _calculateEndDate() {
    _calculateMealDates();
  }

  // Get all meal delivery dates
  List<DateTime> _getMealDeliveryDates() {
    return _mealDates;
  }

  // Handle weekday selection change
  void _handleWeekdaySelection(int index, bool? value) {
    // Ensure at least one weekday is selected
    final wouldHaveSelection =
        _selectedWeekdays.asMap().entries.any((e) => e.key != index && e.value);

    if (value == false && !wouldHaveSelection) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You must select at least one weekday',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _selectedWeekdays[index] = value!;

      // Update the start date based on the earliest selected weekday
      if (_isCustomPlan) {
        _startDate = calculateCustomPlanStartDate(
          selectedStartDate: _startDate,
          selectedWeekdays: _getSelectedWeekdayIndexes(),
        );
        _focusedCalendarDate = _startDate;
      }

      // Recalculate meal dates with the new start date
      _calculateMealDates();
    });
  }

  // Handle plan mode toggle
  void _handlePlanModeToggle(bool isCustom) {
    setState(() {
      _isCustomPlan = isCustom;

      if (!isCustom) {
        // Reset to default weekdays for regular plan
        _selectedWeekdays.fillRange(0, 5, true);

        // Default start date for regular mode
        _startDate = _getNextWeekday(DateTime.now());
      } else {
        // For custom mode, find the earliest date based on selected weekdays
        _startDate = calculateCustomPlanStartDate(
          selectedStartDate: _startDate,
          selectedWeekdays: _getSelectedWeekdayIndexes(),
        );
      }

      _focusedCalendarDate = _startDate;
      _calculateMealDates();
    });
  }

  // Handle plan selection change
  void _handlePlanSelection(int index) {
    final bool isSingleDay = _subscriptionPlans[index]['isSingleDay'] ?? false;

    setState(() {
      _selectedPlanIndex = index;

      // Reset to regular plan mode if Single Day is selected
      if (isSingleDay) {
        _isCustomPlan = false;
      }

      _calculateMealDates();
    });
  }

  // Get formatted string of selected weekdays
  String _getSelectedWeekdaysText() {
    List<String> selectedDays = [];
    for (int i = 0; i < _selectedWeekdays.length; i++) {
      if (_selectedWeekdays[i]) {
        selectedDays.add(_weekdayNames[i]);
      }
    }

    if (selectedDays.isEmpty) {
      return "None";
    } else if (selectedDays.length == 5) {
      return "All Weekdays";
    } else if (selectedDays.length >= 3) {
      // For 3 or more days, use abbreviated form to save space
      return selectedDays.map((day) => day.substring(0, 3)).join(", ");
    } else {
      return selectedDays.join(", ");
    }
  }

  // Calculate price with or without discount
  double _calculatePrice() {
    final baseCost = widget.totalMealCost;
    final isSingleDay =
        _subscriptionPlans[_selectedPlanIndex]['isSingleDay'] ?? false;

    // For single day plan, always use 1 meal
    final mealCount = isSingleDay
        ? 1
        : (_isCustomPlan
            ? _mealDates.length
            : _subscriptionPlans[_selectedPlanIndex]['meals']);

    final discount = _subscriptionPlans[_selectedPlanIndex]['discount'];

    final totalPrice = baseCost * mealCount;
    final discountedPrice = totalPrice * (1 - discount);

    return discountedPrice;
  }

  // Calculate original price before discount
  double _calculateOriginalPrice() {
    final baseCost = widget.totalMealCost;
    final isSingleDay =
        _subscriptionPlans[_selectedPlanIndex]['isSingleDay'] ?? false;

    // For single day plan, always use 1 meal
    final mealCount = isSingleDay
        ? 1
        : (_isCustomPlan
            ? _mealDates.length
            : _subscriptionPlans[_selectedPlanIndex]['meals']);

    return baseCost * mealCount;
  }

  // Get savings amount
  double _getSavings() {
    final originalPrice = _calculateOriginalPrice();
    final discountedPrice = _calculatePrice();
    return originalPrice - discountedPrice;
  }

  // Get formatted start date string including weekday name
  String _getFormattedStartDate() {
    if (_selectedWeekdays.where((day) => day).isEmpty) {
      return "No weekdays selected";
    }

    final String weekdayName = DateFormat('EEEE').format(_startDate);
    final String formattedDate = DateFormat('MMMM d, yyyy').format(_startDate);
    return "$weekdayName, $formattedDate";
  }

  // Ensure the focused day is valid and within the range of firstDay and lastDay
  DateTime _ensureValidFocusedDay() {
    final DateTime now = DateTime.now();
    final DateTime lastDay = now.add(const Duration(days: 365));

    // If focusedDay is null, use startDate
    if (_focusedCalendarDate == null) {
      return _startDate;
    }

    // Ensure focusedDay is not before firstDay
    if (_focusedCalendarDate!.isBefore(_firstAvailableDate)) {
      return _firstAvailableDate;
    }

    // Ensure focusedDay is not after lastDay
    if (_focusedCalendarDate!.isAfter(lastDay)) {
      return lastDay;
    }

    // Return the valid focusedDay
    return _focusedCalendarDate!;
  }

  // Update plan index and also check if we need to force it to Custom or Regular mode
  void _selectPlan(int index) {
    setState(() {
      _selectedPlanIndex = index;
      // If Single Day or Express plan, force to Regular mode
      if (index == 0 || widget.isExpressOrder) {
        _isCustomPlan = false;
      }
      // Calculate end date and meal dates
      _calculateMealDates();
    });
  }

  // Toggle custom plan mode
  void _toggleCustomMode() {
    if (_selectedPlanIndex != 0 && !widget.isExpressOrder) {
      setState(() {
        _isCustomPlan = !_isCustomPlan;

        // If switching to regular mode (Mon to Fri), select all weekdays automatically
        if (!_isCustomPlan) {
          // Auto-select all weekdays (Monday to Friday)
          _selectedWeekdays.fillRange(0, 5, true);
          _startDate = _firstAvailableDate;
        } else {
          // If switching to custom mode (Custom Days), use existing selections
          // (No need to modify selections here - keep current user selection)
          _startDate = _findEarliestDateFromSelectedWeekdays();
        }

        // Calculate end date and meal dates
        _calculateMealDates();
      });
    }
  }

  // Toggle weekday selection for custom plan
  void _toggleWeekday(int index) {
    if (_selectedPlanIndex != 0 && !widget.isExpressOrder) {
      setState(() {
        // Toggle the selection for this weekday
        _selectedWeekdays[index] = !_selectedWeekdays[index];

        // Ensure at least one weekday is selected
        bool anySelected = _selectedWeekdays.any((day) => day);
        if (!anySelected) {
          // If none selected, revert the change
          _selectedWeekdays[index] = true;
          return;
        }

        // Update start date based on selected weekdays if in custom mode
        if (_isCustomPlan) {
          _startDate = _findEarliestDateFromSelectedWeekdays();
        }

        // Calculate end date and meal dates
        _calculateMealDates();
      });
    }
  }

  // Handle date selection from calendar
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      // Only update if the selected date is not before the min date
      if (!selectedDay.isBefore(_firstAvailableDate)) {
        _startDate = selectedDay;
        _focusedCalendarDate = focusedDay;

        // Calculate end date and meal dates
        _calculateMealDates();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasDiscount = _subscriptionPlans[_selectedPlanIndex]['discount'] > 0;

    return Scaffold(
      appBar: GradientAppBar(
        titleText: 'Subscription Plan',
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Express Order Banner (only for Express orders)
              if (widget.isExpressOrder)
                InfoBanner(
                  title: MealPlanValidator.isWithinExpressWindow()
                      ? "Express 1-Day Delivery"
                      : "Express Order Window Closed",
                  message: MealPlanValidator.isWithinExpressWindow()
                      ? "Orders for same-day delivery are available between 12:00 AM to 8:00 AM (IST). Please confirm your order below."
                      : "Express orders are only available between 12:00 AM and 8:00 AM IST. Please try again during this time window.",
                  type: MealPlanValidator.isWithinExpressWindow()
                      ? InfoBannerType.success
                      : InfoBannerType.warning,
                ),

              // Show some space if Express banner is shown
              if (widget.isExpressOrder) const SizedBox(height: 16),

              // Plan selection heading
              Text(
                widget.isExpressOrder
                    ? "Express 1-Day Delivery Plan"
                    : "Select ${widget.mealType.substring(0, 1).toUpperCase()}${widget.mealType.substring(1)} Subscription Plan",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),

              const SizedBox(height: 16),

              // Plan selection cards - grid layout format
              widget.isExpressOrder
                  ? Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child:
                          _buildExpressOnlyPlanCard(), // Show only Single Day plan for Express
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        // Calculate the number of columns based on screen width
                        int crossAxisCount = 2; // Default 2 columns for phones
                        if (constraints.maxWidth > 600) {
                          // For tablets or larger screens
                          crossAxisCount = 3;
                        }

                        return GridView.builder(
                          shrinkWrap: true,
                          physics:
                              const NeverScrollableScrollPhysics(), // Use parent's scroll
                          padding: EdgeInsets.zero,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 16,
                            childAspectRatio:
                                constraints.maxWidth > 600 ? 1.2 : 1.1,
                          ),
                          itemCount: _subscriptionPlans.length,
                          itemBuilder: (context, index) {
                            final plan = _subscriptionPlans[index];
                            final hasDiscount = plan['discount'] > 0;

                            return Container(
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppTheme.deepPurple.withOpacity(0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Card(
                                margin: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: _selectedPlanIndex == index
                                        ? AppTheme.purple
                                        : Colors.transparent,
                                    width:
                                        _selectedPlanIndex == index ? 1.5 : 0,
                                  ),
                                ),
                                elevation: 0,
                                child: InkWell(
                                  onTap: () => _selectPlan(index),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.all(16.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: _selectedPlanIndex == index
                                          ? LinearGradient(
                                              colors: [
                                                AppTheme.purple
                                                    .withOpacity(0.05),
                                                AppTheme.deepPurple
                                                    .withOpacity(0.05),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            )
                                          : null,
                                      border: Border.all(
                                        color: _selectedPlanIndex == index
                                            ? AppTheme.purple
                                            : Colors.purple.shade100,
                                        width: _selectedPlanIndex == index
                                            ? 1.5
                                            : 0,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 24,
                                              height: 24,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color:
                                                    _selectedPlanIndex == index
                                                        ? null
                                                        : Colors.grey.shade100,
                                                gradient:
                                                    _selectedPlanIndex == index
                                                        ? AppTheme
                                                            .purpleToDeepPurple
                                                        : null,
                                              ),
                                              child: Center(
                                                child:
                                                    _selectedPlanIndex == index
                                                        ? const Icon(
                                                            Icons.check,
                                                            color: Colors.white,
                                                            size: 14,
                                                          )
                                                        : null,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                plan['name'],
                                                style: GoogleFonts.poppins(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.textDark,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Text(
                                              '${plan['duration']}',
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                color: AppTheme.textMedium,
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                            Container(
                                              width: 4,
                                              height: 4,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: AppTheme.textMedium
                                                    .withOpacity(0.5),
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                            Expanded(
                                              child: Text(
                                                '${plan['meals']} meals',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  color: AppTheme.textMedium,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Spacer(),
                                        if (hasDiscount)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [
                                                  Color(0xFF8E44AD),
                                                  Color(0xFF9B59B6),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppTheme.deepPurple
                                                      .withOpacity(0.2),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              '${(plan['discount'] * 100).toInt()}% OFF',
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: hasDiscount
                                              ? MainAxisAlignment.spaceBetween
                                              : MainAxisAlignment.end,
                                          children: [
                                            if (hasDiscount)
                                              Text(
                                                '₹${(widget.totalMealCost * plan['meals']).toStringAsFixed(0)}',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  decoration: TextDecoration
                                                      .lineThrough,
                                                  color: AppTheme.textMedium,
                                                ),
                                              ),
                                            Text(
                                              '₹${(widget.totalMealCost * plan['meals'] * (1 - plan['discount'])).toStringAsFixed(0)}',
                                              style: GoogleFonts.poppins(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: hasDiscount
                                                    ? AppTheme.success
                                                    : AppTheme.purple,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),

              const SizedBox(height: 24),

              // Plan mode selection
              if (!widget.isExpressOrder &&
                  !(_subscriptionPlans[_selectedPlanIndex]['isSingleDay'] ??
                      false))
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.deepPurple.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Card(
                    margin: EdgeInsets.zero,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delivery Mode',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _toggleCustomMode(),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      decoration: BoxDecoration(
                                        gradient: !_isCustomPlan
                                            ? AppTheme.purpleToDeepPurple
                                            : null,
                                        color: !_isCustomPlan
                                            ? null
                                            : Colors.transparent,
                                        borderRadius:
                                            const BorderRadius.horizontal(
                                          left: Radius.circular(16),
                                        ),
                                        boxShadow: !_isCustomPlan
                                            ? [
                                                BoxShadow(
                                                  color: AppTheme.purple
                                                      .withOpacity(0.2),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Center(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            if (!_isCustomPlan)
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(4),
                                                decoration: const BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.check,
                                                  size: 12,
                                                  color: AppTheme.purple,
                                                ),
                                              ),
                                            if (!_isCustomPlan)
                                              const SizedBox(width: 8),
                                            Text(
                                              'Mon to Fri',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: !_isCustomPlan
                                                    ? Colors.white
                                                    : AppTheme.textMedium,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _toggleCustomMode(),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      decoration: BoxDecoration(
                                        gradient: _isCustomPlan
                                            ? AppTheme.purpleToDeepPurple
                                            : null,
                                        color: _isCustomPlan
                                            ? null
                                            : Colors.transparent,
                                        borderRadius:
                                            const BorderRadius.horizontal(
                                          right: Radius.circular(16),
                                        ),
                                        boxShadow: _isCustomPlan
                                            ? [
                                                BoxShadow(
                                                  color: AppTheme.purple
                                                      .withOpacity(0.2),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Center(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            if (_isCustomPlan)
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(4),
                                                decoration: const BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.check,
                                                  size: 12,
                                                  color: AppTheme.purple,
                                                ),
                                              ),
                                            if (_isCustomPlan)
                                              const SizedBox(width: 8),
                                            Text(
                                              'Custom Days',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: _isCustomPlan
                                                    ? Colors.white
                                                    : AppTheme.textMedium,
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
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),

              // Weekday selection for custom plan - MOVED HERE
              if (!widget.isExpressOrder &&
                  !(_subscriptionPlans[_selectedPlanIndex]['isSingleDay'] ??
                      false) &&
                  _isCustomPlan)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Select Weekdays for Delivery",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (false) // Hiding the information card for custom plan
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: AppTheme.purple.withOpacity(0.05),
                          border: Border.all(
                            color: AppTheme.purple.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.purple.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.calendar_today_outlined,
                                  color: AppTheme.purple,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Custom Plan",
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Select at least one weekday for meal delivery. The start date will be calculated based on the earliest selected weekday.",
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
                      ),
                    const SizedBox(height: 12),

                    // Weekday selection chips layout
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _weekdayNames.asMap().entries.map((entry) {
                        final index = entry.key;
                        final day = entry.value;
                        final isSelected = _selectedWeekdays[index];

                        return GestureDetector(
                          onTap: () => _toggleWeekday(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? AppTheme.purpleToDeepPurple
                                  : null,
                              color: isSelected ? null : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? AppTheme.deepPurple.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.1),
                                  blurRadius: isSelected ? 6 : 4,
                                  offset: isSelected
                                      ? const Offset(0, 3)
                                      : const Offset(0, 2),
                                  spreadRadius: isSelected ? 1 : 0,
                                ),
                              ],
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              day,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.textDark,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // Start date display (custom plan version) - Hidden
                    if (false) // Hiding the start date display in custom plan section
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          // boxShadow: [
                          //   BoxShadow(
                          //     color: AppTheme.deepPurple.withOpacity(0.05),
                          //     blurRadius: 8,
                          //     offset: const EdgeInsets.symmetric(horizontal: 12),
                          //   ),
                          // ],
                          border: Border.all(
                            color: _selectedWeekdays.contains(true)
                                ? AppTheme.purple.withOpacity(0.3)
                                : Colors.grey.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: _selectedWeekdays.contains(true)
                                      ? LinearGradient(
                                          colors: [
                                            AppTheme.purple.withOpacity(0.15),
                                            AppTheme.deepPurple
                                                .withOpacity(0.15),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : null,
                                  color: _selectedWeekdays.contains(true)
                                      ? null
                                      : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.event_available,
                                  color: _selectedWeekdays.contains(true)
                                      ? AppTheme.purple
                                      : Colors.grey,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Start Date",
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _selectedWeekdays.contains(true)
                                            ? AppTheme.textDark
                                            : Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _selectedWeekdays.contains(true)
                                          ? _getFormattedStartDate()
                                          : "Please select at least one weekday",
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: _selectedWeekdays.contains(true)
                                            ? AppTheme.textMedium
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),

              // Selected days pattern display
              if (!widget.isExpressOrder &&
                  !(_subscriptionPlans[_selectedPlanIndex]['isSingleDay'] ??
                      false))
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.deepPurple.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Card(
                    margin: EdgeInsets.zero,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.purple.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.calendar_month_rounded,
                                  color: AppTheme.purple,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Your Weekly Delivery Days',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildWeekdayCircleViewOnly(
                                    'M', _selectedWeekdays[0]),
                                _buildWeekdayCircleViewOnly(
                                    'T', _selectedWeekdays[1]),
                                _buildWeekdayCircleViewOnly(
                                    'W', _selectedWeekdays[2]),
                                _buildWeekdayCircleViewOnly(
                                    'T', _selectedWeekdays[3]),
                                _buildWeekdayCircleViewOnly(
                                    'F', _selectedWeekdays[4]),
                                _buildWeekdayCircleViewOnly('S', false,
                                    disabled: true),
                                _buildWeekdayCircleViewOnly('S', false,
                                    disabled: true),
                              ],
                            ),
                          ),
                          if (widget.isExpressOrder)
                            Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: Text(
                                'Express 1-Day orders are fixed for the selected delivery date only',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ),
                          if (!widget.isExpressOrder)
                            Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 14,
                                    color: AppTheme.textMedium,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'This displays your selected delivery pattern for the subscription',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                        color: AppTheme.textMedium,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Single Day Plan Info Banner
              if (_subscriptionPlans[_selectedPlanIndex]['isSingleDay'] ??
                  false)
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

              const SizedBox(height: 16),

              // Calendar view section
              Text(
                "Schedule",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),

              const SizedBox(height: 12),

              // New Schedule Card with fixed BoxShadow offset and vertical layout
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Start date section - Shown for all plan modes
                      // if (!_isCustomPlan)
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 20,
                            color: widget.isExpressOrder
                                ? Colors.grey
                                : AppTheme.purple,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Start Date',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _isCustomPlan &&
                                          _selectedWeekdays
                                              .where((day) => day)
                                              .isEmpty
                                      ? "No weekdays selected"
                                      : _getFormattedStartDate(),
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: _isCustomPlan
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                                    color: AppTheme.textDark,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                if (widget.isExpressOrder ||
                                    (_isCustomPlan &&
                                        !_selectedWeekdays
                                            .where((day) => day)
                                            .isEmpty))
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      widget.isExpressOrder
                                          ? 'Locked for express delivery'
                                          : 'Based on earliest selected weekday',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                        color: widget.isExpressOrder
                                            ? Colors.orange
                                            : AppTheme.purple,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (!widget.isExpressOrder)
                            TextButton.icon(
                              onPressed: () async {
                                final selectedDate = await showDatePicker(
                                  context: context,
                                  initialDate: _startDate,
                                  firstDate: _firstAvailableDate,
                                  lastDate: DateTime.now()
                                      .add(const Duration(days: 90)),
                                  selectableDayPredicate: (DateTime date) {
                                    // Only allow weekdays (Monday to Friday)
                                    return date.weekday <= 5;
                                  },
                                );

                                if (selectedDate != null) {
                                  setState(() {
                                    // For custom plan, use the smart start date calculation
                                    if (_isCustomPlan) {
                                      _startDate = calculateCustomPlanStartDate(
                                        selectedStartDate: selectedDate,
                                        selectedWeekdays:
                                            _getSelectedWeekdayIndexes(),
                                      );
                                    } else {
                                      _startDate = selectedDate;
                                    }

                                    _focusedCalendarDate = _startDate;

                                    // If in custom mode, only allow selected weekdays
                                    if (_isCustomPlan &&
                                        !_selectedWeekdays[
                                            selectedDate.weekday - 1]) {
                                      // Show an error message
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Selected date doesn\'t match your weekday preferences. Adjusting selections.',
                                            style: GoogleFonts.poppins(),
                                          ),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );

                                      // Enable the selected weekday
                                      _selectedWeekdays[
                                          selectedDate.weekday - 1] = true;
                                    }

                                    // Recalculate meal dates with new start date
                                    _calculateMealDates();
                                  });
                                }
                              },
                              icon: Icon(
                                Icons.edit_calendar,
                                color: AppTheme.purple,
                                size: 18,
                              ),
                              label: Text(
                                'Change',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.purple,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: const Size(60, 36),
                              ),
                            ),
                        ],
                      ),

                      // Divider between Start Date and End Date sections
                      Divider(
                          thickness: 1, color: Colors.grey.withOpacity(0.1)),

                      // End date section
                      Row(
                        children: [
                          Icon(
                            Icons.event_available,
                            size: 20,
                            color: AppTheme.purple,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'End Date',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _endDate != null
                                      ? DateFormat('EEEE, MMMM d, yyyy')
                                          .format(_endDate!)
                                      : 'Select at least one weekday',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: _endDate != null
                                        ? AppTheme.textDark
                                        : Colors.red,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                if (_endDate != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Calculated based on plan',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                        color: AppTheme.textMedium,
                                      ),
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
              ),

              const SizedBox(height: 16),

              // Calendar view with meal dates - Hidden in all scenarios
              // Meal Schedule Card is completely removed/hidden in all scenarios
              // No "if (false)" condition needed as we're completely removing it

              const SizedBox(height: 16),

              // Upcoming Meal Preview Section
              if (false) // Hide Upcoming Meal Preview Section
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.deepPurple.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Card(
                    margin: EdgeInsets.zero,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.purple.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.restaurant_rounded,
                                  color: AppTheme.purple,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Upcoming Meal',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          ..._getUpcomingMealDates()
                              .map((date) => Container(
                                    margin: const EdgeInsets.only(bottom: 14),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color:
                                            AppTheme.purple.withOpacity(0.15),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(7),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    AppTheme.purple
                                                        .withOpacity(0.1),
                                                    AppTheme.deepPurple
                                                        .withOpacity(0.1),
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.calendar_today_rounded,
                                                color: AppTheme.purple,
                                                size: 16,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              DateFormat('EEE dd, MMM yyyy')
                                                  .format(date),
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.textDark,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 2),
                                              child: VegIcon(),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _getMealItemsText(),
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  color: AppTheme.textMedium,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                          // Show message if no upcoming meals (for custom plan with no weekdays selected)
                          if (_getUpcomingMealDates().isEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.grey.shade600,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'No upcoming meals. Please select at least one weekday.',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Order Summary Section
              if (false) // Hide Order Summary Section
                Container(
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
                        //     AppTheme.purple.withOpacity(0.08),
                        //   ],
                        // ),
                      ),
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Enhanced header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.purple.withOpacity(0.9),
                                      AppTheme.deepPurple.withOpacity(0.9),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          AppTheme.deepPurple.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.receipt_long_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'Order Summary',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textDark,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.white,
                              border: Border.all(
                                color: AppTheme.purple.withOpacity(0.15),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                // Enhanced summary rows
                                _buildEnhancedSummaryRow(
                                  'Plan Type',
                                  _subscriptionPlans[_selectedPlanIndex]
                                          ['name'] +
                                      (_isCustomPlan
                                          ? ' (Custom)'
                                          : ' (Mon to Fri)'),
                                  Icons.assignment_outlined,
                                ),
                                _buildEnhancedSummaryRow(
                                  'Duration',
                                  _subscriptionPlans[_selectedPlanIndex]
                                      ['duration'],
                                  Icons.date_range_outlined,
                                ),
                                if (_isCustomPlan)
                                  _buildEnhancedSummaryRow(
                                    'Selected Days',
                                    _getSelectedWeekdaysText(),
                                    Icons.calendar_today_outlined,
                                    isMultiline: true,
                                  ),
                                _buildEnhancedSummaryRow(
                                  'Total Meals',
                                  '${_mealDates.length} of ${_subscriptionPlans[_selectedPlanIndex]['meals']}',
                                  Icons.restaurant_menu_outlined,
                                ),
                                _buildEnhancedSummaryRow(
                                  'Start Date',
                                  _isCustomPlan
                                      ? (_selectedWeekdays
                                              .where((day) => day)
                                              .isEmpty
                                          ? "No weekdays selected"
                                          : _getFormattedStartDate())
                                      : DateFormat('MMM d, yyyy')
                                          .format(_startDate),
                                  Icons.play_circle_outline_rounded,
                                ),
                                if (_endDate != null)
                                  _buildEnhancedSummaryRow(
                                    'End Date',
                                    DateFormat('MMM d, yyyy').format(_endDate!),
                                    Icons.event_busy_outlined,
                                  ),
                              ],
                            ),
                          ),
                          // Enhanced divider with gradient
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Container(
                              height: 2,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    // Colors.transparent,
                                    AppTheme.gray.withOpacity(0.8),
                                    AppTheme.gray.withOpacity(0.8),

                                    // Colors.transparent,
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ),

                          // Pricing section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppTheme.purple.withOpacity(0.1),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.05),
                                  blurRadius: 10,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                if (hasDiscount)
                                  _buildEnhancedSummaryRow(
                                    'Subtotal',
                                    '₹${_calculateOriginalPrice().toStringAsFixed(0)}',
                                    Icons.wallet_outlined,
                                    valueStyle: GoogleFonts.poppins(
                                      fontSize: 14,
                                      decoration: TextDecoration.lineThrough,
                                      color: AppTheme.textMedium,
                                    ),
                                    showIcon: false,
                                  ),
                                if (hasDiscount)
                                  _buildEnhancedSummaryRow(
                                    'Discount (${(_subscriptionPlans[_selectedPlanIndex]['discount'] * 100).toInt()}%)',
                                    '-₹${_getSavings().toStringAsFixed(0)}',
                                    Icons.discount_outlined,
                                    valueStyle: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: AppTheme.success,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    showIcon: false,
                                  ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppTheme.purple.withOpacity(0.05),
                                        AppTheme.deepPurple.withOpacity(0.1),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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
                                        '₹${_calculatePrice().toStringAsFixed(0)}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.purple,
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
                  ),
                ),

              const SizedBox(height: 32),

              // Proceed to payment button
              Container(
                margin: const EdgeInsets.only(bottom: 32),
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
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
                ),
                child: ElevatedButton(
                  onPressed: _endDate != null &&
                          !(widget.isExpressOrder &&
                              !MealPlanValidator.isWithinExpressWindow())
                      ? () => _navigateToOrderSummary(context)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: EdgeInsets.zero,
                    disabledBackgroundColor: Colors.transparent,
                    disabledForegroundColor: Colors.white.withOpacity(0.6),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.isExpressOrder
                            ? (MealPlanValidator.isWithinExpressWindow()
                                ? 'Confirm Express Order'
                                : 'Express Orders Unavailable')
                            : 'Continue',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      // const SizedBox(width: 10),
                      // Container(
                      //   padding: const EdgeInsets.all(6),
                      //   decoration: BoxDecoration(
                      //     color: Colors.white.withOpacity(0.2),
                      //     shape: BoxShape.circle,
                      //   ),
                      //   child: const Icon(
                      //     Icons.arrow_forward_rounded,
                      //     color: Colors.white,
                      //     size: 20,
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),

              // Warning for closed express window
              if (widget.isExpressOrder &&
                  !MealPlanValidator.isWithinExpressWindow()) ...[
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Express ordering is currently unavailable',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.red,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeekdayCircle(String text, bool isSelected,
      {bool disabled = false}) {
    return GestureDetector(
      onTap: disabled
          ? null
          : () {
              int index = _weekdayNames.indexWhere((day) =>
                  day.substring(0, 1).toUpperCase() == text.toUpperCase());
              if (index != -1) {
                setState(() {
                  _selectedWeekdays[index] = !_selectedWeekdays[index];
                  _calculateMealDates();
                });
              }
            },
      child: Container(
        width: 42,
        height: 42,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient:
              isSelected && !disabled ? AppTheme.purpleToDeepPurple : null,
          color: isSelected
              ? null
              : disabled
                  ? Colors.grey.shade200
                  : Colors.white,
          boxShadow: isSelected && !disabled
              ? [
                  BoxShadow(
                    color: AppTheme.deepPurple.withOpacity(0.2),
                    blurRadius: 6,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    blurRadius: 4,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  )
                ],
          border: Border.all(
            color: isSelected && !disabled
                ? Colors.transparent
                : disabled
                    ? Colors.grey.shade300
                    : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected && !disabled
                  ? Colors.white
                  : disabled
                      ? Colors.grey.shade500
                      : AppTheme.textMedium,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeekdayCircleViewOnly(String text, bool isSelected,
      {bool disabled = false}) {
    return Container(
      width: 42,
      height: 42,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isSelected && !disabled ? AppTheme.purpleToDeepPurple : null,
        color: isSelected
            ? null
            : disabled
                ? Colors.grey.shade200
                : Colors.white,
        boxShadow: isSelected && !disabled
            ? [
                BoxShadow(
                  color: AppTheme.deepPurple.withOpacity(0.2),
                  blurRadius: 6,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                )
              ]
            : [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.15),
                  blurRadius: 4,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                )
              ],
        border: Border.all(
          color: isSelected && !disabled
              ? Colors.transparent
              : disabled
                  ? Colors.grey.shade300
                  : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected && !disabled
                ? Colors.white
                : disabled
                    ? Colors.grey.shade500
                    : AppTheme.textMedium,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textMedium,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: valueStyle ??
                  GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppTheme.textDark,
                  ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpressOnlyPlanCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepPurple.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppTheme.purple,
            width: 1.5,
          ),
        ),
        elevation: 0,
        child: InkWell(
          onTap: () => _selectPlan(0),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    AppTheme.purple.withOpacity(0.05),
                    AppTheme.deepPurple.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.purpleToDeepPurple,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Single Day',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppTheme.orange.withOpacity(0.5),
                              ),
                            ),
                            child: Text(
                              'EXPRESS',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '1 Day • 1 meal',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppTheme.textMedium,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${widget.totalMealCost.toStringAsFixed(0)}',
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
          ),
        ),
      ),
    );
  }

  void _navigateToOrderSummary(BuildContext context) {
    log("endDate: $_endDate");
    log("startDate: $_startDate");
    log("mealDates: $_mealDates");
    log("selectedWeekdays: $_selectedWeekdays");
    log("selectedPlanIndex: $_selectedPlanIndex");
    log("isCustomPlan: $_isCustomPlan");
    log("isExpressOrder: ${widget.isExpressOrder}");

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ManageStudentProfileScreen(
          planType: _subscriptionPlans[_selectedPlanIndex]['name'],
          isCustomPlan: _isCustomPlan,
          selectedWeekdays: _selectedWeekdays,
          startDate: _startDate,
          endDate: _endDate!,
          mealDates: _mealDates,
          totalAmount: _calculatePrice(),
          selectedMeals: widget.selectedMeals,
          isExpressOrder: widget.isExpressOrder,
          mealType: widget.mealType,
        ),
      ),
    );
  }

  // Helper method to build calendar legend item
  Widget _buildCalendarLegendItem(
    String label,
    Color color, {
    Color? backgroundColor,
    bool hasBorder = false,
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: hasBorder
            ? Border.all(
                color: borderColor ?? color.withOpacity(0.3),
                width: 1,
              )
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced summary row with icon and modern styling
  Widget _buildEnhancedSummaryRow(
    String label,
    String value,
    IconData icon, {
    TextStyle? valueStyle,
    bool showIcon = true,
    bool isMultiline = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment:
            isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          if (showIcon) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 16,
                color: AppTheme.purple,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textDark,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: isMultiline
                ? Tooltip(
                    message: value,
                    waitDuration: const Duration(milliseconds: 500),
                    showDuration: const Duration(seconds: 2),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.purple.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    child: Text(
                      value,
                      style: valueStyle ??
                          GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textDark,
                          ),
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  )
                : Text(
                    value,
                    style: valueStyle ??
                        GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textDark,
                        ),
                    textAlign: TextAlign.right,
                  ),
          ),
        ],
      ),
    );
  }

  // Special builder for Selected Days row to handle potential overflow
  Widget _buildSelectedDaysRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textMedium,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Tooltip(
              message: value, // Show full text in tooltip
              waitDuration: const Duration(milliseconds: 500),
              showDuration: const Duration(seconds: 2),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.purple.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
              ),
              child: Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.textDark,
                ),
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableMealScheduleCard() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with icon, title and arrow
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _isMealScheduleExpanded = !_isMealScheduleExpanded;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _isMealScheduleExpanded
                        ? AppTheme.purple.withOpacity(0.3)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: _isMealScheduleExpanded
                      ? AppTheme.purple.withOpacity(0.03)
                      : Colors.transparent,
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.calendar_month_rounded,
                        color: AppTheme.purple,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Meal Schedule',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (!(_subscriptionPlans[_selectedPlanIndex]
                                  ['isSingleDay'] ??
                              false))
                            Text(
                              _isCustomPlan
                                  ? 'Delivery Days: ${_getSelectedWeekdaysText()}'
                                  : 'Delivery Days: Monday to Friday',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: AppTheme.textMedium,
                              ),
                            ),
                          if (!_isMealScheduleExpanded)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.touch_app,
                                    size: 14,
                                    color: AppTheme.purple.withOpacity(0.7),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Tap to view calendar',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: AppTheme.purple.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _isMealScheduleExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _isMealScheduleExpanded
                              ? AppTheme.purple.withOpacity(0.1)
                              : Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: _isMealScheduleExpanded
                              ? AppTheme.purple
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Animated container for expanding/collapsing content
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _isMealScheduleExpanded
                  ? Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: AppTheme.purple.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                      ),
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.only(left: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          // Calendar
                          Container(
                            constraints: BoxConstraints(
                              maxHeight:
                                  MediaQuery.of(context).size.width * 0.9,
                            ),
                            child: TableCalendar(
                              firstDay: _firstAvailableDate,
                              lastDay:
                                  DateTime.now().add(const Duration(days: 365)),
                              focusedDay: _ensureValidFocusedDay(),
                              calendarFormat: _calendarFormat,
                              startingDayOfWeek: StartingDayOfWeek.monday,
                              availableCalendarFormats: const {
                                CalendarFormat.month: 'Month',
                                CalendarFormat.twoWeeks: '2 Weeks',
                              },
                              onFormatChanged: (format) {
                                setState(() {
                                  _calendarFormat = format;
                                });
                              },
                              onPageChanged: (focusedDay) {
                                setState(() {
                                  _focusedCalendarDate = focusedDay;
                                });
                              },
                              // Disable day selection for express orders
                              onDaySelected:
                                  widget.isExpressOrder ? null : _onDaySelected,
                              eventLoader: (day) {
                                // Return a list with 1 item if the day has a meal, empty list otherwise
                                return _hasMealOnDate(day) ? [day] : [];
                              },
                              // Customize the appearance of calendar days
                              calendarStyle: CalendarStyle(
                                markersMaxCount: 1,
                                markerSize: 8,
                                markerDecoration: BoxDecoration(
                                  color: AppTheme.purple,
                                  shape: BoxShape.circle,
                                ),
                                weekendTextStyle: GoogleFonts.poppins(
                                  color: Colors.grey.shade600,
                                ),
                                outsideTextStyle: GoogleFonts.poppins(
                                  color: Colors.grey.shade400,
                                ),
                                disabledTextStyle: GoogleFonts.poppins(
                                  color: Colors.grey.shade400,
                                ),
                                // Style for the selected dates - using minimal styling to be enhanced with marker
                                selectedDecoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.transparent,
                                ),
                                selectedTextStyle: GoogleFonts.poppins(
                                  color: AppTheme.textDark,
                                  fontWeight: FontWeight.w600,
                                ),
                                // Style for today's date
                                todayDecoration: BoxDecoration(
                                  color: AppTheme.purple.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.purple.withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                todayTextStyle: GoogleFonts.poppins(
                                  color: AppTheme.purple,
                                  fontWeight: FontWeight.w600,
                                ),
                                // Default day cell style
                                defaultDecoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                ),
                                // Highlighted weekends
                                weekendDecoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey.shade50,
                                ),
                                // Add proper cell margin to avoid overflow
                                cellPadding: const EdgeInsets.all(6),
                                cellMargin: const EdgeInsets.all(4),
                              ),
                              // Header styling
                              headerStyle: HeaderStyle(
                                titleCentered: true,
                                formatButtonVisible: true,
                                formatButtonDecoration: BoxDecoration(
                                  color: AppTheme.purple.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                formatButtonTextStyle: GoogleFonts.poppins(
                                  color: AppTheme.purple,
                                  fontWeight: FontWeight.w500,
                                ),
                                titleTextStyle: GoogleFonts.poppins(
                                  color: AppTheme.textDark,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                leftChevronIcon: Icon(
                                  Icons.chevron_left,
                                  color: AppTheme.purple,
                                ),
                                rightChevronIcon: Icon(
                                  Icons.chevron_right,
                                  color: AppTheme.purple,
                                ),
                                headerPadding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                // Make sure the day of week headers are visible
                                headerMargin: const EdgeInsets.only(bottom: 8),
                              ),
                              // Specify which days are enabled
                              enabledDayPredicate: (day) {
                                // For express orders, only enable the selected day and disable all others
                                if (widget.isExpressOrder) {
                                  return day.year == _startDate.year &&
                                      day.month == _startDate.month &&
                                      day.day == _startDate.day;
                                }
                                // For regular orders, only enable weekdays
                                return day.weekday <= 5;
                              },
                              // Highlight the selected weekdays in the calendar
                              selectedDayPredicate: (day) {
                                return _hasMealOnDate(day);
                              },
                              calendarBuilders: CalendarBuilders(
                                // Custom marker builder for selected days - small dot under the date
                                markerBuilder: (context, date, events) {
                                  if (events.isEmpty) return null;

                                  return Container(
                                    margin: const EdgeInsets.only(top: 6),
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppTheme.purple,
                                    ),
                                  );
                                },
                                // Custom builder for day of week labels
                                dowBuilder: (context, day) {
                                  final weekdayNames = [
                                    'M',
                                    'T',
                                    'W',
                                    'T',
                                    'F',
                                    'S',
                                    'S'
                                  ];
                                  final idx = day.weekday -
                                      1; // 0-indexed (0 = Monday, 6 = Sunday)

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 4),
                                    height: 30,
                                    padding: const EdgeInsets.only(bottom: 4),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.grey.shade200,
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      weekdayNames[idx],
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: day.weekday >= 6
                                            ? AppTheme.error.withOpacity(0.7)
                                            : AppTheme.purple,
                                      ),
                                    ),
                                  );
                                },
                                // Override the selected day to have a custom appearance (no background, just text highlight)
                                selectedBuilder: (context, date, _) {
                                  return Container(
                                    margin: const EdgeInsets.all(4),
                                    alignment: Alignment.center,
                                    child: Text(
                                      date.day.toString(),
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.purple,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              // Prevent overflow by allowing the calendar to fit the container
                              daysOfWeekHeight: 32,
                              rowHeight: 52,
                            ),
                          ),
                          // Calendar legend/hint
                          Padding(
                            padding:
                                const EdgeInsets.only(top: 16.0, bottom: 8),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline,
                                    size: 16, color: AppTheme.textMedium),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Dots indicate days with scheduled meal deliveries',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic,
                                      color: AppTheme.textMedium,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(),
            ),
          ),
        ],
      ),
    );
  }
}
