import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:startwell/utils/routes.dart';
import 'package:startwell/widgets/home/home_widgets.dart';
import 'package:startwell/widgets/shimmer/home_shimmer.dart';
import 'package:startwell/widgets/shimmer/shimmer_widgets.dart';
import 'package:startwell/screens/main_screen.dart';
import 'package:startwell/screens/startwell_wallet_page.dart';
import 'package:startwell/screens/invite_startwell_screen.dart';
import 'package:startwell/services/student_profile_service.dart';
import 'package:startwell/models/student_model.dart';
import 'package:startwell/services/subscription_service.dart' as services;
import 'package:startwell/models/subscription_model.dart';
import 'package:startwell/types/subscription_types.dart';
import 'package:startwell/screens/active_plan_details_page.dart';
import 'package:startwell/screens/remaining_meal_details_page.dart';
import 'package:startwell/widgets/home/value_carousel.dart';
import 'package:startwell/services/user_profile_service.dart';
import 'package:startwell/models/user_profile.dart';
import 'package:startwell/widgets/profile_avatar.dart';
import 'package:startwell/screens/all_student_subscription_page.dart';

class DashboardScreen extends StatefulWidget {
  final UserProfile? userProfile;
  final bool ishomeMode;
  const DashboardScreen({super.key, this.userProfile, this.ishomeMode = false});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _showFooter = false;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  // UserProfile? userProfile;

  // Subscription data
  List<Student> _students = [];
  Map<String, List<SubscriptionPlanData>> _studentPlans = {};
  bool _hasActivePlans = false;

