import 'dart:developer';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/screens/meal_plan_screen.dart';
import 'package:startwell/services/event_bus_service.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:startwell/widgets/subscription/meal_card.dart';
import 'package:intl/intl.dart';
import 'package:startwell/services/meal_service.dart';
import 'package:startwell/services/student_profile_service.dart';
import 'package:startwell/models/student_model.dart';
import 'package:startwell/models/subscription_model.dart';
import 'package:startwell/screens/my_subscription_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:math' as math;

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

// Class to store meal data for calendar view
class MealData {
  final String studentName;
  final String name;
  final String planType;
  final List<String> items;
  String
      status; // Scheduled / Swapped / Cancelled / Paused - Non-final to allow updates
  final Subscription subscription;
  final bool canSwap;
  final bool canCancel;
  bool
      canPauseOrResume; // Whether this meal can be paused/resumed based on cutoff time
  final DateTime date; // Add date property

  MealData({
    required this.studentName,
    required this.name,
    required this.planType,
    required this.items,
    required this.status,
    required this.subscription,
    required this.canSwap,
    required this.canCancel,
    required this.canPauseOrResume,
    required this.date, // Add required date parameter
  });

  // Helper to check if the meal is paused
  bool get isPaused => status == "Paused";

  // Helper to check if this is an express plan (no pause/resume allowed)
  bool get isExpressPlan => subscription.planType == 'express';

  // Override toString for better logging
  @override
  String toString() {
    return 'MealData(student: $studentName, meal: $name, type: $planType, status: $status, date: ${DateFormat('yyyy-MM-dd').format(date)}, canSwap: $canSwap, canCancel: $canCancel, canPauseOrResume: $canPauseOrResume)';
  }
}

class _UpcomingMealsTabState extends State<UpcomingMealsTab> {
  bool _isCalendarView = false;
  bool _isLoading = true;
  final MealService _mealService = MealService();
  final StudentProfileService _studentProfileService = StudentProfileService();
  final SubscriptionService _subscriptionService = SubscriptionService();

  List<Subscription> _activeSubscriptions = [];
  String? _selectedStudentId;
  List<Student> _studentsWithMealPlans = [];

  // Calendar view variables
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, List<MealData>> _mealsMap = {};
  List<MealData> _selectedDateMeals = [];

  // Track cancelled meal dates for marking with red dots in calendar
  final Set<DateTime> _cancelledMealDates = {};

  @override
  void initState() {
    super.initState();
    _loadStudentsWithMealPlans();
  }

  // Get the earliest subscription start date
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

    // If the earliest date is in the past, use today
    final today = DateTime.now();
    if (earliestDate.isBefore(today)) {
      return today;
    }

