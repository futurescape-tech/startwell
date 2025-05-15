import 'package:flutter/foundation.dart';
import 'package:startwell/models/student_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing the currently selected student across the app
class SelectedStudentService extends ChangeNotifier {
  static const String _selectedStudentIdKey = 'selected_student_id';

  // Singleton pattern
  static final SelectedStudentService _instance =
      SelectedStudentService._internal();

  factory SelectedStudentService() {
    return _instance;
  }

  SelectedStudentService._internal();

  String? _selectedStudentId;

  // Getter for the selected student ID
  String? get selectedStudentId => _selectedStudentId;

  // Set the selected student and persist to SharedPreferences
  Future<void> setSelectedStudent(String studentId) async {
    if (_selectedStudentId != studentId) {
      _selectedStudentId = studentId;

      // Persist the selection
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_selectedStudentIdKey, studentId);
      } catch (e) {
        print('Error saving selected student ID: $e');
      }

      // Notify listeners about the change
      notifyListeners();
    }
  }

  // Load the selected student from SharedPreferences
  Future<String?> loadSelectedStudent() async {
    if (_selectedStudentId != null) {
      return _selectedStudentId;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      _selectedStudentId = prefs.getString(_selectedStudentIdKey);
      return _selectedStudentId;
    } catch (e) {
      print('Error loading selected student ID: $e');
      return null;
    }
  }

  // Clear the selected student (e.g., on logout)
  Future<void> clearSelectedStudent() async {
    _selectedStudentId = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_selectedStudentIdKey);
    } catch (e) {
      print('Error clearing selected student ID: $e');
    }

    notifyListeners();
  }
}
