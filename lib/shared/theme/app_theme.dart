import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Midnight & Aurora Palette
  static const Color midnightNavy = Color(0xFF020817);
  static const Color arcticBlue = Color(0xFF3B82F6);
  static const Color electricCyan = Color(0xFF06B6D4);
  static const Color glassWhite = Color(0xFFF8FAFC);
  static const Color auroraPurple = Color(0xFF8B5CF6);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: arcticBlue,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: arcticBlue,
        brightness: Brightness.light,
        primary: arcticBlue,
        secondary: electricCyan,
        surface: glassWhite,
      ),
      textTheme: GoogleFonts.outfitTextTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: midnightNavy),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: arcticBlue,
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, 64.h),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
          elevation: 8,
          shadowColor: arcticBlue.withOpacity(0.3),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: arcticBlue,
      scaffoldBackgroundColor: midnightNavy,
      colorScheme: ColorScheme.fromSeed(
        seedColor: arcticBlue,
        brightness: Brightness.dark,
        surface: const Color(0xFF0F172A),
        primary: arcticBlue,
        secondary: auroraPurple,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: arcticBlue,
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, 64.h),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
          elevation: 0,
        ),
      ),
    );
  }
}
