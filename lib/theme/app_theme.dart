import 'package:flutter/material.dart';

class AppTheme {
  // Primary Colors
  static const Color primaryColor = Color(0xFF5B88F6);
  static const Color primaryColorDark = Color(0xFF3D5AFE);
  static const Color primaryColorLight = Color(0xFFE6E9FD);

  // Accent/Secondary Colors
  static const Color accentColor = Color(0xFF4CAF50);
  static const Color accentColorDark = Color(0xFF3A8C3D);
  static const Color accentColorLight = Color(0xFFDCF1DD);

  // Background Colors
  static const Color backgroundColor = Color(0xFFF5F9FE);
  static const Color backgroundColorDark = Color(0xFF121212);

  // Text Colors
  static const Color textColor = Color(0xFF2D3142);
  static const Color textColorDark = Color(0xFFE1E1E1);
  static const Color textColorLight = Color(0xFF7B7F9E);

  // Status Colors
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFFC107);
  static const Color errorColor = Color(0xFFE53935);
  static const Color infoColor = Color(0xFF2196F3);

  // Light Theme
  static final ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: accentColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      background: backgroundColor,
      onBackground: textColor,
      surface: Colors.white,
      onSurface: textColor,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(color: textColor, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(color: textColor, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: textColor, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(color: textColor, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: textColor),
      bodyMedium: TextStyle(color: textColor),
      bodySmall: TextStyle(color: textColorLight),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: Colors.white,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor),
      ),
      contentPadding: const EdgeInsets.all(16),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFEAECF0),
      thickness: 1,
    ),
  );

  // Dark Theme
  static final ThemeData darkTheme = ThemeData(
    primaryColor: primaryColorDark,
    scaffoldBackgroundColor: backgroundColorDark,
    colorScheme: ColorScheme.dark(
      primary: primaryColorDark,
      secondary: accentColorDark,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      background: backgroundColorDark,
      onBackground: textColorDark,
      surface: const Color(0xFF1E1E1E),
      onSurface: textColorDark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(
        color: textColorDark,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: TextStyle(
        color: textColorDark,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: TextStyle(
        color: textColorDark,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: textColorDark,
        fontWeight: FontWeight.bold,
      ),
      headlineSmall: TextStyle(
        color: textColorDark,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(color: textColorDark, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: textColorDark, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(color: textColorDark, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: textColorDark),
      bodyMedium: TextStyle(color: textColorDark),
      bodySmall: TextStyle(color: Colors.grey.shade400),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColorDark,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColorDark,
        side: const BorderSide(color: primaryColorDark),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColorDark,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: const Color(0xFF2A2A2A),
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColorDark),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor),
      ),
      contentPadding: const EdgeInsets.all(16),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF2A2A2A),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF3A3A3A),
      thickness: 1,
    ),
  );
}
