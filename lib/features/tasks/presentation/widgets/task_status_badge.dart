import 'package:flutter/material.dart';
import 'package:task_track/core/constants/app_colors.dart';
import 'package:task_track/core/constants/app_constants.dart';
import 'package:task_track/core/localization/app_translations.dart';
import 'package:task_track/core/utils/status_helper.dart';
import 'package:task_track/features/tasks/domain/task_status.dart';
import 'package:task_track/shared/widgets/glass_card.dart';

class TaskStatusBadge extends StatelessWidget {
  final TaskStatus status;
  final bool larger;

  const TaskStatusBadge({super.key, required this.status, this.larger = false});

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final color = StatusHelper.getColor(status, p);
    final foreground = StatusHelper.getForegroundColor(status, p);
    final label = context.tr(StatusHelper.getLabelKey(status));

    return GlassCard(
      level: GlassLevel.control,
      blurEnabled: false,
      tintColor: color,
      borderColor: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
      padding: EdgeInsets.symmetric(
        horizontal: larger ? 12 : 8,
        vertical: larger ? 6 : 4,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: AppConstants.fontBadge,
          fontWeight: FontWeight.w600,
          color: foreground,
          height: 1.2,
        ),
      ),
    );
  }
}