    return earliestDate;
  }

  // Get the latest subscription end date
  DateTime _getLatestSubscriptionEndDate() {
    if (_activeSubscriptions.isEmpty) {
      // Default to 1 year from now if no active subscriptions
      return DateTime.now().add(const Duration(days: 365));
    }

    DateTime latestDate = _activeSubscriptions.first.endDate;
    for (final subscription in _activeSubscriptions) {
      if (subscription.endDate.isAfter(latestDate)) {
        latestDate = subscription.endDate;
      }
    }

    // Add 30 days buffer for better UX
    return latestDate.add(const Duration(days: 30));
  }

  // Ensure focused day is valid and within range
  void _ensureValidFocusedDay() {
    final DateTime firstDay = _getEarliestSubscriptionStartDate();
    final DateTime lastDay = _getLatestSubscriptionEndDate();

    // Add debug logging
    log('[Calendar Init] firstDay: ${DateFormat('yyyy-MM-dd').format(firstDay)}');
    log('[Calendar Init] lastDay: ${DateFormat('yyyy-MM-dd').format(lastDay)}');
    log('[Calendar Init] original focusedDay: ${DateFormat('yyyy-MM-dd').format(_focusedDay)}');

    // Ensure focusedDay is not before firstDay
    if (_focusedDay.isBefore(firstDay)) {
      _focusedDay = firstDay;
      log('[Calendar Init] focusedDay adjusted to firstDay: ${DateFormat('yyyy-MM-dd').format(_focusedDay)}');
    }

    // Ensure focusedDay is not after lastDay
    if (_focusedDay.isAfter(lastDay)) {
      _focusedDay = lastDay;
      log('[Calendar Init] focusedDay adjusted to lastDay: ${DateFormat('yyyy-MM-dd').format(_focusedDay)}');
    }

    // Ensure selectedDay matches focusedDay if it's outside range
    if (_selectedDay.isBefore(firstDay) || _selectedDay.isAfter(lastDay)) {
      _selectedDay = _focusedDay;
      log('[Calendar Init] selectedDay adjusted to match focusedDay: ${DateFormat('yyyy-MM-dd').format(_selectedDay)}');
    }
  }

  Future<void> _loadStudentsWithMealPlans() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get students with active meal plans
      final List<String> studentIds =
          await _mealService.getStudentsWithMealPlans();
      final List<Student> students =
          await _studentProfileService.getStudentProfiles();

      log("Students with meal plans: ${students.length}");

      //print list of students
      for (final student in students) {
        log("Student List: ${student.name} ${student.id}");
      }

      _studentsWithMealPlans =
          students.where((student) => studentIds.contains(student.id)).toList();

      if (_studentsWithMealPlans.isNotEmpty) {
        // If a specific student ID was passed, use it
        if (widget.selectedStudentId != null &&
            _studentsWithMealPlans
                .any((s) => s.id == widget.selectedStudentId)) {
          _selectedStudentId = widget.selectedStudentId;
        } else {
          // Otherwise default to the first student
          _selectedStudentId = _studentsWithMealPlans.first.id;
        }

        await _loadSubscriptionsForStudent(_selectedStudentId!,
            skipCancelled: true);
      } else {
        _activeSubscriptions = [];
      }
    } catch (e) {
      print('Error loading students with meal plans: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadSubscriptionsForStudent(String studentId,
      {bool skipCancelled = false}) async {
    setState(() {
      _isLoading = true;
    });
    log("Loading subscriptions for student ID: $studentId");

    // Improved logging for collections
    if (_activeSubscriptions.isNotEmpty) {
      log("Current active subscriptions count: ${_activeSubscriptions.length}");
      for (int i = 0; i < _activeSubscriptions.length; i++) {
        log("Active subscription[$i]: ${_activeSubscriptions[i]}");
      }
    } else {
      log("No active subscriptions currently loaded");
    }

    if (_studentsWithMealPlans.isNotEmpty) {
      log("Students with meal plans count: ${_studentsWithMealPlans.length}");
      for (int i = 0; i < _studentsWithMealPlans.length; i++) {
        log("Student[$i]: ${_studentsWithMealPlans[i]}");
      }
    } else {
      log("No students with meal plans found");
    }

    log("Selected student ID: $_selectedStudentId");

    // Log summary of meal map
    if (_mealsMap.isNotEmpty) {
      log("Current meal map entries: ${_mealsMap.length}");
      // Log first 3 entries at most
      int count = 0;
      _mealsMap.forEach((date, meals) {
        if (count < 3) {
          log("Meal map[${DateFormat('yyyy-MM-dd').format(date)}]: ${meals.length} meals");
          count++;
        }
      });
    } else {
      log("Meal map is empty");
    }

    if (_selectedDateMeals.isNotEmpty) {
      log("Selected date meals count: ${_selectedDateMeals.length}");
    } else {
      log("No meals for selected date");
    }

    try {
      // Get active subscriptions based on the student's actual meal plans
      _activeSubscriptions = await _subscriptionService
          .getActiveSubscriptionsForStudent(studentId);

      // If we're skipping cancelled meals, ensure we keep the cancellation state
      if (skipCancelled) {
        log("Skipping cancelled meals - preserving cancellation state");
        // Preserve cancelled dates from our current state
        for (final subscription in _activeSubscriptions) {
          // If we had this subscription loaded previously, check for cancelled dates
          final cancelledDates = _cancelledMealDates.toList();
          log("Current cancelled dates count: ${cancelledDates.length}");

          // For each cancelled date, make sure the corresponding meal is truly cancelled
          for (final date in cancelledDates) {
            // Mark this subscription's delivery as cancelled for this date
            subscription.addCancelledDate(date);
            log("Restored cancelled date: ${DateFormat('yyyy-MM-dd').format(date)} for subscription: ${subscription.id}");
          }
        }
      }

      // Debug log for Express plans
      final expressPlans = _activeSubscriptions
          .where((sub) => sub.planType == 'express')
          .toList();
      if (expressPlans.isNotEmpty) {
        log("📱 FOUND EXPRESS PLANS: ${expressPlans.length}");
        for (final plan in expressPlans) {
          log("  📱 Express Plan ID: ${plan.id}");
          log("  📱 Express Plan Date: ${DateFormat('yyyy-MM-dd').format(plan.startDate)}");
          SubscriptionService.logSubscriptionDetails(plan);
        }
      } else {
        log("📱 NO EXPRESS PLANS FOUND for student $studentId");
      }

      // Generate meal map for calendar view
      _generateMealMap();

      // Ensure focused day is valid before showing calendar
      _ensureValidFocusedDay();
    } catch (e) {
      print('Error loading subscriptions: $e');
      _activeSubscriptions = [];
      _mealsMap = {};
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Generate a map of dates to meal data for the calendar view
  void _generateMealMap() {
    _mealsMap = {};

    for (final subscription in _activeSubscriptions) {
      // Find the correct student for this subscription
      final student = _studentsWithMealPlans.firstWhere(
        (s) => s.id == subscription.studentId,
        orElse: () => _studentsWithMealPlans.first,
      );

      // Get all the scheduled dates for this subscription
      log("=== Generating schedule dates for subscription ===");
      log("Subscription ID: ${subscription.id}");
      log("Student ID: ${subscription.studentId}, Student name: ${student.name}");
      log("Plan Type: ${subscription.planType}");
      log("Start Date: ${DateFormat('yyyy-MM-dd').format(subscription.startDate)}");
      log("End Date: ${DateFormat('yyyy-MM-dd').format(subscription.endDate)}");
      log("Selected Weekdays: ${subscription.selectedWeekdays}");
      log("Custom Plan: ${subscription.selectedWeekdays.isNotEmpty && subscription.selectedWeekdays.length < 5}");

      // Log detailed subscription info
      SubscriptionService.logSubscriptionDetails(subscription);

      // Debug log for subscription duration
      log("Subscription duration: ${subscription.duration}");
      log("Duration display name: ${subscription.durationDisplayName}");
      log("Days between start and end: ${subscription.endDate.difference(subscription.startDate).inDays}");

      // Generate scheduled dates specifically for this subscription's weekdays
      final scheduledDates = _generateScheduleDates(
        subscription.startDate,
        subscription.endDate,
        subscription.selectedWeekdays,
        subscription.planType,
      );

      log("Total Scheduled Dates: ${scheduledDates.length}");
      if (scheduledDates.isNotEmpty) {
        log("First Date: ${DateFormat('yyyy-MM-dd').format(scheduledDates.first)}");
        log("Last Date: ${DateFormat('yyyy-MM-dd').format(scheduledDates.last)}");
      }
      log("=== End of scheduled dates generation ===");

      // Create a MealData object for each date
      for (final date in scheduledDates) {
        final normalized = DateTime(date.year, date.month, date.day);

        // Skip dates in the past, but always include Express plans
        if (normalized.isBefore(DateTime.now()) &&
            !normalized.isAtSameMomentAs(DateTime.now()) &&
            subscription.planType != 'express') {
          continue;
        }

        // Skip this date if it's been cancelled for this subscription
        if (subscription.isCancelledForDate(normalized)) {
          log("Skipping cancelled meal for subscription ${subscription.id} on ${DateFormat('yyyy-MM-dd').format(normalized)}");
          // Add to cancelled meal dates set for UI marking
          _cancelledMealDates.add(normalized);
          continue;
        }

        // Check if swap/cancel is allowed for this date
        final bool canSwap = _isSwapAllowed(date, subscription.planType);
        final bool canCancel = _isCancelAllowed(date, subscription.planType);
        final bool canPauseResume =
            _isPauseResumeAllowed(date, subscription.planType);

        // Create a MealData object for this date
        final mealData = MealData(
          studentName: student.name,
          name: subscription.mealItemName,
          planType: _getFormattedPlanType(subscription),
          items: subscription.getMealItems(),
          status: "Scheduled",
          subscription: subscription,
          canSwap: canSwap,
          canCancel: canCancel,
          canPauseOrResume: canPauseResume,
          date: date,
        );

        // Add to the map
        if (_mealsMap.containsKey(normalized)) {
          _mealsMap[normalized]!.add(mealData);
        } else {
          _mealsMap[normalized] = [mealData];
        }
      }
    }

    // Update the selected day's meals
    _updateSelectedDayMeals();
  }

  // Update meals for the selected day
  void _updateSelectedDayMeals() {
    final normalizedSelectedDay =
        DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    _selectedDateMeals = _mealsMap[normalizedSelectedDay] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildViewControls(),
        if (_isLoading)
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        else
          Expanded(
            child: _studentsWithMealPlans.isEmpty
                ? _buildNoSubscriptionsView()
                : _isCalendarView
                    ? _buildCalendarView()
                    : _buildListView(),
          ),
      ],
    );
  }

  Widget _buildViewControls() {
    return Column(
      children: [
        if (_studentsWithMealPlans.isNotEmpty)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Select Student',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              value: _selectedStudentId,
              items: _studentsWithMealPlans.map((student) {
                return DropdownMenuItem<String>(
                  value: student.id,
                  child: Text(student.name),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null && value != _selectedStudentId) {
                  setState(() {
                    _selectedStudentId = value;
                  });
                  _loadSubscriptionsForStudent(value, skipCancelled: true);
                }
              },
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Upcoming Meals',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              ToggleButtons(
                isSelected: [!_isCalendarView, _isCalendarView],
                onPressed: (index) {
                  setState(() {
                    _isCalendarView = index == 1;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                selectedColor: Colors.white,
                fillColor: AppTheme.purple,
                color: AppTheme.textMedium,
                constraints: const BoxConstraints(
                  minHeight: 36,
                  minWidth: 60,
                ),
                children: const [
                  Icon(Icons.list),
                  Icon(Icons.calendar_today),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListView() {
    // Check for errors first
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Check if we have active subscriptions
    if (_activeSubscriptions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              "No active subscriptions for this student",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Subscribe to a meal plan to see upcoming meals here",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textMedium,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Generate a list of all scheduled meal dates across all active subscriptions
    List<Map<String, dynamic>> allScheduledMeals = [];

    for (final subscription in _activeSubscriptions) {
      // Find the correct student for this subscription
      final student = _studentsWithMealPlans.firstWhere(
        (s) => s.id == subscription.studentId,
        orElse: () => _studentsWithMealPlans.first,
      );

      // Get all the scheduled dates for this subscription
      final scheduledDates = _generateScheduleDates(
        subscription.startDate,
        subscription.endDate,
        subscription.selectedWeekdays,
        subscription.planType,
      );

      // Create a meal entry for each scheduled date
      for (final date in scheduledDates) {
        // Skip dates in the past
        if (date.isBefore(DateTime.now()) &&
            !date.isAtSameMomentAs(DateTime.now())) {
          continue;
        }

        // Check if date is valid for swap and cancel
        final bool canSwap = _isSwapAllowed(date, subscription.planType);
        final bool canCancel = _isCancelAllowed(date, subscription.planType);

        allScheduledMeals.add({
          'date': date,
          'subscription': subscription,
          'student': student,
          'canSwap': canSwap,
          'canCancel': canCancel,
        });
      }
    }

    // Sort the meals by date (ascending) and then by meal type (breakfast first, then lunch)
    allScheduledMeals.sort((a, b) {
      final dateComparison =
          (a['date'] as DateTime).compareTo(b['date'] as DateTime);
      if (dateComparison != 0) {
        return dateComparison;
      }

      // If dates are the same, sort by meal type (breakfast first)
      final aIsBreakfast =
          (a['subscription'] as Subscription).planType == 'breakfast';
      final bIsBreakfast =
          (b['subscription'] as Subscription).planType == 'breakfast';

      if (aIsBreakfast && !bIsBreakfast) {
        return -1;
      } else if (!aIsBreakfast && bIsBreakfast) {
        return 1;
      } else {
        return 0;
      }
    });

    // If no upcoming meals are found
    if (allScheduledMeals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              "No upcoming meals found",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Your meal plan has no scheduled deliveries",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textMedium,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (_selectedStudentId != null) {
          await _loadSubscriptionsForStudent(_selectedStudentId!);
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: allScheduledMeals.length,
        itemBuilder: (context, index) {
          final mealData = allScheduledMeals[index];
          final date = mealData['date'] as DateTime;
          final subscription = mealData['subscription'] as Subscription;
          final student = mealData['student'] as Student;
          final canSwap = mealData['canSwap'] as bool;
          final canCancel = mealData['canCancel'] as bool;
          final isBreakfast = subscription.planType == 'breakfast';

          // Define meal status - this would typically come from the subscription data
          // In a real implementation, this would track actual status from backend
          String mealStatus = "Scheduled"; // Default status

          // Display a date header if this is the first meal of the day or the first item
          final bool showDateHeader = index == 0 ||
              (index > 0 &&
                  !isSameDay(
                      date, allScheduledMeals[index - 1]['date'] as DateTime));

          // Create a MealData object to match calendar view's pattern
          final mealDataObj = MealData(
            studentName: student.name,
            name: subscription.mealItemName,
            planType: _getFormattedPlanType(subscription),
            items: subscription.getMealItems(),
            status: "Scheduled",
            subscription: subscription,
            canSwap: canSwap,
            canCancel: canCancel,
            canPauseOrResume: false,
            date: date,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showDateHeader)
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4),
                  child: Text(
                    DateFormat('EEEE, MMMM dd, yyyy').format(date),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
              Card(
                margin: const EdgeInsets.only(bottom: 16, top: 8),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with status pill
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isBreakfast
                                    ? Icons.breakfast_dining
                                    : Icons.lunch_dining,
                                color: isBreakfast
                                    ? AppTheme.purple
                                    : Colors.green.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isBreakfast ? "Breakfast" : "Lunch",
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: isBreakfast
                                      ? AppTheme.purple
                                      : Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: mealStatus == "Paused"
                                  ? Colors.orange.withOpacity(0.2)
                                  : mealStatus == "Cancelled"
                                      ? Colors.red.withOpacity(0.2)
                                      : mealStatus == "Swapped"
                                          ? Colors.blue.withOpacity(0.2)
                                          : Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              mealStatus,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: mealStatus == "Paused"
                                    ? Colors.orange.shade800
                                    : mealStatus == "Cancelled"
                                        ? Colors.red.shade800
                                        : mealStatus == "Swapped"
                                            ? Colors.blue.shade800
                                            : Colors.green.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Meal details
                      _buildDetailRow(Icons.person, "Student", student.name),
                      const SizedBox(height: 8),
                      _buildDetailRow(Icons.restaurant_menu, "Meal Item",
                          subscription.mealItemName),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        Icons.calendar_today,
                        "Subscription Plan",
                        mealDataObj.planType,
                      ),
                      const SizedBox(height: 8),
                      if (subscription.selectedWeekdays.isNotEmpty &&
                          subscription.selectedWeekdays.length < 5)
                        _buildDetailRow(
                          Icons.today,
                          "Delivery Days",
                          _formatWeekdays(subscription.selectedWeekdays),
                        ),
                      if (subscription.selectedWeekdays.isNotEmpty &&
                          subscription.selectedWeekdays.length < 5)
                        const SizedBox(height: 8),
                      _buildDetailRow(Icons.event, "Scheduled Date",
                          DateFormat('EEE dd, MMM yyyy').format(date)),
                      const SizedBox(height: 8),
                      _buildDetailRow(Icons.lunch_dining, "Items",
                          subscription.getMealItems().join(", ")),

                      const SizedBox(height: 20),

                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // PAUSE/RESUME BUTTON - Toggles based on meal status
                          if (subscription.planType != 'express')
                            Expanded(
                              child: GestureDetector(
                                onTap: _isPauseResumeAllowed(
                                        date, subscription.planType)
                                    ? mealStatus == "Paused"
                                        ? () => _showResumeMealDialog(
                                            subscription, date)
                                        : () => _showPauseMealDialog(
                                            subscription, date)
                                    : null,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _isPauseResumeAllowed(
                                            date, subscription.planType)
                                        ? mealStatus == "Paused"
                                            ? Colors.green.withOpacity(0.2)
                                            : Colors.orange.withOpacity(0.2)
                                        : Colors.grey.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        mealStatus == "Paused"
                                            ? Icons.play_circle_outline
                                            : Icons.pause_circle_outline,
                                        color: _isPauseResumeAllowed(
                                                date, subscription.planType)
                                            ? mealStatus == "Paused"
                                                ? Colors.green
                                                : Colors.orange
                                            : Colors.grey,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        mealStatus == "Paused"
                                            ? "Resume"
                                            : "Pause",
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: _isPauseResumeAllowed(
                                                  date, subscription.planType)
                                              ? mealStatus == "Paused"
                                                  ? Colors.green
                                                  : Colors.orange
                                              : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          // Create a bit more space between buttons
                          if (subscription.planType != 'express')
                            const SizedBox(width: 8),

                          // SWAP BUTTON
                          Expanded(
                            child: GestureDetector(
                              onTap: canSwap
                                  ? () => _showSwapMealBottomSheet(subscription)
                                  : null,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: canSwap
                                      ? Colors.blue.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.swap_horiz,
                                      color:
                                          canSwap ? Colors.blue : Colors.grey,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Swap",
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color:
                                            canSwap ? Colors.blue : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // CANCEL BUTTON
                          Expanded(
                            child: GestureDetector(
                              onTap: canCancel
                                  ? () {
                                      // For calendar view, use the selected date
                                      final DateTime targetDate =
                                          _isCalendarView
                                              ? _selectedDay
                                              : subscription.nextDeliveryDate;
                                      _showCancelMealDialogWithSubscription(
                                          subscription, targetDate);
                                    }
                                  : null,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: canCancel
                                      ? Colors.red.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.cancel_outlined,
                                      color:
                                          canCancel ? Colors.red : Colors.grey,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Cancel",
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: canCancel
                                            ? Colors.red
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (canSwap && subscription.planType != 'express')
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 4),
                          child: Text(
                            "You can swap until 11:59 PM the previous day",
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: isBreakfast
                                  ? AppTheme.purple.withOpacity(0.7)
                                  : Colors.green.shade700.withOpacity(0.7),
                            ),
                          ),
                        ),

                      if (mealDataObj.status == "Paused" &&
                          subscription.planType != 'express')
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 4),
                          child: Text(
                            "You can only pause or resume meals until 11:59 PM the previous day",
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),

                      if (subscription.planType == 'express')
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 4),
                          child: Text(
                            "Express 1-Day meals cannot be paused or resumed",
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),

                      if (!canCancel)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 4),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              "Cancellation window closed",
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Helper to check if two dates are the same day
  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Widget _buildCalendarView() {
    // Calendar view implementation
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Check if we have active subscriptions
    if (_activeSubscriptions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              "No active subscriptions for this student",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Subscribe to a meal plan to see upcoming meals here",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textMedium,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Log calendar parameters for debugging
    log('[Calendar Build] Setting up unrestricted calendar navigation');

    // Define a very wide date range for unlimited navigation
    final firstDay = DateTime(2020);
    final lastDay = DateTime(2100);

    // Use today's date as focused day if current focused day is invalid
    final today = DateTime.now();
    final focusedDay = _focusedDay;

    return Column(
      children: [
        // Calendar
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TableCalendar(
              firstDay: firstDay,
              lastDay: lastDay,
              focusedDay: focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: CalendarFormat.month,
              // Enable only today and future dates
              enabledDayPredicate: (date) => !date.isBefore(DateTime(
                  DateTime.now().year,
                  DateTime.now().month,
                  DateTime.now().day)),
              eventLoader: (day) {
                // Use our new event function to show both meal and cancelled markers
                return _getEventsForDay(day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                  _updateSelectedDayMeals();

                  // Show toast if no meals are scheduled for this date
                  if (_selectedDateMeals.isEmpty) {
                    _showSnackBar(
                      message:
                          'No meals scheduled for ${DateFormat('EEE dd, MMM yyyy').format(selectedDay)}',
                      backgroundColor: Colors.orange,
                    );
                  }
                });
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: AppTheme.purple.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: AppTheme.purple,
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                // Grey out disabled dates
                disabledTextStyle: GoogleFonts.poppins(
                  color: Colors.grey.shade400,
                ),
                // Grey out dates outside subscription periods
                outsideTextStyle: GoogleFonts.poppins(
                  color: Colors.grey.shade300,
                ),
                // Make weekends slightly different to distinguish them
                weekendTextStyle: GoogleFonts.poppins(
                  color: Colors.redAccent.withOpacity(0.7),
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  color: AppTheme.purple,
                  size: 28,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: AppTheme.purple,
                  size: 28,
                ),
                headerPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              calendarBuilders: CalendarBuilders(
                // Add disabledBuilder for past dates
                disabledBuilder: (context, date, _) => Center(
                  child: Text(
                    '${date.day}',
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
                markerBuilder: (context, date, events) {
                  if (events.isEmpty) return const SizedBox.shrink();

                  // Use our custom marker builder for showing meal and cancelled markers
                  return Positioned(
                    bottom: 1,
                    child: _buildCalendarMarker(events as List<dynamic>, date),
                  );
                },
              ),
            ),
          ),
        ),

        // Meal details for selected day
        Expanded(
          child: _selectedDateMeals.isEmpty
              ? _buildNoMealsForSelectedDay()
              : _buildMealDetailsForSelectedDay(),
        ),
      ],
    );
  }

  // Build widget when no meals are scheduled for selected day
  Widget _buildNoMealsForSelectedDay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.no_food,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            "No meals scheduled for ${DateFormat('EEE dd, MMM yyyy').format(_selectedDay)}",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.textDark,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Build meal details for the selected day
  Widget _buildMealDetailsForSelectedDay() {
    // Sort meals by type (breakfast first, then lunch)
    final sortedMeals = List<MealData>.from(_selectedDateMeals)
      ..sort((a, b) {
        if (a.subscription.planType == 'breakfast' &&
            b.subscription.planType != 'breakfast') {
          return -1;
        } else if (a.subscription.planType != 'breakfast' &&
            b.subscription.planType == 'breakfast') {
          return 1;
        } else {
          return 0;
        }
      });

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: sortedMeals.length,
      itemBuilder: (context, index) {
        final meal = sortedMeals[index];
        final bool isBreakfast = meal.subscription.planType == 'breakfast';
        final bool isExpressPlan = meal.isExpressPlan;

        return Card(
          margin: const EdgeInsets.only(bottom: 16, top: 8),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with status pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isBreakfast
                              ? Icons.breakfast_dining
                              : Icons.lunch_dining,
                          color: isBreakfast
                              ? AppTheme.purple
                              : Colors.green.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isBreakfast ? "Breakfast" : "Lunch",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isBreakfast
                                ? AppTheme.purple
                                : Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: meal.isPaused
                            ? Colors.orange.withOpacity(0.2)
                            : Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        meal.status,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: meal.isPaused
                              ? Colors.orange.shade800
                              : Colors.green.shade800,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Meal details
                _buildDetailRow(Icons.person, "Student", meal.studentName),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.restaurant_menu, "Meal Item", meal.name),
                const SizedBox(height: 8),
                _buildDetailRow(
                  Icons.calendar_today,
                  "Subscription Plan",
                  meal.planType,
                ),
                const SizedBox(height: 8),
                if (meal.subscription.selectedWeekdays.isNotEmpty &&
                    meal.subscription.selectedWeekdays.length < 5)
                  _buildDetailRow(
                    Icons.today,
                    "Delivery Days",
                    _formatWeekdays(meal.subscription.selectedWeekdays),
                  ),
                if (meal.subscription.selectedWeekdays.isNotEmpty &&
                    meal.subscription.selectedWeekdays.length < 5)
                  const SizedBox(height: 8),
                _buildDetailRow(Icons.event, "Scheduled Date",
                    DateFormat('EEE dd, MMM yyyy').format(_selectedDay)),
                const SizedBox(height: 8),
                _buildDetailRow(
                    Icons.lunch_dining, "Items", meal.items.join(", ")),

                const SizedBox(height: 20),

                // Action buttons - Only show for non-express plans
                if (!isExpressPlan) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // PAUSE BUTTON - Show when not paused and within cutoff time
                        if (meal.status != "Paused")
                          Expanded(
                            child: GestureDetector(
                              onTap: meal.canPauseOrResume && !meal.isPaused
                                  ? () => _showPauseMealDialog(
                                      meal.subscription, meal.date)
                                  : null,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: meal.canPauseOrResume
                                      ? Colors.orange.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.pause_circle_outline,
                                      color: meal.canPauseOrResume
                                          ? Colors.orange
                                          : Colors.grey,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Pause",
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: meal.canPauseOrResume
                                            ? Colors.orange
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        // RESUME BUTTON - Show when paused and within cutoff time
                        if (meal.status == "Paused")
                          Expanded(
                            child: GestureDetector(
                              onTap: meal.canPauseOrResume
                                  ? () {
                                      Navigator.pop(context);
                                      _showResumeMealDialog(
                                          meal.subscription, meal.date);
                                    }
                                  : null,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: meal.canPauseOrResume
                                      ? Colors.green.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.play_circle_outline,
                                      color: meal.canPauseOrResume
                                          ? Colors.green
                                          : Colors.grey,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Resume",
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: meal.canPauseOrResume
                                            ? Colors.green
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(width: 8),

                        // SWAP BUTTON
                        Expanded(
                          child: GestureDetector(
                            onTap: meal.canSwap
                                ? () {
                                    Navigator.pop(context);
                                    _showSwapMealBottomSheet(meal.subscription);
                                  }
                                : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: meal.canSwap
                                    ? Colors.blue.withOpacity(0.2)
                                    : Colors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.swap_horiz,
                                    color: meal.canSwap
                                        ? Colors.blue
                                        : Colors.grey,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Swap",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: meal.canSwap
                                          ? Colors.blue
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // CANCEL BUTTON
                        Expanded(
                          child: GestureDetector(
                            onTap: meal.canCancel
                                ? () {
                                    Navigator.pop(context);
                                    _showCancelMealDialogWithSubscription(
                                        meal.subscription, meal.date);
                                  }
                                : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: meal.canCancel
                                    ? Colors.red.withOpacity(0.2)
                                    : Colors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.cancel_outlined,
                                    color: meal.canCancel
                                        ? Colors.red
                                        : Colors.grey,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Cancel",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: meal.canCancel
                                          ? Colors.red
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Messaging for disabled buttons
                  if (!meal.canPauseOrResume ||
                      !meal.canSwap ||
                      !meal.canCancel)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 4),
                      child: Text(
                        "You can only make changes until 11:59 PM the previous day.",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ] else
                  // Message for Express Plans
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Text(
                      "Actions not allowed for Express 1-Day plans.",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper to build detail rows
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: AppTheme.purple,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textDark,
              ),
              children: [
                TextSpan(
                  text: "$label: ",
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoSubscriptionsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          Text(
            "No Active Meal Plans",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Subscribe to a meal plan to see upcoming meals here.",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textMedium,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Navigate to meal plan screen - index 3 in bottom navigation
              final navigationState = Navigator.of(context);

              // Pop until we get to the main screen
              while (navigationState.canPop()) {
                navigationState.pop();
              }

              // Navigate to the meal plan tab

              // MealPlanScreen

              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const MealPlanScreen(),
                ),
              );

              // Navigator.of(context).pushReplacementNamed(
              //   '/',
              //   arguments: 3, // Meal Plan tab
              // );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.purple,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Browse Meal Plans',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSwapMealBottomSheet(Subscription subscription) {
    // Express plans cannot be swapped
    if (subscription.planType == 'express') {
      _showSnackBar(
        message: 'Swapping not allowed for Express 1-Day plans',
        backgroundColor: Colors.redAccent,
      );
      return;
    }

    // When in calendar view, check against selected day rather than next delivery date
    final cutoffDate = _isCalendarView
        ? DateTime(
                _selectedDay.year, _selectedDay.month, _selectedDay.day, 23, 59)
            .subtract(const Duration(days: 1))
        : DateTime(
                subscription.nextDeliveryDate.year,
                subscription.nextDeliveryDate.month,
                subscription.nextDeliveryDate.day,
                23,
                59)
            .subtract(const Duration(days: 1));

    final now = DateTime.now();
    if (now.isAfter(cutoffDate)) {
      _showSnackBar(
        message: 'Swap window closed for this meal',
        backgroundColor: Colors.redAccent,
      );
      return;
    }

    // Generate available options based on meal type
    final List<Map<String, String>> swapOptions =
        _getSwapOptionsForMealType(subscription.planType);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Swap Meal',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Current: ${subscription.mealItemName}',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: AppTheme.textDark,
              ),
            ),
            Text(
              'Date: ${_isCalendarView ? DateFormat('EEE dd, MMM yyyy').format(_selectedDay) : DateFormat('EEE dd, MMM yyyy').format(subscription.nextDeliveryDate)}',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Select a new meal to swap with:',
              style: GoogleFonts.poppins(
                color: AppTheme.textMedium,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            // Available meal options for swapping
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: swapOptions.length,
                itemBuilder: (context, index) {
                  final option = swapOptions[index];
                  // Don't show the current meal as an option
                  if (option['name'] == subscription.mealItemName) {
                    return const SizedBox.shrink();
                  }

                  return ListTile(
                    leading:
                        const Icon(Icons.food_bank, color: AppTheme.purple),
                    title: Text(
                      option['name'] ?? '',
                      style: GoogleFonts.poppins(),
                    ),
                    subtitle: Text(
                      option['description'] ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textMedium,
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      // Show loading indicator
                      _showSnackBar(
                        message: 'Swapping meal...',
                        duration: const Duration(seconds: 1),
                      );

                      // Swap the meal
                      final success = await _subscriptionService.swapMeal(
                        subscription.id,
                        option['name'] ?? '',
                      );

                      if (success && mounted) {
                        // Reload data after successful swap
                        await _loadSubscriptionsForStudent(_selectedStudentId!,
                            skipCancelled: true);

                        // Update the status in the mealsMap for the selected date
                        if (_isCalendarView) {
                          final normalizedDate = DateTime(_selectedDay.year,
                              _selectedDay.month, _selectedDay.day);
                          if (_mealsMap.containsKey(normalizedDate)) {
                            for (final meal in _mealsMap[normalizedDate]!) {
                              if (meal.subscription.id == subscription.id) {
                                meal.status = "Swapped";
                              }
                            }
                            setState(() {
                              _updateSelectedDayMeals();
                            });
                          }
                        }

                        _showSnackBar(
                          message: 'Successfully swapped to ${option['name']}',
                          backgroundColor: Colors.green,
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
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
    } else if (planType == 'lunch') {
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

    // Default empty list for express or other meal types
    return [];
  }

  // Helper function to generate scheduled dates for a subscription
  List<DateTime> _generateScheduleDates(
    DateTime startDate,
    DateTime endDate,
    List<int> selectedWeekdays,
    String planType,
  ) {
    List<DateTime> dates = [];

    // Handle Single Day or Express 1-Day plans
    if (planType == 'express' ||
        startDate.isAtSameMomentAs(endDate) ||
        startDate.add(const Duration(days: 1)).isAfter(endDate)) {
      log("📱 Single day or express plan detected!");

      if (planType == 'express') {
        log("📱 EXPRESS PLAN DATE: ${DateFormat('yyyy-MM-dd').format(startDate)}");

        // For Express plans, ensure the date is included even if it's in the past
        // This ensures the Express plan is always shown in the My Subscription screen
        return [startDate];
      } else {
        log("📱 Single day plan - returning single date: ${DateFormat('yyyy-MM-dd').format(startDate)}");
        return [startDate];
      }
    }

    // Use the actual start date
    DateTime actualStartDate = startDate;
    log("Using actual start date: ${DateFormat('yyyy-MM-dd').format(actualStartDate)}");

    // Determine if this is a custom plan
    bool isCustomPlan =
        selectedWeekdays.isNotEmpty && selectedWeekdays.length < 5;

    // For Regular plan with no selected weekdays, use all weekdays Mon-Fri
    // For Custom plans, use only the specifically selected weekdays
    List<int> weekdays =
        selectedWeekdays.isEmpty ? [1, 2, 3, 4, 5] : selectedWeekdays;

    log("Is custom plan: $isCustomPlan");
    log("Using weekdays: $weekdays");

    // Generate all dates within the range
    DateTime current = actualStartDate;
    while (!current.isAfter(endDate)) {
      // Only include dates that match this subscription's weekday selection
      if (weekdays.contains(current.weekday)) {
        dates.add(current);
      }
      current = current.add(const Duration(days: 1));
    }

    log("Generated ${dates.length} dates from ${DateFormat('yyyy-MM-dd').format(actualStartDate)} to ${DateFormat('yyyy-MM-dd').format(endDate)}");

    // Log some sample dates for debugging
    if (dates.length > 0) {
      log("Sample dates for this subscription:");
      for (int i = 0; i < (dates.length > 5 ? 5 : dates.length); i++) {
        log("  Date ${i + 1}: ${DateFormat('yyyy-MM-dd (EEEE)').format(dates[i])}");
      }
    }

    return dates;
  }

  // Helper function to check if swap is allowed for a date
  bool _isSwapAllowed(DateTime date, String planType) {
    // Express plans cannot be swapped
    if (planType == 'express') {
      log("Swap not allowed: Express 1-Day plans can never be swapped");
      return false;
    }

    // Check if we're past the cutoff time (11:59 PM the day before)
    final now = DateTime.now();
    final cutoffDate = DateTime(date.year, date.month, date.day, 23, 59)
        .subtract(const Duration(days: 1));

    final bool allowed = now.isBefore(cutoffDate);
    if (!allowed) {
      log("Swap not allowed: Past cutoff time for date ${DateFormat('yyyy-MM-dd').format(date)}");
    }

    return allowed;
  }

  // Helper function to check if cancellation is allowed for a date
  bool _isCancelAllowed(DateTime date, String planType) {
    // Express plans cannot be cancelled
    if (planType == 'express') {
      log("Cancel not allowed: Express 1-Day plans can never be cancelled");
      return false;
    }

    // Only Breakfast and Lunch meals can be cancelled
    if (planType != 'breakfast' && planType != 'lunch') {
      log("Cancel not allowed: Only Breakfast and Lunch meals can be cancelled");
      return false;
    }

    // Check if we're past the cutoff time (11:59 PM the day before)
    final now = DateTime.now();
    final cutoffDate = DateTime(date.year, date.month, date.day, 23, 59)
        .subtract(const Duration(days: 1));

    return now.isBefore(cutoffDate);
  }

  // Helper function to check if pause/resume is allowed for a date
  bool _isPauseResumeAllowed(DateTime date, String planType) {
    // Express plans cannot be paused/resumed
    if (planType == 'express') {
      log("Pause/Resume not allowed: Express 1-Day plans can never be paused or resumed");
      return false;
    }

    // Check if we're past the cutoff time (11:59 PM the day before)
    final now = DateTime.now();
    final cutoffDate = DateTime(date.year, date.month, date.day, 23, 59)
        .subtract(const Duration(days: 1));

    return now.isBefore(cutoffDate);
  }

  // Helper method to show SnackBars with proper context
  void _showSnackBar({
    required String message,
    Color backgroundColor = Colors.black,
    bool isLoading = false,
    Duration duration = const Duration(seconds: 2),
  }) {
    if (!mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.clearSnackBars();

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: isLoading
            ? Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    message,
                    style: GoogleFonts.poppins(),
                  ),
                ],
              )
            : Text(
                message,
                style: GoogleFonts.poppins(),
              ),
        duration: duration,
        backgroundColor: backgroundColor,
      ),
    );
  }

  // Method to remove a cancelled meal from all views
  void _removeCancelledMealFromViews(MealData cancelledMeal) {
    log('[Meal Cancellation] Starting removal of cancelled meal from views: ${cancelledMeal.toString()}');

    // Get the subscription ID
    final String subscriptionId = cancelledMeal.subscription.id;

    log('[Meal Cancellation] Working with subscription ID: $subscriptionId');

    // Update meal status
    cancelledMeal.status = 'Cancelled';
    log('[Meal Cancellation] Updated meal status to: ${cancelledMeal.status}');

    // Add the date to cancelled dates set for UI indication
    final DateTime deliveryDate = cancelledMeal.date;
    _cancelledMealDates.add(deliveryDate);
    log('[Meal Cancellation] Added ${DateFormat('yyyy-MM-dd').format(deliveryDate)} to cancelled dates');

    // Find the date key for the meal in _mealsMap
    DateTime? dateKey;
    for (final date in _mealsMap.keys) {
      if (date.year == deliveryDate.year &&
          date.month == deliveryDate.month &&
          date.day == deliveryDate.day) {
        dateKey = date;
        break;
      }
    }

    if (dateKey != null) {
      log('[Meal Cancellation] Found date key: ${DateFormat('yyyy-MM-dd').format(dateKey)}');

      // Get meals for this date
      final List<MealData> mealsForDate = _mealsMap[dateKey] ?? [];

      // Find the index of the cancelled meal
      final int cancelledMealIndex = mealsForDate.indexWhere((meal) =>
          meal.subscription.id == subscriptionId &&
          meal.date.day == deliveryDate.day &&
          meal.date.month == deliveryDate.month &&
          meal.date.year == deliveryDate.year);

      if (cancelledMealIndex != -1) {
        log('[Meal Cancellation] Found meal at index: $cancelledMealIndex for date: ${DateFormat('yyyy-MM-dd').format(dateKey)}');

        // If this is the only meal for that date, remove the whole entry
        if (mealsForDate.length == 1) {
          _mealsMap.remove(dateKey);
          log('[Meal Cancellation] Removed entire entry for date: ${DateFormat('yyyy-MM-dd').format(dateKey)}');
        }
      } else {
        log('[Meal Cancellation] Warning: Cancelled meal not found in _mealsMap for date: ${DateFormat('yyyy-MM-dd').format(dateKey)}');
      }
    } else {
      log('[Meal Cancellation] Warning: Date key not found for cancelled meal: ${DateFormat('yyyy-MM-dd').format(deliveryDate)}');
    }

    // Update UI
    if (mounted) {
      setState(() {
        // Update _selectedDateMeals if the cancelled meal was for the selected day
        if (_selectedDay.year == deliveryDate.year &&
            _selectedDay.month == deliveryDate.month &&
            _selectedDay.day == deliveryDate.day) {
          _selectedDateMeals = _mealsMap[_selectedDay] ?? [];
          log('[Meal Cancellation] Updated _selectedDateMeals, new count: ${_selectedDateMeals.length}');
        }
      });
    } else {
      log('[Meal Cancellation] Widget no longer mounted, skipping UI update');
    }
  }

  // Show dialog to confirm cancelling a meal
  void _showCancelMealDialog(MealData meal) {
    log('cancel meal flow: confirmation popup opened');
    log('cancel meal flow: Showing cancel meal dialog for: ${meal.name}');

    // Extract the student ID from the subscription
    final String studentId = meal.subscription.studentId;
    log('cancel meal flow: Student ID for cancellation: $studentId');

    // Show dialog to confirm cancellation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Meal'),
        content:
            const Text('Are you sure you want to cancel this meal delivery?'),
        actions: [
          TextButton(
            onPressed: () {
              log('cancel meal flow: User chose to keep meal');
              Navigator.of(context).pop(); // Close dialog
            },
            child: const Text('Keep Meal'),
          ),
          TextButton(
            onPressed: () async {
              log('cancel meal flow: User confirmed cancellation - cancel button clicked');
              Navigator.of(context).pop(); // Close dialog

              // Show loading snackbar
              _showSnackBar(
                message: 'Cancelling meal...',
                isLoading: true,
              );

              // Get subscription ID from the meal
              final String subscriptionId = meal.subscription.id;
              log('cancel meal flow: cancel API triggered');
              log('cancel meal flow: Cancelling meal with subscription ID: $subscriptionId');

              try {
                // Call service to cancel the meal
                final success = await _subscriptionService.cancelMealDelivery(
                  subscriptionId,
                  meal.date,
                  studentId: studentId,
                );

                // Hide loading snackbar
                if (mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                }

                if (success) {
                  log('cancel meal flow: API success');
                  log('cancel meal flow: removing from upcoming meals');

                  // Remove the cancelled meal from our data structures
                  if (mounted) {
                    _removeCancelledMealFromViews(meal);

                    // Show success message
                    _showSnackBar(
                      message: 'Meal cancelled successfully',
                      backgroundColor: Colors.green,
                    );

                    // Fire the meal cancelled event to update the cancelled meals tab
                    log('cancel meal flow: Firing event to update cancelled meals tab');
                    final event = MealCancelledEvent(
                      meal.subscription.id,
                      meal.date,
                      studentId: studentId,
                      shouldNavigateToTab: true,
                    );
                    eventBus.fireMealCancelled(event);
                    log('cancel meal flow: adding to cancelled meals list');
                  }
                } else {
                  log('cancel meal flow: API failure - returned false');
                  if (mounted) {
                    _showSnackBar(
                      message: 'Failed to cancel meal',
                      backgroundColor: Colors.red,
                    );
                  }
                }
              } catch (e) {
                log('cancel meal flow: API error exception: $e');
                if (mounted) {
                  _showSnackBar(
                    message: 'Error cancelling meal: $e',
                    backgroundColor: Colors.red,
                  );
                }
              }
            },
            child: const Text('Cancel Meal'),
          ),
        ],
      ),
    );
  }

  // Helper to get formatted plan type display text
  String _getFormattedPlanType(Subscription subscription) {
    // Get custom plan status
    bool isCustomPlan = subscription.selectedWeekdays.isNotEmpty &&
        subscription.selectedWeekdays.length < 5;
    String customBadge = isCustomPlan ? " (Custom)" : " (Regular)";

    // Debug logging
    log("📊 Plan: ${subscription.id}, Type: ${subscription.planType}");
    log("📊 Date Range: ${DateFormat('yyyy-MM-dd').format(subscription.startDate)} to ${DateFormat('yyyy-MM-dd').format(subscription.endDate)}");
    log("📊 Selected Weekdays: ${subscription.selectedWeekdays}");

    // Handle Express plans
    if (subscription.planType == 'express') {
      return "Express 1-Day Lunch Plan";
    }

    // Handle Single Day plans
    if (subscription.endDate.difference(subscription.startDate).inDays <= 1) {
      return "Single Day ${subscription.planType == 'breakfast' ? 'Breakfast' : 'Lunch'} Plan";
    }

    // Get the meal type
    String mealType =
        subscription.planType == 'breakfast' ? 'Breakfast' : 'Lunch';

    // Calculate total delivery duration for plan name determination
    String planPeriod;

    if (isCustomPlan) {
      // For custom plans, calculate based on actual delivery occurrences
      int totalDeliveryDays = _calculateTotalDeliveryDays(
          subscription.startDate,
          subscription.endDate,
          subscription.selectedWeekdays);

      log("📊 Custom Plan: Total delivery days calculated: $totalDeliveryDays");

      // Apply the day range mapping to determine plan name
      if (totalDeliveryDays <= 7) {
        planPeriod = "Weekly";
      } else if (totalDeliveryDays <= 31) {
        planPeriod = "Monthly";
      } else if (totalDeliveryDays <= 90) {
        planPeriod = "Quarterly";
      } else if (totalDeliveryDays <= 180) {
        planPeriod = "Half-Yearly";
      } else {
        planPeriod = "Annual";
      }
    } else {
      // For regular plans, use the standard day range between start and end
      int days = subscription.endDate.difference(subscription.startDate).inDays;
      log("📊 Regular Plan: Total days in range: $days");

      // Apply the day range mapping to determine plan name
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
    }

    log("📊 Final Plan Period: $planPeriod");

    // Return the correct formatted plan name
    return "$planPeriod $mealType Plan$customBadge";
  }

  // Helper to calculate the total actual delivery days for a custom plan
  int _calculateTotalDeliveryDays(
      DateTime startDate, DateTime endDate, List<int> selectedWeekdays) {
    // For empty weekdays (standard Mon-Fri), use weekdays 1-5
    List<int> weekdays =
        selectedWeekdays.isEmpty ? [1, 2, 3, 4, 5] : selectedWeekdays;

    // If the plan spans less than a week, it's a partial week
    if (endDate.difference(startDate).inDays < 7) {
      int count = 0;
      DateTime current = startDate;
      while (!current.isAfter(endDate)) {
        if (weekdays.contains(current.weekday)) {
          count++;
        }
        current = current.add(const Duration(days: 1));
      }
      return count;
    }

    // Calculate how many of each weekday occurs in the date range
    int totalOccurrences = 0;

    // Count full weeks
    int fullWeeks = endDate.difference(startDate).inDays ~/ 7;
    totalOccurrences += fullWeeks * weekdays.length;

    // Handle remaining days
    DateTime remainingStart = startDate.add(Duration(days: fullWeeks * 7));
    DateTime current = remainingStart;

    while (!current.isAfter(endDate)) {
      if (weekdays.contains(current.weekday)) {
        totalOccurrences++;
      }
      current = current.add(const Duration(days: 1));
    }

    log("📊 Plan covers $totalOccurrences delivery days over ${endDate.difference(startDate).inDays} calendar days");
    return totalOccurrences;
  }

  // Helper function to format weekdays list to readable string
  String _formatWeekdays(List<int> weekdays) {
    const Map<int, String> weekdayNames = {
      1: 'Monday',
      2: 'Tuesday',
      3: 'Wednesday',
      4: 'Thursday',
      5: 'Friday',
      6: 'Saturday',
      7: 'Sunday',
    };

    List<String> days =
        weekdays.map((day) => weekdayNames[day] ?? 'Unknown').toList();
    return days.join(', ');
  }

  // Add a date to the cancelled dates for red dot marker in calendar
  void _addCancelledDateMarker(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    _cancelledMealDates.add(normalizedDate);
  }

  // Override calendar builder to show red dots for cancelled meal dates
  Widget _calendarBuilder(
      BuildContext context, DateTime day, DateTime focusedDay) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final hasMeals = _mealsMap.containsKey(normalizedDay) &&
        _mealsMap[normalizedDay]!.isNotEmpty;
    final isCancelled = _cancelledMealDates.contains(normalizedDay);

    final isSelected = isSameDay(day, _selectedDay);
    final isToday = isSameDay(day, DateTime.now());

    // Initialize decorations
    List<Widget> dots = [];

    // Add meal indicator (green dot)
    if (hasMeals) {
      dots.add(
        Positioned(
          bottom: 5,
          left: 18,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green,
            ),
          ),
        ),
      );
    }

    // Add cancelled meal indicator (red dot)
    if (isCancelled) {
      dots.add(
        Positioned(
          bottom: 5,
          right: 18,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color:
            isSelected ? AppTheme.purple.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? AppTheme.purple
              : isToday
                  ? AppTheme.purple.withOpacity(0.3)
                  : Colors.transparent,
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              day.day.toString(),
              style: GoogleFonts.poppins(
                color: isSelected
                    ? AppTheme.purple
                    : day.month == focusedDay.month
                        ? AppTheme.textDark
                        : AppTheme.textLight,
                fontWeight:
                    isSelected || isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          ...dots,
        ],
      ),
    );
  }

  // Function to find and show the appropriate action dialog based on meal status
  void _showActionDialogForMeal(MealData meal) {
    if (meal.status == "Paused") {
      // For paused meals, show the resume dialog
      _showResumeMealDialogWithMeal(meal);
    } else {
      // For active meals, show the cancel dialog
      _showCancelMealDialog(meal);
    }
  }

  // Show cancel meal dialog - overloaded version with Subscription and date
  void _showCancelMealDialogWithSubscription(
      Subscription subscription, DateTime targetDate) {
    // Create MealData from subscription and date
    final meal = _createMealDataFromSubscription(subscription, targetDate);
    _showCancelMealDialog(meal);
  }

  // Adapter method for showing cancel dialog using MealData
  void showCancelDialogForMealData(MealData meal) {
    log("meal delete flow: Using adapter method to show dialog for MealData");
    _showCancelMealDialog(meal);
  }

  // Helper adapter for showing cancel dialog for MealData objects
  void cancelMealDialogFromMealData(MealData meal) {
    log("meal delete flow: Using MealData adapter to show dialog");
    _showCancelMealDialog(meal);
  }

  // Helper to create a MealData object from a Subscription and date
  MealData _createMealDataFromSubscription(
      Subscription subscription, DateTime date) {
    // Find the student for this subscription
    final student = _studentsWithMealPlans.firstWhere(
      (s) => s.id == subscription.studentId,
      orElse: () => Student(
        id: subscription.studentId,
        name: "Unknown Student",
        schoolName: "",
        className: "",
        division: "",
        floor: "",
        allergies: "",
        schoolAddress: "",
        grade: "",
        section: "",
        profileImageUrl: "",
      ),
    );

    // Check if cancel/swap is allowed for this date
    final bool canSwap = _isSwapAllowed(date, subscription.planType);
    final bool canCancel = _isCancelAllowed(date, subscription.planType);
    final bool canPauseResume =
        _isPauseResumeAllowed(date, subscription.planType);

    // Create a MealData object
    return MealData(
      studentName: student.name,
      name: subscription.mealItemName,
      planType: _getFormattedPlanType(subscription),
      items: subscription.getMealItems(),
      status: "Scheduled", // Default status
      subscription: subscription,
      canSwap: canSwap,
      canCancel: canCancel,
      canPauseOrResume: canPauseResume,
      date: date,
    );
  }

  // Show dialog to pause a meal with Subscription and date
  void _showPauseMealDialog(Subscription subscription, DateTime targetDate) {
    // Create MealData from subscription and date
    final meal = _createMealDataFromSubscription(subscription, targetDate);
    _showPauseMealDialogWithMeal(meal);
  }

  // Show dialog to pause a meal using MealData
  void _showPauseMealDialogWithMeal(MealData meal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Pause Meal',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.orange.shade700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Would you like to pause this meal delivery?',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 8),
            Text(
              'Date: ${DateFormat('EEE dd, MMM yyyy').format(meal.date)}',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: AppTheme.textDark,
              ),
            ),
            Text(
              'Meal: ${meal.name}',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              // Close the dialog first
              Navigator.pop(context);

              if (!mounted) return;

              // Show loading indicator
              _showSnackBar(
                message: 'Pausing meal...',
                duration: const Duration(seconds: 1),
              );

              try {
                // Pause the meal for the specific date
                final success = await _subscriptionService.pauseMealDelivery(
                  meal.subscription.id,
                  meal.date,
                );

                if (!mounted) return;

                if (success) {
                  // Update meal status in the UI
                  if (_isCalendarView) {
                    final normalizedDate = DateTime(_selectedDay.year,
                        _selectedDay.month, _selectedDay.day);
                    if (_mealsMap.containsKey(normalizedDate)) {
                      for (final mealItem in _mealsMap[normalizedDate]!) {
                        if (mealItem.subscription.id == meal.subscription.id) {
                          setState(() {
                            mealItem.status = "Paused";
                            _updateSelectedDayMeals();
                          });
                        }
                      }
                    }
                  } else {
                    // Force reload for list view
                    await _loadSubscriptionsForStudent(_selectedStudentId!,
                        skipCancelled: true);
                  }

                  // Show success message
                  _showSnackBar(
                    message: 'Meal paused successfully!',
                    backgroundColor: Colors.orange,
                  );
                } else {
                  _showSnackBar(
                    message: 'Failed to pause meal. Please try again.',
                    backgroundColor: Colors.red,
                  );
                }
              } catch (e) {
                log("Error pausing meal: $e");
                if (mounted) {
                  _showSnackBar(
                    message: 'An error occurred: $e',
                    backgroundColor: Colors.red,
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: Text(
              'Pause Meal',
              style: GoogleFonts.poppins(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Show dialog to resume a meal (overloaded version with Subscription and date)
  void _showResumeMealDialog(Subscription subscription, DateTime targetDate) {
    // Create MealData from subscription and date
    final meal = _createMealDataFromSubscription(subscription, targetDate);
    _showResumeMealDialogWithMeal(meal);
  }

  // Show dialog to resume a meal using MealData
  void _showResumeMealDialogWithMeal(MealData meal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Resume Meal',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Would you like to resume this meal delivery?',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 8),
            Text(
              'Date: ${DateFormat('EEE dd, MMM yyyy').format(meal.date)}',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: AppTheme.textDark,
              ),
            ),
            Text(
              'Meal: ${meal.name}',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              // Close the dialog first
              Navigator.pop(context);

              if (!mounted) return;

              // Show loading indicator
              _showSnackBar(
                message: 'Resuming meal...',
                duration: const Duration(seconds: 1),
              );

              try {
                // Resume the meal for the specific date
                final success = await _subscriptionService.resumeMealDelivery(
                  meal.subscription.id,
                  meal.date,
                );

                if (!mounted) return;

                if (success) {
                  // Update meal status in the UI
                  if (_isCalendarView) {
                    final normalizedDate = DateTime(_selectedDay.year,
                        _selectedDay.month, _selectedDay.day);
                    if (_mealsMap.containsKey(normalizedDate)) {
                      for (final mealItem in _mealsMap[normalizedDate]!) {
                        if (mealItem.subscription.id == meal.subscription.id) {
                          setState(() {
                            mealItem.status = "Scheduled";
                            _updateSelectedDayMeals();
                          });
                        }
                      }
                    }
                  } else {
                    // Force reload for list view
                    await _loadSubscriptionsForStudent(_selectedStudentId!,
                        skipCancelled: true);
                  }

                  // Show success message
                  _showSnackBar(
                    message: 'Meal resumed successfully!',
                    backgroundColor: Colors.green,
                  );
                } else {
                  _showSnackBar(
                    message: 'Failed to resume meal. Please try again.',
                    backgroundColor: Colors.red,
                  );
                }
              } catch (e) {
                log("Error resuming meal: $e");
                if (mounted) {
                  _showSnackBar(
                    message: 'An error occurred: $e',
                    backgroundColor: Colors.red,
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Resume',
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // Update the calendar markers to include cancelled dates
  List<dynamic> _getEventsForDay(DateTime day) {
    // Normalize the date to avoid time comparisons
    final normalizedDate = DateTime(day.year, day.month, day.day);

    // Events list - will contain different types of markers
    List<dynamic> events = [];

    // Add regular meal marker if there's a meal on this date
    if (_mealsMap.containsKey(normalizedDate)) {
      events.add('meal');
    }

    // Add cancelled meal marker if this date has a cancelled meal
    if (_cancelledMealDates.contains(normalizedDate)) {
      events.add('cancelled');
    }

    return events;
  }

  // Custom calendar marker builder to show different markers for meals and cancelled meals
  Widget _buildCalendarMarker(List<dynamic> events, DateTime day) {
    // Show both markers side by side if needed
    if (events.isEmpty) {
      return Container(); // Return empty container for days without events
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Regular meal marker (purple dot)
        if (events.contains('meal'))
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.purple,
            ),
          ),

        // Cancelled meal marker (red dot)
        if (events.contains('cancelled'))
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red,
            ),
          ),
      ],
    );
  }

  // Helper to build a detail row for dialogs
  Widget _buildDialogDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade700,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: AppTheme.textDark,
            ),
            softWrap: true,
          ),
        ),
      ],
    );
  }

  // Helper to get Student for a subscription
  Future<Student?> _getStudentForSubscription(Subscription subscription) async {
    // If we already have the student loaded, return it
    if (_studentsWithMealPlans.any((s) => s.id == subscription.studentId)) {
      return _studentsWithMealPlans
          .firstWhere((s) => s.id == subscription.studentId);
    }

    // Otherwise load the student from the service
    try {
      final student =
          await _studentProfileService.getStudentById(subscription.studentId);
      return student;
    } catch (e) {
      log('Error loading student: $e');
      return null;
    }
  }

  // Helper adapter for handling MealData objects
  void cancelMealFromMealData(MealData meal) {
    log("meal delete flow: Using MealData adapter to cancel meal");
    _removeCancelledMealFromViews(meal);
  }

  // Adapter method for cancelling a meal using MealData
  void handleMealDataCancellation(MealData meal) {
    log("meal delete flow: Using adapter method to cancel MealData");
    _removeCancelledMealFromViews(meal);
  }
}