  @override
  void initState() {
    super.initState();
    log('User Profile: ${widget.userProfile}');

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // Add scroll listener to show footer when at bottom
    _scrollController.addListener(_onScroll);

    // Load user profile
    // _loadUserProfile();

    // Load student data and their subscriptions
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    try {
      final studentProfileService = StudentProfileService();
      final subscriptionService = services.SubscriptionService();

      // Get all student profiles
      final List<Student> students =
          await studentProfileService.getStudentProfiles();
      _students = students;

      print('Total students: ${_students.length}');

      // For each student, fetch their active subscriptions
      Map<String, List<SubscriptionPlanData>> studentPlans = {};
      bool hasAnyActivePlans = false;

      for (var student in students) {
        final List<Subscription> subscriptions = await subscriptionService
            .getActiveSubscriptionsForStudent(student.id);

        print(
          'Student: ${student.name}, Active subscriptions: ${subscriptions.length}',
        );

        if (subscriptions.isNotEmpty) {
          hasAnyActivePlans = true;
          List<SubscriptionPlanData> planDataList = [];

          // Process each subscription for this student
          for (var subscription in subscriptions) {
            // Get cancelled meals for this subscription
            final cancelledMeals = await subscriptionService.getCancelledMeals(
              student.id,
            );
            final int cancelledCount = cancelledMeals.length;

            // Calculate meal summary
            final int totalMeals = _calculateTotalMeals(subscription);
            final int consumedMeals = (subscription.planType == 'express')
                ? 0
                : _calculateConsumedMeals(subscription, cancelledCount);

            // Create plan data object
            planDataList.add(
              SubscriptionPlanData(
                student: student,
                subscription: subscription,
                planType: _getPlanTypeDisplay(subscription),
                totalMeals: totalMeals,
                remainingMeals: totalMeals - consumedMeals,
                nextRenewalDate: subscription.endDate.day.toString() +
                    ' ' +
                    _getMonthName(subscription.endDate.month),
              ),
            );
          }

          studentPlans[student.id] = planDataList;
        }
      }

      if (mounted) {
        setState(() {
          _studentPlans = studentPlans;
          _hasActivePlans = hasAnyActivePlans;
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      print('Error loading student data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _animationController.forward();
      }
    }
  }

  String _getPlanTypeDisplay(Subscription plan) {
    String planPeriod;
    final days = plan.endDate.difference(plan.startDate).inDays;

    if (days <= 1) {
      planPeriod = "Single Day";
    } else if (days <= 7) {
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

    final mealType = plan.planType == 'breakfast' ? 'Breakfast' : 'Lunch';
    return "$planPeriod $mealType";
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  int _calculateTotalMeals(Subscription subscription) {
    if (subscription.planType == 'express') {
      return 1; // Express plan is just one meal
    }

    // Calculate days between start and end date
    final days =
        subscription.endDate.difference(subscription.startDate).inDays + 1;

    // If using custom weekdays
    if (subscription.selectedWeekdays.isNotEmpty) {
      // Calculate how many of each weekday falls within the date range
      final weekdayCounts = <int, int>{};
      for (int i = 0; i < days; i++) {
        final date = subscription.startDate.add(Duration(days: i));
        final weekday = date.weekday;
        if (subscription.selectedWeekdays.contains(weekday)) {
          weekdayCounts[weekday] = (weekdayCounts[weekday] ?? 0) + 1;
        }
      }

      // Sum all weekday counts
      return weekdayCounts.values.fold(0, (sum, count) => sum + count);
    } else {
      // Default Mon-Fri plan
      final weekdays = [1, 2, 3, 4, 5]; // Monday to Friday

      // Calculate how many weekdays fall within the date range
      int count = 0;
      for (int i = 0; i < days; i++) {
        final date = subscription.startDate.add(Duration(days: i));
        if (weekdays.contains(date.weekday)) {
          count++;
        }
      }

      return count;
    }
  }

  int _calculateConsumedMeals(Subscription subscription, int cancelledCount) {
    // Calculate days passed since subscription start
    final today = DateTime.now();
    if (today.isBefore(subscription.startDate)) {
      return 0; // Subscription hasn't started yet
    }

    final endDate =
        subscription.endDate.isAfter(today) ? today : subscription.endDate;
    final daysPassed = endDate.difference(subscription.startDate).inDays + 1;

    // If using custom weekdays
    if (subscription.selectedWeekdays.isNotEmpty) {
      // Calculate how many of each weekday has passed
      final weekdayCounts = <int, int>{};
      for (int i = 0; i < daysPassed; i++) {
        final date = subscription.startDate.add(Duration(days: i));
        final weekday = date.weekday;
        if (subscription.selectedWeekdays.contains(weekday)) {
          weekdayCounts[weekday] = (weekdayCounts[weekday] ?? 0) + 1;
        }
      }

      // Sum all weekday counts and subtract cancelled meals
      final totalPassed = weekdayCounts.values.fold(
        0,
        (sum, count) => sum + count,
      );
      return totalPassed - cancelledCount;
    } else {
      // Default Mon-Fri plan
      final weekdays = [1, 2, 3, 4, 5]; // Monday to Friday

      // Calculate how many weekdays have passed
      int count = 0;
      for (int i = 0; i < daysPassed; i++) {
        final date = subscription.startDate.add(Duration(days: i));
        if (weekdays.contains(date.weekday)) {
          count++;
        }
      }

      return count - cancelledCount;
    }
  }

  void _onScroll() {
    // Show footer when close to bottom (within 200 pixels of max scroll extent)
    if (_scrollController.hasClients) {
      // Check if close to bottom (within 200 pixels of max scroll extent)
      bool shouldShowFooter = _scrollController.position.pixels >
          (_scrollController.position.maxScrollExtent - 200);

      // Only update state if there's a change in visibility
      if (shouldShowFooter != _showFooter) {
        setState(() {
          _showFooter = shouldShowFooter;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Navigate to different tabs or screens
  void _navigateToTab(int index) {
    // Try to find MainScreen ancestor
    final MainScreenState? mainScreenState =
        context.findAncestorStateOfType<MainScreenState>();

    if (mainScreenState != null) {
      // If found, switch tab
      mainScreenState.switchToTab(index);
    } else {
      // Fallback to direct navigation
      if (index == 3) {
        // Meal Plan
        Navigator.pushNamed(context, Routes.mealPlan);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const HomeScreenShimmer();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Home',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppTheme.purpleToDeepPurple),
        ),
        elevation: 0,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 10),
            Image.asset(
              'assets/images/start_well.png',
              fit: BoxFit.cover,
              width: 30,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.home, color: Colors.white, size: 28);
              },
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ProfileAvatar(
              userProfile: widget.userProfile,
              radius: 18,
              onAvatarTap: () {
                Navigator.pushNamed(context, Routes.profileSettings);
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Banner
                  _buildAnimatedSection(
                    animation: _fadeAnimation,
                    slideAnimation: _slideAnimation,
                    delay: 0.1,
                    child: HomeBannerCard(
                      onExplorePressed: () =>
                          _navigateToTab(3), // Meal Plan tab
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Subscription Overview Section
                  _buildAnimatedSection(
                    animation: _fadeAnimation,
                    slideAnimation: _slideAnimation,
                    delay: 0.2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionTitle(
                          title: 'Your Subscriptions',
                          actionText: _hasActivePlans ? 'See All' : null,
                          onActionPressed: _hasActivePlans
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          AllStudentSubscriptionPage(
                                        students: _students,
                                        studentPlans: _studentPlans,
                                      ),
                                    ),
                                  );
                                }
                              : null,
                        ),
                        const SizedBox(height: 15),

                        // No active plans message
                        if (!_hasActivePlans)
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            shadowColor: AppTheme.deepPurple.withOpacity(0.15),
                            child: Ink(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: AppTheme.offWhite,
                              ),
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
                                        Icons.calendar_month,
                                        color: Colors.grey,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        'No active subscription plans found',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          color: AppTheme.textMedium,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        // Active plans - Show only the first student with active plan
                        if (_hasActivePlans)
                          Builder(
                            builder: (context) {
                              // Get first student with active plans
                              final studentsWithPlans = _students
                                  .where(
                                    (student) => _studentPlans.containsKey(
                                      student.id,
                                    ),
                                  )
                                  .toList();

                              if (studentsWithPlans.isEmpty)
                                return const SizedBox.shrink();

                              final firstStudent = studentsWithPlans.first;
                              final plans =
                                  _studentPlans[firstStudent.id] ?? [];
                              final planCount = plans.length;

                              return Column(
                                children: [
                                  Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
                                    margin: const EdgeInsets.only(bottom: 12),
                                    shadowColor:
                                        AppTheme.deepPurple.withOpacity(0.15),
                                    child: InkWell(
                                      onTap: () {
                                        // Add haptic feedback for better tactile response
                                        HapticFeedback.lightImpact();

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                ActivePlanDetailsPage(
                                              studentId: firstStudent.id,
                                            ),
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Ink(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          color: AppTheme.offWhite,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 48,
                                                height: 48,
                                                decoration: BoxDecoration(
                                                  color: Colors.blue
                                                      .withOpacity(0.1),
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.blue
                                                          .withOpacity(0.1),
                                                      blurRadius: 4,
                                                      offset: const Offset(
                                                        0,
                                                        2,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                child: Icon(
                                                  Icons.calendar_month,
                                                  color: Colors.blue,
                                                  size: 24,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      firstStudent.name,
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            AppTheme.textDark,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      planCount == 1
                                                          ? '1 Active Plan'
                                                          : '$planCount Active Plans',
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize: 14,
                                                        color:
                                                            AppTheme.textMedium,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.green
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      width: 8,
                                                      height: 8,
                                                      decoration:
                                                          const BoxDecoration(
                                                        color: Colors.green,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Active',
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: Colors.green,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Icon(
                                                Icons.chevron_right,
                                                color: Colors.grey.shade600,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Add Remaining Meals card for this student
                                  _buildStudentRemainingMealsCard(
                                    firstStudent,
                                    plans,
                                  ),
                                ],
                              );
                            },
                          ),
                      ],
                    ),
                  ),

                  // Upcoming Meals Section
                  _buildAnimatedSection(
                    animation: _fadeAnimation,
                    slideAnimation: _slideAnimation,
                    delay: 0.3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionTitle(
                          title: 'Upcoming Meals',
                          actionText: 'See All',
                          onActionPressed: () =>
                              _navigateToTab(2), // My Subscription tab
                        ),
                        const SizedBox(height: 15),
                        const UpcomingMealCardList(),
                      ],
                    ),
                  ),

                  // StartwellPromiseCarousel - Moved from above
                  _buildAnimatedSection(
                    margin: 0,
                    animation: _fadeAnimation,
                    slideAnimation: _slideAnimation,
                    delay: 0.35,
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: 20),
                          child: SectionTitle(title: 'Why Parents Choose Us'),
                        ),
                        const SizedBox(height: 15),
                        ValueCarousel(),
                      ],
                    ),
                  ),

                  // Quick Actions Section
                  _buildAnimatedSection(
                    animation: _fadeAnimation,
                    slideAnimation: _slideAnimation,
                    delay: 0.4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle(title: 'Quick Actions'),
                        const SizedBox(height: 15),
                        QuickActions(
                          onInviteSchoolPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const InviteStartWellScreen(),
                              ),
                            );
                          },
                          onWalletPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const StartwellWalletPage(),
                              ),
                            );
                          },
                          onMealPlanPressed: () =>
                              _navigateToTab(3), // Meal Plan tab
                          onManageStudentPressed: () =>
                              _navigateToTab(1), // Student Profiles tab
                          onTopUpWalletPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const StartwellWalletPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Footer Note - only show when scrolled to the bottom
                  if (_showFooter)
                    _buildAnimatedSection(
                      margin: 0,
                      animation: _fadeAnimation,
                      slideAnimation: _slideAnimation,
                      delay: 0.5,
                      child: const FooterNote(),
                    ),
                  // Add height even if footer isn't showing yet to allow scrolling
                  if (!_showFooter) const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedSection({
    required Animation<double> animation,
    required Animation<double> slideAnimation,
    required double delay,
    required Widget child,
    double? margin,
  }) {
    // Apply a delay based on the index for staggered animation
    final delayedAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(delay, 1.0, curve: Curves.easeOut),
    );

    return Container(
      margin: EdgeInsets.all(margin ?? 20),
      child: AnimatedBuilder(
        animation: delayedAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: animation.value,
            child: Transform.translate(
              offset: Offset(
                0,
                slideAnimation.value * (1 - delayedAnimation.value),
              ),
              child: child,
            ),
          );
        },
        child: child,
      ),
    );
  }

  // Add this method to build remaining meals card for each student
  Widget _buildStudentRemainingMealsCard(
    Student student,
    List<SubscriptionPlanData> plans,
  ) {
    // Calculate total remaining meals
    int totalRemaining = 0;
    int totalMeals = 0;
    int consumedMeals = 0;
    Map<String, int> mealTypeCount = {};

    for (var plan in plans) {
      totalRemaining += plan.remainingMeals;
      totalMeals += plan.totalMeals;
      consumedMeals +=
          (plan.totalMeals - plan.remainingMeals); // Calculate consumed meals

      // Track by meal type
      final mealType = plan.subscription.planType;
      final formattedType = mealType == 'breakfast' ? 'Breakfast' : 'Lunch';
      mealTypeCount[formattedType] =
          (mealTypeCount[formattedType] ?? 0) + plan.remainingMeals;
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      shadowColor: AppTheme.purple.withOpacity(0.3),
      margin: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        onTap: () {
          // Add haptic feedback for better tactile response
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RemainingMealDetailsPage(studentId: student.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppTheme.offWhite,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.restaurant,
                    color: Colors.green,
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
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: Colors.grey.shade600),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
