import 'package:flutter/material.dart';
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
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF121418),
    primaryColor: const Color(0xFF1A1D24),
    cardColor: const Color(0xFF1E2128),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF121418), // Deep dark for app bar
      iconTheme: IconThemeData(color: Colors.white),
      elevation: 0,
      centerTitle: true,
    ),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF1A1D24),
      secondary: AppColors.buttonColor,
      surface: Color(0xFF1E2128),
    ),
    dividerColor: Colors.white12,
  );
}
