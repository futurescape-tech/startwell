import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:startwell/widgets/subscription/upcoming_meals_tab.dart';
import 'package:startwell/widgets/subscription/delivered_meals_tab.dart';
import 'package:startwell/widgets/subscription/cancelled_meals_tab.dart';

class MySubscriptionScreen extends StatefulWidget {
  final int defaultTabIndex;
  final String? selectedStudentId;

  const MySubscriptionScreen({
    Key? key,
    this.defaultTabIndex = 0,
    this.selectedStudentId,
  }) : super(key: key);

  @override
  State<MySubscriptionScreen> createState() => _MySubscriptionScreenState();
}

class _MySubscriptionScreenState extends State<MySubscriptionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 3, vsync: this, initialIndex: widget.defaultTabIndex);
  }

  @override
  void dispose() {
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
          const DeliveredMealsTab(),
          const CancelledMealsTab(),
        ],
      ),
    );
  }
}
