import 'package:flutter/material.dart';
import 'package:task_track/core/constants/app_colors.dart';
import 'package:task_track/core/constants/app_constants.dart';
import 'package:task_track/shared/widgets/glass_card.dart';

class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.color,
    this.iconSize = 22,
    this.size = AppConstants.minTouchTarget,
    this.level = GlassLevel.control,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;
  final double iconSize;
  final double size;
  final GlassLevel level;

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return Tooltip(
      message: tooltip,
      child: GlassCard(
        level: level,
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(size / 2),
        semanticLabel: tooltip,
        onTap: onPressed,
        child: SizedBox.square(
          dimension: size,
          child: Icon(
            icon,
            size: iconSize,
            color: onPressed == null
                ? p.textSecondary.withValues(alpha: 0.55)
                : color ?? p.iconColor,
          ),
        ),
      ),
    );
  }
}
