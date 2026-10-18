import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:task_track/core/constants/app_colors.dart';
import 'package:task_track/core/constants/app_constants.dart';
import 'package:task_track/core/localization/app_translations.dart';
import 'package:task_track/core/utils/date_formatter.dart';
import 'package:task_track/core/utils/status_helper.dart';
import 'package:task_track/features/tasks/domain/task.dart';
import 'package:task_track/features/tasks/domain/task_status.dart';
import 'package:task_track/features/tasks/presentation/modals/task_form_modal.dart';
import 'package:task_track/features/tasks/presentation/widgets/task_progress_bar.dart';
import 'package:task_track/features/tasks/presentation/widgets/task_status_badge.dart';
import 'package:task_track/features/tasks/providers/task_provider.dart';
import 'package:task_track/shared/widgets/action_confirmation_dialog.dart';
import 'package:task_track/shared/widgets/app_feedback.dart';
import 'package:task_track/shared/widgets/glass_card.dart';
import 'package:task_track/shared/widgets/glass_icon_button.dart';
import 'package:task_track/shared/widgets/glass_modal_shell.dart';
import 'package:task_track/shared/widgets/neon_button.dart';

class TaskDetailModal extends ConsumerStatefulWidget {
  final Task task;

  const TaskDetailModal({super.key, required this.task});

  static Future<void> show(BuildContext context, Task task) {
    return showGlassBottomSheet(
      context,
      builder: (context) => TaskDetailModal(task: task),
    );
  }

  @override
  ConsumerState<TaskDetailModal> createState() => _TaskDetailModalState();
}

enum _TaskMutation { status, delete }

class _TaskDetailModalState extends ConsumerState<TaskDetailModal> {
  _TaskMutation? _mutation;

  Future<void> _quickUpdateStatus(TaskStatus newStatus) async {
    if (_mutation != null) return;
    setState(() => _mutation = _TaskMutation.status);
    try {
      await ref
          .read(taskListProvider.notifier)
          .updateTaskStatus(widget.task.id, newStatus);
    } catch (_) {
      if (!mounted) return;
      setState(() => _mutation = null);
      _showMutationError();
      return;
    }
    if (mounted) {
      AppFeedback.show(
        context,
        message: context.tr('task_status_updated'),
        type: AppFeedbackType.success,
        aboveNavigation: true,
      );
      Navigator.pop(context);
    }
  }

  Future<void> _deleteTask() async {
    if (_mutation != null) return;
    setState(() => _mutation = _TaskMutation.delete);
    final confirm = await ActionConfirmationDialog.show(
      context,
      icon: PhosphorIconsRegular.trash,
      title: context.tr('delete_confirm_title'),
      description: context.tr('delete_confirm'),
      actionLabel: context.tr('confirm'),
      cancelLabel: context.tr('cancel'),
      nested: true,
    );

    if (!mounted) return;
    if (confirm != true) {
      setState(() => _mutation = null);
      return;
    }

    try {
      await ref.read(taskListProvider.notifier).deleteTask(widget.task.id);
    } catch (_) {
      if (!mounted) return;
      setState(() => _mutation = null);
      _showMutationError();
      return;
    }
    if (mounted) {
      AppFeedback.show(
        context,
        message: context.tr('task_deleted'),
        type: AppFeedbackType.success,
        aboveNavigation: true,
      );
      Navigator.pop(context);
    }
  }

