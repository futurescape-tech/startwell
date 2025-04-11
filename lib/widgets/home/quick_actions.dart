import 'package:flutter/material.dart';
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
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.restaurant_menu,
                label: 'Meal Plan',
                iconColor: AppTheme.deepPurple,
                onPressed: onMealPlanPressed,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildActionButton(
                icon: Icons.person,
                label: 'Manage Student',
                iconColor: AppTheme.orange,
                onPressed: onManageStudentPressed,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.account_balance_wallet,
                label: 'Top Up Wallet',
                iconColor: AppTheme.deepPurple,
                onPressed: onTopUpWalletPressed,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildActionButton(
                icon: Icons.school,
                label: 'Invite School',
                iconColor: AppTheme.orange,
                onPressed: onInviteSchoolPressed,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: AppTheme.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: AppTheme.deepPurple.withOpacity(0.1),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: iconColor,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
