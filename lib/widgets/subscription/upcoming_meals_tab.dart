import 'dart:developer';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/services/meal_service.dart';
import 'package:startwell/services/student_profile_service.dart';
import 'package:startwell/services/subscription_service.dart' as service;
import 'package:startwell/models/student_model.dart';
import 'package:startwell/models/subscription_model.dart';
import 'package:startwell/models/cancelled_meal.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:startwell/screens/my_subscription_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpcomingMealsTab extends StatefulWidget {
  final String? selectedStudentId;
  final DateTime? startDate;
  final DateTime? endDate;

  const UpcomingMealsTab({
    Key? key,
    this.selectedStudentId,
    this.startDate,
    this.endDate,
  }) : super(key: key);

  @override
  State<UpcomingMealsTab> createState() => _UpcomingMealsTabState();
}

class MealData {
  final String studentName;
  final String name;
  final String planType;
  final List<String> items;
  final String studentId;
  final String subscriptionId;
  String status;
  final Subscription subscription;
  final bool canSwap;
  final DateTime date;

  MealData({
    required this.studentName,
    required this.name,
    required this.planType,
    required this.items,
    required this.status,
    required this.subscription,
    required this.canSwap,
    required this.date,
    required this.studentId,
    required this.subscriptionId,
  });

  bool get isExpressPlan => subscription.planType == 'express';

  @override
  String toString() {
    return 'MealData(student: $studentName, meal: $name, type: $planType, status: $status, date: ${DateFormat('yyyy-MM-dd').format(date)}, canSwap: $canSwap)';
  }
}

class _UpcomingMealsTabState extends State<UpcomingMealsTab> {
  bool _isCalendarView = false;
  bool _isLoading = true;
  final MealService _mealService = MealService();
  final StudentProfileService _studentProfileService = StudentProfileService();
  final service.SubscriptionService _subscriptionService =
      service.SubscriptionService();

  List<Subscription> _activeSubscriptions = [];
  String? _selectedStudentId;
  List<Student> _studentsWithMealPlans = [];
  List<Map<String, dynamic>> _allScheduledMeals = [];

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, List<MealData>> _mealsMap = {};
  List<MealData> _selectedDateMeals = [];

  // Add a loading flag for SwapMeal operations
  bool _isSwapLoading = false;

  @override
  void initState() {
    super.initState();
    // Only call _loadData() which handles both loading subscriptions and applying local swaps
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadStudentsWithMealPlans();
    // We're now applying local swaps in _generateMealMap after the meal map is fully populated
    // so we don't need to call it here
  }

  // Method to apply locally swapped meals
  Future<void> _applyLocalSwappedMeals() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get all keys that start with swappedMeal_
      final keys = prefs
          .getKeys()
          .where((key) => key.startsWith('swappedMeal_'))
          .toList();

      if (keys.isEmpty) {
        return;
      }

      log('[swap_meal_flow] Found ${keys.length} locally swapped meals');

      // Apply each swapped meal to the UI
      for (final key in keys) {
        final swappedJson = prefs.getString(key);
        if (swappedJson != null) {
          final swappedData = jsonDecode(swappedJson);

          // Extract important information
          final String subscriptionId = swappedData['subscriptionId'];
          final String newMealName = swappedData['newMealName'];
          final DateTime date = DateTime.parse(swappedData['date']);

          // Update in memory meals map
          _updateMealFromLocalStorage(subscriptionId, newMealName, date);
        }
      }

