import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/services/event_bus_service.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:startwell/widgets/subscription/upcoming_meals_tab.dart';
import 'package:startwell/widgets/subscription/cancelled_meals_tab.dart';
import 'package:startwell/utils/routes.dart';

// Global key for direct access to the MySubscriptionScreen state
final GlobalKey<_MySubscriptionScreenState> mySubscriptionScreenKey =
    GlobalKey<_MySubscriptionScreenState>();

class MySubscriptionScreen extends StatefulWidget {
  final String? selectedStudentId;
  final DateTime? startDate;
  final DateTime? endDate;
  final int defaultTabIndex;

  const MySubscriptionScreen({
    Key? key,
    this.selectedStudentId,
    this.startDate,
    this.endDate,
    this.defaultTabIndex = 0,
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

    log("MySubscriptionScreen initState - _currentlySelectedStudentId set to: ${_currentlySelectedStudentId ?? 'null'}");
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
        log("[cancelled_meal_data_flow] Switched to Cancelled Meals tab, refreshing data");
        // Delay slightly to allow the tab animation to complete
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_cancelledMealsTabKey.currentState != null) {
            _cancelledMealsTabKey.currentState!.refreshCancelledMeals();
            log("[cancelled_meal_data_flow] Triggered refresh on Cancelled Meals tab");
          } else {
            log("[cancelled_meal_data_flow] WARNING: Could not find Cancelled Meals tab state");
          }
        });
      }
    }
  }

  // Public method to change tabs programmatically
  void switchToTab(int index) {
    if (index >= 0 && index < _tabController.length) {
      log("[cancelled_meal_data_flow] Programmatically switching to tab: $index");
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Subscription',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.purple,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, color: AppTheme.white),
            onPressed: () {
              Navigator.pushNamed(context, Routes.profileSettings);
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48), // Slightly reduced height
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.purple
                  .withOpacity(0.9), // Slightly darker background for contrast
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true, // Allows tabs to be scrollable
              labelStyle: GoogleFonts.poppins(
                fontSize: 14, // Further reduced font size
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontSize: 14, // Further reduced font size
                fontWeight: FontWeight.w400,
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.7),

              // Enhanced indicator for better selected tab visibility
              indicatorColor: AppTheme
                  .yellow, // Use yellow from AppTheme for better contrast
              indicatorWeight: 3.0,
              indicatorSize: TabBarIndicatorSize.tab,

              // Add indicator padding for more distinct highlight
              indicatorPadding: const EdgeInsets.symmetric(horizontal: 12),

              labelPadding: const EdgeInsets.symmetric(
                  horizontal: 8), // Tighter label padding
              padding: const EdgeInsets.symmetric(
                  horizontal: 8), // Reduced outer padding

              // Use a more pronounced decoration for the indicator
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(6), // Smaller radius
                color: Colors.white
                    .withOpacity(0.15), // Lighter overlay for selection
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.yellow,
                    width: 3.0,
                  ),
                ),
              ),

              tabs: const [
                Tab(
                  height: 40, // Slightly taller for better touch targets
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fastfood, size: 18), // Smaller icon
                      SizedBox(
                          width: 6), // Slightly more spacing for readability
                      Text('Upcoming Meals'),
                    ],
                  ),
                ),
                Tab(
                  height: 40, // Slightly taller for better touch targets
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cancel_outlined, size: 18), // Smaller icon
                      SizedBox(
                          width: 6), // Slightly more spacing for readability
                      Text('Cancelled Meals'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
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
    );
  }
}
