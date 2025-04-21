import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:startwell/utils/app_colors.dart';

/// A utility class that provides reusable UI components for the app
class UIComponents {
  // Reusable gradient app bar
  static AppBar gradientAppBar({
    required String title,
    required BuildContext context,
    List<Widget>? actions,
    bool showBackButton = true,
    Gradient? customGradient,
    double elevation = 2,
  }) {
    return AppBar(
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: AppTheme.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      centerTitle: true,
      automaticallyImplyLeading: showBackButton,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.white),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      actions: actions,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: customGradient ?? AppTheme.purpleToDeepPurple,
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: elevation,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
      ),
    );
  }

  // Gradient button with rounded corners
  static Widget gradientButton({
    required String text,
    required VoidCallback onPressed,
    Gradient? gradient,
    double height = 50,
    double borderRadius = 16,
    bool isFullWidth = true,
    EdgeInsetsGeometry? padding,
    TextStyle? textStyle,
    bool elevated = false,
  }) {
    return Container(
      height: height,
      width: isFullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        gradient: gradient ?? AppTheme.purpleToOrange,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: elevated ? AppTheme.softShadow : null,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppTheme.white,
          shadowColor: Colors.transparent,
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: Text(
          text,
          style: textStyle ??
              GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.white,
              ),
        ),
      ),
    );
  }

  // Card with optional gradient background
  static Widget customCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(20),
    double borderRadius = 20,
    Color? backgroundColor,
    Gradient? gradient,
    bool elevated = true,
    double? width,
    double? height,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.white,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: elevated ? AppTheme.softShadow : null,
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }

  // Input field with custom styling
  static Widget customTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? Function(String?)? validator,
    Widget? prefixIcon,
    Widget? suffixIcon,
    int? maxLines = 1,
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      validator: validator,
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: AppTheme.textDark,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.purple.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.purple.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.purple, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.error),
        ),
        filled: true,
        fillColor: AppTheme.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: AppTheme.textMedium,
        ),
        hintStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: AppTheme.textLight,
        ),
      ),
    );
  }

  // Section title with optional gradient
  static Widget sectionTitle({
    required String title,
    Color? color,
    Gradient? gradient,
    double fontSize = 18,
    TextAlign textAlign = TextAlign.start,
  }) {
    if (gradient != null) {
      return ShaderMask(
        shaderCallback: (bounds) => gradient.createShader(bounds),
        child: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: AppTheme.white, // Text must be white for gradient to show
          ),
          textAlign: textAlign,
        ),
      );
    }

    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: color ?? AppTheme.textDark,
      ),
      textAlign: textAlign,
    );
  }

  // Gradient divider
  static Widget gradientDivider({
    Gradient? gradient,
    double height = 2,
    double indent = 0,
    double endIndent = 0,
  }) {
    return Container(
      height: height,
      margin: EdgeInsetsDirectional.only(
        start: indent,
        end: endIndent,
      ),
      decoration: BoxDecoration(
        gradient: gradient ?? AppTheme.purpleToOrange,
      ),
    );
  }

  // Badge with gradient background
  static Widget badge({
    required String text,
    Gradient? gradient,
    double borderRadius = 16,
    EdgeInsetsGeometry padding =
        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    TextStyle? textStyle,
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient ?? AppTheme.orangeToYellow,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Text(
        text,
        style: textStyle ??
            GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
      ),
    );
  }

  // Avatar with gradient background
  static Widget gradientAvatar({
    Widget? child,
    double size = 50,
    Gradient? gradient,
    List<BoxShadow>? boxShadow,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient ?? AppTheme.purpleToDeepPurple,
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: AppTheme.deepPurple.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
      ),
      child: child ??
          Icon(
            Icons.person,
            color: AppTheme.white,
            size: size * 0.6,
          ),
    );
  }
}
