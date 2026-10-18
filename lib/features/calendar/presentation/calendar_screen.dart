import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:task_track/core/constants/app_colors.dart';
import 'package:task_track/core/constants/app_constants.dart';
import 'package:task_track/core/localization/app_translations.dart';
import 'package:task_track/core/utils/status_helper.dart';
import 'package:task_track/features/calendar/providers/calendar_provider.dart';
import 'package:task_track/features/tasks/domain/task.dart';
import 'package:task_track/features/tasks/presentation/modals/task_detail_modal.dart';
import 'package:task_track/features/tasks/presentation/widgets/task_card.dart';
import 'package:task_track/features/tasks/providers/task_provider.dart';
import 'package:task_track/shared/widgets/ambient_background.dart';
import 'package:task_track/shared/widgets/bottom_nav_bar.dart';
import 'package:task_track/shared/widgets/empty_state.dart';
import 'package:task_track/shared/widgets/error_view.dart';
import 'package:task_track/shared/widgets/glass_card.dart';
import 'package:task_track/shared/widgets/loading_view.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = AppColors.of(context);
    final selectedDate = ref.watch(selectedDateProvider);
    final tasksByDateAsync = ref.watch(tasksByDateProvider);
    final selectedTasksAsync = ref.watch(selectedDateTasksProvider);
    const bottomPad = BottomNavBar.contentClearance;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const Positioned.fill(child: AmbientBackground()),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppConstants.spacingXL,
                      AppConstants.spacingXL,
                      AppConstants.spacingXL,
                      AppConstants.spacingSM,
                    ),
                    child: Text(
                      context.tr('calendar_title'),
                      style: TextStyle(
                        fontSize: AppConstants.fontTitle,
                        fontWeight: FontWeight.bold,
                        color: p.textPrimary,
                      ),
                    ),
                  ),
                ),

                // Calendar Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingXL,
                    ),
                    child: tasksByDateAsync.when(
                      data: (tasksMap) => GlassCard(
                        padding: const EdgeInsets.all(AppConstants.spacingSM),
                        child: TableCalendar<Task>(
                          focusedDay: selectedDate,
                          firstDay: DateTime.now().subtract(
                            const Duration(days: 365),
                          ),
                          lastDay: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                          calendarFormat: CalendarFormat.month,
                          startingDayOfWeek: StartingDayOfWeek.monday,
                          rowHeight: 44,
                          daysOfWeekHeight: 28,
                          headerStyle: HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                            headerPadding: const EdgeInsets.symmetric(
                              vertical: AppConstants.spacingXS,
                            ),
                            titleTextStyle: TextStyle(
                              fontSize: AppConstants.fontTask,
                              fontWeight: FontWeight.bold,
                              color: p.textPrimary,
                            ),
                            leftChevronMargin: EdgeInsets.zero,
                            rightChevronMargin: EdgeInsets.zero,
                            leftChevronPadding: const EdgeInsets.all(12),
                            rightChevronPadding: const EdgeInsets.all(12),
                            leftChevronIcon: Icon(
                              PhosphorIconsRegular.caretLeft,
                              color: p.iconColor,
                              size: 20,
                            ),
                            rightChevronIcon: Icon(
                              PhosphorIconsRegular.caretRight,
                              color: p.iconColor,
                              size: 20,
                            ),
                          ),
                          daysOfWeekStyle: DaysOfWeekStyle(
                            weekdayStyle: TextStyle(
                              color: p.textSecondary,
                              fontSize: AppConstants.fontSecondary,
                            ),
                            weekendStyle: TextStyle(
                              color: p.textSecondary,
                              fontSize: AppConstants.fontSecondary,
                            ),
                          ),
                          calendarStyle: CalendarStyle(
                            defaultTextStyle: TextStyle(color: p.textPrimary),
                            weekendTextStyle: TextStyle(color: p.textPrimary),
                            outsideDaysVisible: false,
                            selectedTextStyle: TextStyle(
                              color: p.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                            todayTextStyle: TextStyle(
                              color: p.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          selectedDayPredicate: (day) =>
                              isSameDay(selectedDate, day),
                          onDaySelected: (selectedDay, focusedDay) {
                            ref
                                .read(selectedDateProvider.notifier)
                                .state = DateTime(
                              selectedDay.year,
                              selectedDay.month,
                              selectedDay.day,
                            );
                          },
                          eventLoader: (day) {
                            final dateKey = DateTime(
                              day.year,
                              day.month,
                              day.day,
                            );
                            return tasksMap[dateKey] ?? [];
                          },
                          calendarBuilders: CalendarBuilders(
                            todayBuilder: (context, day, focusedDay) {
                              return Center(
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: p.primaryOrange.withValues(
                                      alpha: 0.2,
                                    ),
                                    border: Border.all(
                                      color: p.primaryOrange.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${day.day}',
                                      style: TextStyle(
                                        color: p.textPrimary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: AppConstants.fontBody,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                            selectedBuilder: (context, day, focusedDay) {
                              return Center(
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: p.primaryOrange,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${day.day}',
                                      style: TextStyle(
                                        color: p.onPrimary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: AppConstants.fontBody,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                            markerBuilder: (context, date, events) {
                              if (events.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: events.take(3).map((task) {
                                  final color = StatusHelper.getColor(
                                    task.status,
                                    p,
                                  );
                                  return Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 1.5,
                                    ),
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: color,
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ),
                      ),
                      loading: () => const LoadingView(),
                      error: (err, _) => ErrorView(
                        onRetry: () => ref.invalidate(taskListProvider),
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppConstants.spacingLG),
                ),

                // Date Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingXL,
                    ),
                    child: Text(
                      context.tr(
                        'tasks_on_date',
                        args: {
                          'date': DateFormat.yMMMd(
                            Localizations.localeOf(context).toString(),
                          ).format(selectedDate),
                        },
                      ),
                      style: TextStyle(
                        fontSize: AppConstants.fontSection,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppConstants.spacingMD),
                ),

                // Selected Date Tasks List
                selectedTasksAsync.when(
                  data: (tasks) {
                    if (tasks.isEmpty) {
                      return SliverToBoxAdapter(
                        child: EmptyState(
                          icon: PhosphorIconsRegular.calendarX,
                          title: context.tr('no_tasks'),
                          subtitle: context.tr('no_tasks_date'),
                        ),
                      );
                    }
                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppConstants.spacingXL,
                        0,
                        AppConstants.spacingXL,
                        0,
                      ),
                      sliver: SliverList.separated(
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
                      ),
                    );
                  },
                  loading: () => const SliverToBoxAdapter(child: LoadingView()),
                  error: (err, _) => SliverToBoxAdapter(
                    child: ErrorView(
                      onRetry: () => ref.invalidate(taskListProvider),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: bottomPad)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
