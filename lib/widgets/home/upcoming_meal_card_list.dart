import 'dart:developer';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:startwell/utils/routes.dart';
import 'package:startwell/services/meal_service.dart';
import 'package:startwell/services/student_profile_service.dart';
import 'package:startwell/models/student_model.dart';
import 'package:intl/intl.dart';
import 'package:startwell/screens/main_screen.dart';
import 'package:startwell/models/meal_model.dart';
import 'package:startwell/services/subscription_service.dart' as services;
import 'package:startwell/models/subscription_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:startwell/screens/my_subscription_screen.dart';
import 'package:startwell/utils/meal_constants.dart';
import 'package:startwell/utils/meal_names.dart'
    show getMealImageAsset, normalizeMealName;
import 'dart:async';

// Define the MealData class to hold meal information
class MealData {
  final String studentName;
  final String name;
  final String planType;
  final List<String> items;
  String status;
  final Subscription subscription;
  final bool canSwap;
  final DateTime date;
  final String studentId;
  final String subscriptionId;

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
}

class UpcomingMealCardList extends StatefulWidget {
  const UpcomingMealCardList({super.key});

  @override
  State<UpcomingMealCardList> createState() => _UpcomingMealCardListState();
}

class _UpcomingMealCardListState extends State<UpcomingMealCardList> {
  final MealService _mealService = MealService();
  final services.SubscriptionService _subscriptionService =
      services.SubscriptionService();
  final StudentProfileService _studentProfileService = StudentProfileService();
  final SubscriptionService _modelSubscriptionService = SubscriptionService();
  bool _isLoading = true;

