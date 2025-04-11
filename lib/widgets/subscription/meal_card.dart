import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:startwell/utils/date_utils.dart';

class MealCard extends StatelessWidget {
  final DateTime date;
  final String title;
  final String description;
  final String status;
  final VoidCallback onSwapMeal;
  final VoidCallback onCancelMeal;
  final String studentName;
  final String planName;
  final List<String> mealItems;
  final String planType;

  const MealCard({
    Key? key,
    required this.date,
    required this.title,
    required this.description,
    required this.status,
    required this.onSwapMeal,
    required this.onCancelMeal,
    this.studentName = "Not Assigned",
    this.planName = "Not Selected",
    this.mealItems = const ["Item 1", "Item 2", "Item 3"],
    required this.planType,
  }) : super(key: key);

  // Check if swap meal button should be enabled
  bool _isSwapEnabled() {
    // Express plans cannot be swapped
    if (planType == 'express') {
      return false;
    }

    // Check if we're past the cutoff time (11:59 PM the day before)
    final today = DateTime.now();
    final cutoffDate = DateTime(
            date.year, date.month, date.day, 23, 59 // 11:59 PM the day before
            )
        .subtract(const Duration(days: 1));

    return today.isBefore(cutoffDate);
  }

  // Check if cancel meal button should be enabled
  bool _isCancelEnabled() {
    // Check if we're past the cutoff time (11:59 PM the day before)
    final today = DateTime.now();
    final cutoffDate = DateTime(
            date.year, date.month, date.day, 23, 59 // 11:59 PM the day before
            )
        .subtract(const Duration(days: 1));

    return today.isBefore(cutoffDate);
  }

  // Get appropriate message for swap button based on plan type and timing
  String? _getSwapTooltipMessage() {
    if (planType == 'express') {
      return "Swapping not allowed for Express 1-Day";
    }

    if (!_isSwapEnabled()) {
      return "Swap window closed";
    }

    return null; // No tooltip needed for enabled buttons
  }

  // Get appropriate message for cancel button based on timing
  String? _getCancelTooltipMessage() {
    if (!_isCancelEnabled()) {
      return "Cancellation window closed";
    }

    return null; // No tooltip needed for enabled buttons
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DeliveryDateCalculator.formatDate(date);
    final isScheduled = status == 'Scheduled';
    final canSwap = _isSwapEnabled();
    final canCancel = _isCancelEnabled();
    final swapTooltip = _getSwapTooltipMessage();
    final cancelTooltip = _getCancelTooltipMessage();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusBanner(isScheduled),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: AppTheme.textDark,
                              ),
                              children: [
                                const WidgetSpan(
                                  child: Icon(
                                    Icons.person,
                                    size: 18,
                                    color: AppTheme.purple,
                                  ),
                                  alignment: PlaceholderAlignment.middle,
                                ),
                                const TextSpan(text: " Student: "),
                                TextSpan(
                                  text: studentName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          RichText(
                            text: TextSpan(
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: AppTheme.textDark,
                              ),
                              children: [
                                const WidgetSpan(
                                  child: Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: AppTheme.purple,
                                  ),
                                  alignment: PlaceholderAlignment.middle,
                                ),
                                const TextSpan(text: " Subscription Plan: "),
                                TextSpan(
                                  text: planName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.purple,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isScheduled
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isScheduled
                              ? Colors.green.shade800
                              : Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: AppTheme.textDark,
                            fontWeight: FontWeight.w600,
                          ),
                          children: [
                            const WidgetSpan(
                              child: Icon(
                                Icons.restaurant_menu,
                                size: 18,
                                color: AppTheme.purple,
                              ),
                              alignment: PlaceholderAlignment.middle,
                            ),
                            const TextSpan(text: " Meal Item: "),
                            TextSpan(
                              text: title,
                              style: TextStyle(
                                color: AppTheme.purple,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                          children: [
                            const WidgetSpan(
                              child: Icon(
                                Icons.event,
                                size: 18,
                                color: AppTheme.purple,
                              ),
                              alignment: PlaceholderAlignment.middle,
                            ),
                            const TextSpan(text: " Scheduled Date: "),
                            TextSpan(
                              text: formattedDate,
                              style: TextStyle(
                                color: AppTheme.textDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                RichText(
                  overflow: TextOverflow.ellipsis,
                  maxLines: 3,
                  text: TextSpan(
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                    ),
                    children: [
                      const WidgetSpan(
                        child: Icon(
                          Icons.lunch_dining,
                          size: 18,
                          color: AppTheme.purple,
                        ),
                        alignment: PlaceholderAlignment.middle,
                      ),
                      const TextSpan(text: " Includes: "),
                      TextSpan(
                        text: mealItems.join(', '),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Tooltip(
                            message: swapTooltip ??
                                "Swap this meal with another option",
                            child: ElevatedButton.icon(
                              onPressed: canSwap ? onSwapMeal : null,
                              icon: const Icon(Icons.swap_horiz, size: 18),
                              label: Text(
                                'Swap Meal',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.purple,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey.shade300,
                                disabledForegroundColor: Colors.grey.shade600,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          if (!canSwap)
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 4.0, left: 4.0),
                              child: Text(
                                swapTooltip ?? "",
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            )
                          else if (planType != 'express')
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 4.0, left: 4.0),
                              child: Text(
                                "You can swap until 11:59 PM the previous day",
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: AppTheme.purple.withOpacity(0.7),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Tooltip(
                        message: cancelTooltip ?? "Cancel this meal delivery",
                        child: ElevatedButton.icon(
                          onPressed: canCancel ? onCancelMeal : null,
                          icon: const Icon(Icons.close, size: 18),
                          label: Text(
                            'Cancel Meal',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade300,
                            disabledForegroundColor: Colors.grey.shade600,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (!canCancel)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0, left: 4.0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        cancelTooltip ?? "",
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(bool isScheduled) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isScheduled
              ? [Colors.green.shade300, Colors.green.shade500]
              : [Colors.orange.shade300, Colors.orange.shade500],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Center(
        child: Text(
          isScheduled ? 'SCHEDULED' : 'SKIPPED',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
