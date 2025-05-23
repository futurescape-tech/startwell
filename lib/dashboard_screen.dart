import 'package:flutter/material.dart';
import 'package:startwell/screens/main_screen.dart';
import 'package:startwell/utils/routes.dart';

class DashboardScreen extends StatefulWidget {
  // ... (existing code)
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // ... (existing code)

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
        // Meal Plan - explicitly specify breakfast as the initial tab
        Navigator.pushNamed(context, Routes.mealPlan,
            arguments: {'initialTab': 'breakfast'});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (existing code)
    return Scaffold(
      body: Center(
        child: Text('Dashboard'),
      ),
    );
  }
}
