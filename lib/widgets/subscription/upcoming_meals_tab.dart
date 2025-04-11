import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/screens/meal_plan_screen.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:startwell/widgets/subscription/meal_card.dart';
import 'package:intl/intl.dart';
import 'package:startwell/services/meal_service.dart';
import 'package:startwell/services/student_profile_service.dart';
import 'package:startwell/models/student_model.dart';
import 'package:startwell/models/subscription_model.dart';
import 'package:table_calendar/table_calendar.dart';

class UpcomingMealsTab extends StatefulWidget {
  final String? selectedStudentId;
  final DateTime startDate;
  final DateTime endDate;

  const UpcomingMealsTab({
    Key? key,
    this.selectedStudentId,
    required this.startDate,
    required this.endDate,
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
  String status; // Scheduled / Swapped / Cancelled - Non-final to allow updates
  final Subscription subscription;
  final bool canSwap;
  final bool canCancel;

  MealData({
    required this.studentName,
    required this.name,
    required this.planType,
    required this.items,
    required this.status,
    required this.subscription,
    required this.canSwap,
    required this.canCancel,
  });

  // Override toString for better logging
  @override
  String toString() {
    return 'MealData(student: $studentName, meal: $name, type: $planType, status: $status, canSwap: $canSwap, canCancel: $canCancel)';
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

  @override
  void initState() {
    super.initState();
    _loadStudentsWithMealPlans();
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

        await _loadSubscriptionsForStudent(_selectedStudentId!);
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

  Future<void> _loadSubscriptionsForStudent(String studentId) async {
    setState(() {
      _isLoading = true;
    });
    log("_loadSubscriptionsForStudent studentId: $studentId");
    log("_loadSubscriptionsForStudent widget.startDate: ${widget.startDate}");
    log("_loadSubscriptionsForStudent widget.endDate: ${widget.endDate}");

    // Improved logging for collections
    if (_activeSubscriptions.isNotEmpty) {
      log("_loadSubscriptionsForStudent _activeSubscriptions count: ${_activeSubscriptions.length}");
      for (int i = 0; i < _activeSubscriptions.length; i++) {
        log("_loadSubscriptionsForStudent _activeSubscription[$i]: ${_activeSubscriptions[i]}");
      }
    } else {
      log("_loadSubscriptionsForStudent _activeSubscriptions: empty");
    }

    if (_studentsWithMealPlans.isNotEmpty) {
      log("_loadSubscriptionsForStudent _studentsWithMealPlans count: ${_studentsWithMealPlans.length}");
      for (int i = 0; i < _studentsWithMealPlans.length; i++) {
        log("_loadSubscriptionsForStudent _studentsWithMealPlans[$i]: ${_studentsWithMealPlans[i]}");
      }
    } else {
      log("_loadSubscriptionsForStudent _studentsWithMealPlans: empty");
    }

    log("_loadSubscriptionsForStudent _selectedStudentId: $_selectedStudentId");

    // Log summary of meal map
    if (_mealsMap.isNotEmpty) {
      log("_loadSubscriptionsForStudent _mealsMap entries: ${_mealsMap.length}");
      // Log first 3 entries at most
      int count = 0;
      _mealsMap.forEach((date, meals) {
        if (count < 3) {
          log("_loadSubscriptionsForStudent _mealsMap[${DateFormat('yyyy-MM-dd').format(date)}]: ${meals.length} meals");
          count++;
        }
      });
    } else {
      log("_loadSubscriptionsForStudent _mealsMap: empty");
    }

    if (_selectedDateMeals.isNotEmpty) {
      log("_loadSubscriptionsForStudent _selectedDateMeals count: ${_selectedDateMeals.length}");
    } else {
      log("_loadSubscriptionsForStudent _selectedDateMeals: empty");
    }

    try {
      // Get active subscriptions based on the student's actual meal plans
      _activeSubscriptions = await _subscriptionService
          .getActiveSubscriptionsForStudent(studentId);

      // Generate meal map for calendar view
      _generateMealMap();
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
      final scheduledDates = _generateScheduleDates(
        subscription.startDate,
        subscription.endDate,
        subscription.selectedWeekdays,
        subscription.planType,
      );

      log("_generateScheduleDates subscription for studentId: ${subscription.studentId}, plan: ${subscription.planType}");
      log("_generateScheduleDates subscription.startDate: ${DateFormat('yyyy-MM-dd').format(subscription.startDate)}");
      log("_generateScheduleDates subscription.endDate: ${DateFormat('yyyy-MM-dd').format(subscription.endDate)}");
      log("_generateScheduleDates subscription.selectedWeekdays: ${subscription.selectedWeekdays}");
      log("_generateScheduleDates subscription.planType: ${subscription.planType}");

      if (scheduledDates.isNotEmpty) {
        log("_generateScheduleDates scheduledDates count: ${scheduledDates.length}");
        String dateList = scheduledDates
            .map((date) => DateFormat('yyyy-MM-dd').format(date))
            .join(', ');
        log("_generateScheduleDates scheduledDates: $dateList");
      } else {
        log("_generateScheduleDates scheduledDates: empty");
      }

      // Create a meal entry for each scheduled date
      for (final date in scheduledDates) {
        // Normalize date to compare dates without time
        final normalizedDate = DateTime(date.year, date.month, date.day);

        // Check if date is valid for swap and cancel
        final bool canSwap = _isSwapAllowed(date, subscription.planType);
        final bool canCancel = _isCancelAllowed(date, subscription.planType);

        // Create meal data object
        final mealData = MealData(
          studentName: student.name,
          name: subscription.mealItemName,
          planType: subscription.subscriptionType +
              " " +
              (subscription.planType == 'breakfast' ? 'Breakfast' : 'Lunch') +
              " Plan",
          items: subscription.getMealItems(),
          status: "Scheduled", // Default status
          subscription: subscription,
          canSwap: canSwap,
          canCancel: canCancel,
        );

        // Add to map
        if (_mealsMap.containsKey(normalizedDate)) {
          _mealsMap[normalizedDate]!.add(mealData);
        } else {
          _mealsMap[normalizedDate] = [mealData];
        }
      }
    }

    // Update selected day meals
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
                  _loadSubscriptionsForStudent(value);
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

          // Display a date header if this is the first meal of the day or the first item
          final bool showDateHeader = index == 0 ||
              (index > 0 &&
                  !isSameDay(
                      date, allScheduledMeals[index - 1]['date'] as DateTime));

          // Create a MealData object to match calendar view's pattern
          final mealDataObj = MealData(
            studentName: student.name,
            name: subscription.mealItemName,
            planType: subscription.subscriptionType +
                " " +
                (subscription.planType == 'breakfast' ? 'Breakfast' : 'Lunch') +
                " Plan",
            items: subscription.getMealItems(),
            status: "Scheduled",
            subscription: subscription,
            canSwap: canSwap,
            canCancel: canCancel,
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
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              "Scheduled",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.green.shade800,
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
                      _buildDetailRow(Icons.calendar_today, "Subscription Plan",
                          mealDataObj.planType),
                      const SizedBox(height: 8),
                      _buildDetailRow(Icons.event, "Scheduled Date",
                          DateFormat('EEE dd, MMM yyyy').format(date)),
                      const SizedBox(height: 8),
                      _buildDetailRow(Icons.lunch_dining, "Items",
                          subscription.getMealItems().join(", ")),

                      const SizedBox(height: 20),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: canSwap
                                  ? () => _showSwapMealBottomSheet(subscription)
                                  : null,
                              icon: const Icon(Icons.swap_horiz, size: 18),
                              label: Text(
                                'Swap Meal',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isBreakfast
                                    ? AppTheme.purple
                                    : Colors.green.shade700,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey.shade300,
                                disabledForegroundColor: Colors.grey.shade600,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: canCancel
                                  ? () => _showCancelMealDialog(subscription)
                                  : null,
                              icon: const Icon(Icons.close, size: 18),
                              label: Text(
                                'Cancel Meal',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                                side: const BorderSide(color: Colors.redAccent),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
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

                      if (!canSwap && subscription.planType == 'express')
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 4),
                          child: Text(
                            "Swapping not allowed for Express 1-Day plans",
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
              firstDay: DateTime.now().subtract(const Duration(days: 30)),
              lastDay: DateTime.now().add(const Duration(days: 90)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: CalendarFormat.month,
              eventLoader: (day) {
                final normalizedDay = DateTime(day.year, day.month, day.day);
                return _mealsMap[normalizedDay] ?? [];
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                  _updateSelectedDayMeals();
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
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
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.isEmpty) return const SizedBox.shrink();

                  // Use different colors for different statuses
                  final colors = events.map((e) {
                    final mealData = e as MealData;
                    if (mealData.status == "Cancelled") return Colors.red;
                    if (mealData.status == "Swapped") return Colors.orange;
                    return mealData.subscription.planType == 'breakfast'
                        ? AppTheme.purple // Purple for breakfast
                        : Colors.green; // Green for lunch
                  }).toList();

                  // Group markers by meal type to limit to at most 2 markers
                  // (one for breakfast, one for lunch)
                  return Positioned(
                    bottom: 1,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: colors
                          .take(colors.length > 2 ? 2 : colors.length)
                          .map((color) => Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 1),
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: color,
                                ),
                              ))
                          .toList(),
                    ),
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
                        color: meal.status == "Scheduled"
                            ? Colors.green.withOpacity(0.2)
                            : meal.status == "Swapped"
                                ? Colors.orange.withOpacity(0.2)
                                : Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        meal.status,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: meal.status == "Scheduled"
                              ? Colors.green.shade800
                              : meal.status == "Swapped"
                                  ? Colors.orange.shade800
                                  : Colors.red.shade800,
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
                    Icons.calendar_today, "Subscription Plan", meal.planType),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.event, "Scheduled Date",
                    DateFormat('EEE dd, MMM yyyy').format(_selectedDay)),
                const SizedBox(height: 8),
                _buildDetailRow(
                    Icons.lunch_dining, "Items", meal.items.join(", ")),

                const SizedBox(height: 20),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: meal.canSwap
                            ? () => _showSwapMealBottomSheet(meal.subscription)
                            : null,
                        icon: const Icon(Icons.swap_horiz, size: 18),
                        label: Text(
                          'Swap Meal',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isBreakfast
                              ? AppTheme.purple
                              : Colors.green.shade700,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          disabledForegroundColor: Colors.grey.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: meal.canCancel
                            ? () => _showCancelMealDialog(meal.subscription)
                            : null,
                        icon: const Icon(Icons.close, size: 18),
                        label: Text(
                          'Cancel Meal',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                if (meal.canSwap && meal.subscription.planType != 'express')
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

                if (!meal.canSwap && meal.subscription.planType == 'express')
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text(
                      "Swapping not allowed for Express 1-Day plans",
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),

                if (!meal.canCancel)
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Swapping not allowed for Express 1-Day plans',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.redAccent,
        ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Swap window closed for this meal',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.redAccent,
        ),
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Swapping meal...',
                            style: GoogleFonts.poppins(),
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );

                      // Swap the meal
                      final success = await _subscriptionService.swapMeal(
                        subscription.id,
                        option['name'] ?? '',
                      );

                      if (success && mounted) {
                        // Reload data after successful swap
                        await _loadSubscriptionsForStudent(_selectedStudentId!);

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

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Successfully swapped to ${option['name']}',
                              style: GoogleFonts.poppins(),
                            ),
                            backgroundColor: Colors.green,
                          ),
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

  // Helper function to generate all scheduled dates for a subscription
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
      return [startDate];
    }

    // Fix for incorrect start date - ensure we start on the next Monday (14th) if startDate is earlier
    DateTime actualStartDate = startDate;

    // For Regular plan with no selected weekdays, use all weekdays Mon-Fri
    List<int> weekdays =
        selectedWeekdays.isEmpty ? [1, 2, 3, 4, 5] : selectedWeekdays;

    // If we have a Monday-Friday plan, ensure we start on a weekday
    if (selectedWeekdays.isEmpty) {
      // Find the next Monday (weekday 1) if the start date is before the 14th
      if (startDate.day < 14 &&
          startDate.month == 4 &&
          startDate.year == 2025) {
        // Set to April 14, 2025 (Monday)
        actualStartDate = DateTime(2025, 4, 14);
      }
    }

    // Generate all dates within the range
    DateTime current = actualStartDate;
    while (!current.isAfter(endDate)) {
      if (weekdays.contains(current.weekday)) {
        dates.add(current);
      }
      current = current.add(const Duration(days: 1));
    }

    return dates;
  }

  // Helper function to check if swap is allowed for a date
  bool _isSwapAllowed(DateTime date, String planType) {
    // Express plans cannot be swapped
    if (planType == 'express') {
      return false;
    }

    // Check if we're past the cutoff time (11:59 PM the day before)
    final now = DateTime.now();
    final cutoffDate = DateTime(date.year, date.month, date.day, 23, 59)
        .subtract(const Duration(days: 1));

    return now.isBefore(cutoffDate);
  }

  // Helper function to check if cancellation is allowed for a date
  bool _isCancelAllowed(DateTime date, String planType) {
    // Check if we're past the cutoff time (11:59 PM the day before)
    final now = DateTime.now();
    final cutoffDate = DateTime(date.year, date.month, date.day, 23, 59)
        .subtract(const Duration(days: 1));

    return now.isBefore(cutoffDate);
  }

  void _showCancelMealDialog(Subscription subscription) {
    // For calendar view, use the selected date
    final DateTime targetDate =
        _isCalendarView ? _selectedDay : subscription.nextDeliveryDate;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cancel Meal',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel this meal?',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 8),
            Text(
              'Date: ${DateFormat('EEE dd, MMM yyyy').format(targetDate)}',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: AppTheme.textDark,
              ),
            ),
            Text(
              'Meal: ${subscription.mealItemName}',
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
              'No',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Show loading indicator
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Cancelling meal...',
                    style: GoogleFonts.poppins(),
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );

              // Cancel the meal for the specific date
              final success = await _subscriptionService.cancelMealDelivery(
                subscription.id,
                targetDate,
              );

              if (success && mounted) {
                // Reload data after successful cancellation
                await _loadSubscriptionsForStudent(_selectedStudentId!);

                // Update the status in the mealsMap for the selected date
                if (_isCalendarView) {
                  final normalizedDate = DateTime(
                      _selectedDay.year, _selectedDay.month, _selectedDay.day);
                  if (_mealsMap.containsKey(normalizedDate)) {
                    for (final meal in _mealsMap[normalizedDate]!) {
                      if (meal.subscription.id == subscription.id) {
                        meal.status = "Cancelled";
                      }
                    }
                    setState(() {
                      _updateSelectedDayMeals();
                    });
                  }
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Meal cancelled successfully!',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Yes',
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
}
