import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:startwell/models/student_model.dart';

/// Service responsible for managing student profiles with persistence
class StudentProfileService {
  static const String _storageKey = 'student_profiles';

  // List of student profiles (in-memory cache)
  List<Student> _studentProfiles = [];

  // Flag to track if profiles have been loaded
  bool _isInitialized = false;

  // Singleton pattern
  static final StudentProfileService _instance =
      StudentProfileService._internal();

  factory StudentProfileService() {
    return _instance;
  }

  StudentProfileService._internal() {
    // Start loading profiles asynchronously when service is created
    _initializeProfiles();
  }

  // Initialize profiles from storage
  Future<void> _initializeProfiles() async {
    if (!_isInitialized) {
      await loadStudentProfiles();
      _isInitialized = true;
    }
  }

  // Get all student profiles
  Future<List<Student>> getStudentProfiles() async {
    await _ensureInitialized();
    return _studentProfiles;
  }

  // Check if profiles have been loaded
  bool get isInitialized => _isInitialized;

  // Load student profiles from SharedPreferences
  Future<List<Student>> loadStudentProfiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? profilesJson = prefs.getString(_storageKey);

      if (profilesJson != null && profilesJson.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(profilesJson);
        _studentProfiles = Student.studentListFromJson(jsonList);
      }

      // Ensure no duplicates by ID
      final Map<String, Student> uniqueProfiles = {};
      for (var student in _studentProfiles) {
        uniqueProfiles[student.id] = student;
      }
      _studentProfiles = uniqueProfiles.values.toList();

      // Mark as initialized after loading
      _isInitialized = true;

