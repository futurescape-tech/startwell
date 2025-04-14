import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:startwell/models/cancelled_meal.dart';
import 'package:startwell/services/subscription_service.dart';
import 'package:startwell/theme/app_theme.dart';
import 'package:startwell/widgets/empty_state.dart';
import 'package:startwell/widgets/loading.dart';

class CancelledMealsTab extends StatefulWidget {
  final String? studentId;

  const CancelledMealsTab({Key? key, this.studentId}) : super(key: key);

  @override
  State<CancelledMealsTab> createState() => _CancelledMealsTabState();
}

class _CancelledMealsTabState extends State<CancelledMealsTab> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  List<CancelledMeal> _cancelledMeals = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    log("cancelled meals tab: initState called, studentId: ${widget.studentId ?? 'null'}");
    // Load cancelled meals when the tab is first created
    loadCancelledMeals();
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
    log("cancelled meals tab: Loading cancelled meals for studentId: ${widget.studentId ?? 'null'}");

    if (!mounted) {
      log("cancelled meals tab: Widget not mounted, aborting load");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      log("cancelled meals tab: Fetching cancelled meals from subscription service");
      final cancelledMeals =
          await _subscriptionService.getCancelledMeals(widget.studentId);

      log("cancelled meals tab: Fetched ${cancelledMeals.length} cancelled meals");

      if (cancelledMeals.isEmpty) {
        log("cancelled meals tab: No cancelled meals found");
      } else {
        // Log a sample of the first cancelled meal for debugging
        final sample = cancelledMeals.first;
        log("cancelled meals tab: Sample cancelled meal - subscriptionId: ${sample.subscriptionId}, studentId: ${sample.studentId}, date: ${DateFormat('yyyy-MM-dd').format(sample.cancellationDate)}");
      }

      if (mounted) {
        setState(() {
          _cancelledMeals = cancelledMeals;
          _isLoading = false;
        });
      } else {
        log("cancelled meals tab: Widget unmounted during setState");
      }
    } catch (e) {
      log("cancelled meals tab: Error loading cancelled meals: $e");
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load cancelled meals: $e";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    log("cancelled meals tab: Building widget, isLoading: $_isLoading, meals count: ${_cancelledMeals.length}");

    if (_isLoading) {
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
      return const EmptyState(
        icon: Icons.event_busy,
        title: 'No Cancelled Meals',
        message: 'You haven\'t cancelled any meals yet.',
      );
    }

    return RefreshIndicator(
      onRefresh: loadCancelledMeals,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _cancelledMeals.length,
        itemBuilder: (context, index) {
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
        },
      ),
    );
  }
}
