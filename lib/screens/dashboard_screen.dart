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
import 'package:startwell/services/meal_selection_manager.dart';
import 'package:startwell/screens/meal_plan_screen.dart';
import 'package:startwell/screens/menu_page.dart';
import 'package:startwell/widgets/home/upcoming_meal_card_list.dart';

class DashboardScreen extends StatefulWidget {
  final UserProfile? userProfile;
  final bool ishomeMode;
  const DashboardScreen({super.key, this.userProfile, this.ishomeMode = false});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  bool _showFooter = false;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late AnimationController _menuIconController;
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

    _menuIconController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

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

    // Prioritize checking for Single Day duration enum
    if (plan.duration == SubscriptionDuration.singleDay) {
      planPeriod = "Single Day";
    } else {
      // Calculate the number of *calendar days* the plan spans.
      final int durationInDays =
          plan.endDate.difference(plan.startDate).inDays + 1;

      if (durationInDays <= 7) {
        planPeriod = "Weekly";
      } else if (durationInDays <= 31) {
        planPeriod = "Monthly"; // Approximation for a month
      } else if (durationInDays <= 90) {
        planPeriod = "Quarterly"; // Approximation for 3 months
      } else if (durationInDays <= 180) {
        planPeriod = "Half-Yearly"; // Approximation for 6 months
      } else if (durationInDays <= 365) {
        // Approximation for a year
        planPeriod = "Annual";
      } else {
        planPeriod = "Long Term"; // For plans longer than a year
      }
    }

