import 'package:flutter/material.dart';
import 'package:startwell/models/meal_model.dart';
import 'package:startwell/screens/login_screen.dart';
import 'package:startwell/screens/signup_screen.dart';
import 'package:startwell/screens/dashboard_screen.dart';
import 'package:startwell/screens/forgot_password_screen.dart';
import 'package:startwell/screens/meal_details_screen.dart';
import 'package:startwell/screens/meal_plan_screen.dart';
import 'package:startwell/screens/main_screen.dart';
import 'package:startwell/screens/profile_settings_screen.dart';
import 'package:startwell/services/meal_selection_manager.dart';
import 'package:startwell/services/student_profile_service.dart';
import 'package:startwell/services/user_profile_service.dart';
import 'package:startwell/utils/routes.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:startwell/widgets/home/upcoming_meal_card_list.dart';
import 'dart:developer';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Project structure was refactored - consolidated theme directories and removed empty folders
  log("Starting StartWell app with refactored project structure");

  // Initialize the student profile service
  final studentProfileService = StudentProfileService();
  await studentProfileService.loadStudentProfiles();

  // Initialize the user profile service
  final userProfileService = UserProfileService();
  final userProfile = await userProfileService.getCurrentProfile();
  if (userProfile == null) {
    // Create a sample profile for demo purposes
    await userProfileService.createSampleProfile();
    log("Created sample user profile");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StartWell',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(),
      initialRoute: Routes.login,
      routes: {
        Routes.login: (context) => const LoginScreen(),
        Routes.signup: (context) => const SignupScreen(),
        Routes.dashboard: (context) => const DashboardScreen(),
        Routes.forgotPassword: (context) => const ForgotPasswordScreen(),
        Routes.mealPlan: (context) => const MealPlanScreen(),
        Routes.main: (context) => const MainScreen(),
        Routes.mealDetails: (context) => const MealDetailsScreen(),
        Routes.profileSettings: (context) => const ProfileSettingsScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/') {
          // Redirect root path to login screen instead of using tabIndex for MainScreen
          return MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          );
        }
        return null;
      },
    );
  }
}
