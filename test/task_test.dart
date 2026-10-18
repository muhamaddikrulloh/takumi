import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_track/features/tasks/domain/task.dart';
import 'package:task_track/features/tasks/domain/task_status.dart';

void main() {
  final now = DateTime(2026, 5, 1, 10);
  final base = Task(
    id: 't1',
    title: 'Tugas',
    subject: 'Matkul',
    description: 'Desc',
    deadline: now.add(const Duration(hours: 5)),
    status: TaskStatus.progress,
    createdAt: now,
    updatedAt: now,
  );

  test('copyWith hanya mengganti field yang diberikan', () {
    final next = base.copyWith(status: TaskStatus.done, title: 'Baru');
    expect(next.status, TaskStatus.done);
    expect(next.title, 'Baru');
    expect(next.id, base.id);
    expect(next.deadline, base.deadline);
    expect(next.subject, base.subject);
  });

  test('toFirestoreMap / fromFirestoreMap round-trip', () {
    final map = base.toFirestoreMap();
    expect(map['status'], 'progress');
    final restored = Task.fromFirestoreMap({...map, 'id': 't1'});
    expect(restored.id, 't1');
    expect(restored.title, base.title);
    expect(restored.subject, base.subject);
    expect(restored.description, base.description);
    expect(restored.status, TaskStatus.progress);
    expect(restored.deadline, base.deadline);
    expect(restored.createdAt, base.createdAt);
    expect(restored.updatedAt, base.updatedAt);
  });

  test('fromFirestoreMap toleransi field opsional', () {
    final map = base.toFirestoreMap()..remove('description');
    final parsed = Task.fromFirestoreMap({...map, 'id': 'x'});
    expect(parsed.description, '');
  });

  test('deadline konversi timestamp', () {
    final ts = Timestamp.fromDate(base.deadline);
    final parsed = Task.fromFirestoreMap({
      ...base.toFirestoreMap()..['deadline'] = ts,
      'id': 't1',
    });
    expect(parsed.deadline, base.deadline);
  });

  test('status tidak dikenal ditolak sebagai data malformed', () {
    expect(
      () => Task.fromFirestoreMap({
        ...base.toFirestoreMap(),
        'id': 'invalid-status',
        'status': 'unexpected',
      }),
      throwsArgumentError,
    );
  });
}
