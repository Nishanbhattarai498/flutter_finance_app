// Font loading utility
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FontLoader {
  /// Preload all commonly needed fonts to avoid missing character issues
  static Future<void> preloadFonts() async {
    await Future.wait([
      _loadFont(GoogleFonts.notoSans),
      _loadFont(GoogleFonts.notoSansSc), // Simplified Chinese
      _loadFont(GoogleFonts.notoSansTc), // Traditional Chinese
      _loadFont(GoogleFonts.notoSansJp), // Japanese
      _loadFont(GoogleFonts.notoSansKr), // Korean
      _loadFont(GoogleFonts.notoSansDevanagari), // Hindi/Sanskrit
      _loadFont(GoogleFonts.notoSansArabic), // Arabic
      _loadFont(GoogleFonts.notoSansThai), // Thai
    ]);

    debugPrint('✅ All Noto fonts preloaded successfully');
  }

  static Future<TextStyle> _loadFont(Function fontFunction) async {
    return await Future.value(fontFunction());
  }

  /// Apply Noto Sans to a standard TextTheme
  static TextTheme createNotoSansTextTheme(TextTheme base) {
    return GoogleFonts.notoSansTextTheme(base);
  }
}
