import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_track/core/providers/clock_provider.dart';
import 'package:task_track/features/tasks/domain/task.dart';
import 'package:task_track/features/tasks/domain/task_status.dart';
import 'package:task_track/features/tasks/providers/task_provider.dart';

final remindersProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final now = ref.watch(currentTimeProvider).valueOrNull ?? DateTime.now();
  return ref
      .watch(taskListProvider)
      .whenData((tasks) => computeReminders(tasks, now));
});

List<Task> computeReminders(List<Task> tasks, DateTime now) {
  final overdue = <Task>[];
  final upcoming = <Task>[];
  for (final t in tasks) {
    if (t.status == TaskStatus.done) continue;
    final diff = t.deadline.difference(now);
    if (diff.isNegative) {
      overdue.add(t);
    } else if (diff <= const Duration(days: 3)) {
      upcoming.add(t);
    }
  }
  overdue.sort((a, b) => a.deadline.compareTo(b.deadline));
  upcoming.sort((a, b) => a.deadline.compareTo(b.deadline));
  return [...overdue, ...upcoming];
}
