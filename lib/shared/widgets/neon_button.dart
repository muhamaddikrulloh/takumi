import 'package:flutter/material.dart';
import 'package:task_track/core/constants/app_colors.dart';
import 'package:task_track/core/constants/app_constants.dart';
import 'package:task_track/shared/widgets/glass_card.dart';

enum NeonButtonType { primary, secondary, inProgress, completed, danger }

class NeonButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final NeonButtonType type;
  final bool isLoading;
  final IconData? icon;
  final Widget? leading;

  const NeonButton({
    super.key,
    required this.label,
    this.onPressed,
    this.type = NeonButtonType.primary,
    this.isLoading = false,
    this.icon,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);

    final Color backgroundColor;
    switch (type) {
      case NeonButtonType.primary:
        backgroundColor = p.primaryOrange;
      case NeonButtonType.secondary:
        backgroundColor = p.glassFill;
      case NeonButtonType.inProgress:
        backgroundColor = p.primaryOrange;
      case NeonButtonType.completed:
        backgroundColor = p.statusCompleted;
      case NeonButtonType.danger:
        backgroundColor = p.destructive.withValues(alpha: 0.12);
    }

    final Color borderColor;
    switch (type) {
      case NeonButtonType.primary:
        borderColor = p.primaryOrange;
      case NeonButtonType.secondary:
        borderColor = p.glassBorder;
      case NeonButtonType.inProgress:
        borderColor = p.primaryOrange;
      case NeonButtonType.completed:
        borderColor = p.statusCompleted;
      case NeonButtonType.danger:
        borderColor = p.destructive.withValues(alpha: 0.28);
    }

    final Color textColor;
    switch (type) {
      case NeonButtonType.primary:
        textColor = p.onPrimary;
      case NeonButtonType.secondary:
        textColor = p.textPrimary;
      case NeonButtonType.inProgress:
        textColor = p.onPrimary;
      case NeonButtonType.completed:
        textColor = p.onSuccess;
      case NeonButtonType.danger:
        textColor = p.destructive;
    }

    final button = SizedBox(
      width: double.infinity,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppConstants.controlHeight,
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: type == NeonButtonType.secondary
                ? Colors.transparent
                : backgroundColor,
            foregroundColor: textColor,
            disabledBackgroundColor: backgroundColor.withValues(alpha: 0.62),
            disabledForegroundColor: textColor.withValues(alpha: 0.7),
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingLG,
              vertical: AppConstants.spacingMD,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              side: BorderSide(
                color: type == NeonButtonType.secondary
                    ? Colors.transparent
                    : borderColor,
              ),
            ),
            shadowColor: p.shadowDark,
            elevation: 0,
          ),
          child: isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: textColor,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (leading != null) ...[
                      leading!,
                      const SizedBox(width: AppConstants.spacingSM),
                    ] else if (icon != null) ...[
                      Icon(icon, size: 20),
                      const SizedBox(width: AppConstants.spacingSM),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: AppConstants.fontButton,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
    return type == NeonButtonType.secondary
        ? GlassCard(
            level: GlassLevel.control,
            padding: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            child: button,
          )
        : button;
  }
}
