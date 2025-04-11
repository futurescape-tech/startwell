import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:intl/intl.dart';

class CancelledMealsTab extends StatelessWidget {
  const CancelledMealsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> cancelledMeals = [
      {
        'date': DateTime.now().subtract(const Duration(days: 2)),
        'title': 'Indian Lunch',
        'cancellationTime': '9:30 AM',
        'reason': 'Cancelled by User',
        'cancelledBy': 'user'
      },
      {
        'date': DateTime.now().subtract(const Duration(days: 4)),
        'title': 'International Breakfast',
        'cancellationTime': '8:00 PM (Previous Day)',
        'reason': 'Cancelled by User',
        'cancelledBy': 'user'
      },
      {
        'date': DateTime.now().subtract(const Duration(days: 7)),
        'title': 'Jain Lunch',
        'cancellationTime': '10:15 AM',
        'reason': 'Cancelled by Admin',
        'cancelledBy': 'admin'
      },
    ];

    if (cancelledMeals.isEmpty) {
      return Center(
        child: Text(
          "No meals yet in this category.",
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: AppTheme.textMedium,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: cancelledMeals.length,
      itemBuilder: (context, index) {
        final meal = cancelledMeals[index];
        return _buildCancelledMealCard(meal);
      },
    );
  }

  Widget _buildCancelledMealCard(Map<String, dynamic> meal) {
    final formattedDate = DateFormat('EEEE, MMMM d').format(meal['date']);
    final isUserCancelled = meal['cancelledBy'] == 'user';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isUserCancelled ? Icons.person : Icons.admin_panel_settings,
                  color: isUserCancelled ? Colors.orange : Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  meal['reason'],
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isUserCancelled ? Colors.orange : Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              meal['title'],
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Scheduled for $formattedDate',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textMedium,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppTheme.textMedium,
                ),
                const SizedBox(width: 4),
                Text(
                  'Cancelled at ${meal['cancellationTime']}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppTheme.textMedium,
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