      return _studentProfiles;
    } catch (e) {
      print('Error loading student profiles: $e');
      return [];
    }
  }

  // Save student profiles to SharedPreferences
  Future<bool> saveStudentProfiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profilesJson =
          jsonEncode(Student.studentListToJson(_studentProfiles));

      await prefs.setString(_storageKey, profilesJson);
      return true;
    } catch (e) {
      print('Error saving student profiles: $e');
      return false;
    }
  }

  // Add a new student profile
  Future<bool> addStudentProfile(Student student) async {
    // Check if a student with the same ID already exists
    if (_studentProfiles.any((s) => s.id == student.id)) {
      // If it exists, just update it
      return await updateStudentProfile(student);
    }

    // Add the new student
    _studentProfiles.add(student);
    return await saveStudentProfiles();
  }

  // Update an existing student profile
  Future<bool> updateStudentProfile(Student updatedStudent) async {
    final index = _studentProfiles.indexWhere((s) => s.id == updatedStudent.id);

    if (index >= 0) {
      // Get the existing student to check if we need to preserve meal plan info
      final existingStudent = _studentProfiles[index];

      // If the updated student doesn't have meal plan info but the existing one does,
      // preserve the meal plan information using copyWith
      if ((!updatedStudent.hasActiveBreakfast &&
              existingStudent.hasActiveBreakfast) ||
          (!updatedStudent.hasActiveLunch && existingStudent.hasActiveLunch)) {
        updatedStudent = updatedStudent.copyWith(
          hasActiveBreakfast: existingStudent.hasActiveBreakfast,
          hasActiveLunch: existingStudent.hasActiveLunch,
          breakfastPlanStartDate: existingStudent.breakfastPlanStartDate,
          lunchPlanStartDate: existingStudent.lunchPlanStartDate,
          breakfastPlanEndDate: existingStudent.breakfastPlanEndDate,
          lunchPlanEndDate: existingStudent.lunchPlanEndDate,
          breakfastPreference: existingStudent.breakfastPreference,
          lunchPreference: existingStudent.lunchPreference,
          breakfastSelectedWeekdays: existingStudent.breakfastSelectedWeekdays,
          lunchSelectedWeekdays: existingStudent.lunchSelectedWeekdays,
          // Keep the deprecated selectedWeekdays field for backward compatibility
          selectedWeekdays: existingStudent.selectedWeekdays,
        );
      }

      _studentProfiles[index] = updatedStudent;
      return await saveStudentProfiles();
    }

    return false;
  }

  // Delete a student profile
  Future<bool> deleteStudentProfile(String studentId) async {
    _studentProfiles.removeWhere((s) => s.id == studentId);
    return await saveStudentProfiles();
  }

  // Clear all student profiles (e.g., on logout)
  Future<bool> clearStudentProfiles() async {
    _studentProfiles.clear();
    return await saveStudentProfiles();
  }

  // Get a student profile by ID
  Student? getStudentById(String id) {
    try {
      return _studentProfiles.firstWhere((student) => student.id == id);
    } catch (e) {
      return null;
    }
  }

  // Assign a breakfast meal plan to a student
  Future<bool> assignBreakfastPlan(String studentId, DateTime endDate) async {
    final index = _studentProfiles.indexWhere((s) => s.id == studentId);
    if (index >= 0) {
      final updatedStudent = _studentProfiles[index].copyWith(
        hasActiveBreakfast: true,
        breakfastPlanEndDate: endDate,
      );
      _studentProfiles[index] = updatedStudent;
      return await saveStudentProfiles();
    }
    return false;
  }

  // Assign a lunch meal plan to a student
  Future<bool> assignLunchPlan(String studentId, DateTime endDate) async {
    final index = _studentProfiles.indexWhere((s) => s.id == studentId);
    if (index >= 0) {
      final updatedStudent = _studentProfiles[index].copyWith(
        hasActiveLunch: true,
        lunchPlanEndDate: endDate,
      );
      _studentProfiles[index] = updatedStudent;
      return await saveStudentProfiles();
    }
    return false;
  }

  // Assign meal plan to a student
  Future<bool> assignMealPlan(
      DateTime startDate, String studentId, String planType, DateTime endDate,
      {String? mealPreference, List<int>? selectedWeekdays}) async {
    await _ensureInitialized();

    final int index =
        _studentProfiles.indexWhere((profile) => profile.id == studentId);
    if (index >= 0) {
      // Get existing student to preserve plan info
      final existingStudent = _studentProfiles[index];

      // Update student with meal plan info, preserving existing plans
      _studentProfiles[index] = _studentProfiles[index].copyWith(
        mealPlanType: planType,
        mealPlanEndDate: endDate,
        // Set the specific plan type without affecting the other plan
        hasActiveBreakfast:
            planType == 'breakfast' ? true : existingStudent.hasActiveBreakfast,
        hasActiveLunch: (planType == 'lunch' || planType == 'express')
            ? true
            : existingStudent.hasActiveLunch,
        // Store start dates based on plan type
        breakfastPlanStartDate: planType == 'breakfast'
            ? startDate
            : existingStudent.breakfastPlanStartDate,
        lunchPlanStartDate: (planType == 'lunch' || planType == 'express')
            ? startDate
            : existingStudent.lunchPlanStartDate,
        // Store end dates based on plan type
        breakfastPlanEndDate: planType == 'breakfast'
            ? endDate
            : existingStudent.breakfastPlanEndDate,
        lunchPlanEndDate: (planType == 'lunch' || planType == 'express')
            ? endDate
            : existingStudent.lunchPlanEndDate,
        // Set meal preferences based on plan type, preserving existing preferences
        breakfastPreference: planType == 'breakfast'
            ? mealPreference
            : existingStudent.breakfastPreference,
        lunchPreference: (planType == 'lunch' || planType == 'express')
            ? mealPreference
            : existingStudent.lunchPreference,
        // Store selected weekdays in meal-specific fields
        breakfastSelectedWeekdays: planType == 'breakfast'
            ? selectedWeekdays
            : existingStudent.breakfastSelectedWeekdays,
        lunchSelectedWeekdays: (planType == 'lunch' || planType == 'express')
            ? selectedWeekdays
            : existingStudent.lunchSelectedWeekdays,
        // Don't update the deprecated selectedWeekdays field when adding a new plan
        // This prevents conflicts between breakfast and lunch weekday selections
        selectedWeekdays: existingStudent.selectedWeekdays,
      );

      await _saveStudentProfiles();
      return true;
    }
    return false;
  }

  // Cancel a meal plan
  Future<bool> cancelMealPlan(String studentId, String planType) async {
    final index = _studentProfiles.indexWhere((s) => s.id == studentId);
    if (index >= 0) {
      var updatedStudent = _studentProfiles[index];

      if (planType == 'breakfast') {
        updatedStudent = updatedStudent.copyWith(
          hasActiveBreakfast: false,
          breakfastPlanStartDate: null,
          breakfastPlanEndDate: null,
        );
      } else if (planType == 'lunch' || planType == 'express') {
        updatedStudent = updatedStudent.copyWith(
          hasActiveLunch: false,
          lunchPlanStartDate: null,
          lunchPlanEndDate: null,
        );
      } else if (planType == 'all') {
        updatedStudent = updatedStudent.copyWith(
          hasActiveBreakfast: false,
          hasActiveLunch: false,
          breakfastPlanStartDate: null,
          lunchPlanStartDate: null,
          breakfastPlanEndDate: null,
          lunchPlanEndDate: null,
        );
      }

      _studentProfiles[index] = updatedStudent;
      return await saveStudentProfiles();
    }
    return false;
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _initializeProfiles();
    }
  }

  Future<void> _saveStudentProfiles() async {
    await saveStudentProfiles();
  }

  // Debug method to verify meal plan weekday selections
  void debugVerifyMealPlanWeekdays(String studentId) {
    final student = getStudentById(studentId);
    if (student != null) {
      print('===== MEAL PLAN WEEKDAY DEBUG INFO =====');
      print('Student: ${student.name} (ID: ${student.id})');
      print('Has Breakfast Plan: ${student.hasActiveBreakfast}');
      print('Has Lunch Plan: ${student.hasActiveLunch}');

      print(
          'Breakfast Selected Weekdays: ${student.breakfastSelectedWeekdays}');
      print('Lunch Selected Weekdays: ${student.lunchSelectedWeekdays}');
      print(
          '(Deprecated) Generic Selected Weekdays: ${student.selectedWeekdays}');

      if (student.hasActiveBreakfast &&
          student.hasActiveLunch &&
          student.breakfastSelectedWeekdays != null &&
          student.lunchSelectedWeekdays != null) {
        // Check if the weekdays are actually different
        bool areWeekdaysDifferent = false;
        if (student.breakfastSelectedWeekdays!.length !=
            student.lunchSelectedWeekdays!.length) {
          areWeekdaysDifferent = true;
        } else {
          // Compare contents regardless of order
          final breakfastSet = Set.from(student.breakfastSelectedWeekdays!);
          final lunchSet = Set.from(student.lunchSelectedWeekdays!);
          areWeekdaysDifferent = !setEquals(breakfastSet, lunchSet);
        }

        print(
            'Breakfast and Lunch have different weekday selections: $areWeekdaysDifferent');
      }
      print('========================================');
    }
  }

  // Helper method to compare sets
  bool setEquals<T>(Set<T> a, Set<T> b) {
    return a.length == b.length && a.containsAll(b);
  }
}
