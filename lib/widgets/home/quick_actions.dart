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
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1.0, end: 1.0),
      duration: const Duration(milliseconds: 150),
      builder: (context, scale, child) {
        return Material(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          elevation: 4,
          shadowColor: AppTheme.deepPurple.withOpacity(0.15),
          child: InkWell(
            onTap: () {
              // Trigger haptic feedback for better tactile response
              HapticFeedback.lightImpact();
              onPressed();
            },
            onHighlightChanged: (isPressed) {
              // This would be handled by StatefulWidget in a real implementation
              // but we'll use the simpler InkWell effect for this enhancement
            },
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: AppTheme.white,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.deepPurple.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                    spreadRadius: 0.5,
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      color: iconColor,
                      size: 30, // Slightly larger icon
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
          ),
        );
      },
    );
  }
}
