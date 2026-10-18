import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_track/core/providers/clock_provider.dart';
import 'package:task_track/features/tasks/domain/task.dart';
import 'package:task_track/features/tasks/domain/task_status.dart';
import 'package:task_track/features/tasks/providers/task_provider.dart';

final completedTasksProvider = Provider<AsyncValue<int>>((ref) {
  return ref
      .watch(taskListProvider)
      .whenData(
        (tasks) => tasks.where((t) => t.status == TaskStatus.done).length,
      );
});

final belumTasksProvider = Provider<AsyncValue<int>>((ref) {
  return ref
      .watch(taskListProvider)
      .whenData(
        (tasks) => tasks.where((t) => t.status == TaskStatus.belum).length,
      );
});

final progressTasksProvider = Provider<AsyncValue<int>>((ref) {
  return ref
      .watch(taskListProvider)
      .whenData(
        (tasks) => tasks.where((t) => t.status == TaskStatus.progress).length,
      );
});

final urgentTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final now = ref.watch(currentTimeProvider).valueOrNull ?? DateTime.now();
  return ref
      .watch(taskListProvider)
      .whenData((tasks) => computeUrgentTasks(tasks, now));
});

List<Task> computeUrgentTasks(List<Task> tasks, DateTime now) {
  return tasks.where((t) {
    if (t.status == TaskStatus.done) return false;
    final diff = t.deadline.difference(now);
    return diff <= const Duration(hours: 24) && !diff.isNegative;
  }).toList()..sort((a, b) => a.deadline.compareTo(b.deadline));
}

final upcomingTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final now = ref.watch(currentTimeProvider).valueOrNull ?? DateTime.now();
  return ref
      .watch(taskListProvider)
      .whenData((tasks) => computeUpcomingTasks(tasks, now));
});

List<Task> computeUpcomingTasks(List<Task> tasks, DateTime now) {
  return tasks
      .where((t) => t.status != TaskStatus.done && t.deadline.isAfter(now))
      .toList()
    ..sort((a, b) => a.deadline.compareTo(b.deadline));
}
