import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:task_track/core/constants/app_colors.dart';
import 'package:task_track/core/constants/app_constants.dart';
import 'package:task_track/core/localization/app_translations.dart';
import 'package:task_track/core/utils/status_helper.dart';
import 'package:task_track/features/tasks/domain/task_status.dart';
import 'package:task_track/features/tasks/presentation/modals/task_detail_modal.dart';
import 'package:task_track/features/tasks/presentation/widgets/task_card.dart';
import 'package:task_track/features/tasks/providers/task_provider.dart';
import 'package:task_track/shared/widgets/ambient_background.dart';
import 'package:task_track/shared/widgets/bottom_nav_bar.dart';
import 'package:task_track/shared/widgets/empty_state.dart';
import 'package:task_track/shared/widgets/error_view.dart';
import 'package:task_track/shared/widgets/glass_text_field.dart';
import 'package:task_track/shared/widgets/glass_card.dart';
import 'package:task_track/shared/widgets/loading_view.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(searchQueryProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectFilter(TaskStatus? status) {
    ref.read(selectedFilterProvider.notifier).state = status;
  }

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final tasksAsync = ref.watch(filteredTasksProvider);
    final selectedFilter = ref.watch(selectedFilterProvider);
    const bottomPad = BottomNavBar.contentClearance;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BackdropGroup(
        child: Stack(
          children: [
            const Positioned.fill(child: AmbientBackground()),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppConstants.spacingXL,
                      AppConstants.spacingXL,
                      AppConstants.spacingXL,
                      AppConstants.spacingSM,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('task_list'),
                          style: TextStyle(
                            fontSize: AppConstants.fontTitle,
                            fontWeight: FontWeight.bold,
                            color: p.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppConstants.spacingLG),
                        GlassTextField(
                          controller: _searchController,
                          hintText: context.tr('search_hint'),
                          prefixIcon: Icon(
                            PhosphorIconsRegular.magnifyingGlass,
                            color: p.textSecondary,
                          ),
                          onChanged: (val) {
                            ref.read(searchQueryProvider.notifier).state = val;
                          },
                          textInputAction: TextInputAction.search,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingXL,
                    ),
                    child: LayoutBuilder(
                      key: const ValueKey('task_filter_row'),
                      builder: (context, constraints) {
                        final compactWidth =
                            (constraints.maxWidth -
                                (AppConstants.spacingSM * 3)) /
                            5;
                        double chipWidth(bool selected) =>
                            compactWidth * (selected ? 2 : 1);

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              width: chipWidth(selectedFilter == null),
                              duration: AppConstants.animationFast,
                              curve: Curves.easeOut,
                              child: _FilterChip(
                                key: const ValueKey('task_filter_all'),
                                label: context.tr('all'),
                                icon: PhosphorIconsRegular.squaresFour,
                                foregroundColor: p.statusProgressForeground,
                                isSelected: selectedFilter == null,
                                onTap: () => _selectFilter(null),
                              ),
                            ),
                            const SizedBox(width: AppConstants.spacingSM),
                            AnimatedContainer(
                              width: chipWidth(
                                selectedFilter == TaskStatus.belum,
                              ),
                              duration: AppConstants.animationFast,
                              curve: Curves.easeOut,
                              child: _FilterChip(
                                key: const ValueKey('task_filter_pending'),
                                label: context.tr('pending'),
                                icon: StatusHelper.getIcon(TaskStatus.belum),
                                color: StatusHelper.getColor(
                                  TaskStatus.belum,
                                  p,
                                ),
                                foregroundColor:
                                    StatusHelper.getForegroundColor(
                                      TaskStatus.belum,
                                      p,
                                    ),
                                isSelected: selectedFilter == TaskStatus.belum,
                                onTap: () => _selectFilter(TaskStatus.belum),
                              ),
                            ),
                            const SizedBox(width: AppConstants.spacingSM),
                            AnimatedContainer(
                              width: chipWidth(
                                selectedFilter == TaskStatus.progress,
                              ),
                              duration: AppConstants.animationFast,
                              curve: Curves.easeOut,
                              child: _FilterChip(
                                key: const ValueKey('task_filter_progress'),
                                label: context.tr('in_progress'),
                                icon: StatusHelper.getIcon(TaskStatus.progress),
                                color: StatusHelper.getColor(
                                  TaskStatus.progress,
                                  p,
                                ),
                                foregroundColor:
                                    StatusHelper.getForegroundColor(
                                      TaskStatus.progress,
                                      p,
                                    ),
                                isSelected:
                                    selectedFilter == TaskStatus.progress,
                                onTap: () => _selectFilter(TaskStatus.progress),
                              ),
                            ),
                            const SizedBox(width: AppConstants.spacingSM),
                            AnimatedContainer(
                              width: chipWidth(
                                selectedFilter == TaskStatus.done,
                              ),
                              duration: AppConstants.animationFast,
                              curve: Curves.easeOut,
                              child: _FilterChip(
                                key: const ValueKey('task_filter_done'),
                                label: context.tr('completed'),
                                icon: StatusHelper.getIcon(TaskStatus.done),
                                color: StatusHelper.getColor(
                                  TaskStatus.done,
                                  p,
                                ),
                                foregroundColor:
                                    StatusHelper.getForegroundColor(
                                      TaskStatus.done,
                                      p,
                                    ),
                                isSelected: selectedFilter == TaskStatus.done,
                                onTap: () => _selectFilter(TaskStatus.done),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingMD),
                  Expanded(
                    child: tasksAsync.when(
                      data: (tasks) {
                        if (tasks.isEmpty) {
                          return EmptyState(
                            icon: PhosphorIconsRegular.clipboardText,
                            title: context.tr('no_tasks'),
                            subtitle: context.tr('no_tasks_subtitle'),
                          );
                        }
                        return ListView.separated(
                          key: ValueKey(
                            '$selectedFilter-${ref.watch(searchQueryProvider)}',
                          ),
                          padding: EdgeInsets.fromLTRB(
                            AppConstants.spacingXL,
                            AppConstants.spacingSM,
                            AppConstants.spacingXL,
                            bottomPad,
                          ),
                          itemCount: tasks.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: AppConstants.spacingMD),
                          itemBuilder: (context, index) {
                            final task = tasks[index];
                            return TaskCard(
                              task: task,
                              onTap: () => TaskDetailModal.show(context, task),
                            );
                          },
                        );
                      },
                      loading: () => const LoadingView(),
                      error: (err, _) => ErrorView(
                        onRetry: () => ref.invalidate(taskListProvider),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;
  final Color? foregroundColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    super.key,
    required this.label,
    required this.icon,
    this.color,
    this.foregroundColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final activeColor = color ?? p.primaryOrange;
    final activeForeground = foregroundColor ?? p.statusProgressForeground;
    return Semantics(
      label: label,
      button: true,
      selected: isSelected,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingXS),
          child: GlassCard(
            level: GlassLevel.control,
            padding: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
            tintColor: isSelected ? activeColor : null,
            borderColor: isSelected
                ? activeColor.withValues(alpha: 0.14)
                : null,
            child: AnimatedContainer(
              key: const ValueKey('filter_visual_surface'),
              height: 40,
              duration: AppConstants.animationNormal,
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingSM,
              ),
              alignment: Alignment.center,
              child: AnimatedSwitcher(
                duration: AppConstants.animationFast,
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeOut,
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: isSelected
                    ? FittedBox(
                        key: const ValueKey('active_filter_content'),
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Transform.translate(
                              offset: const Offset(0, 1),
                              child: Icon(
                                icon,
                                size: 14,
                                color: activeForeground,
                              ),
                            ),
                            const SizedBox(width: AppConstants.spacingXS),
                            Text(
                              label,
                              maxLines: 1,
                              softWrap: false,
                              style: TextStyle(
                                color: activeForeground,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Icon(
                        icon,
                        key: const ValueKey('inactive_filter_content'),
                        size: 14,
                        color: p.textSecondary,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
