import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

/// Central color theme class for the StartWell app
class AppTheme {
  // Primary and Secondary Colors
  static const Color purple = Color(0xFF8E44AD);
  static const Color deepPurple = Color(0xFF5D3D9C);
  static const Color orange = Color(0xFFF39C12);
  static const Color yellow = Color(0xFFF1C40F);
  static const Color white = Colors.white;
  static const Color offWhite = Color(0xFFF8F8F8);

  // Text and UI Colors
  static const Color textDark = Color(0xFF2D2D2D);
  static const Color textMedium = Color(0xFF757575);
  static const Color textLight = Color(0xFFA7A7A7);
  static const Color success = Color(0xFF27AE60);
  static const Color error = Color(0xFFE74C3C);

  // Add the missing colors
  static const Color gray = Color(0xFFEEEEEE);
  static const Color lightGreen = Color(0xFFE6F4EA);
  static const Color lightOrange = Color(0xFFFFF3E0);

  // Gradients
  static const LinearGradient purpleToDeepPurple = LinearGradient(
    colors: [purple, deepPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleToOrange = LinearGradient(
    colors: [purple, orange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient deepPurpleToYellow = LinearGradient(
    colors: [deepPurple, yellow],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangeToYellow = LinearGradient(
    colors: [orange, yellow],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadow styles
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: deepPurple.withOpacity(0.08),
          offset: const Offset(0, 4),
          blurRadius: 12,
        ),
      ];

  static List<BoxShadow> get mediumShadow => [
        BoxShadow(
          color: deepPurple.withOpacity(0.12),
          offset: const Offset(0, 6),
          blurRadius: 16,
          spreadRadius: 1,
        ),
      ];

  // Get the main ThemeData for the app
  static ThemeData getTheme() {
    return ThemeData(
      useMaterial3: true,
      primaryColor: purple,
      scaffoldBackgroundColor: white,

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: deepPurple,
        foregroundColor: white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: white,
        ),
      ),

      // Text Theme with Poppins font
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        displaySmall: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          color: textMedium,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          color: textMedium,
        ),
        labelLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: white,
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: purple,
          foregroundColor: white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: purple,
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: purple,
          side: const BorderSide(color: purple, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: textLight, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: textLight.withOpacity(0.5), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: purple, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 1),
        ),
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: textMedium,
        ),
        hintStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: textLight,
        ),
      ),

      // Card Theme
      cardTheme: CardTheme(
        color: offWhite,
        elevation: 2,
        shadowColor: deepPurple.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: purple,
        size: 24,
      ),

      // Tab Bar Theme
      tabBarTheme: const TabBarTheme(
        labelColor: purple,
        unselectedLabelColor: textLight,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: purple, width: 2),
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: white,
        selectedItemColor: purple,
        unselectedItemColor: textLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        checkColor: MaterialStateProperty.all(white),
        fillColor: MaterialStateProperty.all(purple),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // Radio Button Theme
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.all(purple),
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return purple;
          }
          return textLight;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return purple.withOpacity(0.5);
          }
          return textLight.withOpacity(0.3);
        }),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: purple,
        linearTrackColor: Color(0xFFE5E5E5),
      ),

      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: purple,
        secondary: deepPurple,
        tertiary: orange,
        tertiaryContainer: yellow,
        surface: white,
        background: white,
        error: error,
        onPrimary: white,
        onSecondary: white,
        onTertiary: textDark,
        onSurface: textDark,
        onBackground: textDark,
        onError: white,
      ),
    );
  }

  // Get the base theme data
  static ThemeData lightTheme() {
    return ThemeData(
      primaryColor: purple,
      scaffoldBackgroundColor: white,
      colorScheme: const ColorScheme.light().copyWith(
        primary: purple,
        secondary: orange,
        background: white,
        error: error,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: purple,
        elevation: 2,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: const IconThemeData(color: white),
        actionsIconTheme: const IconThemeData(color: white),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: white,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        displaySmall: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          color: textMedium,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          color: textMedium,
        ),
        labelLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: purple,
          foregroundColor: white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: purple,
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: purple,
          side: const BorderSide(color: purple, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: textLight, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: textLight.withOpacity(0.5), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: purple, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 1),
        ),
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: textMedium,
        ),
        hintStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: textLight,
        ),
      ),
      cardTheme: CardTheme(
        color: offWhite,
        elevation: 2,
        shadowColor: deepPurple.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      ),
      iconTheme: const IconThemeData(
        color: purple,
        size: 24,
      ),
      tabBarTheme: const TabBarTheme(
        labelColor: purple,
        unselectedLabelColor: textLight,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: purple, width: 2),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: white,
        selectedItemColor: purple,
        unselectedItemColor: textLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      checkboxTheme: CheckboxThemeData(
        checkColor: MaterialStateProperty.all(white),
        fillColor: MaterialStateProperty.all(purple),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.all(purple),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return purple;
          }
          return textLight;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return purple.withOpacity(0.5);
          }
          return textLight.withOpacity(0.3);
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: purple,
        linearTrackColor: Color(0xFFE5E5E5),
      ),
    );
  }
}
