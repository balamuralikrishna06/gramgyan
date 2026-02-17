import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// Builds light and dark ThemeData for GramGyan.
/// Earthy, rural, trustworthy aesthetic with deep green and soft beige.
class AppTheme {
  AppTheme._();

  // ─────────────────────────── LIGHT ───────────────────────────
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: AppTextStyles.fontFamily,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          primaryContainer: AppColors.cardGreen,
          secondary: AppColors.secondary,
          secondaryContainer: AppColors.secondaryLight,
          tertiary: AppColors.accent,
          surface: AppColors.surfaceLight,
          error: AppColors.error,
          onPrimary: AppColors.onPrimary,
          onSecondary: AppColors.onSecondary,
          onSurface: AppColors.onSurfaceLight,
          onSurfaceVariant: AppColors.onSurfaceVariantLight,
          onError: Colors.white,
          outline: AppColors.divider,
        ),
        scaffoldBackgroundColor: AppColors.surfaceLight,
        cardColor: AppColors.cardLight,
        dividerColor: AppColors.divider,

        // AppBar — transparent / surface colored, dark text
        appBarTheme: AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: AppColors.surfaceLight,
          foregroundColor: AppColors.onSurfaceLight,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ),
          titleTextStyle: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.onSurfaceLight,
          ),
          iconTheme: const IconThemeData(color: AppColors.onSurfaceLight),
        ),

        // Navigation Bar (Material 3)
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.cardLight,
          indicatorColor: AppColors.navPillLight,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppTextStyles.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              );
            }
            return AppTextStyles.labelSmall.copyWith(
              color: AppColors.onSurfaceVariantLight,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: AppColors.primary, size: 24);
            }
            return const IconThemeData(
                color: AppColors.onSurfaceVariantLight, size: 24);
          }),
          elevation: 0,
          height: 68,
        ),

        // FAB
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 6,
          shape: CircleBorder(),
          sizeConstraints: BoxConstraints.tightFor(width: 68, height: 68),
        ),

        // Cards — warm cream with rounded corners (20px)
        cardTheme: CardThemeData(
          color: AppColors.cardLight,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        ),

        // Elevated Button
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            textStyle: AppTextStyles.labelLarge,
            elevation: 0,
          ),
        ),

        // Outlined Button
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            textStyle: AppTextStyles.labelLarge,
          ),
        ),

        // Chip
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.cardLight,
          selectedColor: AppColors.cardGreen,
          labelStyle: AppTextStyles.labelMedium,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24)),
          side: const BorderSide(color: AppColors.divider),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),

        // Input
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.cardLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),

        // Bottom Sheet
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.cardLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
        ),
      );

  // ─────────────────────────── DARK ────────────────────────────
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: AppTextStyles.fontFamily,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primaryLight,
          primaryContainer: AppColors.cardGreenDark,
          secondary: AppColors.secondary,
          secondaryContainer: AppColors.secondaryDark,
          tertiary: AppColors.accent,
          surface: AppColors.surfaceDark,
          error: AppColors.error,
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onSurface: AppColors.onSurfaceDark,
          onSurfaceVariant: AppColors.onSurfaceVariantDark,
          onError: Colors.white,
          outline: AppColors.dividerDark,
        ),
        scaffoldBackgroundColor: AppColors.surfaceDark,
        cardColor: AppColors.cardDark,
        dividerColor: AppColors.dividerDark,

        appBarTheme: AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: AppColors.surfaceDark,
          foregroundColor: AppColors.onSurfaceDark,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
          titleTextStyle: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.onSurfaceDark,
          ),
          iconTheme: const IconThemeData(color: AppColors.onSurfaceDark),
        ),

        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.cardDark,
          indicatorColor: AppColors.cardGreenDark,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppTextStyles.labelSmall.copyWith(
                color: AppColors.primaryLight,
                fontWeight: FontWeight.w700,
              );
            }
            return AppTextStyles.labelSmall.copyWith(
              color: AppColors.onSurfaceVariantDark,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(
                  color: AppColors.primaryLight, size: 24);
            }
            return const IconThemeData(
                color: AppColors.onSurfaceVariantDark, size: 24);
          }),
          elevation: 0,
          height: 68,
        ),

        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: Colors.black,
          elevation: 6,
          shape: CircleBorder(),
          sizeConstraints: BoxConstraints.tightFor(width: 68, height: 68),
        ),

        cardTheme: CardThemeData(
          color: AppColors.cardDark,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryLight,
            foregroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            textStyle: AppTextStyles.labelLarge,
            elevation: 0,
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryLight,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            side: const BorderSide(
                color: AppColors.primaryLight, width: 1.5),
            textStyle: AppTextStyles.labelLarge,
          ),
        ),

        chipTheme: ChipThemeData(
          backgroundColor: AppColors.cardDark,
          selectedColor: AppColors.cardGreenDark,
          labelStyle: AppTextStyles.labelMedium,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24)),
          side: const BorderSide(color: AppColors.dividerDark),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.cardDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.dividerDark),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.dividerDark),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
                color: AppColors.primaryLight, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),

        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
        ),
      );
}
