import 'package:flutter/material.dart';

/// Semantic color tokens for GramGyan app.
/// Earthy, rural, clean, trustworthy palette —
/// deep agricultural green, soft beige, warm orange accents.
class AppColors {
  AppColors._();

  // ── Primary Palette (Deep Agricultural Green) ──
  static const Color primary = Color(0xFF4A6B2A);
  static const Color primaryLight = Color(0xFF6B8C3E);
  static const Color primaryDark = Color(0xFF2F4A15);
  static const Color primaryMuted = Color(0xFF8DA060);
  static const Color onPrimary = Colors.white;

  // ── Secondary / Accent (Warm Yellow-Orange for alerts) ──
  static const Color secondary = Color(0xFFE8943A);
  static const Color secondaryLight = Color(0xFFF0B060);
  static const Color secondaryDark = Color(0xFFD47B20);
  static const Color onSecondary = Colors.white;

  // ── Accent Orange (for alerts, notifications) ──
  static const Color accent = Color(0xFFE8943A);
  static const Color accentLight = Color(0xFFF5C882);
  static const Color accentDark = Color(0xFFD47B20);

  // ── Surface (Light) — Soft Beige ──
  static const Color surfaceLight = Color(0xFFF4F1E8);
  static const Color cardLight = Color(0xFFF8F6F1);
  static const Color cardGreen = Color(0xFFD6DFC3);
  static const Color cardGreenLight = Color(0xFFE4EBD5);
  static const Color onSurfaceLight = Color(0xFF2C2C2C);
  static const Color onSurfaceVariantLight = Color(0xFF6B6B5E);
  static const Color textSecondary = onSurfaceVariantLight;

  // ── Surface (Dark) ──
  static const Color surfaceDark = Color(0xFF1A1C16);
  static const Color cardDark = Color(0xFF252820);
  static const Color cardGreenDark = Color(0xFF333D28);
  static const Color onSurfaceDark = Color(0xFFE4E1D9);
  static const Color onSurfaceVariantDark = Color(0xFF9E9D8F);

  // ── Functional ──
  static const Color error = Color(0xFFBA1A1A);
  static const Color success = Color(0xFF4A6B2A);
  static const Color warning = Color(0xFFE8943A);
  static const Color info = Color(0xFF4A7B8C);

  // ── Karma ──
  static const Color karma = Color(0xFFD4853A);
  static const Color karmaBackground = Color(0xFFFFF0E0);

  // ── Verified Badge ──
  static const Color verified = Color(0xFF4A7B8C);

  // ── Badge Colors ──
  static const Color badgeGold = Color(0xFFD4A843);
  static const Color badgeBlue = Color(0xFF4A7B8C);
  static const Color badgeOrange = Color(0xFFE8943A);
  static const Color badgePurple = Color(0xFF7B5EA7);

  // ── Map ──
  static const Color mapMarker = Color(0xFFBA1A1A);

  // ── Shimmer ──
  static const Color shimmerBase = Color(0xFFE8E4DC);
  static const Color shimmerHighlight = Color(0xFFF5F2EC);
  static const Color shimmerBaseDark = Color(0xFF2A2D24);
  static const Color shimmerHighlightDark = Color(0xFF363A30);

  // ── Borders & Dividers ──
  static const Color divider = Color(0xFFDDD8CE);
  static const Color dividerDark = Color(0xFF3A3D34);

  // ── Bottom Nav ──
  static const Color navPill = Color(0xFF4A6B2A);
  static const Color navPillLight = Color(0xFFD6DFC3);

  // ── Glass / Frosted ──
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color glassOverlay = Color(0x1A4A6B2A);

  // ── AI Insight ──
  static const Color aiPrimary = Color(0xFF4A7B8C);
  static const Color aiBackground = Color(0xFFE8F4F8);
  static const Color aiBackgroundDark = Color(0xFF1E2D33);
  static const Color confidenceHigh = Color(0xFF4A6B2A);
  static const Color confidenceMedium = Color(0xFFE8943A);
  static const Color confidenceLow = Color(0xFFBA1A1A);
}
