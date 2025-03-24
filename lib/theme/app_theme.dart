import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const double cardBorderRadius = 20.0;
  static const double buttonBorderRadius = 12.0;
  static const double defaultPadding = 16.0;

  // HCMUT Colors
  static const Color primaryColor = Color(0xFF1A5CAC);  // HCMUT Blue
  static const Color secondaryColor = Color(0xFF3478D5); // Lighter Blue
  static const Color accentColor = Color(0xFF0A4A90);   // Darker Blue
  static const Color backgroundColor = Color(0xFFFAFAFA); // Light background
  static const Color cardColor = Color(0xFFFFFFFF);      // White cards
  static const Color textColor = Color(0xFF333333);      // Dark text
  static const Color subtitleColor = Color(0xFF666666);  // Gray text

  static const TextStyle headingStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textColor,
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A5CAC),  // HCMUT Blue
      Color(0xFF0A4A90),  // Darker Blue
    ],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF3478D5),  // Lighter Blue
      Color(0xFF1A5CAC),  // HCMUT Blue
    ],
  );

  static final glassEffect = BoxDecoration(
    color: Colors.white.withOpacity(0.9),
    borderRadius: BorderRadius.circular(cardBorderRadius),
    border: Border.all(
      color: primaryColor.withOpacity(0.2),
      width: 1.5,
    ),
  );

  static final cardShadow = [
    BoxShadow(
      color: primaryColor.withOpacity(0.1),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];

  static TextStyle get subheadingStyle => GoogleFonts.poppins(
    fontSize: 16,
    color: textColor.withOpacity(0.7),
  );

  static TextStyle get buttonTextStyle => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static ThemeData get theme => ThemeData(
    primarySwatch: MaterialColor(primaryColor.value, {
      50: primaryColor.withOpacity(0.1),
      100: primaryColor.withOpacity(0.2),
      200: primaryColor.withOpacity(0.3),
      300: primaryColor.withOpacity(0.4),
      400: primaryColor.withOpacity(0.5),
      500: primaryColor,
      600: accentColor,
      700: accentColor.withOpacity(0.7),
      800: accentColor.withOpacity(0.8),
      900: accentColor.withOpacity(0.9),
    }),
    scaffoldBackgroundColor: backgroundColor,
    textTheme: GoogleFonts.poppinsTextTheme(
      ThemeData.light().textTheme.copyWith(
        headlineLarge: headingStyle,
        headlineMedium: headingStyle.copyWith(fontSize: 20),
        titleLarge: TextStyle(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: textColor,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: textColor.withOpacity(0.8),
          fontSize: 14,
        ),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      elevation: 0,
      titleTextStyle: headingStyle.copyWith(color: Colors.white),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    cardTheme: CardTheme(
      color: cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    iconTheme: IconThemeData(
      color: textColor,
      size: 24,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor.withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor),
      ),
      labelStyle: TextStyle(color: textColor.withOpacity(0.8)),
      prefixIconColor: primaryColor,
    ),
  );
}