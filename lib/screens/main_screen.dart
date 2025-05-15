import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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

  // Helper method to build navigation items with custom styling
  BottomNavigationBarItem _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isSelected,
    required String semanticLabel,
  }) {
    return BottomNavigationBarItem(
      icon: TweenAnimationBuilder<double>(
        tween: Tween<double>(
            begin: isSelected ? 0.8 : 1.0, end: isSelected ? 1.0 : 1.0),
        curve: Curves.elasticOut,
        duration: const Duration(milliseconds: 500),
        builder: (context, scale, _) {
          return Transform.scale(
            scale: scale,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.purple.withOpacity(0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: isSelected
                    ? Border.all(
                        color: AppTheme.purple.withOpacity(0.3), width: 1.5)
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.purple.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                          spreadRadius: 0.5,
                        )
                      ]
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        AppTheme.purpleToDeepPurple.createShader(bounds),
                    child: Icon(
                      isSelected ? activeIcon : icon,
                      size: isSelected ? 30 : 26,
                      semanticLabel: semanticLabel,
                      color: Colors.white, // Base color for gradient
                      shadows: isSelected
                          ? [
                              Shadow(
                                  color: AppTheme.purple.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1))
                            ]
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        child: null,
      ),
      label: label,
      tooltip: semanticLabel,
    );
  }

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
      // Add haptic feedback for better tactile response
      HapticFeedback.selectionClick();

      setState(() {
        _selectedIndex = index;
      });

      // Animate to the new page with a custom curve for a bouncy effect
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  // Function to expose to children for navigating to specific tabs
  void switchToTab(int index) {
    _onItemTapped(index);
  }

  // Function to launch WhatsApp support
  void _launchWhatsAppSupport() async {
    final whatsappUrl = Uri.parse(
        "https://wa.me/919833607011?text=Hello, I need assistance with the StartWell app.");

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        // Show a snackbar or toast if WhatsApp is not installed
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Could not launch WhatsApp. Please make sure it is installed.",
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error launching WhatsApp: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error launching WhatsApp: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
      bottomNavigationBar: SafeArea(
        // Wrap with SafeArea to ensure proper spacing on different devices
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex > 3
                  ? 3
                  : (_selectedIndex == 0
                      ? 0
                      : _selectedIndex == 3
                          ? 1
                          : _selectedIndex == 2
                              ? 2
                              : 0),
              onTap: (index) {
                // Handle support tab separately
                if (index == 3) {
                  _launchWhatsAppSupport();
                  return;
                }

                // Map navigation bar index to page index
                int actualIndex;
                if (index == 0) {
                  actualIndex = 0; // Home
                } else if (index == 1) {
                  actualIndex = 3; // Order Meal
                } else if (index == 2) {
                  actualIndex = 2; // My Subscription
                } else {
                  actualIndex = 0; // Default to Home
                }

                _onItemTapped(actualIndex);
              },
              selectedItemColor: AppTheme.purple,
              unselectedItemColor: Colors.grey.shade600, // Higher contrast
              showUnselectedLabels: true,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white.withOpacity(0.9),
              elevation:
                  0, // Set to 0 as we're handling shadow in the Container
              selectedFontSize: 12,
              unselectedFontSize: 12,
              selectedLabelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
              ),
              items: [
                _buildNavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Home',
                  isSelected: _selectedIndex == 0,
                  semanticLabel: 'Home Screen',
                ),
                _buildNavItem(
                  icon: Icons.restaurant_menu_outlined,
                  activeIcon: Icons.restaurant_menu,
                  label: 'Order Meal',
                  isSelected: _selectedIndex == 3,
                  semanticLabel: 'Order Meal',
                ),
                _buildNavItem(
                  icon: Icons.subscriptions_outlined,
                  activeIcon: Icons.subscriptions,
                  label: 'My Subscription',
                  isSelected: _selectedIndex == 2,
                  semanticLabel: 'My Meal Subscriptions',
                ),
                _buildNavItem(
                  icon: FontAwesomeIcons.whatsapp,
                  activeIcon: FontAwesomeIcons.whatsapp,
                  label: 'Support',
                  isSelected: false, // Always false as it redirects to WhatsApp
                  semanticLabel: 'WhatsApp Support',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
