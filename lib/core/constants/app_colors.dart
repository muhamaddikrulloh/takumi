import 'package:flutter/material.dart';

/// Single source of truth for all colors.
///
/// Never hardcode `Colors.white.withValues(...)` or raw hex outside this file.
/// Access the application's palette via [AppColors.of].
class AppPalette {
  const AppPalette({
    required this.backgroundPrimary,
    required this.backgroundDark,
    required this.primaryOrange,
    required this.accentViolet,
    required this.textPrimary,
    required this.textSecondary,
    required this.statusPending,
    required this.statusCompleted,
    required this.statusPendingForeground,
    required this.statusProgressForeground,
    required this.statusCompletedForeground,
    required this.destructive,
    required this.onPrimary,
    required this.onSuccess,
    required this.onDestructive,
    required this.glassFillSubtle,
    required this.glassFill,
    required this.glassFillStrong,
    required this.glassBorder,
    required this.glassHighlight,
    required this.shadowDark,
    required this.iconColor,
    required this.divider,
    required this.modalSurface,
    required this.progressTrack,
    required this.scrim,
    required this.nestedScrim,
  });

  final Color backgroundPrimary;
  final Color backgroundDark;
  final Color primaryOrange;
  final Color accentViolet;
  final Color textPrimary;
  final Color textSecondary;
  final Color statusPending;
  final Color statusCompleted;
  final Color statusPendingForeground;
  final Color statusProgressForeground;
  final Color statusCompletedForeground;
  final Color destructive;
  final Color onPrimary;
  final Color onSuccess;
  final Color onDestructive;
  final Color glassFillSubtle;
  final Color glassFill;
  final Color glassFillStrong;
  final Color glassBorder;
  final Color glassHighlight;
  final Color shadowDark;
  final Color iconColor;
  final Color divider;
  final Color modalSurface;
  final Color progressTrack;
  final Color scrim;
  final Color nestedScrim;

  /// Cool near-black instead of a flat #121212.
  static const dark = AppPalette(
    backgroundPrimary: Color(0xFF101014),
    backgroundDark: Color(0xFF0A0A0E),
    primaryOrange: AppColors.primaryOrange,
    accentViolet: Color(0xFF9773FF),
    textPrimary: Color(0xFFECEDF1),
    textSecondary: Color(0xFFA2A8B4),
    statusPending: Color(0xFFF05252),
    statusCompleted: Color(0xFF2FBF8F),
    statusPendingForeground: Color(0xFFF05252),
    statusProgressForeground: AppColors.primaryOrange,
    statusCompletedForeground: Color(0xFF2FBF8F),
    destructive: Color(0xFFF05252),
    onPrimary: Color(0xFF0A0A0E),
    onSuccess: Color(0xFF0A0A0E),
    onDestructive: Color(0xFFECEDF1),
    glassFillSubtle: Color(0x0CFFFFFF),
    glassFill: Color(0x0FFFFFFF),
    glassFillStrong: Color(0x17FFFFFF),
    glassBorder: Color(0x16FFFFFF),
    glassHighlight: Color(0x54FFFFFF),
    shadowDark: Color(0x4D000000),
    iconColor: Color(0xFFDFE2E8),
    divider: Color(0x24FFFFFF),
    modalSurface: Color(0xAD101014),
    progressTrack: Color(0x24FFFFFF),
    scrim: Color(0x990A0A0E),
    nestedScrim: Color(0x520A0A0E),
  );
}

/// Accessor for the application's fixed dark palette.
class AppColors {
  /// Shared orange for the center FAB, primary actions, and in-progress state.
  static const Color primaryOrange = Color(0xFFFFB020);

  AppColors._();

  static AppPalette of(BuildContext _) => AppPalette.dark;
}