  void _showMutationError() {
    AppFeedback.show(
      context,
      message: context.tr('error_generic'),
      type: AppFeedbackType.error,
      aboveNavigation: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final task = widget.task;
    final statusColor = StatusHelper.getColor(task.status, p);
    final statusForeground = StatusHelper.getForegroundColor(task.status, p);
    final isOverdue = task.deadline.isBefore(DateTime.now());
    final isUrgent = DateFormatter.isUrgent(task.deadline);
    final deadlineColor = isOverdue
        ? p.destructive
        : isUrgent
        ? p.primaryOrange
        : p.textSecondary;

    return GlassModalShell(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: AppConstants.fontSection,
                          fontWeight: FontWeight.w700,
                          color: p.textPrimary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingXS),
                      Text(
                        task.subject,
                        style: TextStyle(
                          fontSize: AppConstants.fontBody,
                          color: p.textSecondary,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppConstants.spacingSM),
                GlassIconButton(
                  icon: PhosphorIconsRegular.pencil,
                  tooltip: context.tr('edit_task'),
                  color: p.primaryOrange,
                  size: AppConstants.minTouchTarget,
                  onPressed: _mutation == null
                      ? () {
                          Navigator.pop(context);
                          TaskFormModal.show(context, task: task);
                        }
                      : null,
                ),
              ],
            ),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: AppConstants.spacingXL),
              Text(
                context.tr('description'),
                style: TextStyle(
                  fontSize: AppConstants.fontSecondary,
                  color: p.textSecondary,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: AppConstants.spacingSM),
              Text(
                task.description,
                style: TextStyle(
                  fontSize: AppConstants.fontBody,
                  color: p.textPrimary,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: AppConstants.spacingXL),
            GlassCard(
              level: GlassLevel.elevated,
              tintColor: statusColor,
              borderColor: statusColor.withValues(alpha: 0.12),
              padding: const EdgeInsets.all(AppConstants.spacingLG),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) => Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          PhosphorIconsRegular.clock,
                          size: 18,
                          color: deadlineColor,
                        ),
                        const SizedBox(width: AppConstants.spacingSM),
                        Expanded(
                          key: const ValueKey('task_detail_deadline'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormatter.formatDateTime(
                                  task.deadline,
                                  Localizations.localeOf(context),
                                ),
                                style: TextStyle(
                                  fontSize: AppConstants.fontBody,
                                  color: isOverdue || isUrgent
                                      ? deadlineColor
                                      : p.textPrimary,
                                  fontWeight: isOverdue || isUrgent
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: AppConstants.spacingXS),
                              Text(
                                DateFormatter.formatDeadline(
                                  context,
                                  task.deadline,
                                ),
                                style: TextStyle(
                                  fontSize: AppConstants.fontSecondary,
                                  color: deadlineColor,
                                  fontWeight: FontWeight.w500,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppConstants.spacingSM),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: constraints.maxWidth * 0.42,
                          ),
                          child: TaskStatusBadge(
                            key: const ValueKey('task_detail_status'),
                            status: task.status,
                            larger: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: AppConstants.glassBorderWidth,
                    margin: const EdgeInsets.symmetric(
                      vertical: AppConstants.spacingLG,
                    ),
                    color: p.divider,
                  ),
                  Row(
                    key: const ValueKey('task_detail_progress_header'),
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Text(
                          context.tr('progress_work'),
                          key: const ValueKey('task_detail_progress_label'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: AppConstants.fontBody,
                            fontWeight: FontWeight.w600,
                            color: p.textPrimary,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppConstants.spacingMD),
                      Text(
                        StatusHelper.getPercentLabel(task.status),
                        key: const ValueKey('task_detail_progress_value'),
                        style: TextStyle(
                          fontSize: AppConstants.fontSecondary,
                          fontWeight: FontWeight.w700,
                          color: statusForeground,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spacingMD),
                  TaskProgressBar(status: task.status),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.spacingXXL),
            if (task.status != TaskStatus.done) ...[
              Row(
                children: [
                  if (task.status == TaskStatus.belum)
                    Expanded(
                      child: NeonButton(
                        label: context.tr('start_task'),
                        type: NeonButtonType.inProgress,
                        icon: PhosphorIconsRegular.clock,
                        isLoading: _mutation == _TaskMutation.status,
                        onPressed: _mutation == null
                            ? () => _quickUpdateStatus(TaskStatus.progress)
                            : null,
                      ),
                    ),
                  if (task.status == TaskStatus.progress)
                    Expanded(
                      child: NeonButton(
                        label: context.tr('finish_task'),
                        type: NeonButtonType.completed,
                        icon: PhosphorIconsRegular.checkCircle,
                        isLoading: _mutation == _TaskMutation.status,
                        onPressed: _mutation == null
                            ? () => _quickUpdateStatus(TaskStatus.done)
                            : null,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingMD),
            ],
            Row(
              children: [
                Expanded(
                  child: NeonButton(
                    label: context.tr('delete_task'),
                    type: NeonButtonType.danger,
                    icon: PhosphorIconsRegular.trash,
                    isLoading: _mutation == _TaskMutation.delete,
                    onPressed: _mutation == null ? _deleteTask : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
