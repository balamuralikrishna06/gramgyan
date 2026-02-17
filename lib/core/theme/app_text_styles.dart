import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography scale for GramGyan.
/// Uses Nunito — rounded, friendly, highly readable for a rural audience.
class AppTextStyles {
  AppTextStyles._();

  static String get fontFamily => GoogleFonts.nunito().fontFamily!;

  // ── Display ──
  static TextStyle displayLarge = GoogleFonts.nunito(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static TextStyle displayMedium = GoogleFonts.nunito(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.25,
    height: 1.25,
  );

  // ── Headlines ──
  static TextStyle headlineLarge = GoogleFonts.nunito(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  static TextStyle headlineMedium = GoogleFonts.nunito(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static TextStyle headlineSmall = GoogleFonts.nunito(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  // ── Title ──
  static TextStyle titleLarge = GoogleFonts.nunito(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static TextStyle titleMedium = GoogleFonts.nunito(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static TextStyle titleSmall = GoogleFonts.nunito(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  // ── Body ──
  static TextStyle bodyLarge = GoogleFonts.nunito(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle bodyMedium = GoogleFonts.nunito(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle bodySmall = GoogleFonts.nunito(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  // ── Labels ──
  static TextStyle labelLarge = GoogleFonts.nunito(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static TextStyle labelMedium = GoogleFonts.nunito(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  static TextStyle labelSmall = GoogleFonts.nunito(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );
}
