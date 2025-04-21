import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/themes/app_theme.dart';

class GradientButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final TextStyle? textStyle;
  final double? width;
  final double? height;
  final bool isFullWidth;
  final Widget? icon;
  final bool isEnabled;

  const GradientButton({
    required this.onPressed,
    required this.text,
    this.borderRadius = 12.0,
    this.padding = const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
    this.textStyle,
    this.width,
    this.height,
    this.isFullWidth = false,
    this.icon,
    this.isEnabled = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Ink(
          width: isFullWidth ? double.infinity : width,
          height: height,
          decoration: BoxDecoration(
            gradient: isEnabled ? AppTheme.purpleToDeepPurple : null,
            color: isEnabled ? null : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: AppTheme.deepPurple.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Container(
            padding: padding,
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  icon!,
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: textStyle ??
                      GoogleFonts.poppins(
                        color: isEnabled ? Colors.white : Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
