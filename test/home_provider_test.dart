import 'package:flutter_test/flutter_test.dart';
import 'package:task_track/features/home/providers/home_provider.dart';
import 'package:task_track/features/tasks/domain/task.dart';
import 'package:task_track/features/tasks/domain/task_status.dart';

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

  test('urgent hanya <=24 jam, belum/selesai, tidak lewat, urut ascending', () {
    final result = computeUrgentTasks([
      _task('far', now.add(const Duration(hours: 30)), TaskStatus.belum),
      _task(
        'just-over-boundary',
        now.add(const Duration(hours: 24, minutes: 1)),
        TaskStatus.belum,
      ),
      _task('done', now.add(const Duration(hours: 5)), TaskStatus.done),
      _task(
        'overdue',
        now.subtract(const Duration(hours: 1)),
        TaskStatus.belum,
      ),
      _task('later', now.add(const Duration(hours: 20)), TaskStatus.progress),
      _task('soon', now.add(const Duration(hours: 3)), TaskStatus.belum),
    ], now);

    expect(result.map((t) => t.id).toList(), ['soon', 'later']);
  });

  test('upcoming hanya status bukan done dan belum lewat, urut ascending', () {
    final result = computeUpcomingTasks([
      _task('done', now.add(const Duration(hours: 1)), TaskStatus.done),
      _task(
        'overdue',
        now.subtract(const Duration(hours: 1)),
        TaskStatus.belum,
      ),
      _task('b', now.add(const Duration(hours: 10)), TaskStatus.progress),
      _task('a', now.add(const Duration(days: 1)), TaskStatus.belum),
    ], now);

    expect(result.map((t) => t.id).toList(), ['b', 'a']);
  });
}
