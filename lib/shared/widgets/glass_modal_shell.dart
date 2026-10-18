import 'package:flutter/material.dart';
import 'package:task_track/core/constants/app_colors.dart';
import 'package:task_track/core/constants/app_constants.dart';
import 'package:task_track/shared/widgets/glass_card.dart';

Future<T?> showGlassBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.of(context).scrim,
    builder: builder,
  );
}

Future<T?> showGlassDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool nested = false,
}) {
  final p = AppColors.of(context);
  return showDialog<T>(
    context: context,
    barrierColor: nested ? p.nestedScrim : p.scrim,
    builder: builder,
  );
}

class GlassModalShell extends StatelessWidget {
  const GlassModalShell({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(
      AppConstants.modalPadding,
      AppConstants.spacingXL,
      AppConstants.modalPadding,
      AppConstants.spacingXXL,
    ),
    this.showHandle = true,
    this.height,
    this.maxWidth = 720,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool showHandle;
  final double? height;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final p = AppColors.of(context);
    final topClearance = media.padding.top + AppConstants.spacingXXL;
    final maxHeight =
        (media.size.height - topClearance - media.viewInsets.bottom).clamp(
          0.0,
          media.size.height,
        );
    final contentPadding = padding.copyWith(
      top: padding.top + (showHandle ? AppConstants.spacingMD : 0),
    );

    Widget surface = GlassCard(
      level: GlassLevel.modal,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppConstants.radiusXLarge),
      ),
      padding: EdgeInsets.zero,
      child: SafeArea(
        top: false,
        child: Stack(
          children: [
            Padding(
              padding: contentPadding,
              child: GlassMaterialScope(child: child),
            ),
            if (showHandle)
              Positioned(
                top: AppConstants.spacingMD,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: p.textSecondary.withValues(alpha: 0.38),
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusPill,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (height != null) surface = SizedBox(height: height, child: surface);

    return AnimatedPadding(
      duration: media.disableAnimations
          ? Duration.zero
          : AppConstants.animationFast,
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(
        top: topClearance,
        bottom: media.viewInsets.bottom,
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
          child: surface,
        ),
      ),
    );
  }
}

class GlassDialogShell extends StatelessWidget {
  const GlassDialogShell({
    super.key,
    required this.child,
    this.tintColor,
    this.padding = const EdgeInsets.all(AppConstants.spacingXXL),
    this.maxWidth = 380,
  });

  final Widget child;
  final Color? tintColor;
  final EdgeInsets padding;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingXXL,
        vertical: AppConstants.spacingXXL,
      ),
      clipBehavior: Clip.none,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: GlassCard(
          level: GlassLevel.modal,
          tintColor: tintColor,
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          padding: padding,
          child: GlassMaterialScope(child: child),
        ),
      ),
    );
  }
}
