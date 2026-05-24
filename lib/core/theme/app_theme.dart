import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.deepNavy,
      colorScheme: const ColorScheme.dark(
        primary:   AppColors.electricBlue,
        secondary: AppColors.emerald,
        surface:   AppColors.navyLight,
        error:     AppColors.danger,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
            fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white),
        headlineMedium: GoogleFonts.plusJakartaSans(
            fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
        bodyMedium: GoogleFonts.plusJakartaSans(
            fontSize: 13, color: AppColors.textSecondary),
      ),
    );
  }
}