import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:startwell/widgets/subscription/meal_card.dart';
import 'package:intl/intl.dart';
import 'package:startwell/services/meal_service.dart';
import 'package:startwell/services/student_profile_service.dart';
import 'package:startwell/models/student_model.dart';
import 'package:startwell/models/subscription_model.dart';

class UpcomingMealsTab extends StatefulWidget {
  final String? selectedStudentId;

  const UpcomingMealsTab({Key? key, this.selectedStudentId}) : super(key: key);

  @override
  State<UpcomingMealsTab> createState() => _UpcomingMealsTabState();
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

    try {
      // Get active subscriptions based on the student's actual meal plans
      _activeSubscriptions = await _subscriptionService
          .getActiveSubscriptionsForStudent(studentId);
    } catch (e) {
      print('Error loading subscriptions: $e');
      _activeSubscriptions = [];
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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

    return RefreshIndicator(
      onRefresh: () async {
        if (_selectedStudentId != null) {
          await _loadSubscriptionsForStudent(_selectedStudentId!);
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: _activeSubscriptions.length,
        itemBuilder: (context, index) {
          final subscription = _activeSubscriptions[index];

          // Find the correct student for this subscription
          final student = _studentsWithMealPlans.firstWhere(
            (s) => s.id == subscription.studentId,
            orElse: () => _studentsWithMealPlans.first,
          );

          // Calculate next delivery date
          final nextDeliveryDate = subscription.nextDeliveryDate;
          log("nextDeliveryDate: $nextDeliveryDate");
          log("nextDeliveryDate subscription.endDate: ${subscription.endDate}");
          log("nextDeliveryDate subscription $subscription");

          // Check if subscription is still valid (not expired)
          final bool isExpired = nextDeliveryDate.isBefore(DateTime.now()) &&
              nextDeliveryDate == subscription.endDate;

          if (isExpired) {
            // Skip expired subscriptions or show them differently
            return _buildExpiredSubscriptionCard(subscription, student);
          }

          return MealCard(
            date: nextDeliveryDate,
            title: subscription.mealItemName,
            description: "Next scheduled delivery",
            status: "Scheduled",
            studentName: student.name,
            planName: subscription.subscriptionType +
                " " +
                (subscription.planType == 'breakfast' ? 'Breakfast' : 'Lunch') +
                " Plan",
            mealItems: subscription.getMealItems(),
            planType: subscription.planType,
            onSwapMeal: subscription.isSwapEnabled
                ? () => _showSwapMealBottomSheet(subscription)
                : () {},
            onCancelMeal: subscription.isCancelEnabled
                ? () => _showCancelMealDialog(subscription)
                : () {},
          );
        },
      ),
    );
  }

  Widget _buildCalendarView() {
    // Calendar view implementation
    return const Center(
      child: Text("Calendar view coming soon"),
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
              Navigator.of(context).pushReplacementNamed(
                '/',
                arguments: 3, // Meal Plan tab
              );
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

    // Check if we're past the swap window cutoff
    final now = DateTime.now();
    final cutoffDate = DateTime(
            subscription.nextDeliveryDate.year,
            subscription.nextDeliveryDate.month,
            subscription.nextDeliveryDate.day,
            23,
            59)
        .subtract(const Duration(days: 1));

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

  // Get appropriate swap options based on meal type
  List<Map<String, String>> _getSwapOptionsForMealType(String mealType) {
    if (mealType == 'breakfast') {
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
    } else if (mealType == 'lunch') {
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

  void _showCancelMealDialog(Subscription subscription) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cancel Meal',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to cancel this meal?',
          style: GoogleFonts.poppins(),
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

              // Cancel the meal
              final success = await _subscriptionService.cancelMealDelivery(
                subscription.id,
                subscription.nextDeliveryDate,
              );

              if (success && mounted) {
                // Reload data after successful cancellation
                await _loadSubscriptionsForStudent(_selectedStudentId!);

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

  // Build a card for expired subscriptions
  Widget _buildExpiredSubscriptionCard(
      Subscription subscription, Student student) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      color: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  'Expired Subscription',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${subscription.subscriptionType} ${subscription.planType == 'breakfast' ? 'Breakfast' : 'Lunch'} Plan (${subscription.mealItemName})',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 4),
            Text(
              'Ended on: ${DateFormat('EEE, MMM dd, yyyy').format(subscription.endDate)}',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                // Navigate to subscription renewal screen
                // Navigate to meal plan screen - index 3 in bottom navigation
                final navigationState = Navigator.of(context);

                // Pop until we get to the main screen
                while (navigationState.canPop()) {
                  navigationState.pop();
                }

                // Navigate to the meal plan tab
                Navigator.of(context).pushReplacementNamed(
                  '/',
                  arguments: 3, // Meal Plan tab
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.purple.withOpacity(0.8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Renew Subscription', style: GoogleFonts.poppins()),
            ),
          ],
        ),
      ),
    );
  }
}
