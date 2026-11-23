import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// One place for every color in the app, so all pages look the same.
class AppColors {
  static const bg = Color(0xFF120F1D);
  static const bgDeep = Color(0xFF0B0914);
  static const surface = Color(0xFF1C182B);
  static const surfaceHigh = Color(0xFF262139);
  static const stroke = Color(0x1FFFFFFF);
  static const violet = Color(0xFF7B5CFF);
  static const lilac = Color(0xFFB79CFF);
  static const peach = Color(0xFFFF9E7A);
  static const mint = Color(0xFF6EE7B7);
  static const gold = Color(0xFFFFD166);
  static const text = Color(0xFFF5F1FF);
  static const textMuted = Color(0xFFA9A2C0);
  static const danger = Color(0xFFFF6B81);

  static const brandGradient = LinearGradient(
    colors: [violet, lilac, peach],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const mutedGradient = LinearGradient(
    colors: [Color(0xFF3A3450), Color(0xFF2E2942)],
  );
}

/// Fonts: Fraunces (elegant serif) for headings, Manrope for body text.
class AppText {
  static TextStyle display(double size,
          {Color color = AppColors.text, FontWeight weight = FontWeight.w600}) =>
      GoogleFonts.fraunces(
          fontSize: size, fontWeight: weight, color: color, height: 1.15, letterSpacing: -0.3);

  static TextStyle body(double size,
          {Color color = AppColors.text, FontWeight weight = FontWeight.w500}) =>
      GoogleFonts.manrope(fontSize: size, fontWeight: weight, color: color);
}

ThemeData buildTheme() {
  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c, width: w),
      );

  final base = ThemeData(useMaterial3: true, brightness: Brightness.dark);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.lilac,
      onPrimary: AppColors.bgDeep,
      secondary: AppColors.peach,
      onSecondary: AppColors.bgDeep,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      error: AppColors.danger,
    ),
    textTheme: GoogleFonts.manropeTextTheme(base.textTheme)
        .apply(bodyColor: AppColors.text, displayColor: AppColors.text),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(color: AppColors.textMuted),
      floatingLabelStyle: const TextStyle(color: AppColors.lilac, fontWeight: FontWeight.w600),
      hintStyle: const TextStyle(color: AppColors.textMuted),
      prefixIconColor: AppColors.textMuted,
      suffixIconColor: AppColors.textMuted,
      border: border(AppColors.stroke),
      enabledBorder: border(AppColors.stroke),
      focusedBorder: border(AppColors.lilac, 1.6),
      errorBorder: border(AppColors.danger),
      focusedErrorBorder: border(AppColors.danger, 1.6),
      errorStyle: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.surfaceHigh,
      contentTextStyle: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600),
      actionTextColor: AppColors.lilac,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.lilac,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      side: const BorderSide(color: AppColors.textMuted, width: 1.5),
      fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.lilac : Colors.transparent),
      checkColor: const WidgetStatePropertyAll(AppColors.bgDeep),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: AppColors.lilac,
      inactiveTrackColor: Colors.white.withOpacity(0.12),
      thumbColor: AppColors.peach,
      overlayColor: AppColors.peach.withOpacity(0.18),
      valueIndicatorColor: AppColors.surfaceHigh,
      valueIndicatorTextStyle: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w700),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.lilac),
  );
}
