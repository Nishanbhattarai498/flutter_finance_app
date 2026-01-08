import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Sleek neo-card palette
  static const Color primaryColor = Color(0xFF0F3D91); // Deep vivid blue
  static const Color secondaryColor = Color(0xFF12B0A5); // Teal glow
  static const Color accentColor = Color(0xFFFF6B6B); // Coral contrast
  static const Color mistColor = Color(0x99FFFFFF); // Translucent glass

  // Semantic
  static const Color errorColor = Color(0xFFFF5A5F);
  static const Color successColor = Color(0xFF1DD1A1);
  static const Color warningColor = Color(0xFFFFC75F);
  static const Color infoColor = Color(0xFF00A3FF);

  // Backgrounds
  static const Color backgroundColor = Color(0xFFF3F6FF);
  static const Color backgroundColorDark = Color(0xFF0B1224);

  // Surfaces
  static const Color surfaceColor = Colors.white;
  static const Color surfaceColorDark = Color(0xFF12192D);

  // Text
  static const Color textColor = Color(0xFF0B1B3D);
  static const Color textColorDark = Color(0xFFE6EDFF);
  static const Color textSecondaryColor = Color(0xFF4A5A7A);
  static const Color textSecondaryColorDark = Color(0xFFA5B8D8);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0F3D91), Color(0xFF0B7FD6), Color(0xFF12B0A5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradientLight = LinearGradient(
    colors: [Color(0xCCFFFFFF), Color(0xB3FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradientDark = LinearGradient(
    colors: [Color(0x1AFFFFFF), Color(0x33FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkSurfaceGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF0B1224)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Typography - Space Grotesk for bold, modern shapes
  static TextTheme _createTextTheme(Color color, Color secondaryColor) {
    return GoogleFonts.spaceGroteskTextTheme(
      TextTheme(
        displayLarge: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: -1.2,
        ),
        displayMedium: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: -0.8,
        ),
        displaySmall: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: -0.6,
        ),
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: color,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: color,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: color,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: color,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: color,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: color,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: secondaryColor,
          letterSpacing: 0.1,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  static CardThemeData _glassCardTheme({required bool isDark}) {
    return CardThemeData(
      color: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.white.withOpacity(0.6),
          width: 1,
        ),
      ),
      margin: const EdgeInsets.only(bottom: 16),
    );
  }

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        error: errorColor,
        background: backgroundColor,
        surface: surfaceColor,
        onPrimary: Colors.white,
        onSurface: textColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
      cardTheme: _glassCardTheme(isDark: false),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
          textStyle: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: TextStyle(color: textSecondaryColor.withOpacity(0.7)),
        labelStyle:
            TextStyle(color: textSecondaryColor, fontWeight: FontWeight.w600),
      ),
      textTheme: _createTextTheme(textColor, textSecondaryColor),
      dividerTheme: DividerThemeData(
        color: Colors.black.withOpacity(0.04),
        thickness: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white.withOpacity(0.7),
        indicatorColor: secondaryColor.withOpacity(0.15),
        elevation: 0,
        labelTextStyle: MaterialStateProperty.all(
          GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600, fontSize: 12),
        ),
        iconTheme:
            MaterialStateProperty.all(const IconThemeData(color: textColor)),
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        error: errorColor,
        background: backgroundColorDark,
        surface: surfaceColorDark,
        onPrimary: Colors.white,
        onSurface: textColorDark,
      ),
      scaffoldBackgroundColor: backgroundColorDark,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textColorDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textColorDark,
        ),
      ),
      cardTheme: _glassCardTheme(isDark: true),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
          textStyle: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColorDark.withOpacity(0.7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: secondaryColor, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: TextStyle(color: textSecondaryColorDark.withOpacity(0.8)),
        labelStyle: TextStyle(
            color: textSecondaryColorDark, fontWeight: FontWeight.w600),
      ),
      textTheme: _createTextTheme(textColorDark, textSecondaryColorDark),
      dividerTheme: DividerThemeData(
        color: Colors.white.withOpacity(0.08),
        thickness: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColorDark.withOpacity(0.8),
        indicatorColor: secondaryColor.withOpacity(0.2),
        elevation: 0,
        labelTextStyle: MaterialStateProperty.all(
          GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w600, fontSize: 12, color: textColorDark),
        ),
        iconTheme: MaterialStateProperty.all(
            const IconThemeData(color: textColorDark)),
      ),
    );
  }
}