      // Update UI if needed
      if (mounted) {
        setState(() {
          _updateSelectedDayMeals();
        });
      }
    } catch (e) {
      log('[swap_meal_flow] Error applying local swapped meals: $e');
    }
  }

  // Helper to update meals from local storage
  void _updateMealFromLocalStorage(
      String subscriptionId, String newMealName, DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);

    log('[swap_meal_flow] Attempting to apply local swap: subscriptionId=$subscriptionId, newMealName=$newMealName, date=${DateFormat('yyyy-MM-dd').format(normalizedDate)}');

    if (_mealsMap.containsKey(normalizedDate)) {
      final meals = _mealsMap[normalizedDate]!;
      log('[swap_meal_flow] Found ${meals.length} meals for this date');

      for (int i = 0; i < meals.length; i++) {
        if (meals[i].subscriptionId == subscriptionId) {
          log('[swap_meal_flow] Found matching meal to update: ${meals[i].name} -> $newMealName');

          final updatedMeal = MealData(
            studentName: meals[i].studentName,
            name: newMealName,
            planType: meals[i].planType,
            items: meals[i].items,
            status: 'Swapped',
            subscription: meals[i].subscription,
            canSwap: meals[i].canSwap,
            date: meals[i].date,
            studentId: meals[i].studentId,
            subscriptionId: meals[i].subscriptionId,
          );

          meals[i] = updatedMeal;
          log('[swap_meal_flow] Successfully updated meal in memory');
          break;
        }
      }
    } else {
      log('[swap_meal_flow] No meals found for date ${DateFormat('yyyy-MM-dd').format(normalizedDate)}');
    }
  }

  DateTime _getEarliestSubscriptionStartDate() {
    if (_activeSubscriptions.isEmpty) {
      return DateTime.now();
    }

    DateTime earliestDate = _activeSubscriptions.first.startDate;
    for (final subscription in _activeSubscriptions) {
      if (subscription.startDate.isBefore(earliestDate)) {
        earliestDate = subscription.startDate;
      }
    }

    final today = DateTime.now();
    if (earliestDate.isBefore(today)) {
      return today;
    }

    return earliestDate;
  }

  DateTime _getLatestSubscriptionEndDate() {
    if (_activeSubscriptions.isEmpty) {
      return DateTime.now().add(const Duration(days: 365));
    }

    DateTime latestDate = _activeSubscriptions.first.endDate;
    for (final subscription in _activeSubscriptions) {
      if (subscription.endDate.isAfter(latestDate)) {
        latestDate = subscription.endDate;
      }
    }

    return latestDate.add(const Duration(days: 30));
  }

  void _ensureValidFocusedDay() {
    final DateTime firstDay = _getEarliestSubscriptionStartDate();
    final DateTime lastDay = _getLatestSubscriptionEndDate();

    if (_focusedDay.isBefore(firstDay)) {
      _focusedDay = firstDay;
    }

    if (_focusedDay.isAfter(lastDay)) {
      _focusedDay = lastDay;
    }

    if (_selectedDay.isBefore(firstDay) || _selectedDay.isAfter(lastDay)) {
      _selectedDay = _focusedDay;
    }
  }

  Future<void> _loadStudentsWithMealPlans() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final List<String> studentIds =
          await _mealService.getStudentsWithMealPlans();
      final List<Student> students =
          await _studentProfileService.getStudentProfiles();

      _studentsWithMealPlans =
          students.where((student) => studentIds.contains(student.id)).toList();

      if (_studentsWithMealPlans.isNotEmpty) {
        if (widget.selectedStudentId != null &&
            _studentsWithMealPlans
                .any((s) => s.id == widget.selectedStudentId)) {
          _selectedStudentId = widget.selectedStudentId;
        } else {
          _selectedStudentId = _studentsWithMealPlans.first.id;
        }

        await _loadSubscriptionsForStudent(_selectedStudentId!,
            skipCancelled: true);
      } else {
        _activeSubscriptions = [];
      }
    } catch (e) {
      log('Error loading students with meal plans: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSubscriptionsForStudent(String studentId,
      {bool skipCancelled = false}) async {
    try {
      // Create a temporary SubscriptionService from the model
      final modelService = SubscriptionService();

      _activeSubscriptions =
          await modelService.getActiveSubscriptionsForStudent(studentId);

      _generateMealMap();
      _updateSelectedDayMeals();
    } catch (e) {
      log('Error loading subscriptions: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _generateMealMap() {
    log('[cancel_meal_flow] Generating meal map for student: $_selectedStudentId');
    _mealsMap = {};
    int totalMealsAdded = 0;

    if (_activeSubscriptions.isEmpty) {
      log('[cancel_meal_flow] No active subscriptions found, skipping meal map generation');
      return;
    }

    // Pre-fetch cancellation data to avoid multiple queries
    _subscriptionService
        .getCancelledMeals(_selectedStudentId)
        .then((cancelledMeals) {
      log('[cancel_meal_flow] Fetched ${cancelledMeals.length} cancelled meals for filtering');

      setState(() {
        for (final subscription in _activeSubscriptions) {
          final student = _studentsWithMealPlans.firstWhere(
            (s) => s.id == subscription.studentId,
            orElse: () => _studentsWithMealPlans.first,
          );

          log('[cancel_meal_flow] Processing subscription ${subscription.id} for student ${student.name}');

          // Get scheduled dates for this subscription
          final List<DateTime> scheduledDates = _generateScheduleDates(
            subscription.startDate,
            subscription.endDate,
            subscription.selectedWeekdays,
            subscription.planType,
          );

          log('[cancel_meal_flow] Generated ${scheduledDates.length} scheduled dates for subscription');

          int mealsAddedForThisSubscription = 0;
          for (final date in scheduledDates) {
            final normalized = DateTime(date.year, date.month, date.day);

            // Skip past dates except for express plans
            if (normalized.isBefore(DateTime.now()) &&
                !normalized.isAtSameMomentAs(DateTime.now()) &&
                subscription.planType != 'express') {
              continue;
            }

            // Check if the meal is cancelled, but don't skip it
            bool isCancelled = cancelledMeals.any((meal) =>
                meal.subscriptionId == subscription.id &&
                meal.cancellationDate.year == normalized.year &&
                meal.cancellationDate.month == normalized.month &&
                meal.cancellationDate.day == normalized.day);

            final bool canSwap = _isSwapAllowed(date, subscription.planType);

            final mealData = MealData(
              studentName: student.name,
              name: subscription.getMealNameForDate(date),
              planType: _getFormattedPlanType(subscription),
              items: subscription.getMealItems(),
              status: isCancelled
                  ? "Cancelled"
                  : (subscription.getMealNameForDate(date) !=
                          subscription.mealName
                      ? "Swapped"
                      : "Scheduled"),
              subscription: subscription,
              canSwap: canSwap && !isCancelled, // Can't swap if cancelled
              date: date,
              studentId: student.id,
              subscriptionId: subscription.id,
            );

            if (isCancelled) {
              log('[cancel_meal_flow] Including cancelled meal in UI with cancelled status: ${DateFormat('yyyy-MM-dd').format(date)}');
            }

            final dateMealList = _mealsMap[normalized] ?? [];
            dateMealList.add(mealData);
            _mealsMap[normalized] = dateMealList;
            mealsAddedForThisSubscription++;
          }

          totalMealsAdded += mealsAddedForThisSubscription;
          log('[cancel_meal_flow] Added $mealsAddedForThisSubscription meals for this subscription');
        }

        // Now apply local swapped meals after generating the entire meal map
        _applyLocalSwappedMeals().then((_) {
          // Update selected date meals if necessary
          if (_mealsMap.containsKey(_selectedDay)) {
            _selectedDateMeals = _mealsMap[_selectedDay] ?? [];
          } else {
            _selectedDateMeals = [];
          }

          log('[cancel_meal_flow] Finished generating meal map, added $totalMealsAdded total meals');
          log('[cancel_meal_flow] Selected day (${DateFormat('yyyy-MM-dd').format(_selectedDay)}) has ${_selectedDateMeals.length} meals');
        });
      });
    });
  }

  List<DateTime> _generateScheduleDates(
    DateTime startDate,
    DateTime endDate,
    List<int> selectedWeekdays,
    String planType,
  ) {
    List<DateTime> scheduledDates = [];

    final int days = endDate.difference(startDate).inDays;

    List<int> weekdaysToInclude;
    if (selectedWeekdays.isEmpty) {
      weekdaysToInclude = [1, 2, 3, 4, 5];
    } else {
      weekdaysToInclude = selectedWeekdays;
    }

    for (int i = 0; i <= days; i++) {
      final DateTime date = startDate.add(Duration(days: i));

      if (!weekdaysToInclude.contains(date.weekday)) {
        continue;
      }

      scheduledDates.add(date);
    }

    return scheduledDates;
  }

  void _updateSelectedDayMeals() {
    final normalizedSelectedDay =
        DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    _selectedDateMeals = _mealsMap[normalizedSelectedDay] ?? [];
  }

  String _getFormattedPlanType(Subscription subscription) {
    bool isCustomPlan = subscription.selectedWeekdays.isNotEmpty &&
        subscription.selectedWeekdays.length < 5;
    String customBadge = isCustomPlan ? " (Custom)" : " (Regular)";

    if (subscription.planType == 'express') {
      return "Express 1-Day Lunch Plan";
    }

    if (subscription.endDate.difference(subscription.startDate).inDays <= 1) {
      return "Single Day ${subscription.planType == 'breakfast' ? 'Breakfast' : 'Lunch'} Plan";
    }

    String mealType =
        subscription.planType == 'breakfast' ? 'Breakfast' : 'Lunch';

    int days = subscription.endDate.difference(subscription.startDate).inDays;

    String planPeriod;
    if (days <= 7) {
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

    return "$planPeriod $mealType Plan$customBadge";
  }

  bool _isSwapAllowed(DateTime date, String planType) {
    if (planType == 'express') {
      return false;
    }

    final now = DateTime.now();
    final cutoffDate = DateTime(date.year, date.month, date.day, 23, 59)
        .subtract(const Duration(days: 1));

    return now.isBefore(cutoffDate);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_studentsWithMealPlans.isEmpty) {
      return const Center(
        child: Text('No students with meal plans found'),
      );
    }

    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: _isCalendarView ? _buildCalendarView() : _buildListView(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Student selector with nice styling
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedStudentId,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down),
                items: _studentsWithMealPlans.map((student) {
                  return DropdownMenuItem(
                    value: student.id,
                    child: Text(
                      student.name,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedStudentId = newValue;
                    });
                    _loadSubscriptionsForStudent(newValue, skipCancelled: true);
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // View toggle with better styling
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Upcoming Meals',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    // List view toggle
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isCalendarView = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: !_isCalendarView
                              ? Colors.blue
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.list,
                          color: !_isCalendarView ? Colors.white : Colors.grey,
                        ),
                      ),
                    ),
                    // Calendar view toggle
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isCalendarView = true;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _isCalendarView
                              ? Colors.blue
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.calendar_today,
                          color: _isCalendarView ? Colors.white : Colors.grey,
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
    );
  }

  Widget _buildCalendarView() {
    _ensureValidFocusedDay();

    // Wrap everything in a SingleChildScrollView for full scrollability
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Calendar component with event markers
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            elevation: 4,
            shadowColor: Colors.black.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: TableCalendar(
                firstDay: _getEarliestSubscriptionStartDate(),
                lastDay: _getLatestSubscriptionEndDate(),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                    _selectedDateMeals = _mealsMap[DateTime(selectedDay.year,
                            selectedDay.month, selectedDay.day)] ??
                        [];

                    print(
                        '[Calendar View] Selected date: ${DateFormat('yyyy-MM-dd').format(selectedDay)} - Found ${_selectedDateMeals.length} meals');
                    for (final meal in _selectedDateMeals) {
                      print(
                          '[Calendar View] Meal loaded for ${DateFormat('yyyy-MM-dd').format(selectedDay)} – ${meal.subscription.planType} (${meal.status})');
                    }
                  });
                },
                calendarFormat: CalendarFormat.month,
                startingDayOfWeek: StartingDayOfWeek.monday,
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  markerSize: 8,
                  markerDecoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  weekendTextStyle: GoogleFonts.poppins(
                    color: Colors.red.shade300,
                  ),
                  holidayTextStyle: GoogleFonts.poppins(
                    color: Colors.red.shade300,
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                  leftChevronIcon: Icon(
                    Icons.chevron_left,
                    color: Colors.grey.shade700,
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right,
                    color: Colors.grey.shade700,
                  ),
                  headerPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                  weekendStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    color: Colors.red.shade300,
                  ),
                ),
                // Event loader to display dots for meals
                eventLoader: (day) {
                  final normalizedDay = DateTime(day.year, day.month, day.day);
                  final events = _mealsMap[normalizedDay] ?? [];
                  return events;
                },
                // Custom marker builder for colored dots
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    if (events.isEmpty) return null;

                    return Positioned(
                      bottom: 1,
                      child: _buildCalendarMarker(events, date),
                    );
                  },
                ),
              ),
            ),
          ),

          // Legend for dot indicators
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Card(
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Meal Types:',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildLegendItem(
                            Colors.purple,
                            'Breakfast',
                          ),
                        ),
                        Expanded(
                          child: _buildLegendItem(
                            Colors.green,
                            'Lunch',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildLegendItem(
                            Colors.blue,
                            'Express 1-Day',
                          ),
                        ),
                        Expanded(
                          child: _buildLegendItem(
                            Colors.orange,
                            'Swapped',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildLegendItem(
                            Colors.red,
                            'Cancelled',
                          ),
                        ),
                        const Expanded(child: SizedBox()),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Meal cards for selected date
          _selectedDateMeals.isEmpty
              ? _buildNoMealsForSelectedDay()
              : _buildScrollableMealList(),
        ],
      ),
    );
  }

  // Build calendar marker with colored dots for meal types
  Widget _buildCalendarMarker(List<dynamic> events, DateTime date) {
    if (events.isEmpty) {
      return const SizedBox.shrink();
    }

    // Collect meal information for proper display
    bool hasBreakfast = false;
    bool hasLunch = false;
    bool hasExpress = false;
    bool hasSwapped = false;
    bool hasCancelled = false;

    log('[cancel_meal_flow] Building calendar marker for ${DateFormat('yyyy-MM-dd').format(date)} with ${events.length} events');

    // Process MealData objects
    for (final event in events) {
      if (event is MealData) {
        // Check if meal is cancelled
        if (event.status.toLowerCase() == 'cancelled') {
          hasCancelled = true;
        }
        // Skip other checks if cancelled
        else {
          // Check meal type
          if (event.planType.toLowerCase().contains('breakfast')) {
            hasBreakfast = true;
          } else if (event.subscription.planType == 'express') {
            hasExpress = true;
          } else {
            hasLunch = true;
          }

          // Check if meal is swapped
          if (event.status.toLowerCase() == 'swapped') {
            hasSwapped = true;
          }
        }
      }
    }

    // Build dots based on meal types
    List<Widget> dots = [];

    // Add cancelled meal marker (red dot) - priority over other statuses
    if (hasCancelled) {
      dots.add(
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red,
          ),
        ),
      );
    }

    // Add breakfast marker (purple dot)
    if (hasBreakfast) {
      dots.add(
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.purple,
          ),
        ),
      );
    }

    // Add lunch marker (green dot)
    if (hasLunch) {
      dots.add(
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.green,
          ),
        ),
      );
    }

    // Add express marker (blue dot)
    if (hasExpress) {
      dots.add(
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue,
          ),
        ),
      );
    }

    // Add swapped meal marker (orange dot)
    if (hasSwapped) {
      dots.add(
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.orange,
          ),
        ),
      );
    }

    // If we have too many dots, limit them
    if (dots.length > 3) {
      dots = dots.sublist(0, 3);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: dots,
    );
  }

  // Helper method to build status badge
  Widget _buildStatusBadge(String status, bool isCancelled) {
    Color bgColor = Colors.green.withOpacity(0.1);
    Color borderColor = Colors.green.withOpacity(0.5);
    Color textColor = Colors.green;

    if (isCancelled) {
      bgColor = Colors.red.withOpacity(0.1);
      borderColor = Colors.red.withOpacity(0.5);
      textColor = Colors.red;
      status = 'Cancelled';
    } else if (status == 'Swapped') {
      bgColor = Colors.orange.withOpacity(0.1);
      borderColor = Colors.orange.withOpacity(0.5);
      textColor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Text(
        status,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  // Helper to check if there are cancelled meals for a specific date
  Future<bool> _checkForCancelledMeals(DateTime date) async {
    // Normalize the date to avoid time issues
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedDateString =
        DateFormat('yyyy-MM-dd').format(normalizedDate);

    try {
      // Get cancelled meals for the selected student
      if (_selectedStudentId == null) {
        return false;
      }

      log('[cancel_meal_flow] Checking for cancelled meals on date: $normalizedDateString for student: $_selectedStudentId');

      // First check in SharedPreferences for any subscription cancellation on this date
      final prefs = await SharedPreferences.getInstance();

      // Since this method only checks if ANY meal is cancelled for the date (not a specific meal),
      // we need to check all active subscriptions
      for (var subscription in _activeSubscriptions) {
        final String key =
            'cancelledMeal_${_selectedStudentId}_${subscription.id}_$normalizedDateString';

        // Check if we have a cached cancellation status
        if (prefs.getBool(key) == true) {
          log('[cancel_meal_flow] Found cancelled meal in SharedPreferences: $key');
          return true;
        }
      }

      log('[cancel_meal_flow] No cancelled meal found in SharedPreferences, checking with service');

      // If not found in SharedPreferences, check with the service
      final List<CancelledMeal> cancelledMeals =
          await _subscriptionService.getCancelledMeals(_selectedStudentId);

      // Log the cancelled meals we found
      log('[cancel_meal_flow] Service returned ${cancelledMeals.length} cancelled meals for student: $_selectedStudentId');

      // Check if any cancelled meals match the given date
      for (var meal in cancelledMeals) {
        try {
          // Compare year, month, and day to check if this meal was cancelled on the given date
          final DateTime cancellationDate = meal.cancellationDate;
          if (cancellationDate.year == normalizedDate.year &&
              cancellationDate.month == normalizedDate.month &&
              cancellationDate.day == normalizedDate.day) {
            log('[cancel_meal_flow] Found cancelled meal for date: $normalizedDateString, meal: ${meal.mealName}, subscription: ${meal.subscriptionId}');

            // Store in SharedPreferences for future reference
            final String key =
                'cancelledMeal_${_selectedStudentId}_${meal.subscriptionId}_$normalizedDateString';
            await prefs.setBool(key, true);

            return true;
          }
        } catch (e) {
          log('[cancel_meal_flow] Error processing cancelled meal: $e');
          // Continue checking other meals even if one has an error
        }
      }

      return false;
    } catch (e) {
      log('[cancel_meal_flow] Error checking for cancelled meals: $e');
      return false;
    }
  }

  // Helper to build legend items
  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(
              color: Colors.white,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 2,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Widget for when no meals are available
  Widget _buildNoMealsForSelectedDay() {
    // Return a SizedBox with fixed height instead of filling parent
    return SizedBox(
      height: 200, // Reasonable minimum height
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.no_meals,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No meals scheduled for ${DateFormat('EEE, MMM d').format(_selectedDay)}',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // New method to build scrollable meal list without Expanded
  Widget _buildScrollableMealList() {
    // Sort meals by type - breakfast first, then lunch
    final sortedMeals = List<MealData>.from(_selectedDateMeals)
      ..sort((a, b) {
        if (a.subscription.planType == 'breakfast' &&
            b.subscription.planType != 'breakfast') {
          return -1;
        } else if (a.subscription.planType != 'breakfast' &&
            b.subscription.planType == 'breakfast') {
          return 1;
        }
        return 0;
      });

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header for selected date
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                'Meals for ${DateFormat('EEE, MMM d').format(_selectedDay)}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${sortedMeals.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.purple,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Meal cards list - use ListView.builder with shrinkWrap for proper scrolling
        ListView.builder(
          itemCount: sortedMeals.length,
          shrinkWrap: true, // Important: Allows list to take only needed space
          physics:
              const NeverScrollableScrollPhysics(), // Disables its own scrolling
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemBuilder: (context, index) {
            final meal = sortedMeals[index];
            final bool isBreakfast = meal.subscription.planType == 'breakfast';
            final bool isCancelled = meal.status == "Cancelled";

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row with meal type icon and status badge
                    Row(
                      children: [
                        // Meal type icon
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isBreakfast
                                ? Colors.purple.withOpacity(0.1)
                                : meal.subscription.planType == 'express'
                                    ? Colors.blue.withOpacity(0.1)
                                    : Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isBreakfast
                                ? Icons.free_breakfast
                                : Icons.lunch_dining,
                            color: isBreakfast
                                ? Colors.purple
                                : meal.subscription.planType == 'express'
                                    ? Colors.blue
                                    : Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Meal name and student
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                meal.name,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                meal.studentName,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Status badge
                        _buildStatusBadge(meal.status, isCancelled),
                      ],
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(),
                    ),

                    // Meal details
                    _buildDetailRow(
                      Icons.restaurant_menu,
                      "Plan Type",
                      meal.planType,
                    ),
                    const SizedBox(height: 8),

                    // Show date with red dot for cancelled meals
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.event,
                            size: 16,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Date",
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    DateFormat('EEE, MMM d').format(meal.date),
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  // Red dot for cancelled meals
                                  if (isCancelled)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(left: 8),
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.red,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Cancellation info message
                    if (isCancelled) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Meal for this day is cancelled",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 8),
                    _buildDetailRow(
                      Icons.list,
                      "Items",
                      meal.items.join(', '),
                    ),

                    // Build meal card actions row (swap and cancel buttons)
                    if (!isCancelled)
                      _buildMealCardActions(meal)
                    else
                      const SizedBox(height: 8), // Padding for cancelled meals
                  ],
                ),
              ),
            );
          },
        ),
        // Add bottom padding to ensure last card is fully visible
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildListView() {
    final allMeals = _mealsMap.values.expand((meals) => meals).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return _buildMealsList(allMeals);
  }

  Widget _buildMealsList(List<MealData> meals) {
    if (meals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.no_meals,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No meals scheduled for this period',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: meals.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final meal = meals[index];
        final bool isBreakfast = meal.subscription.planType == 'breakfast';
        final bool isCancelled = meal.status == "Cancelled";

        // Add a date header if this is a new date or the first item
        final bool showDateHeader = index == 0 ||
            (index > 0 && !isSameDay(meals[index - 1].date, meal.date));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header if needed
            if (showDateHeader) ...[
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          DateFormat('EEEE, MMMM d, yyyy').format(meal.date),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                      // Add red dot indicator for cancelled meals
                      if (isCancelled)
                        Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(left: 8),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],

            // Meal Card with enhanced design
            Card(
              elevation: 3,
              shadowColor: Colors.black.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row with meal type icon and status badge
                    Row(
                      children: [
                        // Meal type icon
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isBreakfast
                                ? Colors.purple.withOpacity(0.1)
                                : meal.subscription.planType == 'express'
                                    ? Colors.blue.withOpacity(0.1)
                                    : Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isBreakfast
                                ? Icons.free_breakfast
                                : Icons.lunch_dining,
                            color: isBreakfast
                                ? Colors.purple
                                : meal.subscription.planType == 'express'
                                    ? Colors.blue
                                    : Colors.green,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Meal name and student
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                meal.name,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              Text(
                                meal.studentName,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Status badge
                        _buildStatusBadge(meal.status, isCancelled),
                      ],
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1),
                    ),

                    // Meal details
                    _buildDetailRow(
                      Icons.restaurant_menu,
                      "Plan Type",
                      meal.planType,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      Icons.event,
                      "Date",
                      DateFormat('EEE, MMM d').format(meal.date),
                    ),

                    // Cancellation info message
                    if (isCancelled) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Meal for this day is cancelled",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 12),
                    _buildDetailRow(
                      Icons.list,
                      "Items",
                      meal.items.join(', '),
                    ),

                    const SizedBox(height: 24),

                    // Only show actions if meal is not cancelled
                    if (!isCancelled)
                      _buildMealCardActions(meal)
                    else
                      const SizedBox(height: 8), // Padding for cancelled meals
                  ],
                ),
              ),
            ),

            // Add some spacing between cards
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  // Helper to build detail rows in the meal card
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 16,
            color: Colors.grey.shade700,
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
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Build meal card actions row (swap and cancel buttons)
  Widget _buildMealCardActions(MealData meal) {
    final bool canCancel =
        _isCancellationAllowed(meal.date, meal.subscription.planType);
    final bool isExpressPlan = meal.subscription.planType == 'express';
    final bool hasSwapAndCancel = meal.canSwap && !isExpressPlan;

    // When we have both buttons, show them side by side
    if (hasSwapAndCancel) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row with both buttons side by side
          Row(
            children: [
              // Swap button
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  label: const Text('Swap'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                  onPressed: () => _showSwapMealBottomSheet(meal),
                ),
              ),

              const SizedBox(width: 12), // Space between buttons

              // Cancel button
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Cancel'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor:
                        canCancel ? Colors.red : Colors.grey.shade400,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                  onPressed:
                      canCancel ? () => _showCancelMealDialog(meal) : null,
                ),
              ),
            ],
          ),

          // Show message if meal can't be cancelled due to cutoff time
          if (!canCancel)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                "Meal cannot be cancelled after 11:59 PM the previous day.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
        ],
      );
    } else {
      // When we have only one button (either swap or cancel), use the original vertical layout
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Swap button (if meal can be swapped)
          if (meal.canSwap) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Swap Meal'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                onPressed: () => _showSwapMealBottomSheet(meal),
              ),
            ),
          ],

          // Cancel button (if meal can be cancelled and not an express plan)
          if (!isExpressPlan) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancel Meal'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor:
                      canCancel ? Colors.red : Colors.grey.shade400,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                onPressed: canCancel ? () => _showCancelMealDialog(meal) : null,
              ),
            ),

            // Show message if meal can't be cancelled due to cutoff time
            if (!canCancel)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  "Meal cannot be cancelled after 11:59 PM the previous day.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
          ] else ...[
            // Show message if express plan
            Center(
              child: Text(
                "Express 1-Day meals cannot be cancelled.",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ],
      );
    }
  }

  void _showSwapMealBottomSheet(MealData meal) {
    final subscription = meal.subscription;
    final targetDate = meal.date;

    if (subscription.planType == 'express') {
      _showSnackBar('Swapping not allowed for Express 1-Day plans');
      return;
    }

    final now = DateTime.now();
    final cutoffDate =
        DateTime(targetDate.year, targetDate.month, targetDate.day, 23, 59)
            .subtract(const Duration(days: 1));

    if (now.isAfter(cutoffDate)) {
      _showSnackBar('Swap window closed for this meal');
      return;
    }

    final swapOptions = _getSwapOptionsForMealType(subscription.planType);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Swap Meal',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text('Current: ${meal.name}'),
              Text(
                  'Date: ${DateFormat('EEE dd, MMM yyyy').format(targetDate)}'),
              const SizedBox(height: 16),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: swapOptions.length,
                  itemBuilder: (context, index) {
                    final option = swapOptions[index];

                    if (option['name'] == meal.name) {
                      return const SizedBox.shrink();
                    }

                    return ListTile(
                      title: Text(option['name'] ?? ''),
                      subtitle: Text(option['description'] ?? ''),
                      onTap: () async {
                        Navigator.pop(context);
                        await _performMealSwap(meal, option['name'] ?? '');
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _performMealSwap(MealData meal, String newMealName) async {
    setState(() {
      _isSwapLoading = true;
    });

    _showSnackBar('Swapping meal...');

    try {
      final success = await _subscriptionService.swapMeal(
        meal.subscription.id,
        newMealName,
        meal.date,
      );

      if (success) {
        // Save swapped meal to local storage with unique key
        await _saveSwappedMealToLocalStorage(meal, newMealName);

        // Update UI
        _updateMealAfterSwap(meal.subscription.id, newMealName, meal.date);
        _showSnackBar('Successfully swapped to $newMealName');
      } else {
        _showSnackBar('Failed to swap meal. Please try again.');
      }
    } catch (e) {
      log('Error during swap: $e');
      _showSnackBar('An error occurred during swap');
    } finally {
      if (mounted) {
        setState(() {
          _isSwapLoading = false;
        });
      }
    }
  }

  // Method to save swapped meal to local storage
  Future<void> _saveSwappedMealToLocalStorage(
      MealData meal, String newMealName) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Create a unique key using student ID and date
      final String key =
          'swappedMeal_${meal.studentId}_${meal.subscriptionId}_${DateFormat('yyyy-MM-dd').format(meal.date)}';

      // Create a map with essential data to save
      final Map<String, dynamic> swapData = {
        'subscriptionId': meal.subscriptionId,
        'studentId': meal.studentId,
        'newMealName': newMealName,
        'date': DateFormat('yyyy-MM-dd').format(meal.date),
        'originalMealName': meal.subscription.mealName,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Save to SharedPreferences
      await prefs.setString(key, jsonEncode(swapData));
      log('[swap_meal_flow] Saved swapped meal to local storage: $key');
    } catch (e) {
      log('[swap_meal_flow] Error saving swapped meal to local storage: $e');
    }
  }

  void _updateMealAfterSwap(
      String subscriptionId, String newMealName, DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);

    if (_mealsMap.containsKey(normalizedDate)) {
      final meals = _mealsMap[normalizedDate]!;

      for (int i = 0; i < meals.length; i++) {
        if (meals[i].subscriptionId == subscriptionId) {
          final updatedMeal = MealData(
            studentName: meals[i].studentName,
            name: newMealName,
            planType: meals[i].planType,
            items: meals[i].items,
            status: 'Swapped',
            subscription: meals[i].subscription,
            canSwap: meals[i].canSwap,
            date: meals[i].date,
            studentId: meals[i].studentId,
            subscriptionId: meals[i].subscriptionId,
          );

          setState(() {
            meals[i] = updatedMeal;

            if (isSameDay(normalizedDate, _selectedDay)) {
              _updateSelectedDayMeals();
            }
          });

          break;
        }
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  List<Map<String, String>> _getSwapOptionsForMealType(String planType) {
    if (planType == 'breakfast') {
      return [
        {
          'name': 'Indian Breakfast',
          'description': 'Traditional Indian breakfast with tea',
        },
        {
          'name': 'Jain Breakfast',
          'description': 'Jain-friendly breakfast items with tea',
        },
        {
          'name': 'International Breakfast',
          'description': 'Continental breakfast options',
        },
        {
          'name': 'Breakfast of the Day',
          'description': 'Chef\'s special breakfast selection',
        },
      ];
    } else {
      return [
        {
          'name': 'Indian Lunch',
          'description': 'Traditional Indian lunch with roti/rice',
        },
        {
          'name': 'Jain Lunch',
          'description': 'Jain-friendly lunch options',
        },
        {
          'name': 'International Lunch',
          'description': 'Global cuisine lunch options',
        },
        {
          'name': 'Lunch of the Day',
          'description': 'Chef\'s special lunch selection',
        },
      ];
    }
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Helper to check if cancellation is allowed for a date and plan type
  bool _isCancellationAllowed(DateTime date, String planType) {
    // Express plans cannot be cancelled
    if (planType == 'express') {
      return false;
    }

    // Check if we're past the cutoff time (11:59 PM the day before)
    final now = DateTime.now();
    final cutoffDate = DateTime(date.year, date.month, date.day, 23, 59)
        .subtract(const Duration(days: 1));

    return now.isBefore(cutoffDate);
  }

  // Show confirmation dialog for meal cancellation
  Future<void> _showCancelMealDialog(MealData meal) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(
                'Cancel Meal',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: Text(
                'Are you sure you want to cancel this meal?',
                style: GoogleFonts.poppins(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'No',
                    style: GoogleFonts.poppins(),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.red,
                  ),
                  child: Text(
                    'Yes',
                    style: GoogleFonts.poppins(),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (confirmed) {
      _cancelMeal(meal);
    }
  }

  // Helper method to remove a cancelled meal from all UI views
  void _removeCancelledMealFromViews(MealData meal) {
    log('[cancel_meal_flow] Removing cancelled meal from views: ${meal.name} on ${DateFormat('yyyy-MM-dd').format(meal.date)}');

    final normalizedDate =
        DateTime(meal.date.year, meal.date.month, meal.date.day);

    // Log before removal
    log('[cancel_meal_flow] Before removal: ${_mealsMap[normalizedDate]?.length ?? 0} meals for date ${DateFormat('yyyy-MM-dd').format(normalizedDate)}');

    if (_mealsMap.containsKey(normalizedDate)) {
      _mealsMap[normalizedDate]!.removeWhere((m) =>
          m.subscriptionId == meal.subscriptionId &&
          isSameDay(m.date, meal.date));

      // Log after removal
      log('[cancel_meal_flow] After removal: ${_mealsMap[normalizedDate]?.length ?? 0} meals for date ${DateFormat('yyyy-MM-dd').format(normalizedDate)}');

      // If no meals left for this date, remove the date entry
      if (_mealsMap[normalizedDate]!.isEmpty) {
        _mealsMap.remove(normalizedDate);
        log('[cancel_meal_flow] Removed entire date entry for ${DateFormat('yyyy-MM-dd').format(normalizedDate)}');
      }

      // Update selected day meals if needed
      if (isSameDay(normalizedDate, _selectedDay)) {
        _selectedDateMeals = _mealsMap[normalizedDate] ?? [];
        log('[cancel_meal_flow] Updated selected day meals: ${_selectedDateMeals.length} meals');
      }
    } else {
      log('[cancel_meal_flow] No meals found for date ${DateFormat('yyyy-MM-dd').format(normalizedDate)}');
    }
  }

  // Handle meal cancellation
  Future<void> _cancelMeal(MealData meal) async {
    log('[cancel_meal_flow] Starting meal cancellation for student: ${meal.studentId}');
    log('[cancel_meal_flow] Meal details - Type: ${meal.planType}, Date: ${DateFormat('yyyy-MM-dd').format(meal.date)}');

    try {
      // Show cancellation in progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Cancelling meal...'),
            ],
          ),
        ),
      );

      // Call the subscription service to cancel the meal
      final success = await _subscriptionService.cancelMealDelivery(
        meal.subscriptionId,
        meal.date,
        studentId: meal.studentId,
      );

      // Dismiss the progress dialog
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (success) {
        log('[cancel_meal_flow] Successfully cancelled meal in service');

        // Also save to SharedPreferences for immediate local persistence
        try {
          final prefs = await SharedPreferences.getInstance();
          final normalizedDate = DateFormat('yyyy-MM-dd').format(meal.date);
          final key =
              'cancelledMeal_${meal.studentId}_${meal.subscriptionId}_$normalizedDate';

          await prefs.setBool(key, true);
          log('[cancel_meal_flow] Saved cancellation to SharedPreferences: $key');
        } catch (e) {
          log('[cancel_meal_flow] Error saving cancellation to SharedPreferences: $e');
          // Continue even if SharedPreferences save fails
        }

        // Wait a moment to ensure cancellation is processed
        await Future.delayed(const Duration(milliseconds: 200));

        // Remove the meal from the UI using the helper method
        setState(() {
          _removeCancelledMealFromViews(meal);
        });

        log('[cancel_meal_flow] Removed meal from UI for date: ${DateFormat('yyyy-MM-dd').format(meal.date)}');

        // Show success toast
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Meal cancelled successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }

        // Navigate to Cancelled Meals tab (index 1)
        if (context.mounted) {
          // Use the static method to get the parent MySubscriptionScreen state
          final mySubscriptionScreenState = MySubscriptionScreen.of(context);
          if (mySubscriptionScreenState != null) {
            log('[cancel_meal_flow] Navigating to Cancelled Meals tab');

            // Add longer delay before tab switch to let UI complete updates and service to fully process the cancellation
            await Future.delayed(const Duration(milliseconds: 500));

            // Switch to Cancelled Meals tab which will trigger a refresh
            mySubscriptionScreenState.switchToTab(1);
          } else {
            log('[cancel_meal_flow] ERROR: Could not find MySubscriptionScreen state, trying with globalKey');
            // Fallback to using the global key if context-based access fails
            if (mySubscriptionScreenKey.currentState != null) {
              await Future.delayed(const Duration(milliseconds: 500));
              mySubscriptionScreenKey.currentState!.switchToTab(1);
            } else {
              log('[cancel_meal_flow] ERROR: Could not find MySubscriptionScreen state with key either');
            }
          }
        }
      } else {
        log('[cancel_meal_flow] Failed to cancel meal in service');
        // Show error toast
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to cancel meal. Please try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      log('[cancel_meal_flow] Error during meal cancellation: $e');
      // Dismiss progress dialog if still showing
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Show error toast
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling meal: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
