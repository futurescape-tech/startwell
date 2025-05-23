import 'package:startwell/models/student_model.dart';
import 'package:startwell/services/student_profile_service.dart';

class MealSchedule {
  final DateTime date;
  final String title;
  final String description;
  final String status;
  final String studentName;
  final String planName;
  final List<String> mealItems;
  final String studentId;
  final String planType; // 'breakfast', 'lunch', or 'express'

  MealSchedule({
    required this.date,
    required this.title,
    required this.description,
    required this.status,
    required this.studentName,
    required this.planName,
    required this.mealItems,
    required this.studentId,
    required this.planType,
  });
}

class MealService {
  // Singleton pattern
  static final MealService _instance = MealService._internal();

  factory MealService() {
    return _instance;
  }

  MealService._internal();

  // Get meal items based on plan type
  List<String> getMealItems(String planType) {
    if (planType == 'breakfast') {
      return ['Breakfast Item 1', 'Breakfast Item 2', 'Seasonal Fruit'];
    }
    return ['Lunch Item 1', 'Lunch Item 2', 'Salad']; // lunch or express
  }

  // Fetch upcoming meals for a student
  Future<List<MealSchedule>> getUpcomingMealsForStudent(
      String studentId) async {
    // Get the student profile
    final StudentProfileService profileService = StudentProfileService();
    final List<Student> students = await profileService.getStudentProfiles();
    final Student? student =
        students.where((s) => s.id == studentId).firstOrNull;

    if (student == null) {
      return [];
    }

    // Check for breakfast plan
    List<MealSchedule> upcomingMeals = [];

    if (student.hasActiveBreakfast && student.breakfastPlanEndDate != null) {
      upcomingMeals.addAll(
        _generateMealsForPlan(
          student: student,
          planType: 'breakfast',
          endDate: student.breakfastPlanEndDate!,
        ),
      );
    }

    // Check for lunch plan
    if (student.hasActiveLunch && student.lunchPlanEndDate != null) {
      // Determine if this is an express plan based on name or other criteria
      final bool isExpress = student.mealPlanType == 'express';

      upcomingMeals.addAll(
        _generateMealsForPlan(
          student: student,
          planType: isExpress ? 'express' : 'lunch',
          endDate: student.lunchPlanEndDate!,
        ),
      );
    }

    // Sort by date
    upcomingMeals.sort((a, b) => a.date.compareTo(b.date));

    return upcomingMeals;
  }

