import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:startwell/models/cancelled_meal.dart';
import 'package:startwell/services/subscription_service.dart';
import 'package:startwell/services/student_profile_service.dart';
import 'package:startwell/models/student_model.dart';

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

      final meals =
          await _subscriptionService.getCancelledMeals(_selectedStudentId);

      log('[cancelled_meal_data_flow] Loaded ${meals.length} cancelled meals');

      if (mounted) {
        setState(() {
          _cancelledMeals = meals;
          _isLoading = false;
        });

        // Log details about loaded meals for debugging
        if (meals.isEmpty) {
          log('[cancelled_meal_data_flow] No cancelled meals found for student $_selectedStudentId');
        } else {
          log('[cancelled_meal_data_flow] === CANCELLED MEALS DETAILS ===');
          for (var meal in meals) {
            log('[cancelled_meal_data_flow] Meal: ${meal.mealName}');
            log('[cancelled_meal_data_flow] Date: ${DateFormat('yyyy-MM-dd').format(meal.cancellationDate)}');
            log('[cancelled_meal_data_flow] Student: ${meal.studentName} (${meal.studentId})');
            log('[cancelled_meal_data_flow] Cancelled at: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(meal.timestamp)}');
            log('[cancelled_meal_data_flow] Reason: ${meal.reason ?? "Not specified"}');
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

  @override
  Widget build(BuildContext context) {
    // If not initialized yet, show a loading indicator
    if (!_initialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _buildStudentSelector(),
        Expanded(
          child: _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Loading cancelled meals...',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade600,
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
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade800,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () =>
                                  _loadCancelledMeals(forceRefresh: true),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Try Again'),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.blue,
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

  Widget _buildStudentSelector() {
    if (_students.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedStudentId,
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
            items: _students.map((student) {
              return DropdownMenuItem(
                value: student.id,
                child: Text(
                  student.name,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedStudentId = newValue;
                });
                _loadCancelledMeals();
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Icon(
              Icons.no_meals,
              size: 64,
              color: Colors.red.shade300,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No cancelled meals found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Any cancelled meals will appear here',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
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
            schoolAddress: 'Unknown Address',
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header if needed
            if (showDateHeader) ...[
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: Text(
                    DateFormat('EEEE, MMMM d, yyyy')
                        .format(meal.cancellationDate),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
              ),
            ],

            Card(
              elevation: 3,
              shadowColor: Colors.black.withOpacity(0.1),
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row with student name and cancellation badge
                    Row(
                      children: [
                        // Meal type icon
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: meal.planType == 'breakfast'
                                ? Colors.purple.withOpacity(0.1)
                                : Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            meal.planType == 'breakfast'
                                ? Icons.free_breakfast
                                : Icons.lunch_dining,
                            color: meal.planType == 'breakfast'
                                ? Colors.purple
                                : Colors.green,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Student name and meal item
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student.name,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              Text(
                                meal.mealName,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Cancelled badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Cancelled',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1),
                    ),

                    // Meal details
                    _buildDetailRow(
                      Icons.restaurant_menu,
                      'Meal Type',
                      meal.planType == 'breakfast' ? 'Breakfast' : 'Lunch',
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      Icons.calendar_today,
                      'Scheduled Date',
                      DateFormat('EEE, MMM d, yyyy')
                          .format(meal.cancellationDate),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      Icons.person,
                      'Cancelled By',
                      meal.cancelledBy == 'parent' ? 'Parent' : 'Admin',
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      Icons.access_time,
                      'Cancelled On',
                      DateFormat('EEE, MMM d, yyyy h:mm a')
                          .format(meal.timestamp),
                    ),
                    if (meal.reason != null && meal.reason!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        Icons.note,
                        'Reason',
                        meal.reason!,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 16,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper to check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
