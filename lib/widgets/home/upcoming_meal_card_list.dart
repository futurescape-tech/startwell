import 'dart:developer';
import 'dart:convert';
import 'package:flutter/material.dart';
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

  // Change to Map<String, List<MealSchedule>> to group by student
  Map<String, List<MealSchedule>> _upcomingMealsByStudent = {};
  // Map to store meal status since MealSchedule.status is final
  Map<String, String> _mealStatusMap = {};
  List<Student> _students = [];

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  // Generate a unique key for a meal to use in our status map
  String _getMealKey(MealSchedule meal) {
    return '${meal.studentId}_${meal.planType}_${DateFormat('yyyy-MM-dd').format(meal.date)}';
  }

  // Check if a meal is swapped in local storage
  Future<bool> _isMealSwapped(
      String studentId, String subscriptionId, DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final normalizedDate = DateFormat('yyyy-MM-dd').format(date);
      final key = 'swappedMeal_${studentId}_${subscriptionId}_$normalizedDate';

      return prefs.containsKey(key);
    } catch (e) {
      log('Error checking if meal is swapped: $e');
      return false;
    }
  }

  // Check if a meal is cancelled by checking with the SubscriptionService
  Future<bool> _isMealCancelled(String studentId, DateTime date) async {
    try {
      final cancelledMeals =
          await _subscriptionService.getCancelledMeals(studentId);

      // Check if any cancelled meal matches this date
      return cancelledMeals.any((meal) =>
          meal.cancellationDate.year == date.year &&
          meal.cancellationDate.month == date.month &&
          meal.cancellationDate.day == date.day);
    } catch (e) {
      log('Error checking if meal is cancelled: $e');
      return false;
    }
  }

  // Update meal status based on whether it's cancelled or swapped
  Future<void> _updateMealStatus(MealSchedule meal) async {
    final mealKey = _getMealKey(meal);

    // First check if it's cancelled
    final isCancelled = await _isMealCancelled(meal.studentId, meal.date);
    if (isCancelled) {
      _mealStatusMap[mealKey] = 'Cancelled';
      return;
    }

    // Only check for swapped if not cancelled
    final isSwapped = await _isMealSwapped(
        meal.studentId,
        // We don't have subscriptionId in MealSchedule, so we create a pattern similar to
        // how it's formed in the system (can be customized based on actual implementation)
        '${meal.planType}-${meal.studentId}',
        meal.date);

    if (isSwapped) {
      _mealStatusMap[mealKey] = 'Swapped';
    } else {
      // Keep original status if not cancelled or swapped
      _mealStatusMap[mealKey] = meal.status;
    }
  }

  // Get the current status of a meal
  String _getMealStatus(MealSchedule meal) {
    final mealKey = _getMealKey(meal);
    return _mealStatusMap[mealKey] ?? meal.status;
  }

  Future<void> _loadMeals() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Load student profiles
      final studentProfileService = StudentProfileService();
      final students = await studentProfileService.getStudentProfiles();
      _students = students;

      if (students.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final mealService = MealService();
      Map<String, List<MealSchedule>> mealsByStudent = {};

      // Clear the status map
      _mealStatusMap.clear();

      // Get meals for each student with active subscription
      for (var student in students) {
        try {
          print('Checking student: ${student.name}, ID: ${student.id}');
          print(
              'Has active breakfast: ${student.hasActiveBreakfast}, Has active lunch: ${student.hasActiveLunch}');

          // Check if student has active meal plans
          if (student.hasActiveBreakfast || student.hasActiveLunch) {
            print('Student has active plan: ${student.name}');

            // Get all upcoming meals for this student
            final studentMeals =
                await mealService.getUpcomingMealsForStudent(student.id);
            print('Retrieved ${studentMeals.length} meals for ${student.name}');

            // Get the current date without time component for comparison
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);

            // Filter out past and cancelled meals
            List<MealSchedule> validMeals = [];

            for (var meal in studentMeals) {
              // Normalize the date to compare properly
              final mealDate =
                  DateTime(meal.date.year, meal.date.month, meal.date.day);

              // Skip if meal date is before today
              if (mealDate.isBefore(today)) {
                continue;
              }

              // Check if meal is cancelled
              await _updateMealStatus(meal);
              final mealKey = _getMealKey(meal);
              if (_mealStatusMap[mealKey] == 'Cancelled') {
                print(
                    'Skipping cancelled meal: ${meal.title} on ${DateFormat('yyyy-MM-dd').format(meal.date)}');
                continue;
              }

              validMeals.add(meal);
            }

            // Sort by date (earliest first)
            validMeals.sort((a, b) => a.date.compareTo(b.date));

            print(
                'Valid upcoming meals for ${student.name} after filtering: ${validMeals.length}');

            // Add to map regardless of whether meals were found
            mealsByStudent[student.id] = validMeals;
          }
        } catch (studentError) {
          print('Error processing student ${student.name}: $studentError');
          // Continue with next student even if there's an error with this one
          mealsByStudent[student.id] = [];
        }
      }

      if (mounted) {
        setState(() {
          _upcomingMealsByStudent = mealsByStudent;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading upcoming meals: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    return RefreshIndicator(
      onRefresh: _loadMeals,
      child: _upcomingMealsByStudent.isEmpty
          ? _buildEmptyState()
          : Column(
              children: _students
                  .where((student) =>
                      _upcomingMealsByStudent.containsKey(student.id))
                  .map((student) {
                return _buildStudentMealsSection(student);
              }).toList(),
            ),
    );
  }

  Widget _buildStudentMealsSection(Student student) {
    final meals = _upcomingMealsByStudent[student.id] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // If no meals found, show a message
        if (meals.isEmpty)
          Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No upcoming meals found',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        else
          // Build a meal card for each meal (limited to max 2)
          ...meals
              .take(2)
              .map((meal) => _buildMealCard(meal, student))
              .toList(),
      ],
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

  Widget _buildMealCard(MealSchedule meal, Student student) {
    final mealStatus = _getMealStatus(meal);

    // Always use the actual date format
    String dateText = DateFormat('EEE, MMM d').format(meal.date);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Meal type icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: meal.planType == 'breakfast'
                        ? Colors.purple.withOpacity(0.1)
                        : meal.planType == 'express'
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    meal.planType == 'breakfast'
                        ? Icons.free_breakfast
                        : Icons.lunch_dining,
                    color: meal.planType == 'breakfast'
                        ? Colors.purple
                        : meal.planType == 'express'
                            ? Colors.blue
                            : Colors.green,
                  ),
                ),
                const SizedBox(width: 12),

                // Meal details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.mealPlanType ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      // Add student name
                      Text(
                        student.name,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      // Show actual date
                      Text(
                        DateFormat('EEE, MMM d').format(
                            student.breakfastPlanStartDate ?? DateTime.now()),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (mealStatus == 'Swapped')
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            'Swapped',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // View details button
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MySubscriptionScreen(
                          selectedStudentId: student.id,
                          defaultTabIndex: 0,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.purple,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: AppTheme.purple,
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
    );
  }
}
