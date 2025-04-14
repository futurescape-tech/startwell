import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:startwell/models/cancelled_meal.dart';
import 'package:startwell/services/event_bus_service.dart';
import 'package:startwell/services/subscription_service.dart';
import 'package:startwell/theme/app_theme.dart';
import 'package:startwell/widgets/empty_state.dart';
import 'package:startwell/widgets/loading.dart';

class CancelledMealsTab extends StatefulWidget {
  final String? studentId;

  const CancelledMealsTab({Key? key, this.studentId}) : super(key: key);

  @override
  State<CancelledMealsTab> createState() => CancelledMealsTabState();
}

class CancelledMealsTabState extends State<CancelledMealsTab> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  List<CancelledMeal> _cancelledMeals = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _hasDataBeenLoaded = false;

  @override
  void initState() {
    super.initState();
    log("cancelled meals tab: initState called, studentId: ${widget.studentId ?? 'null'}");

    // Listen for meal cancellation events
    eventBus.onMealCancelled.listen(_handleMealCancelled);

    // Load cancelled meals when the tab is first created
    loadCancelledMeals();
  }

  // Handle meal cancellation events
  void _handleMealCancelled(MealCancelledEvent event) {
    log("cancel meal flow: CancelledMealsTab received meal cancelled event for subscription ${event.subscriptionId}");
    log("cancel meal flow: Event details: ${event.toString()}");

    // If the event includes a studentId, check if it matches our current filter
    if (event.studentId != null && widget.studentId != null) {
      if (event.studentId != widget.studentId) {
        log("cancel meal flow: Ignoring event for different student (event: ${event.studentId}, current: ${widget.studentId})");
        return;
      }
      log("cancel meal flow: Student ID matches our filter, will refresh");
    }

    // Refresh data when a meal is cancelled
    if (mounted) {
      log("cancel meal flow: Refreshing cancelled meals list from event");

      // First mark as loading to show something is happening
      setState(() {
        _isLoading = true;
      });

      // Add a small delay to ensure backend has completed processing
      Future.delayed(Duration(milliseconds: 300), () {
        if (mounted) {
          loadCancelledMeals();
        }
      });
    }
  }

  @override
  void didUpdateWidget(CancelledMealsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the student ID changes, reload the cancelled meals
    if (oldWidget.studentId != widget.studentId) {
      log("cancelled meals tab: Student ID changed from ${oldWidget.studentId ?? 'null'} to ${widget.studentId ?? 'null'}");
      loadCancelledMeals();
    }
  }

  Future<void> loadCancelledMeals() async {
    log("cancel meal flow: Loading cancelled meals for studentId: ${widget.studentId ?? 'ALL'}");

    if (!mounted) {
      log("cancel meal flow: Widget not mounted, aborting load");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Add small delay to ensure backend has completed processing
      await Future.delayed(Duration(milliseconds: 200));

      log("cancel meal flow: Fetching cancelled meals from subscription service");
      final cancelledMeals =
          await _subscriptionService.getCancelledMeals(widget.studentId);

      log("cancel meal flow: Fetched ${cancelledMeals.length} cancelled meals");

      if (cancelledMeals.isEmpty) {
        log("cancel meal flow: No cancelled meals found");
      } else {
        // Log each cancelled meal for debugging
        for (int i = 0; i < cancelledMeals.length; i++) {
          final meal = cancelledMeals[i];
          log("cancel meal flow: Meal #${i + 1} - subscriptionId: ${meal.subscriptionId}, date: ${DateFormat('yyyy-MM-dd').format(meal.cancellationDate)}");
        }
      }

      if (mounted) {
        setState(() {
          _cancelledMeals = cancelledMeals;
          _isLoading = false;
          _hasDataBeenLoaded = true;
        });

        // If we don't have any meals but expect to, try again after a delay
        // This helps with race conditions between database updates
        if (cancelledMeals.isEmpty) {
          Future.delayed(Duration(milliseconds: 1000), () {
            if (mounted) {
              log("cancel meal flow: Attempting second load after delay");
              _retryLoadingCancelledMeals();
            }
          });
        }
      } else {
        log("cancel meal flow: Widget unmounted during setState");
      }
    } catch (e) {
      log("cancel meal flow: Error loading cancelled meals: $e");
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load cancelled meals: $e";
          _isLoading = false;
        });
      }
    }
  }

  // Retry loading cancelled meals with less UI disruption
  Future<void> _retryLoadingCancelledMeals() async {
    try {
      log("cancel meal flow: Retrying fetch of cancelled meals");
      final cancelledMeals =
          await _subscriptionService.getCancelledMeals(widget.studentId);

      log("cancel meal flow: Retry fetched ${cancelledMeals.length} cancelled meals");

      if (mounted && cancelledMeals.length > _cancelledMeals.length) {
        log("cancel meal flow: Updating with newly found cancelled meals");
        setState(() {
          _cancelledMeals = cancelledMeals;
        });
      }
    } catch (e) {
      log("cancel meal flow: Error in retry loading: $e");
      // Don't update UI on retry error
    }
  }

  @override
  Widget build(BuildContext context) {
    log("cancel meal flow: Building widget, isLoading: $_isLoading, meals count: ${_cancelledMeals.length}");

    if (_isLoading && !_hasDataBeenLoaded) {
      return const Center(child: Loading());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700, size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: GoogleFonts.poppins(color: Colors.red.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: loadCancelledMeals,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_cancelledMeals.isEmpty) {
      return RefreshIndicator(
        onRefresh: loadCancelledMeals,
        child: const SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Center(
            child: Padding(
              padding: EdgeInsets.only(top: 120),
              child: EmptyState(
                icon: Icons.event_busy,
                title: 'No Cancelled Meals',
                message: 'You haven\'t cancelled any meals yet.',
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadCancelledMeals,
      child: _isLoading
          ? Stack(
              children: [
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _cancelledMeals.length,
                  itemBuilder: _buildMealCard,
                ),
                const Center(child: Loading()),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _cancelledMeals.length,
              itemBuilder: _buildMealCard,
            ),
    );
  }

  Widget _buildMealCard(BuildContext context, int index) {
    final meal = _cancelledMeals[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.cancel_outlined,
                    color: Colors.red.shade700,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.mealName,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Cancelled for ${DateFormat('EEE, MMM d, yyyy').format(meal.cancellationDate)}',
                            style: GoogleFonts.poppins(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Cancelled on ${DateFormat('MMM d, yyyy \'at\' h:mm a').format(meal.timestamp)}',
                            style: GoogleFonts.poppins(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Student',
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        meal.studentName,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reason',
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        meal.reason ?? 'Not specified',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
