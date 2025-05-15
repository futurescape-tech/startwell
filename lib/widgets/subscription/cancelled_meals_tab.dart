import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:startwell/models/cancelled_meal.dart';
import 'package:startwell/services/subscription_service.dart';
import 'package:startwell/services/student_profile_service.dart';
import 'package:startwell/models/student_model.dart';
import 'package:startwell/utils/meal_constants.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CancelledMealsTab extends StatefulWidget {
  final String? studentId;

  const CancelledMealsTab({Key? key, this.studentId}) : super(key: key);

  @override
  State<CancelledMealsTab> createState() => CancelledMealsTabState();
}

// Make the state class public so it can be accessed with a key
class CancelledMealsTabState extends State<CancelledMealsTab> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final StudentProfileService _studentProfileService = StudentProfileService();
  List<CancelledMeal> _cancelledMeals = [];
  bool _isLoading = true;
  String? _errorMessage;
  List<Student> _students = [];
  String? _selectedStudentId;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _selectedStudentId = widget.studentId;
    log('[cancelled_meal_data_flow] CancelledMealsTab initState with studentId: ${widget.studentId}');
    _loadStudents();
  }

  @override
  void didUpdateWidget(CancelledMealsTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If student ID changed, reload data
    if (widget.studentId != oldWidget.studentId) {
      log('[cancelled_meal_data_flow] Student ID changed: ${oldWidget.studentId} -> ${widget.studentId}');
      _selectedStudentId = widget.studentId;
      _loadCancelledMeals();
    }
  }

  // Public method to force refresh the cancelled meals data
  void refreshCancelledMeals() {
    log('[cancelled_meal_data_flow] Manual refresh requested for student: $_selectedStudentId');

    // Set a longer delay to ensure the cancellation has been fully processed
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          // Clear any previous error messages
          _errorMessage = null;
          // Show loading indicator while refreshing
          _isLoading = true;
          // Clear existing data to ensure a fresh reload
          _cancelledMeals = [];
        });

        // Force reload the data with longer delay to ensure service has updated
        Future.delayed(const Duration(milliseconds: 300), () {
          _loadCancelledMeals(forceRefresh: true);
          log('[cancelled_meal_data_flow] Refresh triggered for cancelled meals with forced refresh');
        });
      }
    });
  }

  Future<void> _loadStudents() async {
    try {
      log('[cancelled_meal_data_flow] Loading students for cancelled meals tab');
      _students = await _studentProfileService.getStudentProfiles();

      if (_students.isNotEmpty) {
        if (_selectedStudentId == null ||
            !_students.any((s) => s.id == _selectedStudentId)) {
          _selectedStudentId = _students.first.id;
          log('[cancelled_meal_data_flow] No valid student selected, defaulting to first: $_selectedStudentId (${_students.first.name})');
        } else {
          log('[cancelled_meal_data_flow] Using selected student: $_selectedStudentId');
        }
      } else {
        log('[cancelled_meal_data_flow] No students available');
      }

      setState(() {
        _initialized = true;
      });

      // Now load the cancelled meals
      _loadCancelledMeals(forceRefresh: true);
    } catch (e) {
      log('[cancelled_meal_data_flow] Error loading students: $e');
      setState(() {
        _errorMessage = 'Failed to load student profiles';
        _isLoading = false;
        _initialized = true;
      });
    }
  }

  Future<void> _loadCancelledMeals({bool forceRefresh = false}) async {
    if (_selectedStudentId == null) {
      log('[cancelled_meal_data_flow] No student ID available, skipping cancelled meal load');
      setState(() {
        _isLoading = false;
        _errorMessage = null;
        _cancelledMeals =
            []; // Clear any existing meals when no student is selected
      });
      return;
    }

    // Skip if already loading, unless force refresh is requested
    if (_isLoading && !forceRefresh) {
      log('[cancelled_meal_data_flow] Already loading data, skipping');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      log('[cancelled_meal_data_flow] Loading cancelled meals for student: $_selectedStudentId');

      // Force a slight delay to ensure any recent cancellations are processed
      await Future.delayed(const Duration(milliseconds: 100));

      // Get cancelled meals from service
      final servicesMeals =
          await _subscriptionService.getCancelledMeals(_selectedStudentId);

      // Also check SharedPreferences for locally stored cancellations
      final List<CancelledMeal> localCancellations =
          await _getLocalCancelledMeals(_selectedStudentId);

      // Combine both sources, avoiding duplicates
      final combinedMeals = [...servicesMeals];

      // Add local cancellations that don't exist in service meals
      for (final localMeal in localCancellations) {
        bool exists = servicesMeals.any((meal) =>
            meal.subscriptionId == localMeal.subscriptionId &&
            _isSameDay(meal.cancellationDate, localMeal.cancellationDate));

        if (!exists) {
          combinedMeals.add(localMeal);
        }
      }

      // Sort by timestamp, newest first
      combinedMeals.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      log('[cancelled_meal_data_flow] Loaded ${combinedMeals.length} cancelled meals (${servicesMeals.length} from service, ${localCancellations.length} local)');

      if (mounted) {
        setState(() {
          _cancelledMeals = combinedMeals;
          _isLoading = false;
        });

        // Log details about loaded meals for debugging
        if (combinedMeals.isEmpty) {
          log('[cancelled_meal_data_flow] No cancelled meals found for student $_selectedStudentId');
        } else {
          log('[cancelled_meal_data_flow] === CANCELLED MEALS DETAILS ===');
          for (var meal in combinedMeals) {
            log('[cancelled_meal_data_flow] Meal: ${meal.mealName}');
            log('[cancelled_meal_data_flow] Date: ${DateFormat('yyyy-MM-dd').format(meal.cancellationDate)}');
            log('[cancelled_meal_data_flow] Student: ${meal.studentName} (${meal.studentId})');
            log('[cancelled_meal_data_flow] Cancelled at: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(meal.timestamp)}');
            log('[cancelled_meal_data_flow] Reason: ${meal.reason ?? "Not specified"}');
            log('[cancelled_meal_data_flow] Plan type: ${meal.planType}, displayed as: ${meal.planType == 'breakfast' ? 'Breakfast' : 'Lunch'}');
            log('[cancelled_meal_data_flow] --------------------------');
          }
          log('[cancelled_meal_data_flow] === END OF CANCELLED MEALS DETAILS ===');
        }
      }
    } catch (e) {
      log('[cancelled_meal_data_flow] Error loading cancelled meals: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load cancelled meals. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  // Helper method to get cancelled meals from SharedPreferences
  Future<List<CancelledMeal>> _getLocalCancelledMeals(String? studentId) async {
    if (studentId == null) return [];

    try {
      final prefs = await SharedPreferences.getInstance();
      final List<CancelledMeal> localMeals = [];

      // Get all keys that might contain cancelled meals for this student
      final allKeys = prefs
          .getKeys()
          .where((key) =>
              key.startsWith('cancelledMeal_$studentId') ||
              key.contains('_${studentId}_'))
          .toList();

      log('[cancelled_meal_data_flow] Found ${allKeys.length} potential local cancelled meal keys');

      for (final key in allKeys) {
        // Skip boolean flags
        if (prefs.getBool(key) != null) continue;

        // Try to parse the JSON data
        final jsonData = prefs.getString(key);
        if (jsonData != null && jsonData.isNotEmpty) {
          try {
            final mealData = jsonDecode(jsonData);

            // Convert date strings to DateTime objects
            if (mealData['date'] is String) {
              mealData['date'] = DateTime.parse(mealData['date']);
            }
            if (mealData['cancelledAt'] is String) {
              mealData['cancelledAt'] = DateTime.parse(mealData['cancelledAt']);
            }

            // Create CancelledMeal object
            final cancelledMeal = CancelledMeal.fromMap(mealData);
            localMeals.add(cancelledMeal);
            log('[cancelled_meal_data_flow] Added local cancelled meal: ${cancelledMeal.mealName} on ${DateFormat('yyyy-MM-dd').format(cancelledMeal.cancellationDate)}');
            log('[cancelled_meal_data_flow] Meal plan type: ${cancelledMeal.planType}, displayed as: ${cancelledMeal.planType == 'breakfast' ? 'Breakfast' : 'Lunch'}');
          } catch (e) {
            log('[cancelled_meal_data_flow] Error parsing local cancelled meal: $e');
          }
        }
      }

      return localMeals;
    } catch (e) {
      log('[cancelled_meal_data_flow] Error getting local cancelled meals: $e');
      return [];
    }
  }

  // Helper to check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  @override
  Widget build(BuildContext context) {
    // If not initialized yet, show a loading indicator
    if (!_initialized) {
      return Center(
        child: CircularProgressIndicator(
          color: AppTheme.purple,
        ),
      );
    }

    return Column(
      children: [
        _buildScreenHeader(),
        _buildStudentSelector(),
        Expanded(
          child: _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: AppTheme.purple,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading cancelled meals...',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppTheme.textMedium,
                        ),
                      ),
                    ],
                  ),
                )
              : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.error.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.error_outline,
                                size: 40,
                                color: AppTheme.error,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _errorMessage!,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textDark,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () =>
                                  _loadCancelledMeals(forceRefresh: true),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Try Again'),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: AppTheme.purple,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _cancelledMeals.isEmpty
                      ? _buildEmptyState()
                      : _buildCancelledMealsList(),
        ),
      ],
    );
  }

  Widget _buildScreenHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.cancel_outlined,
              color: AppTheme.error,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            "Cancelled Meals",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentSelector() {
    if (_students.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppTheme.softShadow,
          border: Border.all(
            color: AppTheme.deepPurple.withOpacity(0.1),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedStudentId,
            isExpanded: true,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppTheme.purple,
            ),
            dropdownColor: AppTheme.white,
            items: _students.map((student) {
              return DropdownMenuItem(
                value: student.id,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.purple.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person,
                        size: 14,
                        color: AppTheme.purple,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      student.name,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null && newValue != _selectedStudentId) {
                setState(() {
                  _selectedStudentId = newValue;
                  _isLoading = true;
                  _cancelledMeals = [];
                });
                _loadCancelledMeals(forceRefresh: true);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.purple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 64,
                color: AppTheme.purple,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No cancelled meals found',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Any cancelled meals will appear here',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textMedium,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelledMealsList() {
    // Sort by cancellation date, newest first
    final sortedMeals = List<CancelledMeal>.from(_cancelledMeals)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedMeals.length,
      itemBuilder: (context, index) {
        final meal = sortedMeals[index];
        final student = _students.firstWhere(
          (s) => s.id == meal.studentId,
          orElse: () => Student(
            id: '',
            name: 'Unknown Student',
            schoolName: 'Unknown School',
            className: 'Unknown Class',
            division: 'Unknown Division',
            floor: 'Unknown Floor',
            allergies: 'None',
            grade: 'Unknown Grade',
            section: 'Unknown Section',
            profileImageUrl: '',
          ),
        );

        // Add a date header if this is a new date or the first item
        final bool showDateHeader = index == 0 ||
            (index > 0 &&
                !_isSameDay(sortedMeals[index - 1].cancellationDate,
                    meal.cancellationDate));

        // Determine the colors based on meal type
        final bool isBreakfast = meal.planType == 'breakfast';
        final Color primaryColor = isBreakfast
            ? const Color(0xFFFF9800) // Orange for breakfast
            : const Color(0xFF4CAF50); // Green for lunch
        final Color bgColor = primaryColor.withOpacity(0.1);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header if needed
            if (showDateHeader) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.purple.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.purple.withOpacity(0.2), width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: AppTheme.purple,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('EEEE, MMMM d, yyyy')
                            .format(meal.cancellationDate),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            Card(
              elevation: 4,
              shadowColor: AppTheme.error.withOpacity(0.2),
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                  border: Border.all(
                    color: meal.planType == 'breakfast'
                        ? MealConstants.breakfastBorderColor.withOpacity(0.8)
                        : AppTheme.error.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with meal type and student name
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: meal.planType == 'breakfast'
                            ? MealConstants.breakfastBgColor.withOpacity(0.2)
                            : AppTheme.error.withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(15),
                          topRight: Radius.circular(15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.error.withOpacity(0.15),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              meal.planType == 'breakfast'
                                  ? MealConstants.breakfastIcon
                                  : Icons.flatware,
                              color: meal.planType == 'breakfast'
                                  ? MealConstants.breakfastIconColor
                                  : AppTheme.error,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  student.name,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                Text(
                                  meal.mealName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: AppTheme.error.withOpacity(0.7),
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Cancelled badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.error.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppTheme.error,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Cancelled',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Main content
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Cancellation notice
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.error.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.error.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: AppTheme.error,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "This ${meal.planType == 'breakfast' ? 'breakfast' : 'lunch'} meal was cancelled and will not be delivered.",
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: AppTheme.error.withOpacity(0.8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Meal type badge
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: meal.planType == 'breakfast'
                                  ? Colors.pink.withOpacity(0.1)
                                  : Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: meal.planType == 'breakfast'
                                    ? Colors.pink.withOpacity(0.3)
                                    : Colors.green.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  meal.planType == 'breakfast'
                                      ? Icons.wb_sunny_outlined
                                      : Icons.flatware,
                                  color: meal.planType == 'breakfast'
                                      ? Colors.pink
                                      : Colors.green,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  meal.planType == 'breakfast'
                                      ? 'Breakfast'
                                      : 'Lunch',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: meal.planType == 'breakfast'
                                        ? Colors.pink
                                        : Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Meal details in two columns
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left column
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInfoRow(
                                      Icons.restaurant_menu_rounded,
                                      'Meal Type',
                                      meal.planType == 'breakfast'
                                          ? 'Breakfast'
                                          : 'Lunch',
                                      AppTheme.error,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildInfoRow(
                                      Icons.person,
                                      'Cancelled By',
                                      meal.cancelledBy == 'parent'
                                          ? 'Parent'
                                          : 'Admin',
                                      AppTheme.error.withOpacity(0.7),
                                    ),
                                  ],
                                ),
                              ),

                              // Right column
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInfoRow(
                                      Icons.event_rounded,
                                      'Scheduled Date',
                                      DateFormat('EEE, MMM d')
                                          .format(meal.cancellationDate),
                                      AppTheme.error,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildInfoRow(
                                      Icons.access_time_rounded,
                                      'Cancelled On',
                                      DateFormat('MMM d, h:mm a')
                                          .format(meal.timestamp),
                                      AppTheme.error,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Reason section (if available)
                          if (meal.reason != null &&
                              meal.reason!.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Divider(
                                height: 1,
                                color:
                                    Color(0x1A000000), // black with 0.2 opacity
                              ),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.error.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.note_alt,
                                    size: 16,
                                    color: AppTheme.error,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Cancellation Reason',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        meal.reason!,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: AppTheme.textMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(
      IconData icon, String label, String value, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 14,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppTheme.textLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
