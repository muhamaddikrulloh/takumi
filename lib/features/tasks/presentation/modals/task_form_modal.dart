import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:task_track/core/constants/app_colors.dart';
import 'package:task_track/core/constants/app_constants.dart';
import 'package:task_track/core/localization/app_translations.dart';
import 'package:task_track/core/providers/core_providers.dart';
import 'package:task_track/core/providers/locale_provider.dart';
import 'package:task_track/core/services/notification_service.dart';
import 'package:task_track/core/utils/date_formatter.dart';
import 'package:task_track/core/utils/app_logger.dart';
import 'package:task_track/core/utils/validators.dart';
import 'package:task_track/features/tasks/domain/task.dart';
import 'package:task_track/features/tasks/domain/task_status.dart';
import 'package:task_track/features/tasks/providers/task_provider.dart';
import 'package:task_track/shared/widgets/app_feedback.dart';
import 'package:task_track/shared/widgets/glass_card.dart';
import 'package:task_track/shared/widgets/glass_modal_shell.dart';
import 'package:task_track/shared/widgets/glass_text_field.dart';
import 'package:task_track/shared/widgets/neon_button.dart';

class TaskFormModal extends ConsumerStatefulWidget {
  final Task? task;

  const TaskFormModal({super.key, this.task});

  static Future<void> show(BuildContext context, {Task? task}) {
    return showGlassBottomSheet(
      context,
      builder: (context) => TaskFormModal(task: task),
    );
  }

  @override
  ConsumerState<TaskFormModal> createState() => _TaskFormModalState();
}