  // Generate meals for a specific plan type
  List<MealSchedule> _generateMealsForPlan({
    required Student student,
    required String planType,
    required DateTime endDate,
  }) {
    final List<MealSchedule> meals = [];

    // Define meal options based on plan type
    final mealTypes = {
      'breakfast': {
        'options': [
          {
            'title': 'Breakfast of the Day',
            'description': 'Nutritious Breakfast',
            'mealItems': getMealItems('breakfast'),
          },
          {
            'title': 'Indian Breakfast',
            'description': 'Traditional Indian Breakfast',
            'mealItems': getMealItems('breakfast'),
          },
          {
            'title': 'International Breakfast',
            'description': 'Global Breakfast Experience',
            'mealItems': getMealItems('breakfast'),
          },
          {
            'title': 'Jain Breakfast',
            'description': 'Jain-friendly Breakfast',
            'mealItems': getMealItems('breakfast'),
          },
        ],
        'planName': 'Daily Breakfast Plan'
      },
      'lunch': {
        'options': [
          {
            'title': 'Lunch of the Day',
            'description': 'Nutritious Lunch Meal',
            'mealItems': getMealItems('lunch'),
          },
          {
            'title': 'Indian Lunch',
            'description': 'Traditional Indian Lunch',
            'mealItems': getMealItems('lunch'),
          },
          {
            'title': 'International Lunch',
            'description': 'Global Lunch Experience',
            'mealItems': getMealItems('lunch'),
          },
          {
            'title': 'Jain Lunch',
            'description': 'Jain-friendly Lunch',
            'mealItems': getMealItems('lunch'),
          },
        ],
        'planName': 'Daily Lunch Plan'
      },
      'express': {
        'options': [
          {
            'title': 'Lunch of the Day',
            'description': 'Express Lunch Delivery',
            'mealItems': getMealItems('lunch'),
          },
          {
            'title': 'Indian Lunch',
            'description': 'Express Indian Lunch',
            'mealItems': getMealItems('lunch'),
          },
          {
            'title': 'International Lunch',
            'description': 'Express International Lunch',
            'mealItems': getMealItems('lunch'),
          },
          {
            'title': 'Jain Lunch',
            'description': 'Express Jain Lunch',
            'mealItems': getMealItems('lunch'),
          },
        ],
        'planName': 'Express 1-Day Plan'
      },
    };

    // Get meal options based on the meal plan type
    final Map<String, dynamic> mealTypeData =
        mealTypes[planType] ?? mealTypes['lunch']!;
    final List<Map<String, dynamic>> mealOptions = mealTypeData['options'];
    final String planName = mealTypeData['planName'];

    // Generate meals for the entire plan period instead of just 7 days
    final DateTime now = DateTime.now();
    DateTime currentDate = DateTime(now.year, now.month, now.day);

    // Determine the start date for meal generation
    // Use the plan's start date if available, otherwise use today
    DateTime startDate = planType == 'breakfast'
        ? (student.breakfastPlanStartDate ?? currentDate)
        : (student.lunchPlanStartDate ?? currentDate);

    // If the start date is in the past, use today instead
    if (startDate.isBefore(currentDate)) {
      startDate = currentDate;
    }

    // Get the maximum plan period (in days)
    int planPeriodDays = endDate.difference(startDate).inDays + 1;

    // For express plans, show only today's meal
    if (planType == 'express') {
      if (!currentDate.isAfter(endDate)) {
        // Only add the express meal if today is within the plan period
        final Map<String, dynamic> mealOption = mealOptions[0];
        meals.add(
          MealSchedule(
            date: currentDate,
            title: mealOption['title'],
            description: mealOption['description'],
            status: 'Scheduled',
            studentName: student.name,
            planName: planName,
            mealItems: List<String>.from(mealOption['mealItems']),
            studentId: student.id,
            planType: planType,
          ),
        );
      }
    } else {
      // For regular plans, iterate through all days in the plan period
      for (int i = 0; i < planPeriodDays; i++) {
        final DateTime mealDate = startDate.add(Duration(days: i));

        // Stop if we're past the meal plan end date
        if (mealDate.isAfter(endDate)) {
          break;
        }

        // Check if this date is a weekday (Monday to Friday)
        // Skip weekends unless it's a custom plan that includes weekends
        bool isValidDeliveryDay = false;

        // Get the weekday index (1-7, where 1 is Monday)
        int weekday = mealDate.weekday;

        // For now, assume weekday delivery (Mon-Fri) for all plans
        // This can be expanded later to check the plan's selected weekdays
        if (planType == 'breakfast') {
          // For breakfast, typically delivered Tue, Thu (weekdays 2, 4)
          isValidDeliveryDay = (weekday == 2 || weekday == 4);
        } else {
          // For lunch, typically delivered Wed (weekday 3)
          isValidDeliveryDay = (weekday == 3);
        }

        // Add the meal if it's a valid delivery day
        if (isValidDeliveryDay) {
          // For demo purposes, we'll use the first meal option (standard meal)
          // In a real app, this might be the selected meal for this day
          final Map<String, dynamic> mealOption = mealOptions[0];

          meals.add(
            MealSchedule(
              date: mealDate,
              title: mealOption['title'],
              description: mealOption['description'],
              status: 'Scheduled',
              studentName: student.name,
              planName: planName,
              mealItems: List<String>.from(mealOption['mealItems']),
              studentId: student.id,
              planType: planType,
            ),
          );
        }
      }
    }

    return meals;
  }

  // Get all student IDs with active meal plans
  Future<List<String>> getStudentsWithMealPlans() async {
    final StudentProfileService profileService = StudentProfileService();
    final List<Student> students = await profileService.getStudentProfiles();

    // Filter students with active meal plans
    return students
        .where((student) => student.hasActivePlan)
        .map((student) => student.id)
        .toList();
  }
}
