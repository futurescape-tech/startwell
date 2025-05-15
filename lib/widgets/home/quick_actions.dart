import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/themes/app_theme.dart';

class QuickActions extends StatelessWidget {
  final VoidCallback onInviteSchoolPressed;
  final VoidCallback onWalletPressed;
  final VoidCallback onMealPlanPressed;
  final VoidCallback onManageStudentPressed;
  final VoidCallback onTopUpWalletPressed;

  const QuickActions({
    super.key,
    required this.onInviteSchoolPressed,
    required this.onWalletPressed,
    required this.onMealPlanPressed,
    required this.onManageStudentPressed,
    required this.onTopUpWalletPressed,
  });

  @override
  Widget build(BuildContext context) {
    // List of action items to display
    final actionItems = [
      _ActionItem(
        icon: Icons.restaurant_menu,
        label: 'Order Meal',
        color: AppTheme.success,
        onPressed: onMealPlanPressed,
      ),
      _ActionItem(
        icon: Icons.person,
        label: 'Student',
        color: AppTheme.error,
        onPressed: onManageStudentPressed,
      ),
      _ActionItem(
        icon: Icons.account_balance_wallet,
        label: 'Wallet',
        color: AppTheme.deepPurple,
        onPressed: onTopUpWalletPressed,
      ),
      _ActionItem(
        icon: Icons.school,
        label: 'Invite School',
        color: AppTheme.orange,
        onPressed: onInviteSchoolPressed,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Row(
          children: actionItems
              .map((item) => _buildCircularAction(
                    icon: item.icon,
                    label: item.label,
                    color: item.color,
                    onPressed: item.onPressed,
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildCircularAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 80,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular Icon Button
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                color: Colors.grey.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              clipBehavior: Clip.hardEdge,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onPressed();
                },
                child: Container(
                  width: 60,
                  height: 60,
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Label text below icon
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textDark,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// Helper class to organize action items
class _ActionItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  _ActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });
}
