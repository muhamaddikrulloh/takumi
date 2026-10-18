import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:task_track/core/constants/app_colors.dart';
import 'package:task_track/core/constants/app_constants.dart';
import 'package:task_track/core/localization/app_translations.dart';
import 'package:task_track/shared/widgets/neon_button.dart';
import 'package:task_track/shared/widgets/glass_card.dart';

class ErrorView extends StatelessWidget {
  final VoidCallback? onRetry;

  const ErrorView({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingSection),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GlassCard(
              level: GlassLevel.subtle,
              tintColor: p.destructive,
              borderColor: p.destructive.withValues(alpha: 0.28),
              padding: EdgeInsets.zero,
              borderRadius: BorderRadius.circular(36),
              child: SizedBox.square(
                dimension: 72,
                child: Icon(
                  PhosphorIconsRegular.warningCircle,
                  size: 32,
                  color: p.destructive,
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacingLG),
            Text(
              context.tr('error_generic'),
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: p.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppConstants.spacingXXL),
              SizedBox(
                width: 160,
                child: NeonButton(
                  label: context.tr('retry'),
                  onPressed: onRetry,
                  type: NeonButtonType.secondary,
                  icon: PhosphorIconsRegular.arrowsClockwise,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
