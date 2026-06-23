import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    primaryColor: AppColors.primaryDark,
    cardColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primaryDark,
      iconTheme: IconThemeData(color: Colors.white),
      elevation: 0,
      centerTitle: true,
    ),
    colorScheme: const ColorScheme.light(
      primary: AppColors.primaryDark,
      secondary: AppColors.buttonColor,
      surface: Colors.white,
    ),
    dividerColor: Colors.grey.shade300,
    textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF020617), // Premium Slate 950
    primaryColor: const Color(0xFF0F172A), // Premium Slate 900
    cardColor: const Color(0xFF0F172A), // Premium Slate 900
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF020617), // Deep midnight for app bar
      iconTheme: IconThemeData(color: Colors.white),
      elevation: 0,
      centerTitle: true,
    ),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF0F172A),
      secondary: AppColors.buttonColor,
      surface: Color(0xFF0F172A),
    ),
    dividerColor: Colors.white.withOpacity(0.06),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: const Color(0xFFF8FAFC), // Slate 50
      displayColor: const Color(0xFFF8FAFC),
    ),
  );
}
