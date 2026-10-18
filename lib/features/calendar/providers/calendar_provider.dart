import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_track/features/tasks/domain/task.dart';
import 'package:task_track/features/tasks/providers/task_provider.dart';

final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final tasksByDateProvider = Provider<AsyncValue<Map<DateTime, List<Task>>>>((
  ref,
) {
  return ref.watch(taskListProvider).whenData((tasks) {
    final map = <DateTime, List<Task>>{};
    for (final task in tasks) {
      final dateKey = DateTime(
        task.deadline.year,
        task.deadline.month,
        task.deadline.day,
      );
      map.putIfAbsent(dateKey, () => []).add(task);
    }
    return map;
  });
});

final selectedDateTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  return ref.watch(tasksByDateProvider).whenData((map) {
    return map[selectedDate] ?? [];
  });
});