  // List to store all upcoming meals across all students
  List<MealData> _upcomingMeals = [];
  // Map to store meal status
  Map<String, String> _mealStatusMap = {};
  List<Student> _students = [];
  Timer? _autoRefreshTimer;
  bool _isAutoRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadMealsFromHomeStorage();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadMeals();
    _scheduleAutoRefresh();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _scheduleAutoRefresh() {
    // Cancel any existing timer
    _autoRefreshTimer?.cancel();
    // Schedule a new refresh 1.2 seconds after widget is visible
    _autoRefreshTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!_isLoading && !_isAutoRefreshing) {
        _isAutoRefreshing = true;
        _loadMeals().whenComplete(() {
          _isAutoRefreshing = false;
        });
      }
    });
  }

  Future<void> _loadMealsFromHomeStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString('home_upcoming_meals');
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        final List<MealData> meals = jsonList.map((json) {
          return MealData(
            studentName: json['studentName'] ?? '',
            name: json['name'] ?? '',
            planType: json['planType'] ?? '',
            items: [],
            status: json['status'] ?? '',
            subscription: Subscription(
              id: json['subscriptionId'] ?? '',
              studentId: json['studentId'] ?? '',
              planType: json['planType'] ?? '',
              mealName: json['name'] ?? '',
              startDate: DateTime.now(),
              endDate: DateTime.now().add(const Duration(days: 1)),
              status: SubscriptionStatus.active,
              duration: SubscriptionDuration.monthly,
              selectedWeekdays: const [],
              isBreakfastPlan: json['planType'] == 'breakfast',
              isLunchPlan: json['planType'] == 'lunch',
            ),
            canSwap: false,
            date: DateTime.parse(json['date']),
            studentId: json['studentId'] ?? '',
            subscriptionId: json['subscriptionId'] ?? '',
          );
        }).toList();
        setState(() {
          _upcomingMeals = meals;
          _isLoading = false;
        });
        return;
      } catch (e) {
        // Fallback to normal loading
      }
    }
    // Fallback to normal loading if no data or error
    _loadMeals();
  }

  // Generate a unique key for a meal to use in our status map
  String _getMealKey(String studentId, String subscriptionId, DateTime date) {
    return '${studentId}_${subscriptionId}_${DateFormat('yyyy-MM-dd').format(date)}';
  }

  // Check if a meal is swapped in local storage
  Future<Map<String, dynamic>> _getMealSwapInfo(
      String studentId, String subscriptionId, DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final normalizedDate = DateFormat('yyyy-MM-dd').format(date);
      final key = 'swappedMeal_${studentId}_${subscriptionId}_$normalizedDate';

      if (prefs.containsKey(key)) {
        // Get the swap data from shared preferences
        final String? swapDataJson = prefs.getString(key);
        if (swapDataJson != null) {
          final Map<String, dynamic> swapData = jsonDecode(swapDataJson);
          return {
            'isSwapped': true,
            'newMealName': swapData['newMealName'] ?? '',
            'originalMealName': swapData['originalMealName'] ?? '',
          };
        }
      }

      return {'isSwapped': false, 'newMealName': '', 'originalMealName': ''};
    } catch (e) {
      log('Error checking meal swap info: $e');
      return {'isSwapped': false, 'newMealName': '', 'originalMealName': ''};
    }
  }

  // Check if a meal is cancelled
  Future<bool> _isMealCancelled(
      String studentId, String subscriptionId, DateTime date) async {
    try {
      // Create a normalized date string for keys
      final normalizedDate = DateFormat('yyyy-MM-dd').format(date);

      // Key format for cancelled meals in SharedPreferences
      final key =
          'cancelledMeal_${studentId}_${subscriptionId}_$normalizedDate';

      log('[cancelled_meal_check] Checking if meal is cancelled: $key');

      // First check in SharedPreferences for locally stored cancelled status
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(key) == true) {
        log('[cancelled_meal_check] Found cancelled status in SharedPreferences: $key');
        return true;
      }

      log('[cancelled_meal_check] Not found in SharedPreferences, checking with service');

      // If not found locally, check with the subscription service
      final cancelledMeals =
          await _subscriptionService.getCancelledMeals(studentId);

      log('[cancelled_meal_check] Service returned ${cancelledMeals.length} cancelled meals for student $studentId');

      // Check if any cancelled meal matches this date and subscription
      final isCancelled = cancelledMeals.any((meal) {
        final bool matches = meal.subscriptionId == subscriptionId &&
            meal.cancellationDate.year == date.year &&
            meal.cancellationDate.month == date.month &&
            meal.cancellationDate.day == date.day;

        if (matches) {
          log('[cancelled_meal_check] Found match in service data: ${meal.id}');
        }

        return matches;
      });

      // Store the cancelled status in SharedPreferences for future reference
      if (isCancelled) {
        log('[cancelled_meal_check] Saving cancelled status to SharedPreferences: $key');
        await prefs.setBool(key, true);
      }

      log('[cancelled_meal_check] Final cancellation status for $key: $isCancelled');
      return isCancelled;
    } catch (e) {
      log('[cancelled_meal_check] Error checking if meal is cancelled: $e');
      return false;
    }
  }

  Future<void> _loadMeals() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Load student profiles
      final students = await _studentProfileService.getStudentProfiles();
      _students = students;

      if (students.isEmpty) {
        setState(() {
          _isLoading = false;
          _upcomingMeals = [];
        });
        return;
      }

      // Get all active subscriptions for all students
      List<MealData> soonestMealsPerStudent = [];

      for (var student in students) {
        try {
          log('Loading subscriptions for student: [32m${student.name}[0m');

          if (!student.hasActiveBreakfast && !student.hasActiveLunch) {
            continue;
          }

          final subscriptions = await _modelSubscriptionService
              .getActiveSubscriptionsForStudent(student.id);

          if (subscriptions.isEmpty) {
            log('No active subscriptions found for student: ${student.name}');
            continue;
          }

          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          // Fetch all cancelled meals for this student ONCE
          final cancelledMeals =
              await _subscriptionService.getCancelledMeals(student.id);

          // Collect all valid upcoming meals for this student
          List<MealData> studentUpcomingMeals = [];

          for (var subscription in subscriptions) {
            if (subscription.endDate.isBefore(today)) {
              continue;
            }

            final List<DateTime> scheduledDates = _generateScheduleDates(
                subscription.startDate,
                subscription.endDate,
                subscription.selectedWeekdays,
                subscription.planType);

            for (var date in scheduledDates) {
              final normalizedDate = DateTime(date.year, date.month, date.day);
              if (normalizedDate.isBefore(today)) {
                continue;
              }

              // Check if this meal is cancelled using the fetched list
              bool isCancelled = cancelledMeals.any((meal) =>
                  meal.subscriptionId == subscription.id &&
                  meal.cancellationDate.year == normalizedDate.year &&
                  meal.cancellationDate.month == normalizedDate.month &&
                  meal.cancellationDate.day == normalizedDate.day);

              final swapInfo = await _getMealSwapInfo(
                  student.id, subscription.id, normalizedDate);

              String status = "Scheduled";
              String mealName = subscription.getMealNameForDate(date);

              if (isCancelled) {
                status = "Cancelled";
              } else if (swapInfo['isSwapped']) {
                status = "Swapped";
                if (swapInfo['newMealName'].isNotEmpty) {
                  mealName = swapInfo['newMealName'];
                }
              }

              final mealData = MealData(
                studentName: student.name,
                name: mealName,
                planType: _getFormattedPlanType(subscription),
                items: subscription.getMealItems(),
                status: status,
                subscription: subscription,
                canSwap: !isCancelled,
                date: date,
                studentId: student.id,
                subscriptionId: subscription.id,
              );

              studentUpcomingMeals.add(mealData);
            }
          }

          // Find the soonest valid meal for this student
          if (studentUpcomingMeals.isNotEmpty) {
            studentUpcomingMeals.sort((a, b) => a.date.compareTo(b.date));
            soonestMealsPerStudent.add(studentUpcomingMeals.first);
          }
        } catch (error) {
          log('Error processing student ${student.name}: $error');
        }
      }

      // Sort the soonest meals per student by date (closest first)
      soonestMealsPerStudent.sort((a, b) => a.date.compareTo(b.date));

      if (mounted) {
        setState(() {
          _upcomingMeals = soonestMealsPerStudent;
          _isLoading = false;
        });
      }
    } catch (e) {
      log('Error loading upcoming meals: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper method to generate scheduled dates
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
      weekdaysToInclude = [1, 2, 3, 4, 5]; // Monday to Friday by default
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

  // Helper to get formatted plan type
  String _getFormattedPlanType(Subscription subscription) {
    bool isCustomPlan = subscription.selectedWeekdays.isNotEmpty &&
        subscription.selectedWeekdays.length < 5;
    String customBadge = isCustomPlan ? " (Custom)" : "";

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

  // Add a helper to normalize meal name for display
  String _getDisplayMealName(String mealName, String mealType) {
    return normalizeMealName(mealName, mealType);
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    return RefreshIndicator(
      onRefresh: _loadMeals,
      child: _upcomingMeals.isEmpty
          ? _buildEmptyState()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Take only first 2 meals to display
                ..._upcomingMeals
                    .take(2)
                    .map((meal) => _buildMealCard(meal))
                    .toList(),
              ],
            ),
    );
  }

  Widget _buildMealCard(MealData meal) {
    final formattedDate = DateFormat('EEE, dd MMM yyyy').format(meal.date);
    final String asset = getMealImageAsset(
      normalizeMealName(meal.name, meal.planType),
      meal.planType,
    );
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 350;
    final imageSize = isSmall ? 48.0 : 64.0;
    final titleFontSize = isSmall ? 13.0 : 16.0;
    final subtitleFontSize = isSmall ? 11.0 : 14.0;
    final dateFontSize = isSmall ? 10.0 : 13.0;
    return GestureDetector(
      onTap: () {
        // Add haptic feedback for better tactile response
        HapticFeedback.lightImpact();

        // Navigate to MySubscriptionScreen to view more details
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MySubscriptionScreen(
              defaultTabIndex: 0, // Upcoming Meals tab
              startDate: DateTime.now(),
              endDate: DateTime.now().add(const Duration(days: 30)),
            ),
          ),
        );
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        duration: const Duration(milliseconds: 200),
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              shadowColor: AppTheme.purple.withOpacity(0.2),
              child: Stack(
                children: [
                  // Main content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Meal image instead of icon
                            if (asset.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    // boxShadow: [
                                    //   BoxShadow(
                                    //     color: Colors.grey.withOpacity(0.2),
                                    //     blurRadius: 4,
                                    //     offset: const Offset(0, 2),
                                    //   ),
                                    // ],
                                  ),
                                  child: Image.asset(
                                    asset,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(Icons.restaurant,
                                          color: Colors.grey,
                                          size: imageSize * 0.6);
                                    },
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: EdgeInsets.all(imageSize * 0.2),
                                width: imageSize,
                                height: imageSize,
                                decoration: BoxDecoration(
                                  color: MealConstants.getBgColor(
                                      meal.subscription.planType),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: MealConstants.getIconColor(
                                              meal.subscription.planType)
                                          .withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  MealConstants.getIcon(
                                      meal.subscription.planType),
                                  color: MealConstants.getIconColor(
                                      meal.subscription.planType),
                                  size: imageSize * 0.6,
                                ),
                              ),
                            const SizedBox(width: 16),

                            // Meal details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    meal.name.isNotEmpty
                                        ? meal.name
                                        : _getDisplayMealName(
                                            meal.name, meal.planType),
                                    style: GoogleFonts.poppins(
                                      fontSize: titleFontSize,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textDark,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  // Plan type (plan name) wrapped for visibility
                                  Text(
                                    meal.subscription.planDisplayName,
                                    style: GoogleFonts.poppins(
                                      fontSize: subtitleFontSize,
                                      color: AppTheme.textMedium,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    softWrap: true,
                                    overflow: TextOverflow.visible,
                                    maxLines: 2,
                                  ),
                                  Text(
                                    meal.studentName, // Show student name
                                    style: GoogleFonts.poppins(
                                      fontSize: subtitleFontSize,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    formattedDate, // Show formatted date
                                    style: GoogleFonts.poppins(
                                      fontSize: dateFontSize,
                                      color: Colors.grey.shade600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Status badge (Swapped or Cancelled)
                  if (meal.status.toLowerCase() == 'swapped' ||
                      meal.status.toLowerCase() == 'cancelled')
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: meal.status.toLowerCase() == 'cancelled'
                              ? Colors.red.withOpacity(0.15)
                              : Colors.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          // border: Border.all(
                          //   color: meal.status.toLowerCase() == 'cancelled'
                          //       ? Colors.red.withOpacity(0.3)
                          //       : Colors.orange.withOpacity(0.3),
                          //   width: 1,
                          // ),
                          // // boxShadow: [
                          // //   BoxShadow(
                          // //     color: (meal.status.toLowerCase() == 'cancelled'
                          // //             ? Colors.red
                          // //             : Colors.orange)
                          // //         .withOpacity(0.1),
                          // //     blurRadius: 4,
                          // //     offset: const Offset(0, 2),
                          // //   ),
                          // ],
                        ),
                        child: Text(
                          meal.status.toLowerCase() == 'cancelled'
                              ? 'Cancelled'
                              : 'Swapped',
                          style: GoogleFonts.poppins(
                            color: meal.status.toLowerCase() == 'cancelled'
                                ? Colors.red
                                : Colors.orange,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: 200,
        child: Center(
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            shadowColor: AppTheme.purple.withOpacity(0.2),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.restaurant,
                      color: Colors.grey,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No upcoming meals',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You don\'t have any scheduled meals yet',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppTheme.textMedium,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pull down to refresh',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: AppTheme.textLight,
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
      ),
    );
  }
}
