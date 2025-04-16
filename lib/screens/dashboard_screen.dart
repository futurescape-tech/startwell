import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:startwell/utils/routes.dart';
import 'package:startwell/widgets/home/home_widgets.dart';
import 'package:startwell/widgets/shimmer/home_shimmer.dart';
import 'package:startwell/widgets/shimmer/shimmer_widgets.dart';
import 'package:startwell/screens/main_screen.dart';
import 'package:startwell/screens/startwell_wallet_page.dart';
import 'package:startwell/screens/invite_startwell_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

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

  // Mock data
  final String _planType = 'Monthly';
  final int _remainingMeals = 12;
  final String _nextRenewalDate = 'Apr 15';
  final int _studentCount = 2;
  final List<MealInfo> _upcomingMeals = [
    MealInfo(
      name: 'Butter Chicken with Naan',
      deliveryTime: 'Today, 12:30 PM',
      type: MealType.nonVeg,
    ),
    MealInfo(
      name: 'Paneer Pulao with Raita',
      deliveryTime: 'Tomorrow, 12:30 PM',
      type: MealType.veg,
    ),
    MealInfo(
      name: 'Pasta with Garlic Bread',
      deliveryTime: 'Apr 06, 12:30 PM',
      type: MealType.veg,
    ),
  ];

  @override
  void initState() {
    super.initState();

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

    // Simulate loading for 1.5 seconds
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _animationController.forward();
      }
    });
  }

  void _onScroll() {
    // Show footer when close to bottom (within 200 pixels of max scroll extent)
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >
            (_scrollController.position.maxScrollExtent - 200) &&
        !_showFooter) {
      setState(() {
        _showFooter = true;
      });
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
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Home',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.white,
          ),
        ),
        backgroundColor: AppTheme.purple,
        elevation: 0,
        actions: [
          // Profile icon button
          IconButton(
            icon: const Icon(Icons.account_circle, color: AppTheme.white),
            onPressed: () {
              Navigator.pushNamed(context, Routes.profileSettings);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        controller: _scrollController,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Banner
              _buildAnimatedSection(
                animation: _fadeAnimation,
                slideAnimation: _slideAnimation,
                delay: 0.0,
                child: HomeBannerCard(
                  onExplorePressed: () => _navigateToTab(3), // Meal Plan tab
                ),
              ),
              const SizedBox(height: 30),

              // Subscription Overview Section
              _buildAnimatedSection(
                animation: _fadeAnimation,
                slideAnimation: _slideAnimation,
                delay: 0.1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionTitle(
                      title: 'Your Subscription',
                      actionText: 'See All',
                      onActionPressed: () =>
                          _navigateToTab(2), // Subscription tab
                    ),
                    const SizedBox(height: 15),
                    SubscriptionOverview(
                      planType: _planType,
                      remainingMeals: _remainingMeals,
                      nextRenewalDate: _nextRenewalDate,
                      studentCount: _studentCount,
                      onTap: () => _navigateToTab(2), // Subscription tab
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Upcoming Meals Section
              _buildAnimatedSection(
                animation: _fadeAnimation,
                slideAnimation: _slideAnimation,
                delay: 0.2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionTitle(
                      title: 'Upcoming Meals',
                      actionText: 'See All',
                      onActionPressed: () => _navigateToTab(3), // Meal Plan tab
                    ),
                    const SizedBox(height: 15),
                    UpcomingMealCardList(
                      meals: _upcomingMeals,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Quick Actions Section
              _buildAnimatedSection(
                animation: _fadeAnimation,
                slideAnimation: _slideAnimation,
                delay: 0.3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle(
                      title: 'Quick Actions',
                    ),
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
              const SizedBox(height: 40),

              // Footer Note - only show when scrolled to the bottom
              if (_showFooter)
                _buildAnimatedSection(
                  animation: _fadeAnimation,
                  slideAnimation: _slideAnimation,
                  delay: 0.4,
                  child: const FooterNote(),
                ),
              // Add height even if footer isn't showing yet to allow scrolling
              if (!_showFooter) const SizedBox(height: 100),
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
  }) {
    // Apply a delay based on the index for staggered animation
    final delayedAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(delay, 1.0, curve: Curves.easeOut),
    );

    return AnimatedBuilder(
      animation: delayedAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset:
                Offset(0, slideAnimation.value * (1 - delayedAnimation.value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
