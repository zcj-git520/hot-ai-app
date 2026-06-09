import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const _seed = Color(0xFF1E3A8A); // 深蓝
  static const _accent = Color(0xFFEA580C); // 橙色强调

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: _seed);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme.copyWith(secondary: _accent),
      textTheme: GoogleFonts.notoSansScTextTheme(),
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme.copyWith(secondary: _accent),
      textTheme: GoogleFonts.notoSansScTextTheme(ThemeData.dark().textTheme),
    );
  }
}
