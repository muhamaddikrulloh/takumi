import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:task_track/core/constants/app_colors.dart';
import 'package:task_track/core/constants/app_constants.dart';
import 'package:task_track/core/localization/app_translations.dart';
import 'package:task_track/core/utils/date_formatter.dart';
import 'package:task_track/core/utils/status_helper.dart';
import 'package:task_track/features/tasks/domain/task.dart';
import 'package:task_track/features/tasks/providers/reminder_provider.dart';
import 'package:task_track/features/tasks/providers/task_provider.dart';
import 'package:task_track/shared/widgets/empty_state.dart';
import 'package:task_track/shared/widgets/error_view.dart';
import 'package:task_track/shared/widgets/glass_card.dart';
import 'package:task_track/shared/widgets/glass_modal_shell.dart';

class NotificationSheet extends ConsumerWidget {
  const NotificationSheet({super.key});

  static Future<Task?> show(BuildContext context) {
    return showGlassBottomSheet<Task>(
      context,
      builder: (context) => const NotificationSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = AppColors.of(context);
    final remindersAsync = ref.watch(remindersProvider);

    return GlassModalShell(
      height: MediaQuery.sizeOf(context).height * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('notifications'),
            style: TextStyle(
              fontSize: AppConstants.fontSection,
              fontWeight: FontWeight.w700,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingMD),
          Expanded(
            child: remindersAsync.when(
              data: (reminders) {
                if (reminders.isEmpty) {
                  return EmptyState(
                    icon: PhosphorIconsRegular.bellSlash,
                    title: context.tr('no_notifications'),
                    subtitle: context.tr('no_notifications_subtitle'),
                  );
                }
                return ListView.separated(
                  itemCount: reminders.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppConstants.spacingMD),
                  itemBuilder: (context, index) {
                    final task = reminders[index];
                    return _ReminderRow(
                      task: task,
                      onTap: () => Navigator.of(context).pop(task),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (_, _) =>
                  ErrorView(onRetry: () => ref.invalidate(taskListProvider)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;

  const _ReminderRow({required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final statusColor = StatusHelper.getColor(task.status, p);
    final now = DateTime.now();
    final timeUntilDeadline = task.deadline.difference(now);
    final isOverdue = timeUntilDeadline.isNegative;
    final isDueSoon = !isOverdue && timeUntilDeadline < const Duration(days: 1);
    final deadlineColor = isOverdue
        ? p.destructive
        : isDueSoon
        ? p.statusProgressForeground
        : p.textSecondary;
    final deadlineLabel = DateFormatter.formatDeadline(
      context,
      task.deadline,
      now,
    );

    return GlassCard(
      level: GlassLevel.control,
      tintColor: statusColor,
      semanticLabel: '${task.title}, ${task.subject}, $deadlineLabel',
      onTap: onTap,
      padding: const EdgeInsets.all(AppConstants.spacingLG),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stackDeadline =
              constraints.maxWidth < 300 ||
              MediaQuery.textScalerOf(context).scale(1) > 1.2;
          final details = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: AppConstants.spacingSM,
                height: AppConstants.spacingSM,
                margin: const EdgeInsets.only(top: AppConstants.spacingSM),
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppConstants.spacingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: AppConstants.fontTask,
                        fontWeight: FontWeight.w600,
                        color: p.textPrimary,
                        height: 1.25,
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
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          );
          final deadline = GlassCard(
            level: GlassLevel.control,
            blurEnabled: false,
            tintColor: deadlineColor,
            borderColor: deadlineColor.withValues(alpha: 0.12),
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingSM,
              vertical: AppConstants.spacingXS,
            ),
            borderRadius: BorderRadius.circular(AppConstants.radiusPill),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  PhosphorIconsRegular.clock,
                  size: 14,
                  color: deadlineColor,
                ),
                const SizedBox(width: AppConstants.spacingXS),
                Text(
                  deadlineLabel,
                  style: TextStyle(
                    fontSize: AppConstants.fontSecondary,
                    fontWeight: FontWeight.w600,
                    color: deadlineColor,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          );

          if (stackDeadline) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                details,
                const SizedBox(height: AppConstants.spacingMD),
                Padding(
                  padding: const EdgeInsets.only(left: AppConstants.spacingXL),
                  child: deadline,
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: details),
              const SizedBox(width: AppConstants.spacingMD),
              deadline,
            ],
          );
        },
      ),
    );
  }
}
