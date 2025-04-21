import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/themes/app_theme.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onActionPressed;
  final String? actionText;

  const SectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.onActionPressed,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            if (actionText != null && onActionPressed != null)
              TextButton(
                onPressed: onActionPressed,
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(
                  actionText!,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.purple,
                  ),
                ),
              ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textMedium,
            ),
          ),
        ],
      ],
    );
  }
}
