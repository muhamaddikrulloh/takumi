import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:task_track/core/constants/app_colors.dart';
import 'package:task_track/core/constants/app_constants.dart';
import 'package:task_track/core/localization/app_translations.dart';
import 'package:task_track/core/utils/date_formatter.dart';
import 'package:task_track/core/utils/status_helper.dart';
import 'package:task_track/features/tasks/domain/task.dart';
import 'package:task_track/features/tasks/domain/task_status.dart';
import 'package:task_track/features/tasks/presentation/widgets/task_progress_bar.dart';
import 'package:task_track/features/tasks/presentation/widgets/task_status_badge.dart';
import 'package:task_track/shared/widgets/glass_card.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;

  const TaskCard({super.key, required this.task, this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final isOverdue = task.deadline.isBefore(DateTime.now());
    final isUrgent =
        task.status != TaskStatus.done &&
        (isOverdue || DateFormatter.isUrgent(task.deadline));
    final statusColor = StatusHelper.getColor(task.status, p);
    final statusForeground = StatusHelper.getForegroundColor(task.status, p);

    return GlassCard(
      level: GlassLevel.standard,
      groupedBlur: true,
      onTap: onTap,
      semanticLabel:
          '${task.title}, ${task.subject}, ${DateFormatter.formatDeadline(context, task.deadline)}, ${context.tr(StatusHelper.getLabelKey(task.status))}',
      padding: const EdgeInsets.all(AppConstants.spacingLG),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
            ),
            child: Icon(
              PhosphorIconsRegular.clipboardText,
              color: statusForeground,
              size: 24,
            ),
          ),
          const SizedBox(width: AppConstants.spacingMD),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final textScale = MediaQuery.textScalerOf(context).scale(1);
                final stackMetadata =
                    constraints.maxWidth < 210 || textScale > 1.3;
                final deadline = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PhosphorIconsRegular.clock,
                      size: 14,
                      color: isUrgent
                          ? p.destructive
                          : p.textSecondary.withValues(alpha: 0.96),
                    ),
                    const SizedBox(width: AppConstants.spacingXS),
                    Flexible(
                      child: Text(
                        DateFormatter.formatDeadline(context, task.deadline),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: AppConstants.fontMetadata,
                          color: isUrgent
                              ? p.destructive
                              : p.textSecondary.withValues(alpha: 0.96),
                          fontWeight: isUrgent
                              ? FontWeight.w600
                              : FontWeight.w500,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: AppConstants.fontTask,
                        fontWeight: FontWeight.w600,
                        color: p.textPrimary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppConstants.spacingXS),
                    Text(
                      task.subject,
                      style: TextStyle(
                        fontSize: AppConstants.fontMetadata,
                        color: p.textSecondary,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppConstants.spacingMD),
                    if (stackMetadata) ...[
                      deadline,
                      const SizedBox(height: AppConstants.spacingSM),
                      TaskStatusBadge(status: task.status),
                    ] else
                      Row(
                        children: [
                          Expanded(child: deadline),
                          const SizedBox(width: AppConstants.spacingSM),
                          TaskStatusBadge(status: task.status),
                        ],
                      ),
                    const SizedBox(height: AppConstants.spacingSM),
                    Row(
                      children: [
                        Expanded(child: TaskProgressBar(status: task.status)),
                        const SizedBox(width: AppConstants.spacingSM),
                        Text(
                          StatusHelper.getPercentLabel(task.status),
                          style: TextStyle(
                            fontSize: AppConstants.fontSecondary,
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
