import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/models/user_profile.dart';
import 'package:startwell/screens/dashboard_screen.dart';
import 'package:startwell/screens/meal_plan_screen.dart';
import 'package:startwell/services/user_profile_service.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:startwell/utils/app_colors.dart';
import 'package:startwell/screens/manage_student_profile_screen.dart';
import 'package:startwell/screens/my_subscription_screen.dart';
import 'package:startwell/utils/routes.dart';

class MainScreen extends StatefulWidget {
  final int? initialTabIndex;

  const MainScreen({super.key, this.initialTabIndex});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  late int _selectedIndex;
  final PageController _pageController = PageController();
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex ?? 0;
    _loadUserProfile();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialTabIndex != null) {
        _pageController.jumpToPage(_selectedIndex);
      }
    });
  }

  Future<void> _loadUserProfile() async {
    try {
      final userProfileService = UserProfileService();
      _userProfile = await userProfileService.getCurrentProfile();

      // Create a sample profile if none exists (for demo purposes)
      if (_userProfile == null) {
        _userProfile = await userProfileService.createSampleProfile();
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
      // Animate to the new page
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Function to expose to children for navigating to specific tabs
  void switchToTab(int index) {
    _onItemTapped(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Disable swiping
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          DashboardScreen(userProfile: _userProfile),
          ManageStudentProfileScreen(
            isManagementMode: true,
            userProfile: _userProfile,
          ),
          MySubscriptionScreen(
            startDate: DateTime.now(),
            endDate: DateTime.now(),
            defaultTabIndex: widget.initialTabIndex == 2 ? 0 : 0,
            userProfile: _userProfile,
          ),
          MealPlanScreen(userProfile: _userProfile),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 8,
          selectedLabelStyle: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              activeIcon: Icon(Icons.home, size: 28),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person, size: 28),
              label: 'Student',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.subscriptions),
              activeIcon: Icon(Icons.subscriptions, size: 28),
              label: 'My Subscription',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu),
              activeIcon: Icon(Icons.restaurant_menu, size: 28),
              label: 'Meal Plan',
            ),
          ],
        ),
      ),
    );
  }
}
