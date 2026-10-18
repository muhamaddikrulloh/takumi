import 'package:flutter_test/flutter_test.dart';
import 'package:task_track/features/tasks/domain/task.dart';
import 'package:task_track/features/tasks/domain/task_status.dart';
import 'package:task_track/features/tasks/providers/reminder_provider.dart';

Task _task(String id, DateTime deadline, TaskStatus status) {
  return Task(
    id: id,
    title: id,
    subject: 'S',
    description: '',
    deadline: deadline,
    status: status,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

void main() {
  final now = DateTime(2026, 1, 10, 12);

  test('done tasks excluded, >3d excluded', () {
    final result = computeReminders([
      _task('done', now.add(const Duration(hours: 1)), TaskStatus.done),
      _task('far', now.add(const Duration(days: 4)), TaskStatus.progress),
      _task(
        'just-over-boundary',
        now.add(const Duration(days: 3, seconds: 1)),
        TaskStatus.progress,
      ),
    ], now);
    expect(result, isEmpty);
  });

  test('overdue first sorted desc, then upcoming asc', () {
    final result = computeReminders([
      _task(
        'upcoming-2h',
        now.add(const Duration(hours: 2)),
        TaskStatus.progress,
      ),
      _task(
        'overdue-1d',
        now.subtract(const Duration(days: 1)),
        TaskStatus.belum,
      ),
      _task(
        'overdue-2d',
        now.subtract(const Duration(days: 2)),
        TaskStatus.belum,
      ),
      _task(
        'upcoming-30m',
        now.add(const Duration(minutes: 30)),
        TaskStatus.progress,
      ),
    ], now);
    expect(result.map((t) => t.id).toList(), [
      'overdue-2d',
      'overdue-1d',
      'upcoming-30m',
      'upcoming-2h',
    ]);
  });
}