class _TaskFormModalState extends ConsumerState<TaskFormModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _subjectController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _deadlineController;

  DateTime? _selectedDeadline;
  TaskStatus _selectedStatus = TaskStatus.belum;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task?.title);
    _subjectController = TextEditingController(text: task?.subject);
    _descriptionController = TextEditingController(text: task?.description);
    _selectedDeadline = task?.deadline;
    _selectedStatus = task?.status ?? TaskStatus.belum;
    _deadlineController = TextEditingController(
      text: task?.deadline != null
          ? DateFormatter.formatDateTime(
              task!.deadline,
              ref.read(localeProvider),
            )
          : '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    _deadlineController.dispose();
    super.dispose();
  }

  void _refreshDeadlineField() {
    _deadlineController.text = _selectedDeadline != null
        ? DateFormatter.formatDateTime(
            _selectedDeadline!,
            ref.read(localeProvider),
          )
        : '';
  }

  Future<void> _selectDateTime() async {
    final now = DateTime.now();
    final initialDate = _selectedDeadline?.isAfter(now) == true
        ? _selectedDeadline!
        : now.add(const Duration(days: 1));

    final date = await showDatePicker(
      context: context,
      barrierColor: AppColors.of(context).nestedScrim,
      initialDate: initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (date == null) return;

    final initialTime = TimeOfDay.fromDateTime(
      _selectedDeadline ?? now.add(const Duration(hours: 1)),
    );

    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      barrierColor: AppColors.of(context).nestedScrim,
      initialTime: initialTime,
    );

    if (time == null) return;

    setState(() {
      _selectedDeadline = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _refreshDeadlineField();
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) return;
    final deadline = _selectedDeadline;
    if (deadline == null) return;

    setState(() => _isSubmitting = true);

    try {
      if (widget.task != null) {
        final updatedTask = widget.task!.copyWith(
          title: _titleController.text.trim(),
          subject: _subjectController.text.trim(),
          description: _descriptionController.text.trim(),
          deadline: deadline,
          status: _selectedStatus,
        );
        await ref.read(taskListProvider.notifier).updateTask(updatedTask);
      } else {
        await ref
            .read(taskListProvider.notifier)
            .addTask(
              title: _titleController.text.trim(),
              subject: _subjectController.text.trim(),
              description: _descriptionController.text.trim(),
              deadline: deadline,
              status: _selectedStatus,
            );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppFeedback.show(
        context,
        message: context.tr('save_failed'),
        type: AppFeedbackType.error,
        aboveNavigation: true,
      );
      return;
    }

    if (_selectedStatus != TaskStatus.done) {
      try {
        await _maybePromptExactAlarm();
      } catch (e) {
        logDebug('Exact alarm prompt failed', error: e);
      }
    }

    if (mounted) {
      AppFeedback.show(
        context,
        message: context.tr(
          widget.task == null ? 'task_added' : 'task_updated',
        ),
        type: AppFeedbackType.success,
        aboveNavigation: true,
      );
      Navigator.pop(context);
    }
  }

  String _validationMessage(String key) {
    final isIndonesian = Localizations.localeOf(context).languageCode == 'id';
    return switch (key) {
      'error_title_too_long' =>
        isIndonesian
            ? 'Judul tugas maksimal ${Validators.taskTitleMaxLength} karakter'
            : 'Title must be ${Validators.taskTitleMaxLength} characters or fewer',
      'error_subject_too_long' =>
        isIndonesian
            ? 'Mata kuliah maksimal ${Validators.taskSubjectMaxLength} karakter'
            : 'Subject must be ${Validators.taskSubjectMaxLength} characters or fewer',
      'error_description_too_long' =>
        isIndonesian
            ? 'Deskripsi maksimal ${Validators.taskDescriptionMaxLength} karakter'
            : 'Description must be ${Validators.taskDescriptionMaxLength} characters or fewer',
      'error_deadline_not_future' =>
        isIndonesian
            ? 'Tenggat waktu harus di masa mendatang'
            : 'Deadline must be in the future',
      _ => context.tr(key),
    };
  }

  Future<void> _maybePromptExactAlarm() async {
    final title = context.tr('exact_alarm_title');
    final desc = context.tr('exact_alarm_desc');
    final later = context.tr('later');
    final enable = context.tr('enable');
    final prefs = ref.read(sharedPreferencesProvider);
    if (prefs.getBool('exact_alarm_prompted') ?? false) return;
    await NotificationService.refreshExactAlarmStatus();
    if (NotificationService.exactAlarmEnabled) {
      await prefs.setBool('exact_alarm_prompted', true);
      return;
    }
    if (!mounted) return;
    final granted = await showGlassDialog<bool>(
      context,
      nested: true,
      builder: (ctx) => _ExactAlarmDialog(
        title: title,
        description: desc,
        laterLabel: later,
        enableLabel: enable,
      ),
    );
    if (granted == true) {
      await NotificationService.requestExactAlarmPermission();
      if (NotificationService.exactAlarmEnabled) {
        await prefs.setBool('exact_alarm_prompted', true);
        await NotificationService.clearAllNotifications();
        ref.invalidate(taskListProvider);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);

    return GlassModalShell(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.task != null
                    ? context.tr('edit_task')
                    : context.tr('add_task'),
                style: TextStyle(
                  fontSize: AppConstants.fontSection,
                  fontWeight: FontWeight.w700,
                  color: p.textPrimary,
                ),
              ),
              const SizedBox(height: AppConstants.spacingLG),
              GlassTextField(
                controller: _titleController,
                maxLength: Validators.taskTitleMaxLength,
                labelText: context.tr('title'),
                hintText: context.tr('title_hint'),
                validator: (v) {
                  final key = Validators.validateTitle(v);
                  return key != null ? _validationMessage(key) : null;
                },
              ),
              const SizedBox(height: AppConstants.spacingMD),
              GlassTextField(
                controller: _subjectController,
                maxLength: Validators.taskSubjectMaxLength,
                labelText: context.tr('subject'),
                hintText: context.tr('subject_hint'),
                validator: (v) {
                  final key = Validators.validateSubject(v);
                  return key != null ? _validationMessage(key) : null;
                },
              ),
              const SizedBox(height: AppConstants.spacingMD),
              GlassTextField(
                controller: _descriptionController,
                maxLength: Validators.taskDescriptionMaxLength,
                labelText: context.tr('description'),
                hintText: context.tr('description_hint'),
                maxLines: 3,
                validator: (v) {
                  final key = Validators.validateDescription(v);
                  return key != null ? _validationMessage(key) : null;
                },
              ),
              const SizedBox(height: AppConstants.spacingMD),
              GlassTextField(
                labelText: context.tr('deadline'),
                hintText: context.tr('deadline_hint'),
                readOnly: true,
                onTap: _selectDateTime,
                prefixIcon: Icon(
                  PhosphorIconsRegular.calendar,
                  color: p.primaryOrange,
                ),
                controller: _deadlineController,
                validator: (_) {
                  final key = Validators.validateDeadline(
                    _selectedDeadline,
                    originalValue: widget.task?.deadline,
                  );
                  return key != null ? _validationMessage(key) : null;
                },
              ),
              const SizedBox(height: AppConstants.spacingLG),
              Text(
                context.tr('status_progress'),
                style: TextStyle(
                  fontSize: AppConstants.fontBody,
                  fontWeight: FontWeight.w600,
                  color: p.textSecondary,
                ),
              ),
              const SizedBox(height: AppConstants.spacingSM),
              LayoutBuilder(
                builder: (context, constraints) {
                  final stackSelectors =
                      constraints.maxWidth < 348 ||
                      MediaQuery.textScalerOf(context).scale(1) > 1.2;
                  final selectors = [
                    _StatusSelector(
                      label: context.tr('pending'),
                      progressLabel: '0%',
                      color: p.statusPending,
                      foregroundColor: p.statusPendingForeground,
                      isSelected: _selectedStatus == TaskStatus.belum,
                      horizontal: stackSelectors,
                      onTap: () =>
                          setState(() => _selectedStatus = TaskStatus.belum),
                    ),
                    _StatusSelector(
                      label: context.tr('in_progress'),
                      progressLabel: '50%',
                      color: p.primaryOrange,
                      foregroundColor: p.statusProgressForeground,
                      isSelected: _selectedStatus == TaskStatus.progress,
                      horizontal: stackSelectors,
                      onTap: () =>
                          setState(() => _selectedStatus = TaskStatus.progress),
                    ),
                    _StatusSelector(
                      label: context.tr('completed'),
                      progressLabel: '100%',
                      color: p.statusCompleted,
                      foregroundColor: p.statusCompletedForeground,
                      isSelected: _selectedStatus == TaskStatus.done,
                      horizontal: stackSelectors,
                      onTap: () =>
                          setState(() => _selectedStatus = TaskStatus.done),
                    ),
                  ];

                  if (stackSelectors) {
                    return Column(
                      children: [
                        for (var index = 0; index < selectors.length; index++)
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: index == selectors.length - 1
                                  ? 0
                                  : AppConstants.spacingSM,
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              child: selectors[index],
                            ),
                          ),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (
                        var index = 0;
                        index < selectors.length;
                        index++
                      ) ...[
                        Expanded(child: selectors[index]),
                        if (index != selectors.length - 1)
                          const SizedBox(width: AppConstants.spacingSM),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: AppConstants.spacingXL),
              NeonButton(
                label: widget.task != null
                    ? context.tr('save_changes')
                    : context.tr('save'),
                onPressed: _submit,
                isLoading: _isSubmitting,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusSelector extends StatelessWidget {
  final String label;
  final String progressLabel;
  final Color color;
  final Color foregroundColor;
  final bool isSelected;
  final bool horizontal;
  final VoidCallback onTap;

  const _StatusSelector({
    required this.label,
    required this.progressLabel,
    required this.color,
    required this.foregroundColor,
    required this.isSelected,
    required this.horizontal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final semanticLabel = '$label, $progressLabel';
    final marker = Container(
      width: AppConstants.spacingSM,
      height: AppConstants.spacingSM,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );

    return Semantics(
      button: true,
      selected: isSelected,
      label: semanticLabel,
      onTap: onTap,
      excludeSemantics: true,
      child: GlassCard(
        level: GlassLevel.control,
        tintColor: isSelected ? color : null,
        borderColor: isSelected ? color.withValues(alpha: 0.14) : null,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        padding: EdgeInsets.zero,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppConstants.minTouchTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingMD,
              vertical: AppConstants.spacingSM,
            ),
            child: horizontal
                ? Row(
                    children: [
                      marker,
                      const SizedBox(width: AppConstants.spacingSM),
                      Expanded(child: _label(p)),
                      const SizedBox(width: AppConstants.spacingSM),
                      _progress(p),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          marker,
                          const SizedBox(width: AppConstants.spacingXS),
                          Flexible(child: _label(p)),
                        ],
                      ),
                      const SizedBox(height: AppConstants.spacingXS),
                      _progress(p),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _label(AppPalette p) {
    return Text(
      label,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: horizontal ? TextAlign.start : TextAlign.center,
      style: TextStyle(
        fontSize: AppConstants.fontSecondary,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? foregroundColor : p.textSecondary,
        height: 1.2,
      ),
    );
  }

  Widget _progress(AppPalette p) {
    return Text(
      progressLabel,
      style: TextStyle(
        fontSize: AppConstants.fontBadge,
        fontWeight: FontWeight.w700,
        color: isSelected ? foregroundColor : p.textSecondary,
        height: 1.2,
      ),
    );
  }
}

class _ExactAlarmDialog extends StatelessWidget {
  const _ExactAlarmDialog({
    required this.title,
    required this.description,
    required this.laterLabel,
    required this.enableLabel,
  });

  final String title;
  final String description;
  final String laterLabel;
  final String enableLabel;

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);

    return GlassDialogShell(
      tintColor: p.primaryOrange,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.primaryOrange.withValues(alpha: 0.12),
                ),
                child: Icon(
                  PhosphorIconsRegular.bell,
                  color: p.primaryOrange,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacingXL),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: p.textPrimary,
                fontSize: AppConstants.fontSection,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: AppConstants.spacingSM),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: p.textSecondary,
                fontSize: AppConstants.fontBody,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppConstants.spacingXXL),
            LayoutBuilder(
              builder: (context, constraints) {
                final stackActions =
                    constraints.maxWidth < 280 ||
                    MediaQuery.textScalerOf(context).scale(1) > 1.3;
                final later = NeonButton(
                  label: laterLabel,
                  type: NeonButtonType.secondary,
                  onPressed: () => Navigator.pop(context, false),
                );
                final enable = NeonButton(
                  label: enableLabel,
                  onPressed: () => Navigator.pop(context, true),
                );

                if (stackActions) {
                  return Column(
                    children: [
                      later,
                      const SizedBox(height: AppConstants.spacingMD),
                      enable,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: later),
                    const SizedBox(width: AppConstants.spacingMD),
                    Expanded(child: enable),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