    final mealType = plan.planType == 'breakfast' ? 'Breakfast' : 'Lunch';
    return "$planPeriod $mealType Plan";
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
    _menuIconController.dispose();
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
        // Use direct navigation to MealPlanScreen with initialTab set to 'breakfast'
        print(
          'DEBUG: Directly navigating to MealPlanScreen with initialTab=breakfast',
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => MealPlanScreen(initialTab: 'breakfast'),
          ),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 350;
    final sectionPadding = isSmall ? 10.0 : 20.0;
    final cardPadding = isSmall ? 10.0 : 18.0;
    final cardSpacing = isSmall ? 8.0 : 16.0;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Home',
          style: GoogleFonts.poppins(
            fontSize: isSmall ? 16 : 20,
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
            SizedBox(width: isSmall ? 4 : 10),
            Image.asset(
              'assets/images/start_well.png',
              fit: BoxFit.cover,
              width: isSmall ? 22 : 30,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.home, color: Colors.white, size: 28);
              },
            ),
          ],
        ),
        actions: [
          // Weekly Menu icon with animation
          GestureDetector(
            onTap: () {
              MenuPage.showAsDialog(context);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.all(8),
              child: AnimatedBuilder(
                animation: _menuIconController,
                builder: (context, child) {
                  // Create a pulsing effect
                  final scale = 0.9 + 0.1 * _menuIconController.value;
                  final rotate =
                      _menuIconController.value * 0.05; // Subtle rotation of 5%

                  return Transform.rotate(
                    angle: rotate,
                    child: Transform.scale(
                      scale: scale,
                      child: ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return LinearGradient(
                            colors: [
                              AppTheme.yellow,
                              Colors.orange,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds);
                        },
                        child: Icon(
                          Icons.menu_book_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Cart icon
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.shopping_cart_outlined,
                    color: Colors.white,
                    size: 26,
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, Routes.cart);
                  },
                ),
                if (MealSelectionManager.hasBreakfastInCart ||
                    MealSelectionManager.hasLunchInCart)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        '${(MealSelectionManager.hasBreakfastInCart ? 1 : 0) + (MealSelectionManager.hasLunchInCart ? 1 : 0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Profile avatar
          Padding(
            padding: EdgeInsets.only(right: isSmall ? 8.0 : 12.0, left: 4.0),
            child: ProfileAvatar(
              userProfile: widget.userProfile,
              radius: isSmall ? 14 : 18,
              onAvatarTap: () {
                Navigator.pushNamed(context, Routes.profileSettings);
              },
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Banner
                          if (false) // Hide the School Meals Done Right card
                            _buildAnimatedSection(
                              animation: _fadeAnimation,
                              slideAnimation: _slideAnimation,
                              delay: 0.1,
                              child: HomeBannerCard(
                                onExplorePressed: () {
                                  _navigateToTab(3); // Meal Plan tab
                                },
                              ),
                            ),
                          // Remove height spacing as the banner is now hidden
                          // SizedBox(height: isSmall ? 6 : 10),

                          // Why Parents Choose Us Section - now first section without label
                          _buildAnimatedSection(
                            margin: 0,
                            animation: _fadeAnimation,
                            slideAnimation: _slideAnimation,
                            delay: 0.2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Removed the title/label "Why Parents Choose Us"
                                const ValueCarousel(),
                              ],
                            ),
                          ),

                          SizedBox(height: isSmall ? 15 : 25),

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
                                  onActionPressed: () => _navigateToTab(2),
                                ),
                                SizedBox(height: isSmall ? 8 : 15),
                                const UpcomingMealCardList(),
                              ],
                            ),
                          ),

                          // Subscription Overview Section
                          _buildAnimatedSection(
                            animation: _fadeAnimation,
                            slideAnimation: _slideAnimation,
                            delay: 0.35,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SectionTitle(
                                  title: 'Your Subscriptions',
                                  actionText: null,
                                  onActionPressed: null,
                                ),
                                SizedBox(height: isSmall ? 8 : 15),

                                // No active plans message
                                if (!_hasActivePlans)
                                  Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 5,
                                    shadowColor:
                                        AppTheme.deepPurple.withOpacity(0.15),
                                    child: Ink(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: Colors.grey[50],
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.all(cardPadding),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: isSmall ? 32 : 48,
                                              height: isSmall ? 32 : 48,
                                              decoration: BoxDecoration(
                                                color: Colors.grey
                                                    .withOpacity(0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.calendar_month,
                                                color: Colors.grey,
                                                size: 24,
                                              ),
                                            ),
                                            SizedBox(width: isSmall ? 8 : 16),
                                            Expanded(
                                              child: Text(
                                                'No active subscription plans found',
                                                style: GoogleFonts.poppins(
                                                  fontSize: isSmall ? 13 : 16,
                                                  color: AppTheme.textMedium,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                // Active plans - Show aggregated data for all students
                                if (_hasActivePlans)
                                  Builder(
                                    builder: (context) {
                                      // Get all students with active plans
                                      final studentsWithPlans = _students
                                          .where(
                                            (student) => _studentPlans
                                                .containsKey(student.id),
                                          )
                                          .toList();

                                      if (studentsWithPlans.isEmpty)
                                        return const SizedBox.shrink();

                                      // Calculate total plans and meals across all students
                                      int totalActivePlans = 0;
                                      int totalRemainingMeals = 0;
                                      int totalMeals = 0;
                                      Map<String, int> mealTypeCount = {};

                                      for (var student in studentsWithPlans) {
                                        final plans =
                                            _studentPlans[student.id] ?? [];
                                        totalActivePlans += plans.length;

                                        for (var plan in plans) {
                                          totalRemainingMeals +=
                                              plan.remainingMeals;
                                          totalMeals += plan.totalMeals;

                                          // Track by meal type
                                          final mealType =
                                              plan.subscription.planType;
                                          final formattedType =
                                              mealType == 'breakfast'
                                                  ? 'Breakfast'
                                                  : 'Lunch';
                                          mealTypeCount[formattedType] =
                                              (mealTypeCount[formattedType] ??
                                                      0) +
                                                  plan.remainingMeals;
                                        }
                                      }

                                      // Calculate progress value
                                      final double progress = totalMeals > 0
                                          ? (totalMeals - totalRemainingMeals) /
                                              totalMeals
                                          : 0.0;

                                      // First student for navigation (we keep the navigation to individual student pages)
                                      final firstStudent =
                                          studentsWithPlans.first;

                                      return Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Active Plan Card
                                          Expanded(
                                            child: Card(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              elevation: 5,
                                              shadowColor: AppTheme.deepPurple
                                                  .withOpacity(0.1),
                                              color: Colors.grey[50],
                                              child: InkWell(
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          ActivePlanDetailsPage(
                                                        studentId:
                                                            firstStudent.id,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                child: Padding(
                                                  padding: EdgeInsets.all(
                                                      cardPadding),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        children: [
                                                          const Icon(
                                                            Icons
                                                                .calendar_month,
                                                            color: Colors.green,
                                                            size: 20,
                                                          ),
                                                          SizedBox(
                                                              width: isSmall
                                                                  ? 8
                                                                  : 15),
                                                          Flexible(
                                                            child: Text(
                                                              'Active Plan',
                                                              style: GoogleFonts
                                                                  .poppins(
                                                                fontSize:
                                                                    isSmall
                                                                        ? 10
                                                                        : 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: Colors
                                                                    .grey
                                                                    .shade700,
                                                              ),
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      Text(
                                                        '$totalActivePlans',
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontSize:
                                                              isSmall ? 18 : 24,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color:
                                                              AppTheme.textDark,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),

                                          SizedBox(width: cardSpacing),

                                          // Remaining Meals Card
                                          Expanded(
                                            child: Card(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              elevation: 5,
                                              shadowColor: AppTheme.orange
                                                  .withOpacity(0.1),
                                              color: Colors.grey[50],
                                              child: InkWell(
                                                onTap: () {
                                                  HapticFeedback.lightImpact();
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          RemainingMealDetailsPage(
                                                        studentId:
                                                            firstStudent.id,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                child: Padding(
                                                  padding: EdgeInsets.all(
                                                      cardPadding),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          const Icon(
                                                            Icons.restaurant,
                                                            color:
                                                                AppTheme.orange,
                                                            size: 20,
                                                          ),
                                                          SizedBox(
                                                              width: isSmall
                                                                  ? 8
                                                                  : 15),
                                                          Flexible(
                                                            child: Text(
                                                              'Remaining Meals',
                                                              style: GoogleFonts
                                                                  .poppins(
                                                                fontSize:
                                                                    isSmall
                                                                        ? 10
                                                                        : 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: Colors
                                                                    .grey
                                                                    .shade700,
                                                              ),
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      Text(
                                                        '$totalRemainingMeals',
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontSize:
                                                              isSmall ? 18 : 24,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color:
                                                              AppTheme.textDark,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),

                          // Footer Note - HIDDEN (now integrated inside About StartWell card)
                          // if (_showFooter)
                          //   _buildAnimatedSection(
                          //     margin: 0,
                          //     animation: _fadeAnimation,
                          //     slideAnimation: _slideAnimation,
                          //     delay: 0.5,
                          //     child: const FooterNote(),
                          //   ),

                          // About StartWell Section - moved below footer note
                          _buildAnimatedSection(
                            animation: _fadeAnimation,
                            slideAnimation: _slideAnimation,
                            delay:
                                0.6, // Increased delay since it's now after footer
                            margin: isSmall ? 15 : 18,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // About StartWell label - HIDDEN
                                // SectionTitle(
                                //   title: 'About StartWell',
                                //   actionText: null,
                                //   onActionPressed: null,
                                // ),
                                // SizedBox(height: isSmall ? 8 : 12),
                                Card(
                                  elevation: 5,
                                  shadowColor: Colors.grey.withOpacity(0.3),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.all(isSmall ? 14 : 18),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Footer section card at the top
                                        Container(
                                          width: double.infinity,
                                          padding:
                                              EdgeInsets.all(isSmall ? 16 : 20),
                                          margin: EdgeInsets.only(
                                              bottom: isSmall ? 16 : 20),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                                color: AppTheme.purple
                                                    .withOpacity(0.2)),
                                            image: const DecorationImage(
                                              image: AssetImage(
                                                  'assets/images/background_footer.png'),
                                              fit: BoxFit.cover,
                                              opacity:
                                                  0.8, // Make it slightly transparent so text remains readable
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppTheme.purple
                                                    .withOpacity(0.1),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            children: [
                                              // First line: Trusted by parents
                                              Text(
                                                'Trusted by parents',
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.poppins(
                                                  fontSize: isSmall ? 22 : 26,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      const Color(0xFF7F8285),
                                                ),
                                              ),
                                              SizedBox(height: isSmall ? 4 : 6),
                                              // Second line: Loved by kids!
                                              Text(
                                                'Loved by kids!',
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.poppins(
                                                  fontSize: isSmall ? 22 : 26,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      const Color(0xFF7F8285),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Row 1: First two features
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildDetailedFeatureItem(
                                                icon: Icons.book_online_rounded,
                                                title:
                                                    'Online Order Management',
                                                description:
                                                    'Book, swap, or cancel your orders online anytime until midnight. Our flexible system allows you to manage your meals conveniently.',
                                                color: AppTheme.purple,
                                                isSmall: isSmall,
                                              ),
                                            ),
                                            SizedBox(width: isSmall ? 12 : 16),
                                            Expanded(
                                              child: _buildDetailedFeatureItem(
                                                icon: Icons.eco_rounded,
                                                title: 'Natural Ingredients',
                                                description:
                                                    '100% natural and fresh ingredients sourced from trusted suppliers. We prioritize quality in every meal we prepare.',
                                                color: AppTheme.success,
                                                isSmall: isSmall,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: isSmall ? 12 : 16),

                                        // Row 2: Next two features
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildDetailedFeatureItem(
                                                icon: Icons.spa_rounded,
                                                title: 'Vegetarian Options',
                                                description:
                                                    'We offer 100% vegetarian meals with both Indian and International cuisines to cater to diverse tastes and preferences.',
                                                color: Colors.green,
                                                isSmall: isSmall,
                                              ),
                                            ),
                                            SizedBox(width: isSmall ? 12 : 16),
                                            Expanded(
                                              child: _buildDetailedFeatureItem(
                                                icon: Icons
                                                    .calendar_month_rounded,
                                                title:
                                                    'Flexible Subscription Plans',
                                                description:
                                                    'Choose from single-day, weekly, monthly, quarterly, and annual subscription options to fit your schedule and budget.',
                                                color: AppTheme.orange,
                                                isSmall: isSmall,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: isSmall ? 12 : 16),

                                        // Row 3: Last two features
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildDetailedFeatureItem(
                                                icon: Icons
                                                    .health_and_safety_rounded,
                                                title: 'Expert Preparation',
                                                description:
                                                    'Our meals are designed by professional nutritionists and prepared by skilled chefs with the care and attention of home cooking.',
                                                color: Colors.deepPurple,
                                                isSmall: isSmall,
                                              ),
                                            ),
                                            SizedBox(width: isSmall ? 12 : 16),
                                            Expanded(
                                              child: _buildDetailedFeatureItem(
                                                icon: Icons.verified_rounded,
                                                title: 'Certified Quality',
                                                description:
                                                    'FSSAI certified hygienic central kitchen facility ensures that all meals are prepared in a clean and safe environment.',
                                                color: Colors.blue,
                                                isSmall: isSmall,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (!_showFooter)
                            SizedBox(height: isSmall ? 80 : 120),
                        ],
                      ),
                    ),
                  ],
                ),
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
      elevation: 5,
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
            color: Colors.grey[50],
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
                            TextSpan(text: '$totalRemaining meals'),
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

  Widget _buildDetailedFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required bool isSmall,
  }) {
    return Container(
      height: isSmall ? 140 : 160, // Increased height for detailed content
      padding: EdgeInsets.all(isSmall ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and title row
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmall ? 6 : 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: isSmall ? 16 : 18,
                ),
              ),
              SizedBox(width: isSmall ? 8 : 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: isSmall ? 12 : 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmall ? 8 : 10),
          // Description
          Expanded(
            child: Text(
              description,
              style: GoogleFonts.poppins(
                fontSize: isSmall ? 10 : 11,
                height: 1.3,
                fontWeight: FontWeight.w400,
                color: AppTheme.textMedium,
                letterSpacing: 0.1,
              ),
              maxLines: 6, // Allow up to 6 lines for detailed description
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
