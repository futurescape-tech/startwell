import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum InfoBannerType { info, warning, success, error }

class InfoBanner extends StatelessWidget {
  final String title;
  final String message;
  final InfoBannerType type;
  final IconData? customIcon;
  final VoidCallback? onTap;

  const InfoBanner({
    super.key,
    required this.title,
    required this.message,
    this.type = InfoBannerType.info,
    this.customIcon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Define color schemes for different banner types
    final Map<InfoBannerType, BannerColorScheme> colorSchemes = {
      InfoBannerType.info: BannerColorScheme(
        background: const Color(0xFFD1ECF1),
        border: Colors.blue.shade300,
        icon: Colors.blue.shade700,
        titleColor: Colors.blue.shade900,
        messageColor: Colors.blue.shade800,
        defaultIcon: Icons.info_outline,
      ),
      InfoBannerType.warning: BannerColorScheme(
        background: const Color(0xFFFFF3CD),
        border: Colors.amber.shade300,
        icon: Colors.amber.shade800,
        titleColor: Colors.amber.shade900,
        messageColor: Colors.amber.shade800,
        defaultIcon: Icons.warning_amber_rounded,
      ),
      InfoBannerType.success: BannerColorScheme(
        background: const Color(0xFFD4EDDA),
        border: Colors.green.shade300,
        icon: Colors.green.shade700,
        titleColor: Colors.green.shade900,
        messageColor: Colors.green.shade800,
        defaultIcon: Icons.check_circle_outline,
      ),
      InfoBannerType.error: BannerColorScheme(
        background: const Color(0xFFF8D7DA),
        border: Colors.red.shade300,
        icon: Colors.red.shade700,
        titleColor: Colors.red.shade900,
        messageColor: Colors.red.shade800,
        defaultIcon: Icons.error_outline,
      ),
    };

    final colorScheme = colorSchemes[type]!;
    final icon = customIcon ?? colorScheme.defaultIcon;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.background.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.border),
          boxShadow: [
            BoxShadow(
              color: colorScheme.border.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  color: colorScheme.icon,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.titleColor,
                    ),
                  ),
                ),
              ],
            ),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 32),
                child: Text(
                  message,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: colorScheme.messageColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class BannerColorScheme {
  final Color background;
  final Color border;
  final Color icon;
  final Color titleColor;
  final Color messageColor;
  final IconData defaultIcon;

  const BannerColorScheme({
    required this.background,
    required this.border,
    required this.icon,
    required this.titleColor,
    required this.messageColor,
    required this.defaultIcon,
  });
}
