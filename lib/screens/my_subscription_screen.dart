import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/services/event_bus_service.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:startwell/widgets/subscription/upcoming_meals_tab.dart';
import 'package:startwell/widgets/subscription/delivered_meals_tab.dart';
import 'package:startwell/widgets/subscription/cancelled_meals_tab.dart';

// Global key for direct access to the MySubscriptionScreen state
final GlobalKey<_MySubscriptionScreenState> mySubscriptionScreenKey =
    GlobalKey<_MySubscriptionScreenState>();

class MySubscriptionScreen extends StatefulWidget {
  final int defaultTabIndex;
  final String? selectedStudentId;
  final DateTime? startDate;
  final DateTime? endDate;

  const MySubscriptionScreen({
    Key? key,
    this.defaultTabIndex = 0,
    this.selectedStudentId,
    this.startDate,
    this.endDate,
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
  late TabController _tabController;
  StreamSubscription? _mealCancelledSubscription;

  // Reference to the CancelledMealsTab
  final GlobalKey<CancelledMealsTabState> _cancelledMealsTabKey =
      GlobalKey<CancelledMealsTabState>();

  // Getter to expose the TabController
  TabController get tabController => _tabController;

  // Method to navigate to the cancelled meals tab
  void navigateToCancelledMealsTab() {
    _tabController.animateTo(2); // Index 2 is the Cancelled Meals tab
    log("Navigating to Cancelled Meals tab");

    // Try to refresh the cancelled meals tab data
    if (_cancelledMealsTabKey.currentState != null) {
      _cancelledMealsTabKey.currentState!.loadCancelledMeals();
      log("Triggered refresh of CancelledMealsTab via key");
    }
  }

  @override
  void initState() {
    super.initState();
    log("MySubscriptionScreen initState");
    log("MySubscriptionScreen startDate: ${widget.startDate}");
    log("MySubscriptionScreen endDate: ${widget.endDate}");
    log("MySubscriptionScreen defaultTabIndex: ${widget.defaultTabIndex}");

    // Make sure we initialize with the specified tab index
    _tabController = TabController(
        length: 3, vsync: this, initialIndex: widget.defaultTabIndex);

    // Ensure any late initialization correctly sets the current tab
    if (widget.defaultTabIndex != 0) {
      // Use a post-frame callback to ensure the tab transition happens after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _tabController.animateTo(widget.defaultTabIndex);
          log("Animated to tab index ${widget.defaultTabIndex} in post-frame callback");
        }
      });
    }

    // Add listener to refresh data when switching to Cancelled Meals tab
    _tabController.addListener(_handleTabChange);

    // Listen for meal cancellation events
    _mealCancelledSubscription = eventBus.onMealCancelled.listen((event) {
      _handleMealCancelled(event);
    });
  }

  // Handle meal cancellation events
  void _handleMealCancelled(MealCancelledEvent event) {
    log("MySubscriptionScreen received meal cancelled event");
    if (event.shouldNavigateToTab) {
      // Use Future.delayed to ensure this runs after the current build phase
      Future.delayed(Duration.zero, () {
        navigateToCancelledMealsTab();
      });
    }
  }

  // Handle tab changes - refresh data when switching to Cancelled Meals tab
  void _handleTabChange() {
    // Only trigger when the tab selection is fully changed (not during animation)
    if (!_tabController.indexIsChanging) {
      log("Tab changed to index: ${_tabController.index}");

      // Index 2 is the Cancelled Meals tab
      if (_tabController.index == 2) {
        // Refresh cancelled meals data
        if (_cancelledMealsTabKey.currentState != null) {
          _cancelledMealsTabKey.currentState!.loadCancelledMeals();
          log("Refreshed CancelledMealsTab data via key");
        } else {
          log("CancelledMealsTab key state is null");
        }
      }
    }
  }

  @override
  void dispose() {
    _mealCancelledSubscription?.cancel();
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: 'Upcoming Meals'),
            Tab(text: 'Delivered Meals'),
            Tab(text: 'Cancelled Meals'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          UpcomingMealsTab(selectedStudentId: widget.selectedStudentId),
          DeliveredMealsTab(studentId: widget.selectedStudentId),
          CancelledMealsTab(
              key: _cancelledMealsTabKey, studentId: widget.selectedStudentId),
        ],
      ),
    );
  }
}
