import 'package:flutter/material.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? titleWidget;
  final String? titleText;
  final List<Widget>? actions;
  final bool centerTitle;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final double? elevation;
  final Gradient? customGradient;
  final PreferredSizeWidget? bottom;

  const GradientAppBar({
    this.titleText,
    this.titleWidget,
    this.actions,
    this.centerTitle = false,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.elevation = 2,
    this.customGradient,
    this.bottom,
    super.key,
  }) : assert(titleText != null || titleWidget != null,
            'Either titleText or titleWidget must be provided');

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: elevation,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: customGradient ?? AppTheme.purpleToDeepPurple,
          borderRadius: bottom == null
              ? const BorderRadius.vertical(
                  bottom: Radius.circular(0),
                )
              : BorderRadius.zero,
        ),
      ),
      title: titleWidget ??
          Text(
            titleText!,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
      actions: actions,
      centerTitle: centerTitle,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: Colors.transparent,
      shape: bottom == null
          ? const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
            )
          : null,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
}
