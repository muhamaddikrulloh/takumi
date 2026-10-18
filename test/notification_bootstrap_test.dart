import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:task_track/features/auth/providers/auth_provider.dart';
import 'package:task_track/features/tasks/data/task_repository.dart';
import 'package:task_track/features/tasks/domain/task.dart';
import 'package:task_track/features/tasks/domain/task_status.dart';
import 'package:task_track/features/tasks/presentation/modals/task_detail_modal.dart';
import 'package:task_track/features/tasks/providers/task_provider.dart';
import 'package:task_track/main.dart' as app;

class _VerifiedUser extends Fake implements User {
  @override
  String get uid => 'user-id';

  @override
  bool get emailVerified => true;
}

class _TaskRepository implements TaskRepository {
  _TaskRepository(this.task);

  final Task task;

  @override
  String? get currentVerifiedUid => 'user-id';

  @override
  Stream<List<Task>> watchTasks() => Stream.value([task]);

  @override
  Future<void> createTask(Task task) async {}

  @override
  Future<void> deleteTask(String taskId) async {}

  @override
  Future<void> updateTask(Task task) async {}
}

void main() {
  test('keeps persisted reminders during initial authenticated startup', () {
    expect(
      app.shouldClearTaskRemindersForAuthTransition(
        authPreviouslyResolved: false,
        previousUid: null,
        nextUid: 'user-a',
      ),
      isFalse,
    );
  });

  test('clears persisted reminders when startup resolves signed out', () {
    expect(
      app.shouldClearTaskRemindersForAuthTransition(
        authPreviouslyResolved: false,
        previousUid: null,
        nextUid: null,
      ),
      isTrue,
    );
  });

  test('clears reminders on logout and account switch', () {
    expect(
      app.shouldClearTaskRemindersForAuthTransition(
        authPreviouslyResolved: true,
        previousUid: 'user-a',
        nextUid: null,
      ),
      isTrue,
    );
    expect(
      app.shouldClearTaskRemindersForAuthTransition(
        authPreviouslyResolved: true,
        previousUid: 'user-a',
        nextUid: 'user-b',
      ),
      isTrue,
    );
  });

  test('does not clear reminders for repeated auth emissions', () {
    expect(
      app.shouldClearTaskRemindersForAuthTransition(
        authPreviouslyResolved: true,
        previousUid: 'user-a',
        nextUid: 'user-a',
      ),
      isFalse,
    );
  });

  testWidgets('notification task payload opens its detail modal', (
    tester,
  ) async {
    await initializeDateFormatting();
    final now = DateTime.now();
    final task = Task(
      id: 'notification-task',
      title: 'Notification task',
      subject: 'Testing',
      description: 'Opened from a local notification.',
      deadline: now.add(const Duration(days: 1)),
      status: TaskStatus.belum,
      createdAt: now,
      updatedAt: now,
    );
    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith((ref) => Stream.value(_VerifiedUser())),
        taskRepositoryProvider.overrideWithValue(_TaskRepository(task)),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authStateProvider.future);
    await container.read(taskListProvider.future);

    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          navigatorKey: navigatorKey,
          theme: ThemeData.dark(),
          home: const Scaffold(body: Text('Home')),
        ),
      ),
    );

    final handling = app.handleTaskReminderTap(
      container: container,
      navigatorKey: navigatorKey,
      taskId: task.id,
    );
    await tester.pumpAndSettle();

    expect(find.byType(TaskDetailModal), findsOneWidget);
    expect(find.text(task.title), findsOneWidget);

    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    expect(await handling, isTrue);
  });
}
