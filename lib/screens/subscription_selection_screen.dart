import 'dart:developer';

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
    this.initialPlanIndex = 1, // Default to Weekly plan
    this.isExpressOrder = false,
    this.mealType = 'lunch', // Default to lunch if not specified
  }) : super(key: key);

  @override
  State<SubscriptionSelectionScreen> createState() =>
      _SubscriptionSelectionScreenState();
}

class _SubscriptionSelectionScreenState
    extends State<SubscriptionSelectionScreen> {
  // Plan selection
  int _selectedPlanIndex = 0;
  bool _isCustomPlan = false;

  // Custom weekdays selection (Monday to Friday)
  final List<bool> _selectedWeekdays = [true, true, true, true, true];
  final List<String> _weekdayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday'
  ];

  // Calendar
  late DateTime _startDate;
  late DateTime _firstAvailableDate;
  DateTime? _endDate;

  // Smart calendar data
  List<DateTime> _mealDates = [];
  DateTime? _focusedCalendarDate;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // Subscription plans data
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
      'meals': 120,
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

    // Set selected plan from initialPlanIndex
    _selectedPlanIndex = widget.initialPlanIndex;

    // For express orders, we want to force Single Day plan
    if (widget.isExpressOrder) {
      _selectedPlanIndex = 0; // Single Day plan
      _isCustomPlan = false; // Regular plan mode
    }

    // Set first available date - ensure it's not later than today for express orders
    final now = DateTime.now();

    // For express orders, handle the date constraints differently
    if (widget.isExpressOrder) {
      final bool isExpressWindowOpen = isWithinExpressWindow();

      // If express window is open (before 8 AM), allow today's date, otherwise tomorrow
      if (isExpressWindowOpen && now.weekday <= 5) {
        _firstAvailableDate = DateTime(now.year, now.month, now.day);
        _startDate = _firstAvailableDate;
      } else {
        // Next weekday for delivery
        _firstAvailableDate = _getNextWeekday(now);
        _startDate = _firstAvailableDate;
      }
    } else {
      // Normal flow for non-express orders
      _firstAvailableDate = _getNextWeekday(now);
      _startDate = _firstAvailableDate;
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

    // For express orders, just add the start date (today or next available day)
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

        // If switching to regular mode, recalculate dates
        if (!_isCustomPlan) {
          _startDate = _firstAvailableDate;
        } else {
          // If switching to custom mode, update start date
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
      appBar: AppBar(
        title: Text(
          'Subscription Plan',
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

              // Plan selection cards
              ...(widget.isExpressOrder
                  ? [
                      _buildExpressOnlyPlanCard()
                    ] // Show only Single Day plan for Express
                  : _subscriptionPlans.asMap().entries.map((entry) {
                      final index = entry.key;
                      final plan = entry.value;
                      final hasDiscount = plan['discount'] > 0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: _selectedPlanIndex == index
                                ? AppTheme.purple
                                : Colors.grey.shade300,
                            width: _selectedPlanIndex == index ? 2 : 1,
                          ),
                        ),
                        child: InkWell(
                          onTap: () => _selectPlan(index),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Radio<int>(
                                  value: index,
                                  groupValue: _selectedPlanIndex,
                                  activeColor: AppTheme.purple,
                                  onChanged: (value) => _selectPlan(value!),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            plan['name'],
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.textDark,
                                            ),
                                          ),
                                          if (hasDiscount)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppTheme.purple
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                    color: AppTheme.purple
                                                        .withOpacity(0.5)),
                                              ),
                                              child: Text(
                                                '${(plan['discount'] * 100).toInt()}% OFF',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.purple,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${plan['duration']} • ${plan['meals']} meals',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: AppTheme.textMedium,
                                        ),
                                      ),
                                      if (plan['isSingleDay'] ?? false)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4.0),
                                          child: Text(
                                            'Get your meal delivered on a selected weekday.',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: AppTheme.textMedium,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          if (hasDiscount)
                                            Text(
                                              '₹${(widget.totalMealCost * plan['meals']).toStringAsFixed(0)}',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                decoration:
                                                    TextDecoration.lineThrough,
                                                color: AppTheme.textMedium,
                                              ),
                                            ),
                                          if (hasDiscount)
                                            const SizedBox(width: 8),
                                          Text(
                                            '₹${(widget.totalMealCost * plan['meals'] * (1 - plan['discount'])).toStringAsFixed(0)}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: hasDiscount
                                                  ? Colors.green
                                                  : AppTheme.textDark,
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
                        ),
                      );
                    }).toList()),

              const SizedBox(height: 24),

              // Plan mode selection
              if (!widget.isExpressOrder)
                Text(
                  "Choose Delivery Mode",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),

              if (!widget.isExpressOrder) const SizedBox(height: 12),

              // Regular vs Custom toggle
              Visibility(
                visible: !(_subscriptionPlans[_selectedPlanIndex]
                            ['isSingleDay'] ??
                        false) &&
                    !widget.isExpressOrder,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _toggleCustomMode(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !_isCustomPlan
                                    ? AppTheme.purple
                                    : Colors.white,
                                borderRadius: const BorderRadius.horizontal(
                                  left: Radius.circular(8),
                                ),
                                border: Border.all(
                                  color: !_isCustomPlan
                                      ? AppTheme.purple
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Regular Plan',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: !_isCustomPlan
                                        ? Colors.white
                                        : AppTheme.textMedium,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _toggleCustomMode(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _isCustomPlan
                                    ? AppTheme.purple
                                    : Colors.white,
                                borderRadius: const BorderRadius.horizontal(
                                  right: Radius.circular(8),
                                ),
                                border: Border.all(
                                  color: _isCustomPlan
                                      ? AppTheme.purple
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Custom Plan',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: _isCustomPlan
                                        ? Colors.white
                                        : AppTheme.textMedium,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
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

              // Weekday selection for custom plan
              if (_isCustomPlan)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Select Weekdays for Delivery",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InfoBanner(
                      title: "Custom Plan",
                      message:
                          "Select at least one weekday for meal delivery. The start date will be calculated based on the earliest selected weekday.",
                      type: InfoBannerType.info,
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

                        return FilterChip(
                          label: Text(
                            day,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color:
                                  isSelected ? Colors.white : AppTheme.textDark,
                            ),
                          ),
                          selected: isSelected,
                          showCheckmark: false,
                          backgroundColor: Colors.grey.shade100,
                          selectedColor: AppTheme.purple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? AppTheme.purple
                                  : Colors.grey.shade400,
                              width: 1,
                            ),
                          ),
                          onSelected: (bool selected) => _toggleWeekday(index),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // Start date display (custom plan version)
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: AppTheme.purple.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      color: AppTheme.purple.withOpacity(0.05),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.event_available,
                              color: _selectedWeekdays.contains(true)
                                  ? AppTheme.purple
                                  : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedWeekdays.contains(true)
                                    ? "Start Date: ${_getFormattedStartDate()}"
                                    : "Please select at least one weekday",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: _selectedWeekdays.contains(true)
                                      ? AppTheme.textDark
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 24),

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

              // Start date display
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start Date',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 20,
                            color: widget.isExpressOrder
                                ? Colors.grey
                                : AppTheme.purple,
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              if (widget.isExpressOrder)
                                Text(
                                  'Start date is locked for same-day express delivery',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.orange,
                                  ),
                                ),
                              if (_isCustomPlan &&
                                  !_selectedWeekdays
                                      .where((day) => day)
                                      .isEmpty)
                                Text(
                                  'Based on earliest selected weekday',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: AppTheme.purple,
                                  ),
                                ),
                            ],
                          ),
                          const Spacer(),
                          Visibility(
                            visible: !widget.isExpressOrder,
                            child: TextButton(
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
                              child: Text(
                                'Change',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.purple,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // End date display
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'End Date',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.event_available,
                            size: 20,
                            color: AppTheme.purple,
                          ),
                          const SizedBox(width: 8),
                          if (_endDate != null)
                            Text(
                              DateFormat('EEEE, MMMM d, yyyy')
                                  .format(_endDate!),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: AppTheme.textDark,
                              ),
                            )
                          else
                            Text(
                              'Please select at least one weekday',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.red,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Calendar view with meal dates
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Meal Schedule',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                          ),
                          Text(
                            _subscriptionPlans[_selectedPlanIndex]
                                        ['isSingleDay'] ??
                                    false
                                ? '1 meal on selected date'
                                : '${_mealDates.length} meals scheduled',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: AppTheme.purple,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Calendar showing meal dates
                      TableCalendar(
                        firstDay: _firstAvailableDate,
                        lastDay: DateTime.now().add(const Duration(days: 365)),
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
                        onDaySelected: _onDaySelected,
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
                          weekendTextStyle: const TextStyle(color: Colors.grey),
                          outsideTextStyle: const TextStyle(color: Colors.grey),
                          disabledTextStyle:
                              const TextStyle(color: Colors.grey),
                        ),
                        // Specify which days are enabled
                        enabledDayPredicate: (day) {
                          // For express orders, only enable today or next day depending on express window
                          if (widget.isExpressOrder) {
                            final bool isExpressWindowOpen =
                                isWithinExpressWindow();
                            // If in express window, allow today, otherwise only allow future days
                            return isExpressWindowOpen
                                ? day.isAfter(DateTime.now()
                                        .subtract(const Duration(days: 1))) &&
                                    day.weekday <= 5
                                : day.isAfter(DateTime.now()) &&
                                    day.weekday <= 5;
                          }
                          // For regular orders, only enable weekdays
                          return day.weekday <= 5;
                        },
                        // Highlight the selected weekdays in the calendar
                        selectedDayPredicate: (day) {
                          return _hasMealOnDate(day);
                        },
                      ),

                      const SizedBox(height: 16),

                      // Legend for calendar
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppTheme.purple,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Meal Delivery Days',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppTheme.textMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Selected days pattern display
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weekly Pattern',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildWeekdayCircle('M', _selectedWeekdays[0]),
                          _buildWeekdayCircle('T', _selectedWeekdays[1]),
                          _buildWeekdayCircle('W', _selectedWeekdays[2]),
                          _buildWeekdayCircle('T', _selectedWeekdays[3]),
                          _buildWeekdayCircle('F', _selectedWeekdays[4]),
                          _buildWeekdayCircle('S', false, disabled: true),
                          _buildWeekdayCircle('S', false, disabled: true),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Upcoming Meal Preview Section
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upcoming Meal',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._getUpcomingMealDates()
                          .map((date) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('EEE dd, MMM yyyy').format(date),
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const VegIcon(),
                                      const SizedBox(width: 4),
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
                                  const SizedBox(height: 12),
                                ],
                              ))
                          .toList(),
                      // Show message if no upcoming meals (for custom plan with no weekdays selected)
                      if (_getUpcomingMealDates().isEmpty)
                        Text(
                          'No upcoming meals. Please select at least one weekday.',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Order summary
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Summary',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSummaryRow(
                          'Plan Type',
                          _subscriptionPlans[_selectedPlanIndex]['name'] +
                              (_isCustomPlan ? ' (Custom)' : ' (Regular)')),
                      _buildSummaryRow('Duration',
                          _subscriptionPlans[_selectedPlanIndex]['duration']),
                      if (_isCustomPlan)
                        _buildSummaryRow(
                          'Selected Days',
                          _getSelectedWeekdaysText(),
                        ),
                      _buildSummaryRow('Total Meals',
                          '${_mealDates.length} of ${_subscriptionPlans[_selectedPlanIndex]['meals']}'),
                      _buildSummaryRow(
                          'Start Date',
                          _isCustomPlan
                              ? (_selectedWeekdays.where((day) => day).isEmpty
                                  ? "No weekdays selected"
                                  : _getFormattedStartDate())
                              : DateFormat('MMM d, yyyy').format(_startDate)),
                      if (_endDate != null)
                        _buildSummaryRow('End Date',
                            DateFormat('MMM d, yyyy').format(_endDate!)),
                      const Divider(height: 32),
                      if (hasDiscount)
                        _buildSummaryRow(
                          'Subtotal',
                          '₹${_calculateOriginalPrice().toStringAsFixed(0)}',
                          valueStyle: GoogleFonts.poppins(
                            fontSize: 14,
                            decoration: TextDecoration.lineThrough,
                            color: AppTheme.textMedium,
                          ),
                        ),
                      if (hasDiscount)
                        _buildSummaryRow(
                          'Discount (${(_subscriptionPlans[_selectedPlanIndex]['discount'] * 100).toInt()}%)',
                          '-₹${_getSavings().toStringAsFixed(0)}',
                          valueStyle: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      _buildSummaryRow(
                        'Total Amount',
                        '₹${_calculatePrice().toStringAsFixed(0)}',
                        valueStyle: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.purple,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Proceed to payment button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _endDate == null ||
                          (widget.isExpressOrder &&
                              !MealPlanValidator.isWithinExpressWindow())
                      ? null
                      : () {
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
                                planType: _subscriptionPlans[_selectedPlanIndex]
                                    ['name'],
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
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        widget.isExpressOrder ? Colors.orange : AppTheme.purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    widget.isExpressOrder
                        ? 'Confirm Express Order'
                        : 'Continue',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
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

  Widget _buildWeekdayCircle(String day, bool isSelected,
      {bool disabled = false}) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: disabled
            ? Colors.grey.shade200
            : (isSelected ? AppTheme.purple : Colors.white),
        border: Border.all(
          color: disabled
              ? Colors.grey.shade300
              : (isSelected ? AppTheme.purple : Colors.grey.shade300),
        ),
      ),
      child: Center(
        child: Text(
          day,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: disabled
                ? Colors.grey.shade400
                : (isSelected ? Colors.white : AppTheme.textMedium),
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
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textMedium,
            ),
          ),
          Text(
            value,
            style: valueStyle ??
                GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.textDark,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpressOnlyPlanCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color:
              _selectedPlanIndex == 0 ? AppTheme.purple : Colors.grey.shade300,
          width: _selectedPlanIndex == 0 ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => _selectPlan(0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Radio<int>(
                value: 0,
                groupValue: _selectedPlanIndex,
                activeColor: AppTheme.purple,
                onChanged: (value) => _selectPlan(value!),
              ),
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
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '1 Day • 1 meal',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppTheme.textMedium,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '₹${widget.totalMealCost.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
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
      ),
    );
  }
}
