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

    final Map<String, dynamic> mealTypeData =
        mealTypes[planType] ?? mealTypes['lunch']!;
    final List<Map<String, dynamic>> mealOptions = mealTypeData['options'];
    final String planName = mealTypeData['planName'];

    final DateTime now = DateTime.now();
    DateTime currentDate = DateTime(now.year, now.month, now.day);

    // Determine the start date for meal generation
    DateTime startDate = planType == 'breakfast'
        ? (student.breakfastPlanStartDate ?? currentDate)
        : (student.lunchPlanStartDate ?? currentDate);

    // If the start date is in the past, use today instead
    if (startDate.isBefore(currentDate)) {
      startDate = currentDate;
    }

    int planPeriodDays = endDate.difference(startDate).inDays + 1;

    // For express plans, show only today's meal
    if (planType == 'express') {
      if (!currentDate.isAfter(endDate)) {
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
      // Determine selected weekdays for this plan
      List<int>? selectedWeekdays =
          student.getSelectedWeekdaysForMealType(planType);
      // If not set, default to Mon-Fri (1-5)
      if (selectedWeekdays == null || selectedWeekdays.isEmpty) {
        selectedWeekdays = [1, 2, 3, 4, 5];
      }
      // For each day in the plan period, add a meal if it's a valid delivery day
      for (int i = 0; i < planPeriodDays; i++) {
        final DateTime mealDate = startDate.add(Duration(days: i));
        if (mealDate.isAfter(endDate)) {
          break;
        }
        int weekday = mealDate.weekday; // 1=Mon, 7=Sun
        if (selectedWeekdays.contains(weekday)) {
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
