import 'dart:developer';
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
  List<Student> _students = [];

  @override
  void initState() {
    super.initState();
    _loadMeals();
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
      final subscriptionService = services.SubscriptionService();
      Map<String, List<MealSchedule>> mealsByStudent = {};

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

            // Filter out past and cancelled meals
            final now = DateTime.now();
            final validMeals = studentMeals
                .where((meal) =>
                    meal.date.isAfter(now) &&
                    meal.status.toLowerCase() != 'cancelled')
                .toList();

            print(
                'Valid upcoming meals for ${student.name}: ${validMeals.length}');

            // Sort by date (upcoming first)
            validMeals.sort((a, b) => a.date.compareTo(b.date));

            // Limit to 2 meals per student
            final limitedMeals = validMeals.take(2).toList();

            // Add to map regardless of whether meals were found
            mealsByStudent[student.id] = limitedMeals;
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

    // Always show section for students with active plans
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Only show student name header if there are multiple students with meals
        if (_upcomingMealsByStudent.length > 1)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Upcoming Meals for ${student.name}',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
          ),
        // Show meals if available, otherwise show "No upcoming meals" for this student
        if (meals.isNotEmpty)
          ...meals.map((meal) => _buildMealCard(meal)).toList()
        else
          _buildEmptyStateForStudent(student),

        // Add space between student sections if multiple students
        if (_upcomingMealsByStudent.length > 1) const SizedBox(height: 16),
      ],
    );
  }

  // Add new method to show empty state for a specific student
  Widget _buildEmptyStateForStudent(Student student) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
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
                    'No scheduled meals for ${student.name}',
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

  Widget _buildMealCard(MealSchedule meal) {
    // Format the date
    final dateFormat = DateFormat('EEE, MMM d');
    final formattedDate = dateFormat.format(meal.date);

    // Format the time
    final timeFormat = DateFormat('h:mm a');
    final formattedTime = meal.planType == 'breakfast' ? '8:00 AM' : '12:30 PM';

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.purple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.restaurant,
                color: AppTheme.purple,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_getMealTypeLabel(meal.planType)} for ${meal.studentName}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.textMedium,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formattedDate,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedTime,
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
    );
  }

  String _getMealTypeLabel(String planType) {
    switch (planType) {
      case 'breakfast':
        return 'Breakfast';
      case 'express':
        return 'Express Meal';
      case 'lunch':
      default:
        return 'Lunch';
    }
  }
}
