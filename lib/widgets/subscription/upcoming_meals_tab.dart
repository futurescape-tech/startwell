import 'dart:developer';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/services/meal_service.dart';
import 'package:startwell/services/student_profile_service.dart';
import 'package:startwell/services/subscription_service.dart' as service;
import 'package:startwell/services/cancelled_meal_service.dart';
import 'package:startwell/models/student_model.dart';
import 'package:startwell/models/subscription_model.dart';
import 'package:startwell/models/cancelled_meal.dart';
import 'package:startwell/widgets/subscription/cancelled_meals_tab.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:startwell/screens/my_subscription_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:startwell/utils/meal_constants.dart';
import 'package:startwell/themes/app_theme.dart';
import 'dart:math' as math;
import 'package:startwell/services/meal_data_service.dart';
import 'package:startwell/utils/meal_names.dart';

// Extension to add capitalize method to String
extension StringExtension on String {
  String capitalize() {
    return isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : '';
  }
}

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
  final String displayPlanType;
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
    required this.displayPlanType,
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
  bool _isCalendarView = true;
  bool _isLoading = true;
  final MealService _mealService = MealService();
  final StudentProfileService _studentProfileService = StudentProfileService();
  final service.SubscriptionService _subscriptionService =
      service.SubscriptionService();
  final ScrollController _calendarScrollController = ScrollController();

  List<Subscription> _activeSubscriptions = [];
  String? _selectedStudentId;
  List<Student> _studentsWithMealPlans = [];
  List<Map<String, dynamic>> _allScheduledMeals = [];

  // Map to cache meal data by student ID for faster switching between students
  final Map<String, List<Subscription>> _cachedSubscriptionsByStudent = {};
  final Map<String, Map<DateTime, List<MealData>>> _cachedMealMapByStudent = {};

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
    await _loadCombinedSubscriptions();
    // We're now applying local swaps in _generateMealMap after the meal map is fully populated
  }

  // Save the currently selected student ID to SharedPreferences
  Future<void> _saveSelectedStudentId(String studentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_selected_student_id', studentId);
      log('[upcoming_meals] Saved selected student ID: $studentId');
    } catch (e) {
      log('[upcoming_meals] Error saving selected student ID: $e');
    }
  }

  // New method to load combined breakfast and lunch subscriptions
  Future<void> _loadCombinedSubscriptions() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get all keys that contain combined plans
      final combinedPlanKeys = prefs
          .getKeys()
          .where((key) => key.startsWith('combined_subscription_'))
          .toList();

      log('[upcoming_meals] Found ${combinedPlanKeys.length} combined subscription plans');

      for (final key in combinedPlanKeys) {
        final combinedJson = prefs.getString(key);
        if (combinedJson != null) {
          final combinedData = jsonDecode(combinedJson);

          // Extract student ID to check if this combined plan belongs to the selected student
          final String studentId = combinedData['studentId'];

          // Only process if this is for the currently selected student
          if (_selectedStudentId == null || _selectedStudentId == studentId) {
            log('[upcoming_meals] Processing combined plan for student $studentId');

            // Extract plan details
            final DateTime startDate =
                DateTime.parse(combinedData['startDate']);
            final DateTime endDate = DateTime.parse(combinedData['endDate']);
            final String breakfastPlanType = combinedData['breakfastPlanType'];
            final String lunchPlanType = combinedData['lunchPlanType'];
            final String planId = combinedData['planId'];
            final String? mealPreference = combinedData['mealPreference'];

            // Find the student object
            final student = _studentsWithMealPlans.firstWhere(
              (s) => s.id == studentId,
              orElse: () =>
                  Student.empty(), // Use an empty student as a fallback
            );

            if (student.id.isNotEmpty) {
              // Create breakfast subscription
              final breakfastSubscription = Subscription(
                id: 'breakfast_$planId',
                studentId: studentId,
                planType: breakfastPlanType,
                startDate: startDate,
                endDate: endDate,
                status: SubscriptionStatus.active,
                mealName: _getMealServiceNameFromPreference(
                    'breakfast', mealPreference),
                isBreakfastPlan: true,
                isLunchPlan: false,
              );

              // Create lunch subscription
              final lunchSubscription = Subscription(
                id: 'lunch_$planId',
                studentId: studentId,
                planType: lunchPlanType,
                startDate: startDate,
                endDate: endDate,
                status: SubscriptionStatus.active,
                mealName:
                    _getMealServiceNameFromPreference('lunch', mealPreference),
                isBreakfastPlan: false,
                isLunchPlan: true,
              );

              // Add both subscriptions to active subscriptions list if not already present
              bool breakfastExists = _activeSubscriptions.any((s) =>
                  s.id == breakfastSubscription.id ||
                  (s.studentId == studentId && s.isBreakfastPlan));

              bool lunchExists = _activeSubscriptions.any((s) =>
                  s.id == lunchSubscription.id ||
                  (s.studentId == studentId && s.isLunchPlan));

              if (!breakfastExists) {
                _activeSubscriptions.add(breakfastSubscription);
                log('[upcoming_meals] Added breakfast subscription for student $studentId');
              }

              if (!lunchExists) {
                _activeSubscriptions.add(lunchSubscription);
                log('[upcoming_meals] Added lunch subscription for student $studentId');
              }

              // Subscriptions are now in _activeSubscriptions and will be processed by _loadData
            }
          }
        }
      }

      // Update UI
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      log('[upcoming_meals] Error loading combined subscriptions: $e');
    }
  }

  // Helper method to get meal name from preference
  String _getMealServiceNameFromPreference(
      String mealType, String? preference) {
    if (preference == null) {
      return mealType == 'breakfast'
          ? 'Breakfast of the Day'
          : 'Lunch of the Day';
    }
    final lowerPref = preference.trim().toLowerCase();
    if (mealType == 'breakfast' && lowerPref.endsWith('breakfast')) {
      return preference.trim();
    }
    if (mealType == 'lunch' && lowerPref.endsWith('lunch')) {
      return preference.trim();
    }
    return preference.trim() +
        ' ' +
        mealType.substring(0, 1).toUpperCase() +
        mealType.substring(1);
  }

  // Enhance meal card to show subscription type more clearly
  Widget _buildMealCard(MealData meal) {
    // Determine if this is a breakfast or lunch meal
    final bool isBreakfast =
        meal.planType == 'breakfast' || meal.subscription.isBreakfastPlan;

    final Color mealColor = isBreakfast ? Colors.amber : AppTheme.purple;
    final String mealTypeLabel = isBreakfast ? 'Breakfast' : 'Lunch';

    // Get meal image URL by meal name
    final allMeals = MealDataService.getAllMeals();
    final mealObj = allMeals.firstWhere(
      (m) => m.name.toLowerCase() == meal.name.toLowerCase(),
      orElse: () => allMeals.first,
    );
    final String mealImageUrl = mealObj.imageUrl.isNotEmpty
        ? mealObj.imageUrl
        : 'https://i.imgur.com/vYGZVGz.jpg'; // fallback image

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: mealColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Meal image instead of icon
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey[200],
                    child: _getMealImage(mealImageUrl, meal.planType,
                        mealName: meal.name),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.studentName,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: mealColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Remove meal icon here
                                // Icon(
                                //   mealIcon,
                                //   size: 14,
                                //   color: mealColor,
                                // ),
                                // const SizedBox(width: 4),
                                Text(
                                  mealTypeLabel,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: mealColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            meal.displayPlanType,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: AppTheme.textDark,
                              fontWeight: FontWeight.w500,
                            ),
                            softWrap: true,
                            overflow: TextOverflow.visible,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status indicator (e.g., Delivered, Pending)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(meal.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getStatusColor(meal.status).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    meal.status,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _getStatusColor(meal.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Rest of the existing meal card content
            // ... existing meal card content ...
          ],
        ),
      ),
    );
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

          // Ensure displayPlanType is not null
          String displayPlanType;
          try {
            displayPlanType = meals[i].displayPlanType;
            // If we get here, displayPlanType is not null
          } catch (e) {
            // If an error occurs when accessing displayPlanType, generate a new one
            displayPlanType = meals[i].subscription.planDisplayName;
            log('[swap_meal_flow] Error accessing displayPlanType: $e. Generated new value: $displayPlanType');
          }

          final updatedMeal = MealData(
            studentName: meals[i].studentName,
            name: newMealName,
            planType: meals[i].planType,
            displayPlanType: displayPlanType,
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
      // First, check for recently active students in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      List<String> recentStudentIds = [];

      // Get the list of recently active student IDs
      final recentStudentsKey = 'recently_active_students';
      if (prefs.containsKey(recentStudentsKey)) {
        final recentStudentsJson = prefs.getString(recentStudentsKey) ?? '[]';
        recentStudentIds = List<String>.from(jsonDecode(recentStudentsJson));
        log('[upcoming_meals] Found ${recentStudentIds.length} recently active students');
      }

      // Check for the last selected student ID
      String? lastSelectedStudentId =
          prefs.getString('last_selected_student_id');
      if (lastSelectedStudentId != null) {
        log('[upcoming_meals] Found last selected student ID: $lastSelectedStudentId');
      }

      // Get student profiles from prefs for recently active students first
      List<Student> recentStudents = [];
      for (var studentId in recentStudentIds) {
        final key = 'student_profile_$studentId';
        if (prefs.containsKey(key)) {
          try {
            final studentJson = prefs.getString(key);
            if (studentJson != null) {
              final Map<String, dynamic> studentData = jsonDecode(studentJson);
              final student = Student.fromJson(studentData);
              recentStudents.add(student);
              log('[upcoming_meals] Loaded student ${student.name} from SharedPreferences');
            }
          } catch (e) {
            log('[upcoming_meals] Error parsing student profile from SharedPreferences: $e');
          }
        }
      }

      // Then get the rest of the students from the service
      final List<String> studentIds =
          await _mealService.getStudentsWithMealPlans();
      final List<Student> otherStudents =
          await _studentProfileService.getStudentProfiles();

      // Filter out students that are already in recentStudents
      final existingStudentIds = recentStudents.map((s) => s.id).toList();
      otherStudents
          .removeWhere((student) => existingStudentIds.contains(student.id));

      // Merge the lists, putting recent students first
      _studentsWithMealPlans = [...recentStudents];

      // Add any other students with meal plans that aren't in recent list
      _studentsWithMealPlans.addAll(otherStudents
          .where((student) => studentIds.contains(student.id))
          .toList());

      if (_studentsWithMealPlans.isNotEmpty) {
        // Priority for student selection:
        // 1. Explicitly provided selectedStudentId from widget
        // 2. Last selected student ID from SharedPreferences
        // 3. Most recent student from recents list
        // 4. First student in the list

        if (widget.selectedStudentId != null &&
            _studentsWithMealPlans
                .any((s) => s.id == widget.selectedStudentId)) {
          _selectedStudentId = widget.selectedStudentId;
          log('[upcoming_meals] Using provided student ID: $_selectedStudentId');
        } else if (lastSelectedStudentId != null &&
            _studentsWithMealPlans.any((s) => s.id == lastSelectedStudentId)) {
          _selectedStudentId = lastSelectedStudentId;
          log('[upcoming_meals] Using last selected student ID: $_selectedStudentId');
        } else if (recentStudents.isNotEmpty) {
          _selectedStudentId = recentStudents.first.id;
          log('[upcoming_meals] Using most recent student ID: $_selectedStudentId');
        } else {
          _selectedStudentId = _studentsWithMealPlans.first.id;
          log('[upcoming_meals] Using first available student ID: $_selectedStudentId');
        }

        await _loadSubscriptionsForStudent(_selectedStudentId!,
            skipCancelled: true);
      } else {
        _activeSubscriptions = [];
      }
    } catch (e) {
      log('[upcoming_meals] Error loading students with meal plans: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSubscriptionsForStudent(String studentId,
      {bool skipCancelled = false}) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Check if we have cached subscription data for this student
      if (_cachedSubscriptionsByStudent.containsKey(studentId)) {
        log('[upcoming_meals] Using cached subscriptions for student $studentId');
        _activeSubscriptions = _cachedSubscriptionsByStudent[studentId]!;

        // Check if we also have cached meal map data
        if (_cachedMealMapByStudent.containsKey(studentId)) {
          log('[upcoming_meals] Using cached meal map for student $studentId');
          _mealsMap = _cachedMealMapByStudent[studentId]!;
          _updateSelectedDayMeals();
          setState(() {
            _isLoading = false;
          });
          return;
        }
      } else {
        // Create a temporary SubscriptionService from the model
        final modelService = SubscriptionService();

        _activeSubscriptions =
            await modelService.getActiveSubscriptionsForStudent(studentId);

        // Cache the subscriptions for this student
        _cachedSubscriptionsByStudent[studentId] =
            List.from(_activeSubscriptions);
        log('[upcoming_meals] Cached subscriptions for student $studentId');
      }

      // Generate meal map if we don't have it cached
      _generateMealMap();

      // Cache the generated meal map for faster future access
      _cachedMealMapByStudent[studentId] = Map.from(_mealsMap);
      log('[upcoming_meals] Cached meal map for student $studentId');

      _updateSelectedDayMeals();
    } catch (e) {
      log('[upcoming_meals] Error loading subscriptions: $e');
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
              planType: subscription.planType,
              displayPlanType: subscription.planDisplayName,
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final normalizedSelectedDay =
        DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    final meals = _mealsMap[normalizedSelectedDay] ?? [];
    _selectedDateMeals = meals.where((meal) {
      if (meal.status == "Cancelled") return false;
      if (meal.date.year == today.year &&
          meal.date.month == today.month &&
          meal.date.day == today.day) {
        if (meal.planType == 'breakfast') {
          final nineAM = DateTime(today.year, today.month, today.day, 9, 0);
          if (now.isBefore(nineAM)) return true;
        } else if (meal.planType == 'lunch') {
          final onePM = DateTime(today.year, today.month, today.day, 13, 0);
          if (now.isBefore(onePM)) return true;
        }
      }
      return meal.date.isAfter(today) ||
          (meal.date.year == today.year &&
              meal.date.month == today.month &&
              meal.date.day == today.day);
    }).toList();

    // Store upcoming meals for first two students for home page
    _storeUpcomingMealsForHome();
  }

  Future<void> _storeUpcomingMealsForHome() async {
    // Gather all upcoming meals, grouped by student and date
    final List<MealData> allMeals =
        _mealsMap.values.expand((meals) => meals).toList();
    // Group by studentId, then by date
    final Map<String, Map<DateTime, List<MealData>>> mealsByStudentDate = {};
    for (final meal in allMeals) {
      mealsByStudentDate.putIfAbsent(meal.studentId, () => {});
      final dateKey = DateTime(meal.date.year, meal.date.month, meal.date.day);
      mealsByStudentDate[meal.studentId]!.putIfAbsent(dateKey, () => []);
      mealsByStudentDate[meal.studentId]![dateKey]!.add(meal);
    }
    // Take first two students
    final List<Map<DateTime, List<MealData>>> firstTwo =
        mealsByStudentDate.values.take(2).toList();
    // Collect up to two upcoming meals (breakfast and lunch) per student for the earliest date(s)
    final List<MealData> homeMeals = [];
    for (final studentMealsByDate in firstTwo) {
      // Sort dates
      final sortedDates = studentMealsByDate.keys.toList()..sort();
      for (final date in sortedDates) {
        final mealsOnDate = studentMealsByDate[date]!;
        // Add all meals (breakfast and lunch) for this date
        for (final meal in mealsOnDate) {
          homeMeals.add(meal);
          if (homeMeals.length >= 2) break;
        }
        if (homeMeals.length >= 2) break;
      }
      if (homeMeals.length >= 2) break;
    }
    // Store minimal data as JSON
    final List<Map<String, dynamic>> jsonMeals = homeMeals
        .map((meal) => {
              'studentName': meal.studentName,
              'name': meal.name,
              'planType': meal.planType,
              'displayPlanType': meal.displayPlanType,
              'date': meal.date.toIso8601String(),
              'status': meal.status,
              'studentId': meal.studentId,
              'subscriptionId': meal.subscriptionId,
            })
        .toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('home_upcoming_meals', jsonEncode(jsonMeals));
  }

  String _getFormattedPlanType(String planType) {
    switch (planType) {
      case 'breakfast':
        return 'Breakfast';
      case 'lunch':
        return 'Lunch';
      case 'express':
        return 'Express Lunch';
      default:
        return planType.capitalize();
    }
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
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_activeSubscriptions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.no_meals,
                size: 64,
                color: AppTheme.textLight,
              ),
              const SizedBox(height: 16),
              Text(
                'No Meal Plans Found',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'You currently have no active meal subscriptions. Subscribe to a meal plan to see upcoming meals.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.textMedium,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      controller: _calendarScrollController,
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              _buildScreenHeader(),
              _buildStudentSelector(),
            ],
          ),
        ),
        if (_isCalendarView)
          SliverToBoxAdapter(
            child: _buildCalendarView(),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final allMeals = _mealsMap.values
                    .expand((meals) => meals)
                    .where((meal) => meal.status != "Cancelled")
                    .toList()
                  ..sort((a, b) => a.date.compareTo(b.date));
                if (index >= allMeals.length) return null;
                // Add horizontal padding to each meal card in list view
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildCalendarMealCard(allMeals[index]),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildScreenHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Upcoming Meals",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.offWhite,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.deepPurple.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Calendar view toggle
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isCalendarView = true;
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient:
                          _isCalendarView ? AppTheme.purpleToDeepPurple : null,
                      color: _isCalendarView ? null : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _isCalendarView
                          ? [
                              BoxShadow(
                                color: AppTheme.purple.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              )
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_month_rounded,
                          color: _isCalendarView
                              ? Colors.white
                              : AppTheme.textMedium,
                          size: 20,
                        ),
                        if (_isCalendarView) ...[
                          const SizedBox(width: 4),
                          Text(
                            "Calendar",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // List view toggle
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isCalendarView = false;
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient:
                          !_isCalendarView ? AppTheme.purpleToDeepPurple : null,
                      color: !_isCalendarView ? null : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: !_isCalendarView
                          ? [
                              BoxShadow(
                                color: AppTheme.purple.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              )
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.list_rounded,
                          color: !_isCalendarView
                              ? Colors.white
                              : AppTheme.textMedium,
                          size: 20,
                        ),
                        if (!_isCalendarView) ...[
                          const SizedBox(width: 4),
                          Text(
                            "List",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ],
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

  Widget _buildStudentSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.deepPurple.withOpacity(0.08),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: AppTheme.deepPurple.withOpacity(0.1),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedStudentId,
            isExpanded: true,
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                gradient: AppTheme.purpleToDeepPurple,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            dropdownColor: AppTheme.white,
            borderRadius: BorderRadius.circular(16),
            elevation: 3,
            items: _studentsWithMealPlans.map((student) {
              return DropdownMenuItem(
                value: student.id,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppTheme.purpleToDeepPurple,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.purple.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      student.name,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedStudentId = newValue;
                });
                // Save the selected student ID to SharedPreferences
                _saveSelectedStudentId(newValue);
                // Clear cache for this student to force reload
                _cachedSubscriptionsByStudent.remove(newValue);
                _cachedMealMapByStudent.remove(newValue);
                _loadSubscriptionsForStudent(newValue, skipCancelled: true);
              }
            },
          ),
        ),
      ),
    );
  }

  // Helper to build legend items with modern styling
  Widget _buildLegendItem(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
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

  // Build calendar view with modern styling
  Widget _buildCalendarView() {
    _ensureValidFocusedDay();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Calendar component with event markers
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.softShadow,
            border: Border.all(
              color: AppTheme.deepPurple.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 20),
            child: Column(
              children: [
                // Calendar header with month/year and gradient accent
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _focusedDay = DateTime(
                                _focusedDay.year, _focusedDay.month - 1, 1);
                            _selectedDay = _focusedDay;
                            _updateSelectedDayMeals();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.purple.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.chevron_left,
                            color: AppTheme.purple,
                          ),
                        ),
                      ),
                      Text(
                        DateFormat('MMMM yyyy').format(_focusedDay),
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _focusedDay = DateTime(
                                _focusedDay.year, _focusedDay.month + 1, 1);
                            _selectedDay = _focusedDay;
                            _updateSelectedDayMeals();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.purple.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.chevron_right,
                            color: AppTheme.purple,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // TableCalendar widget with existing properties
                TableCalendar(
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
                    });
                  },
                  calendarFormat: CalendarFormat.month,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  headerVisible: false,
                  availableGestures: AvailableGestures.none,
                  enabledDayPredicate: (day) {
                    return true;
                  },
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    markerSize: 8,
                    markerDecoration: BoxDecoration(
                      color: AppTheme.purple,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.purple.withOpacity(0.7),
                          AppTheme.deepPurple.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      gradient: AppTheme.purpleToDeepPurple,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.deepPurple.withOpacity(0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.deepPurple.withOpacity(0.2),
                          blurRadius: 8,
                          spreadRadius: 3,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    selectedTextStyle: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    todayTextStyle: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    weekendTextStyle: GoogleFonts.poppins(
                      color: AppTheme.error.withOpacity(0.7),
                    ),
                    holidayTextStyle: GoogleFonts.poppins(
                      color: AppTheme.error.withOpacity(0.7),
                    ),
                    defaultTextStyle: GoogleFonts.poppins(
                      color: AppTheme.textDark,
                    ),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textDark,
                    ),
                    weekendStyle: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      color: AppTheme.error.withOpacity(0.7),
                    ),
                    // decoration: BoxDecoration(
                    //   border: Border(
                    //     bottom: BorderSide(
                    //       color: Colors.grey.shade200,
                    //       width: 1,
                    //     ),
                    //   ),
                    // ),
                  ),
                  // Event loader to display dots for meals
                  eventLoader: (day) {
                    final normalizedDay =
                        DateTime(day.year, day.month, day.day);
                    final events = _mealsMap[normalizedDay] ?? [];
                    return events;
                  },
                  // Custom marker builder for colored dots
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, date, events) {
                      if (events.isEmpty) return null;

                      return Container(
                        margin: const EdgeInsets.only(top: 6),
                        child: _buildCalendarMarker(events, date),
                      );
                    },
                    dowBuilder: (context, day) {
                      final text = DateFormat.E().format(day);
                      return Center(
                        child: Text(
                          text
                              .substring(0, math.min(text.length, 3))
                              .toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: day.weekday == DateTime.saturday ||
                                    day.weekday == DateTime.sunday
                                ? AppTheme.error.withOpacity(0.7)
                                : AppTheme.purple,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // Legend for dot indicators with updated styling
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.softShadow,
            border: Border.all(
              color: AppTheme.deepPurple.withOpacity(0.1),
              width: 1,
            ),
          ),
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
                      Icons.info_outline,
                      color: AppTheme.purple,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Calendar Legend',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
              const Divider(
                height: 24,
                thickness: 1,
                color: Color(0x33EEEEEE), // 0.2 opacity
              ),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildLegendItem('Breakfast', Colors.pink),
                  _buildLegendItem('Lunch', AppTheme.success),
                  _buildLegendItem('Swapped', AppTheme.orange),
                  _buildLegendItem('Cancelled', AppTheme.error),
                ],
              ),
            ],
          ),
        ),

        // Selected day header when there are meals
        if (_selectedDateMeals.isNotEmpty) _buildSelectedDayHeader(),

        // Meal cards for selected date
        _selectedDateMeals.isEmpty
            ? _buildNoMealsForSelectedDay()
            : _buildScrollableMealList(),
      ],
    );
  }

  // Update the method to build a header for the selected day
  Widget _buildSelectedDayHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
        border: Border.all(
          color: AppTheme.purple.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with icon and title
          Row(
            children: [
              // Calendar icon with accent background
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.purple.withOpacity(0.1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.purple.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.calendar_today_rounded,
                  color: AppTheme.purple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Title and date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Date',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppTheme.textMedium,
                      ),
                    ),
                    Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(_selectedDay),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
              ),

              // Meal count badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _selectedDateMeals.isEmpty
                      ? Colors.grey.withOpacity(0.1)
                      : AppTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedDateMeals.isEmpty
                        ? Colors.grey.withOpacity(0.3)
                        : AppTheme.success.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _selectedDateMeals.isEmpty
                            ? Colors.grey
                            : AppTheme.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${_selectedDateMeals.length} ${_selectedDateMeals.length == 1 ? 'Meal' : 'Meals'}",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _selectedDateMeals.isEmpty
                            ? Colors.grey
                            : AppTheme.success,
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

  // Build calendar marker with improved colored dots for meal types
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

    // Build improved markers based on meal types
    List<Widget> markers = [];

    // Add cancelled meal marker
    if (hasCancelled) {
      markers.add(
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Colors.red.shade300,
                Colors.red.shade700,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.3),
                blurRadius: 2,
                spreadRadius: 0,
              ),
            ],
          ),
        ),
      );
    }

    // Add breakfast marker
    if (hasBreakfast) {
      markers.add(
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Colors.pink.shade300,
                Colors.pink.shade700,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.pink.withOpacity(0.3),
                blurRadius: 2,
                spreadRadius: 0,
              ),
            ],
          ),
        ),
      );
    }

    // Add lunch marker
    if (hasLunch) {
      markers.add(
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Colors.green.shade300,
                Colors.green.shade700,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 2,
                spreadRadius: 0,
              ),
            ],
          ),
        ),
      );
    }

    // Add express marker
    if (hasExpress) {
      markers.add(
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade300,
                Colors.blue.shade700,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 2,
                spreadRadius: 0,
              ),
            ],
          ),
        ),
      );
    }

    // Add swapped meal marker
    if (hasSwapped) {
      markers.add(
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Colors.orange.shade300,
                Colors.orange.shade700,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.3),
                blurRadius: 2,
                spreadRadius: 0,
              ),
            ],
          ),
        ),
      );
    }

    // If we have too many dots, limit them
    if (markers.length > 3) {
      markers = markers.sublist(0, 3);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: markers,
    );
  }

  // Helper method to build status badge
  Widget _buildStatusBadge(String status) {
    LinearGradient gradient;
    Color textColor = Colors.white;

    switch (status) {
      case 'Scheduled':
        gradient = LinearGradient(
          colors: [
            Color(0xFF4CAF50), // Green
            Color(0xFF2E7D32), // Dark Green
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        break;
      case 'Cancelled':
        gradient = LinearGradient(
          colors: [
            Color(0xFFF44336), // Red
            Color(0xFFD32F2F), // Dark Red
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        break;
      case 'Swapped':
        gradient = LinearGradient(
          colors: [
            Color(0xFFFF9800), // Orange
            Color(0xFFE65100), // Dark Orange
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        break;
      default:
        gradient = AppTheme.purpleToDeepPurple;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
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

  // Widget for when no meals are available
  Widget _buildNoMealsForSelectedDay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.no_food_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No meals scheduled for this day',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    // Get all meals and sort by date, but filter out cancelled meals
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final allMeals = _mealsMap.values.expand((meals) => meals).where((meal) {
      if (meal.status == "Cancelled") return false;
      // If meal is today, apply breakfast/lunch time logic
      if (meal.date.year == today.year &&
          meal.date.month == today.month &&
          meal.date.day == today.day) {
        if (meal.planType == 'breakfast') {
          // Show breakfast until 9:00am
          final nineAM = DateTime(today.year, today.month, today.day, 9, 0);
          if (now.isBefore(nineAM)) return true;
        } else if (meal.planType == 'lunch') {
          // Show lunch until 1:00pm
          final onePM = DateTime(today.year, today.month, today.day, 13, 0);
          if (now.isBefore(onePM)) return true;
        }
      }
      // Otherwise, show if meal is today (after cutoff) or in the future
      return meal.date.isAfter(today) ||
          (meal.date.year == today.year &&
              meal.date.month == today.month &&
              meal.date.day == today.day);
    }).toList()
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppTheme.softShadow,
                    border: Border.all(
                      color: AppTheme.deepPurple.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.purple.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.calendar_today_rounded,
                          color: AppTheme.purple,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          DateFormat('EEEE, MMMM d, yyyy').format(meal.date),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Use the same card design as the calendar view
            _buildCalendarMealCard(meal),
          ],
        );
      },
    );
  }

  // Helper method to check if two dates are the same day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _scrollToUpcomingMeal() {
    // If we're not in calendar view, switch to it
    if (!_isCalendarView) {
      setState(() {
        _isCalendarView = true;
      });
      // Give time for the UI to update before scrolling
      Future.delayed(const Duration(milliseconds: 300), () {
        _performScrollToUpcomingMeal();
      });
    } else {
      _performScrollToUpcomingMeal();
    }
  }

  void _performScrollToUpcomingMeal() {
    // Find the next upcoming meal
    final DateTime now = DateTime.now();
    DateTime? nextMealDate;

    // Sort all dates with meals
    final allDates = _mealsMap.keys.toList()..sort((a, b) => a.compareTo(b));

    // Find the first date that has meals scheduled after today
    for (final date in allDates) {
      if (date.isAfter(now) || _isSameDay(date, now)) {
        nextMealDate = date;
        break;
      }
    }

    if (nextMealDate != null) {
      // Set the selected day to the upcoming meal date
      setState(() {
        _selectedDay = nextMealDate!;
        _focusedDay = nextMealDate;
        _updateSelectedDayMeals();
      });

      // Scroll to the position of the calendar (you may need to adjust the scroll offset)
      _calendarScrollController.animateTo(
        0, // Scroll to the top of the calendar view
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      // If no upcoming meals, show a message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No upcoming meals found',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  // Add the missing _formatPlanType method if it doesn't exist
  String _formatPlanType(String planType) {
    switch (planType) {
      case 'breakfast':
        return 'Breakfast';
      case 'lunch':
        return 'Lunch';
      case 'express':
        return 'Express Lunch';
      default:
        return planType.capitalize();
    }
  }

  // Add the missing _getStatusColor method
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Scheduled':
        return AppTheme.success;
      case 'Cancelled':
        return AppTheme.error;
      case 'Swapped':
        return AppTheme.orange;
      default:
        return AppTheme.purple;
    }
  }

  Widget _buildScrollableMealList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _selectedDateMeals.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        return _buildCalendarMealCard(_selectedDateMeals[index]);
      },
    );
  }

  // Update the specialized meal card for the calendar view to match plan detail screen
  Widget _buildCalendarMealCard(MealData meal) {
    final bool isBreakfast = meal.planType == 'breakfast';
    final bool isExpress = meal.planType == 'express';
    final bool isCancelled = meal.status == "Cancelled";
    final bool isSwapped = meal.status == "Swapped";

    // Use MealConstants for consistent styling across app
    final Color planIconColor = MealConstants.getIconColor(meal.planType);
    final Color planBgColor = MealConstants.getBgColor(meal.planType);
    final Color planBorderColor = MealConstants.getBorderColor(meal.planType);
    final IconData planIcon = MealConstants.getIcon(meal.planType);

    // Status display info
    String statusDisplay = meal.status;
    Color statusColor = _getStatusColor(meal.status);

    // Get meal image URL by meal name (same as _buildMealCard)
    final allMeals = MealDataService.getAllMeals();
    final mealObj = allMeals.firstWhere(
      (m) => m.name.toLowerCase() == meal.name.toLowerCase(),
      orElse: () => allMeals.first,
    );
    final String mealImageUrl =
        mealObj.imageUrl.isNotEmpty ? mealObj.imageUrl : '';

    return Card(
      elevation: 4,
      shadowColor: AppTheme.deepPurple.withOpacity(0.15),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          border: Border.all(
            color: isCancelled
                ? AppTheme.error.withOpacity(0.5)
                : isSwapped
                    ? AppTheme.orange.withOpacity(0.5)
                    : planBorderColor,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plan Type Header (Enhanced with icon) - Matches plan detail screen
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isCancelled
                    ? AppTheme.error.withOpacity(0.1)
                    : isSwapped
                        ? AppTheme.orange.withOpacity(0.1)
                        : planBgColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 70,
                      height: 70,
                      color: Colors.grey[200],
                      child: _getMealImage(mealImageUrl, meal.planType,
                          mealName: meal.name),
                    ),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meal.studentName,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getDisplayMealName(meal.name, meal.planType),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppTheme.textDark,
                            fontWeight: FontWeight.w500,
                          ),
                          softWrap: true,
                          overflow: TextOverflow.visible,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),

                  // Status badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusDisplay,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Add a cancellation notice for cancelled meals
                  if (isCancelled) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.error.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppTheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "This meal has been cancelled and will not be delivered.",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppTheme.error.withOpacity(0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Add a swap notification for swapped meals
                  if (isSwapped) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.orange.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.orange.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.swap_horiz_rounded,
                            color: AppTheme.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "This meal has been swapped for a different option.",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Meal details in two columns for better spacing
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow(
                              Icons.restaurant_menu_rounded,
                              "Plan Type",
                              meal.name,
                              planIconColor,
                            ),
                            // HIDE items row
                            // if (meal.items.isNotEmpty)
                            //   _buildInfoRow(
                            //     Icons.restaurant_rounded,
                            //     "Items",
                            //     meal.items.length > 0
                            //         ? "${meal.items.length} items"
                            //         : "No items",
                            //     AppTheme.textMedium,
                            //   ),
                          ],
                        ),
                      ),

                      // Right column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow(
                              Icons.event_rounded,
                              "Date",
                              DateFormat('EEE, MMM d').format(meal.date),
                              AppTheme.purple,
                            ),
                            // HIDE meal time row
                            // const SizedBox(height: 12),
                            // _buildInfoRow(
                            //   Icons.access_time_rounded,
                            //   "Meal Time",
                            //   isBreakfast ? "Morning" : "Lunch Hour",
                            //   AppTheme.purple,
                            // ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Items details if available
                  if (meal.items.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(
                        height: 1,
                        color: Color(0x1A000000), // black with 0.1 opacity
                      ),
                    ),
                    Text(
                      "Meal Items:",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme
                            .textDark, // Keep text color consistent for all statuses
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Show meal items as plain text instead of badges
                    Text(
                      meal.items.join(', '),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppTheme.textMedium,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],

                  // Action buttons
                  if (!isCancelled && (meal.canSwap || true)) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(
                        height: 1,
                        color: Color(0x1A000000), // black with 0.2 opacity
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          icon: Icon(
                            Icons.cancel_outlined,
                            color: AppTheme.error,
                            size: 18,
                          ),
                          label: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.error,
                            side: BorderSide(color: AppTheme.error, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            elevation: 0,
                            shadowColor: AppTheme.error.withOpacity(0.5),
                          ),
                          onPressed: () => _showCancelMealDialog(meal),
                        ),
                        if (meal.canSwap && !isExpress) ...[
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            icon: Icon(
                              Icons.swap_horiz_rounded,
                              color: AppTheme.textDark,
                              size: 18,
                            ),
                            label: Text(
                              'Swap',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.orange,
                              foregroundColor: Colors
                                  .black87, // Dark text for better contrast with yellow
                              elevation: 2,
                              shadowColor: AppTheme.orange.withOpacity(0.3),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => _showSwapMealBottomSheet(meal),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to create meal item chips
  Widget _buildItemChip(String itemName,
      {bool isCancelled = false, bool isSwapped = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.purple
            .withOpacity(0.08), // Keep background color consistent
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        itemName,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: AppTheme.purple, // Keep text color consistent
          fontWeight: FontWeight.w500,
          decoration:
              isCancelled ? TextDecoration.lineThrough : TextDecoration.none,
        ),
      ),
    );
  }

  // Build meal card actions row (swap and cancel buttons)
  Widget _buildMealCardActions(MealData meal) {
    final bool canCancel = _isCancellationAllowed(meal.date, meal.planType);
    final bool isExpressPlan = meal.planType == 'express';
    final bool isBreakfast = meal.planType == 'breakfast';

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (meal.canSwap && !isExpressPlan)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ElevatedButton.icon(
              icon: Icon(
                Icons.swap_horiz_rounded,
                size: 18,
              ),
              label: Text(
                'Swap',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.orange,
                foregroundColor:
                    Colors.black87, // Dark text for better contrast with yellow
                elevation: 2,
                shadowColor: AppTheme.orange.withOpacity(0.3),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _showSwapMealBottomSheet(meal),
            ),
          ),
        if (canCancel)
          ElevatedButton.icon(
            icon: Icon(
              Icons.cancel_outlined,
              size: 18,
            ),
            label: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.error,
              elevation: 2,
              shadowColor: AppTheme.error.withOpacity(0.2),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: AppTheme.error.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            onPressed: () => _showCancelMealDialog(meal),
          ),
      ],
    );
  }

  // Add _isCancellationAllowed if missing
  bool _isCancellationAllowed(DateTime mealDate, String planType) {
    final DateTime now = DateTime.now();
    final DateTime cutoffDate =
        DateTime(mealDate.year, mealDate.month, mealDate.day)
            .subtract(const Duration(days: 1));

    return now.isBefore(cutoffDate);
  }

  // Implement the swap meal bottom sheet
  void _showSwapMealBottomSheet(MealData meal) {
    final List<String> availableMeals = [
      "Lunch of the Day",
      "Indian Lunch",
      "International Lunch",
      "Jain Lunch"
    ];

    if (meal.planType == 'breakfast') {
      availableMeals.clear();
      availableMeals.addAll([
        "Breakfast of the Day",
        "Indian Breakfast",
        "International Breakfast",
        "Jain Breakfast"
      ]);
    }

    // Remove the current meal from the available options (case-insensitive, trimmed)
    availableMeals.removeWhere((mealNameOption) =>
        mealNameOption.trim().toLowerCase() == meal.name.trim().toLowerCase() ||
        _getDisplayMealName(mealNameOption, meal.planType)
                .trim()
                .toLowerCase() ==
            _getDisplayMealName(meal.name, meal.planType).trim().toLowerCase());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      elevation: 10,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.swap_horiz_rounded,
                          color: AppTheme.orange,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Swap Meal',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Current meal info container
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
                    Text(
                      'Current Meal',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: meal.planType == 'breakfast'
                                ? MealConstants.breakfastIconColor
                                    .withOpacity(0.1)
                                : MealConstants.lunchIconColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _getMealImage('', meal.planType,
                                mealName: meal.name),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getDisplayMealName(meal.name, meal.planType),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('EEEE, MMMM d, yyyy').format(meal.date),
                          style: GoogleFonts.poppins(
                            color: AppTheme.textMedium,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // New meal options section
              Text(
                'Choose a new meal:',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 12),

              // Available meals container
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: availableMeals.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: Color(0x33000000), // black with 0.2 opacity
                  ),
                  itemBuilder: (context, index) {
                    final mealName = availableMeals[index];
                    final Color mealColor = meal.planType == 'breakfast'
                        ? MealConstants.breakfastIconColor
                        : MealConstants.lunchIconColor;

                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        padding: const EdgeInsets.all(0),
                        decoration: BoxDecoration(
                          color: mealColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _getMealImage('', meal.planType,
                              mealName: mealName),
                        ),
                      ),
                      title: Text(
                        mealName,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textDark,
                          fontSize: 15,
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.orange.withOpacity(0.1),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.orange.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: AppTheme.orange,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _swapMeal(meal, mealName);
                      },
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      tileColor: Colors.white,
                      hoverColor: AppTheme.purple.withOpacity(0.05),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Cancel and note about swap timing
              Row(
                children: [
                  // Cancel button
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(
                        Icons.close,
                        size: 16,
                        color: AppTheme.error,
                      ),
                      label: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side:
                            BorderSide(color: Colors.grey.shade300, width: 1.5),
                        backgroundColor: Colors.white,
                        elevation: 0,
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Note about swap timing
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.orange.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 16,
                            color: AppTheme.orange,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Swaps allowed until 11:59 PM day before',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Implementation of the meal swap process
  Future<void> _swapMeal(MealData meal, String newMealName) async {
    try {
      setState(() {
        _isSwapLoading = true;
      });
      _showSnackBar('Swapping meal...');

      await Future.delayed(const Duration(seconds: 1));

      // Store in SharedPreferences for persistence
      final prefs = await SharedPreferences.getInstance();
      final swapKey =
          'swappedMeal_${meal.studentId}_${meal.subscriptionId}_${DateFormat('yyyy-MM-dd').format(meal.date)}';

      final swapData = {
        'subscriptionId': meal.subscriptionId,
        'originalMealName': meal.name,
        'newMealName': newMealName,
        'date': DateFormat('yyyy-MM-dd').format(meal.date),
        'studentId': meal.studentId,
        'swappedAt': DateTime.now().toIso8601String(),
      };

      await prefs.setString(swapKey, jsonEncode(swapData));

      _updateMealInUI(meal, newMealName);
      _clearCachedDataForStudent(meal.studentId);
      _showSnackBar('Meal swapped successfully!');
    } catch (e) {
      log('[upcoming_meals] Error swapping meal: $e');
      _showSnackBar('An error occurred while swapping the meal.');
    } finally {
      setState(() {
        _isSwapLoading = false;
      });
    }
  }

  // Update the meal in the UI after swapping
  void _updateMealInUI(MealData meal, String newMealName) {
    setState(() {
      final normalizedDate =
          DateTime(meal.date.year, meal.date.month, meal.date.day);

      // Update in mealsMap
      if (_mealsMap.containsKey(normalizedDate)) {
        final meals = _mealsMap[normalizedDate]!;
        for (int i = 0; i < meals.length; i++) {
          if (meals[i].subscriptionId == meal.subscriptionId) {
            final updatedMeal = MealData(
              studentName: meals[i].studentName,
              name: newMealName,
              planType: meals[i].planType,
              displayPlanType: meals[i].displayPlanType,
              items: meals[i].items,
              status: 'Swapped',
              subscription: meals[i].subscription,
              canSwap: meals[i].canSwap,
              date: meals[i].date,
              studentId: meals[i].studentId,
              subscriptionId: meals[i].subscriptionId,
            );
            meals[i] = updatedMeal;
          }
        }
      }

      // Update in selectedDateMeals if applicable
      for (int i = 0; i < _selectedDateMeals.length; i++) {
        if (_selectedDateMeals[i].subscriptionId == meal.subscriptionId) {
          final updatedMeal = MealData(
            studentName: _selectedDateMeals[i].studentName,
            name: newMealName,
            planType: _selectedDateMeals[i].planType,
            displayPlanType: _selectedDateMeals[i].displayPlanType,
            items: _selectedDateMeals[i].items,
            status: 'Swapped',
            subscription: _selectedDateMeals[i].subscription,
            canSwap: _selectedDateMeals[i].canSwap,
            date: _selectedDateMeals[i].date,
            studentId: _selectedDateMeals[i].studentId,
            subscriptionId: _selectedDateMeals[i].subscriptionId,
          );
          _selectedDateMeals[i] = updatedMeal;
        }
      }
    });
  }

  // Implement the cancel meal dialog
  void _showCancelMealDialog(MealData meal) {
    final bool isBreakfast = meal.planType == 'breakfast';
    final Color mealColor = isBreakfast
        ? MealConstants.breakfastIconColor
        : MealConstants.lunchIconColor;
    final String mealTypeString = isBreakfast ? 'Breakfast' : 'Lunch';
    final IconData mealIcon =
        isBreakfast ? MealConstants.breakfastIcon : MealConstants.lunchIcon;

    // Refund logic
    final now = DateTime.now();
    final deliveryDay =
        DateTime(meal.date.year, meal.date.month, meal.date.day);
    final midnight =
        DateTime(deliveryDay.year, deliveryDay.month, deliveryDay.day, 0, 0);
    final eightAM =
        DateTime(deliveryDay.year, deliveryDay.month, deliveryDay.day, 8, 0);
    String refundMessage = '';
    String after8amMessage = '';
    if (isBreakfast) {
      if (now.isBefore(midnight)) {
        refundMessage = '100% refund will be credited to your wallet.';
      } else {
        refundMessage = 'No refund will be credited to your wallet.';
      }
    } else {
      // Lunch logic
      if (now.isBefore(midnight)) {
        refundMessage = '100% refund will be credited to your wallet.';
      } else if (now.isAfter(midnight) && now.isBefore(eightAM)) {
        refundMessage = '50% refund will be credited to your wallet.';
      } else {
        refundMessage = 'No refund will be credited to your wallet.';
      }
    }
    if (now.isAfter(eightAM)) {
      after8amMessage =
          'No refund for any meal of the day cancelled after 8 am.';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.error.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.cancel_outlined,
                        color: AppTheme.error,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Cancel Meal',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.error,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Are you sure you want to cancel this meal?',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Refund message
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.success.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.account_balance_wallet_outlined,
                                color: AppTheme.success,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  refundMessage,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: AppTheme.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (after8amMessage.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.red,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    after8amMessage,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.red,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    // ... existing meal details and warning message ...
                    const SizedBox(height: 20),

                    // Meal Details Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Meal Type Badge
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 16),
                            decoration: BoxDecoration(
                              color: mealColor.withOpacity(0.1),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    mealIcon,
                                    size: 14,
                                    color: mealColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  mealTypeString,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    color: mealColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Meal Details
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailRow(
                                  Icons.restaurant_menu,
                                  "Meal",
                                  meal.name,
                                  AppTheme.textDark,
                                ),
                                const SizedBox(height: 12),
                                _buildDetailRow(
                                  Icons.calendar_today,
                                  "Date",
                                  DateFormat('EEEE, MMMM d, yyyy')
                                      .format(meal.date),
                                  AppTheme.textDark,
                                ),
                                const SizedBox(height: 12),
                                _buildDetailRow(
                                  Icons.person,
                                  "Student",
                                  meal.studentName,
                                  AppTheme.textDark,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Warning message
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.error.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: AppTheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Once cancelled, this action cannot be undone.',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppTheme.error.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade400),
                          foregroundColor: AppTheme.textMedium,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Keep Meal',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _cancelMeal(meal);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.error,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.cancel_outlined,
                            color: Colors.white, size: 16),
                        label: Text(
                          'Cancel Meal',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
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
    );
  }

  Widget _buildDetailRow(
      IconData icon, String label, String value, Color textColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 14,
            color: AppTheme.purple,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.textLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Implementation of the meal cancellation process
  Future<void> _cancelMeal(MealData meal) async {
    try {
      // Show loading indicator
      _showSnackBar('Cancelling meal...');

      // Call the service to cancel the meal
      final success = await _subscriptionService.cancelMealDelivery(
        meal.subscriptionId,
        meal.date,
        studentId: meal.studentId,
      );

      if (success) {
        // Mark the meal as cancelled in the UI
        _updateMealStatusInUI(meal, "Cancelled");

        // Store in SharedPreferences for local persistence and sharing with cancelled meals tab
        final prefs = await SharedPreferences.getInstance();
        final cancelKey =
            'cancelledMeal_${meal.studentId}_${meal.subscriptionId}_${DateFormat('yyyy-MM-dd').format(meal.date)}';

        // Log meal type information for debugging
        log('[upcoming_meals] Cancelling meal with planType: ${meal.planType}, will display as: ${meal.planType == 'breakfast' ? 'Breakfast' : 'Lunch'}');

        // Create a detailed cancellation record
        final cancelData = {
          'id':
              'cancelled_${meal.subscriptionId}_${meal.date.millisecondsSinceEpoch}',
          'subscriptionId': meal.subscriptionId,
          'studentId': meal.studentId,
          'studentName': meal.studentName,
          'planType': meal.planType,
          'mealName': meal.name,
          'date': DateFormat('yyyy-MM-dd').format(meal.date),
          'cancelledAt': DateTime.now().toIso8601String(),
          'cancelledBy': 'parent',
          'reason': 'Cancelled by parent',
        };

        // Save as JSON string
        await prefs.setString(cancelKey, jsonEncode(cancelData));

        // Also set a boolean flag for quick checks
        await prefs.setBool(cancelKey, true);

        // Clear cached data for this student to ensure fresh data on next load
        _clearCachedDataForStudent(meal.studentId);

        // Show success message
        _showSnackBar('Meal cancelled successfully!');

        // Notify the cancelled meals tab about the change (if it's in the widget tree)
        try {
          final GlobalKey<CancelledMealsTabState>? cancelledMealsTabKey =
              GlobalObjectKey<CancelledMealsTabState>(meal.studentId);

          cancelledMealsTabKey?.currentState?.refreshCancelledMeals();
          log('[upcoming_meals] Notified the cancelled meals tab to refresh');
        } catch (e) {
          log('[upcoming_meals] Could not notify cancelled meals tab: $e');
        }

        // Reload data to ensure UI is up to date
        await _loadSubscriptionsForStudent(_selectedStudentId!);
      } else {
        _showSnackBar('Failed to cancel meal. Please try again.');
      }
    } catch (e) {
      log('[upcoming_meals] Error cancelling meal: $e');
      _showSnackBar('An error occurred while cancelling the meal.');
    }
  }

  // Update the meal status in the UI
  void _updateMealStatusInUI(MealData meal, String newStatus) {
    setState(() {
      final normalizedDate =
          DateTime(meal.date.year, meal.date.month, meal.date.day);

      // Update in mealsMap
      if (_mealsMap.containsKey(normalizedDate)) {
        final meals = _mealsMap[normalizedDate]!;
        for (int i = 0; i < meals.length; i++) {
          if (meals[i].subscriptionId == meal.subscriptionId) {
            meals[i].status = newStatus;
          }
        }
      }

      // Update in selectedDateMeals if applicable
      for (int i = 0; i < _selectedDateMeals.length; i++) {
        if (_selectedDateMeals[i].subscriptionId == meal.subscriptionId) {
          _selectedDateMeals[i].status = newStatus;
        }
      }
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  List<DateTime> _getSwapOptionsForMealType(String planType) {
    // Implementation needed
    return [];
  }

  // Helper to build detail rows in the meal card
  Widget _buildInfoRow(
      IconData icon, String label, String value, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 16,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.textMedium,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Add method to clear cached data for a student when their data is modified
  void _clearCachedDataForStudent(String studentId) {
    _cachedSubscriptionsByStudent.remove(studentId);
    _cachedMealMapByStudent.remove(studentId);
    log('[upcoming_meals] Cleared cached data for student $studentId');
  }

  // Add helper methods for meal image display (copied and adapted from cart_screen.dart)
  Widget _getMealImage(String imageUrl, String mealType, {String? mealName}) {
    // Use special asset for certain meal names
    if (mealName != null) {
      final asset = _getSpecialMealImageAsset(mealName);
      if (asset.isNotEmpty) {
        return Image.asset(
          asset,
          //color: Colors.white,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _getDefaultMealImage(mealType);
          },
        );
      }
    }
    if (imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _getDefaultMealImage(mealType);
        },
      );
    }
    return _getDefaultMealImage(mealType);
  }

  Widget _getDefaultMealImage(String mealType) {
    final String defaultImagePath = mealType == 'breakfast'
        ? 'assets/images/breakfast/breakfast of the day (most recommended).png'
        : 'assets/images/lunch/lunch of the day (most recommended).png';
    return Image.asset(
      defaultImagePath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Center(
          child: Icon(
            mealType == 'breakfast'
                ? Icons.ramen_dining
                : Icons.flatware_rounded,
            color: AppTheme.purple,
            size: 32,
          ),
        );
      },
    );
  }

  // Add a helper to normalize meal name for display
  String _getDisplayMealName(String mealName, String planType) {
    return normalizeMealName(mealName, planType);
  }

  // Add a helper to get the correct asset image for special meal names
  String _getSpecialMealImageAsset(String mealName) {
    final name = mealName.trim().toLowerCase();
    if (name == 'breakfast of the day' ||
        name == 'breakfast of the day breakfast') {
      return 'assets/images/breakfast/breakfast of the day (most recommended).png';
    }
    if (name == 'indian breakfast') {
      return 'assets/images/breakfast/Indian Breakfast.png';
    }
    if (name == 'international breakfast') {
      return 'assets/images/breakfast/International Breakfast.png';
    }
    if (name == 'jain breakfast') {
      return 'assets/images/breakfast/Jain Breakfast.png';
    }
    if (name == 'lunch of the day' || name == 'lunch of the day lunch') {
      return 'assets/images/lunch/lunch of the day (most recommended).png';
    }
    if (name == 'indian lunch') {
      return 'assets/images/lunch/Indian Lunch.png';
    }
    if (name == 'international lunch') {
      return 'assets/images/lunch/International Lunch.png';
    }
    if (name == 'jain lunch') {
      return 'assets/images/lunch/Jain Lunch.png';
    }
    return '';
  }
}
