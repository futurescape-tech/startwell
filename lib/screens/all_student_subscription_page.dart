import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:startwell/models/student_model.dart';
import 'package:startwell/models/subscription_model.dart';
import 'package:startwell/types/subscription_types.dart';
import 'package:startwell/screens/active_plan_details_page.dart';
import 'package:startwell/screens/remaining_meal_details_page.dart';

class AllStudentSubscriptionPage extends StatelessWidget {
  final List<Student> students;
  final Map<String, List<SubscriptionPlanData>> studentPlans;

  const AllStudentSubscriptionPage({
    Key? key,
    required this.students,
    required this.studentPlans,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get only students with active subscriptions
    final List<Student> studentsWithPlans = students
        .where((student) => studentPlans.containsKey(student.id))
        .toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'All Student Subscriptions',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.purple,
      ),
      body: studentsWithPlans.isEmpty
          ? _buildNoPlansView()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: studentsWithPlans.length,
              itemBuilder: (context, index) {
                final student = studentsWithPlans[index];
                final plans = studentPlans[student.id] ?? [];
                return Column(
                  children: [
                    // Active Meal Plan Card
                    _buildActivePlanCard(context, student, plans),

                    // Remaining Meals Card
                    _buildRemainingMealsCard(context, student, plans),

                    const SizedBox(height: 20), // Space between students
                  ],
                );
              },
            ),
    );
  }

  Widget _buildNoPlansView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 72,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No Active Plans',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'There are no active subscription plans for any students.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: AppTheme.textMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivePlanCard(
      BuildContext context, Student student, List<SubscriptionPlanData> plans) {
    final int planCount = plans.length;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ActivePlanDetailsPage(studentId: student.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
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
                  Icons.calendar_month,
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
                      student.name,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      planCount == 1
                          ? '1 Active Plan'
                          : '$planCount Active Plans',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppTheme.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Active',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: AppTheme.textMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRemainingMealsCard(
      BuildContext context, Student student, List<SubscriptionPlanData> plans) {
    // Calculate total remaining meals
    int totalRemaining = 0;
    int totalMeals = 0;
    int consumedMeals = 0;
    Map<String, int> mealTypeCount = {};

    for (var plan in plans) {
      totalRemaining += plan.remainingMeals as int;
      totalMeals += plan.totalMeals as int;
      consumedMeals +=
          ((plan.totalMeals as int) - (plan.remainingMeals as int));

      // Track by meal type
      final mealType = plan.subscription.planType;
      final formattedType = mealType == 'breakfast' ? 'Breakfast' : 'Lunch';
      mealTypeCount[formattedType] =
          (mealTypeCount[formattedType] ?? 0) + (plan.remainingMeals as int);
    }

    // Calculate progress value (consumed / total)
    final double progress = totalMeals > 0 ? consumedMeals / totalMeals : 0.0;

    // Build the meal type breakdown text
    String breakdownText = '';
    if (mealTypeCount.isNotEmpty) {
      if (mealTypeCount.length == 1) {
        // Single plan type
        final entry = mealTypeCount.entries.first;
        breakdownText = '(${entry.key})';
      } else {
        // Multiple plan types
        breakdownText = '(';
        int count = 0;
        mealTypeCount.forEach((type, meals) {
          if (count > 0) breakdownText += ' + ';
          breakdownText += type;
          count++;
        });
        breakdownText += ')';
      }
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RemainingMealDetailsPage(studentId: student.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.restaurant,
                  color: AppTheme.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Remaining Meals for ${student.name}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppTheme.textMedium,
                        ),
                        children: [
                          TextSpan(text: '$totalRemaining meals remaining '),
                          TextSpan(
                            text: breakdownText,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[200],
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(AppTheme.orange),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: AppTheme.textMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
