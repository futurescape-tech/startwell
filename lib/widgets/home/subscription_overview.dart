import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/themes/app_theme.dart';

class SubscriptionOverview extends StatelessWidget {
  final String planType;
  final int remainingMeals;
  final String nextRenewalDate;
  final int studentCount;
  final VoidCallback? onTap;

  const SubscriptionOverview({
    super.key,
    required this.planType,
    required this.remainingMeals,
    required this.nextRenewalDate,
    required this.studentCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 1.4,
        children: [
          _buildSubscriptionItem(
            title: 'Active Plan',
            value: planType,
            icon: Icons.calendar_month,
            iconColor: AppTheme.purple,
            bgColor: AppTheme.purple.withOpacity(0.1),
          ),
          _buildSubscriptionItem(
            title: 'Remaining Meals',
            value: remainingMeals.toString(),
            icon: Icons.restaurant,
            iconColor: AppTheme.orange,
            bgColor: AppTheme.orange.withOpacity(0.1),
          ),
          _buildSubscriptionItem(
            title: 'Next Renewal',
            value: nextRenewalDate,
            icon: Icons.event,
            iconColor: AppTheme.deepPurple,
            bgColor: AppTheme.deepPurple.withOpacity(0.1),
          ),
          _buildSubscriptionItem(
            title: 'Students',
            value: studentCount.toString(),
            icon: Icons.people,
            iconColor: AppTheme.yellow,
            bgColor: AppTheme.yellow.withOpacity(0.1),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionItem({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textMedium,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
