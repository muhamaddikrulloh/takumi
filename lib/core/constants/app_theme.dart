import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_constants.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme => _build();

  static ThemeData _build() {
    const p = AppPalette.dark;
    final textTheme = ThemeData.dark().textTheme.apply(
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      bodyColor: p.textPrimary,
      displayColor: p.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: p.backgroundPrimary,
      canvasColor: Colors.transparent,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: p.primaryOrange,
        onPrimary: p.onPrimary,
        secondary: p.accentViolet,
        onSecondary: p.textPrimary,
        error: p.destructive,
        onError: p.onDestructive,
        surface: p.backgroundPrimary,
        onSurface: p.textPrimary,
        scrim: p.scrim,
      ),
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      textTheme: textTheme.copyWith(
        displaySmall: GoogleFonts.plusJakartaSans(
          fontSize: AppConstants.fontDisplay,
          fontWeight: FontWeight.w700,
          height: 1.16,
          color: p.textPrimary,
        ),
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: AppConstants.fontTitle,
          fontWeight: FontWeight.w700,
          height: 1.2,
          color: p.textPrimary,
        ),
        headlineSmall: GoogleFonts.plusJakartaSans(
          fontSize: AppConstants.fontSection,
          fontWeight: FontWeight.w600,
          height: 1.25,
          color: p.textPrimary,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: AppConstants.fontTask,
          fontWeight: FontWeight.w600,
          height: 1.3,
          color: p.textPrimary,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: AppConstants.fontBodyLarge,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: p.textPrimary,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: AppConstants.fontBody,
          fontWeight: FontWeight.w400,
          height: 1.45,
          color: p.textPrimary,
        ),
        bodySmall: GoogleFonts.plusJakartaSans(
          fontSize: AppConstants.fontMetadata,
          fontWeight: FontWeight.w400,
          height: 1.4,
          color: p.textSecondary,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: AppConstants.fontButton,
          fontWeight: FontWeight.w600,
          height: 1.2,
          color: p.textPrimary,
        ),
        labelMedium: GoogleFonts.plusJakartaSans(
          fontSize: AppConstants.fontBadge,
          fontWeight: FontWeight.w600,
          height: 1.2,
          color: p.textSecondary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.transparent,
        hintStyle: textTheme.bodyMedium?.copyWith(color: p.textSecondary),
        labelStyle: textTheme.bodyMedium?.copyWith(color: p.textSecondary),
        errorStyle: textTheme.bodySmall?.copyWith(color: p.destructive),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          borderSide: BorderSide(color: p.primaryOrange, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          borderSide: BorderSide(color: p.destructive, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          borderSide: BorderSide(color: p.destructive, width: 1.2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingLG,
          vertical: AppConstants.spacingLG,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, AppConstants.controlHeight),
          elevation: 0,
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: p.primaryOrange,
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, AppConstants.controlHeight),
          foregroundColor: p.textPrimary,
          side: BorderSide.none,
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: p.divider, thickness: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.primaryOrange,
        linearTrackColor: p.progressTrack,
        circularTrackColor: p.progressTrack,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        modalBackgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: p.scrim,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        barrierColor: p.scrim,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusXLarge),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.modalSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        ),
        textStyle: textTheme.bodyMedium,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: p.modalSurface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: p.glassFillStrong,
        headerForegroundColor: p.textPrimary,
        todayForegroundColor: WidgetStatePropertyAll(p.primaryOrange),
        todayBorder: BorderSide(color: p.primaryOrange),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? p.primaryOrange : null;
        }),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return p.onPrimary;
          if (states.contains(WidgetState.disabled)) {
            return p.textSecondary.withValues(alpha: 0.45);
          }
          return p.textPrimary;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusXLarge),
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: p.modalSurface,
        dialBackgroundColor: p.glassFillStrong,
        dialHandColor: p.primaryOrange,
        entryModeIconColor: p.primaryOrange,
        hourMinuteColor: p.glassFillStrong,
        hourMinuteTextColor: p.textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusXLarge),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: p.modalSurface,
          borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: p.textPrimary),
      ),
      splashColor: p.primaryOrange.withValues(alpha: 0.08),
      highlightColor: p.primaryOrange.withValues(alpha: 0.04),
    );
  }
}
