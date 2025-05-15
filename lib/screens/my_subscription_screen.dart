import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/models/user_profile.dart';
import 'package:startwell/services/event_bus_service.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:startwell/widgets/profile_avatar.dart';
import 'package:startwell/widgets/subscription/upcoming_meals_tab.dart';
import 'package:startwell/widgets/subscription/cancelled_meals_tab.dart';
import 'package:startwell/utils/routes.dart';
import 'package:startwell/widgets/common/gradient_app_bar.dart';

// Global key for direct access to the MySubscriptionScreen state
final GlobalKey<_MySubscriptionScreenState> mySubscriptionScreenKey =
    GlobalKey<_MySubscriptionScreenState>();

class MySubscriptionScreen extends StatefulWidget {
  final String? selectedStudentId;
  final DateTime? startDate;
  final DateTime? endDate;
  final int defaultTabIndex;
  final UserProfile? userProfile;

  const MySubscriptionScreen({
    Key? key,
    this.selectedStudentId,
    this.startDate,
    this.endDate,
    this.defaultTabIndex = 0,
    this.userProfile,
  }) : super(key: key);

  @override
  State<MySubscriptionScreen> createState() => _MySubscriptionScreenState();

  // Static method to find the nearest MySubscriptionScreen state
  static _MySubscriptionScreenState? of(BuildContext context) {
    return context.findAncestorStateOfType<_MySubscriptionScreenState>();
  }
}

class _MySubscriptionScreenState extends State<MySubscriptionScreen>
    with SingleTickerProviderStateMixin {
  // State variable to hold the currently relevant student ID
  String? _currentlySelectedStudentId;
  late TabController _tabController;
  // Add key for CancelledMealsTab with correct type
  final GlobalKey<CancelledMealsTabState> _cancelledMealsTabKey =
      GlobalKey<CancelledMealsTabState>();

  @override
  void initState() {
    super.initState();
    // Initialize the state variable with the widget's initial value
    _currentlySelectedStudentId = widget.selectedStudentId;

    // Initialize tab controller
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.defaultTabIndex,
    );

    // Add listener to handle tab changes
    _tabController.addListener(_handleTabChange);

    log(
      "MySubscriptionScreen initState - _currentlySelectedStudentId set to: ${_currentlySelectedStudentId ?? 'null'}",
    );
    log("MySubscriptionScreen startDate: ${widget.startDate}");
    log("MySubscriptionScreen endDate: ${widget.endDate}");
    log("MySubscriptionScreen defaultTabIndex: ${widget.defaultTabIndex}");
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  // Handle tab changes
  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      log("[cancelled_meal_data_flow] Tab changed to: ${_tabController.index}");

      // If switched to Cancelled Meals tab (index 1), refresh the data
      if (_tabController.index == 1) {
        log(
          "[cancelled_meal_data_flow] Switched to Cancelled Meals tab, refreshing data",
        );
        // Delay slightly to allow the tab animation to complete
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_cancelledMealsTabKey.currentState != null) {
            _cancelledMealsTabKey.currentState!.refreshCancelledMeals();
            log(
              "[cancelled_meal_data_flow] Triggered refresh on Cancelled Meals tab",
            );
          } else {
            log(
              "[cancelled_meal_data_flow] WARNING: Could not find Cancelled Meals tab state",
            );
          }
        });
      }
    }
  }

  // Public method to change tabs programmatically
  void switchToTab(int index) {
    if (index >= 0 && index < _tabController.length) {
      log(
        "[cancelled_meal_data_flow] Programmatically switching to tab: $index",
      );
      _tabController.animateTo(index);

      // Force refresh immediately when switching to Cancelled tab
      if (index == 1 && _cancelledMealsTabKey.currentState != null) {
        // Delay to allow animation to complete before refresh
        Future.delayed(const Duration(milliseconds: 500), () {
          log("[cancelled_meal_data_flow] Forced refresh after tab switch");
          _cancelledMealsTabKey.currentState!.refreshCancelledMeals();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context)
            .pushNamedAndRemoveUntil(Routes.main, (route) => false);
        return false;
      },
      child: Scaffold(
        backgroundColor: AppTheme.white,
        appBar: GradientAppBar(
          titleText: 'My Subscription',
          customGradient: AppTheme.purpleToDeepPurple,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
            onPressed: () => Navigator.of(context)
                .pushNamedAndRemoveUntil(Routes.main, (route) => false),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: widget.userProfile != null
                  ? ProfileAvatar(
                      userProfile: widget.userProfile,
                      radius: 18,
                      onAvatarTap: () {
                        Navigator.pushNamed(context, Routes.profileSettings);
                      },
                    )
                  : Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppTheme.purpleToDeepPurple,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.deepPurple.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.account_circle,
                          color: AppTheme.white,
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, Routes.profileSettings);
                        },
                      ),
                    ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.purple,
                unselectedLabelColor: AppTheme.textMedium,
                indicatorColor: AppTheme.purple,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.restaurant,
                            size: 18,
                            color: AppTheme.purple,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Upcoming Meals',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.cancel_outlined,
                            size: 18,
                            color: AppTheme.purple,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Cancelled Meals',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
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
        body: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: AppTheme.deepPurple.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: TabBarView(
            controller: _tabController,
            children: [
              // Upcoming Meals Tab
              UpcomingMealsTab(
                selectedStudentId: _currentlySelectedStudentId,
                startDate: widget.startDate,
                endDate: widget.endDate,
              ),

              // Cancelled Meals Tab
              CancelledMealsTab(
                key: _cancelledMealsTabKey,
                studentId: _currentlySelectedStudentId,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
