import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Web-consistent palette - matches web dark header style
  static const _primary = Color(0xFF2563EB);    // Blue
  static const _background = Color(0xFFF8FAFC); // Light gray
  static const _surface = Color(0xFFFFFFFF);     // White
  static const _cardBg = Color(0xFFF1F5F9);      // Web-style card bg
  static const _border = Color(0xFFE2E8F0);      // Light border
  static const _darkHeader = Color(0xFF1E293B);  // Web dark header

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: _primary,
        secondary: Color(0xFF64748B),
        surface: _surface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF1E293B),
      ),
      scaffoldBackgroundColor: _background,
      textTheme: _buildTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: _darkHeader,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.notoSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: _surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _border),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _surface,
        elevation: 0,
        indicatorColor: _primary.withOpacity(0.1),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.notoSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _primary,
            );
          }
          return GoogleFonts.notoSans(
            fontSize: 12,
            color: const Color(0xFF64748B),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: _primary, size: 24);
          }
          return const IconThemeData(color: Color(0xFF64748B), size: 24);
        }),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF64748B)),
      dividerColor: _border,
    );
  }

  static TextTheme _buildTextTheme() {
    return TextTheme(
      headlineLarge: GoogleFonts.notoSans(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1E293B),
      ),
      headlineMedium: GoogleFonts.notoSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1E293B),
      ),
      titleLarge: GoogleFonts.notoSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1E293B),
      ),
      titleMedium: GoogleFonts.notoSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF1E293B),
      ),
      bodyLarge: GoogleFonts.notoSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF64748B),
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.notoSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF64748B),
        height: 1.5,
      ),
    );
  }
}

// Category colors - web consistent
class CategoryColors {
  static const primary = Color(0xFF2563EB);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const info = Color(0xFF06B6D4);
  static const secondary = Color(0xFF64748B);

  static Color getColor(String? category) {
    switch (category) {
      case '技术': return primary;
      case '职业': return warning;
      case '工具': return info;
      case '学习': return success;
      default: return secondary;
    }
  }
}
