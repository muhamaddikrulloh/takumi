import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_track/core/providers/connectivity_provider.dart';
import 'package:task_track/features/auth/providers/auth_provider.dart';
import 'package:task_track/features/tasks/data/task_repository.dart';
import 'package:task_track/features/tasks/domain/task.dart';
import 'package:task_track/features/tasks/domain/task_status.dart';
import 'package:task_track/features/tasks/providers/task_provider.dart';

Task _task(String id, TaskStatus status) => Task(
  id: id,
  title: 'Tugas',
  subject: 'Matkul',
  description: '',
  deadline: DateTime.now().add(const Duration(days: 3)),
  status: status,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

class _FakeUser extends Fake implements User {
  _FakeUser([this.id = 'user-id']);

  final String id;

  @override
  String get uid => id;

  @override
  bool get emailVerified => true;
}

class _ControlledTaskRepository implements TaskRepository {
  final List<Task> initialTasks;
  final createCompleter = Completer<void>();
  Task? createdTask;
  String? currentUid = 'user-id';

  _ControlledTaskRepository(this.initialTasks);

  @override
  String? get currentVerifiedUid => currentUid;

  @override
  Stream<List<Task>> watchTasks() => Stream.value(initialTasks);

  @override
  Future<void> createTask(Task task) {
    createdTask = task;
    return createCompleter.future;
  }

  @override
  Future<void> deleteTask(String taskId) => throw UnimplementedError();

  @override
  Future<void> updateTask(Task task) => throw UnimplementedError();
}

class _StreamingTaskRepository implements TaskRepository {
  final controllers = <StreamController<List<Task>>>[];
  String? currentUid = 'user-id';

  int get watchCount => controllers.length;

  @override
  String? get currentVerifiedUid => currentUid;

  @override
  Stream<List<Task>> watchTasks() {
    final controller = StreamController<List<Task>>();
    controllers.add(controller);
    return controller.stream;
  }

  @override
  Future<void> createTask(Task task) async {}

  @override
  Future<void> deleteTask(String taskId) async {}

  @override
  Future<void> updateTask(Task task) async {}

  Future<void> close() async {
    for (final controller in controllers) {
      await controller.close();
    }
  }
}

void main() {
  test('add awaits repository failure, rolls back, and rethrows', () async {
    final existing = _task('existing', TaskStatus.done);
    final repository = _ControlledTaskRepository([existing]);
    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith((ref) => Stream.value(_FakeUser())),
        connectivityProvider.overrideWith((ref) => Stream.value(true)),
        taskRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authStateProvider.future);
    container.invalidate(taskListProvider);
    await container.read(taskListProvider.future);

    final mutation = container
        .read(taskListProvider.notifier)
        .addTask(
          title: ' New task ',
          subject: ' Subject ',
          description: ' Description ',
          deadline: DateTime.now().add(const Duration(days: 1)),
        );

    expect(repository.createdTask?.title, 'New task');
    expect(
      container.read(taskListProvider).requireValue.map((task) => task.id),
      containsAll(<String>['existing', repository.createdTask!.id]),
    );

    final failure = Exception('write failed');
    final expectation = expectLater(mutation, throwsA(same(failure)));
    repository.createCompleter.completeError(failure);
    await expectation;

    expect(
      container.read(taskListProvider).requireValue.map((task) => task.id),
      ['existing'],
    );
  });

  test('stale task failure cannot roll back the next account', () async {
    final existing = _task('existing', TaskStatus.done);
    final repository = _ControlledTaskRepository([existing])
      ..currentUid = 'user-a';
    final authController = StreamController<User?>();
    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith((ref) => authController.stream),
        connectivityProvider.overrideWith((ref) => Stream.value(true)),
        taskRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await authController.close();
    });

    authController.add(_FakeUser('user-a'));
    await container.read(authStateProvider.future);
    await container.read(taskListProvider.future);

    final mutation = container
        .read(taskListProvider.notifier)
        .addTask(
          title: 'Account A task',
          subject: 'Subject',
          description: '',
          deadline: DateTime.now().add(const Duration(days: 1)),
        );

    repository.currentUid = 'user-b';
    authController.add(_FakeUser('user-b'));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    final failure = Exception('account A write failed');
    final expectation = expectLater(mutation, throwsA(same(failure)));
    repository.createCompleter.completeError(failure);
    await expectation;

    expect(container.read(authStateProvider).requireValue!.uid, 'user-b');
    await container.read(taskListProvider.future);
    expect(container.read(taskListProvider).requireValue, [existing]);
  });

  test('re-subscribes when auth repeats the current user', () async {
    final repository = _StreamingTaskRepository();
    final authController = StreamController<User?>();
    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith((ref) => authController.stream),
        taskRepositoryProvider.overrideWithValue(repository),
      ],
    );
    final subscription = container.listen(
      taskListProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(() async {
      subscription.close();
      container.dispose();
      await authController.close();
      await repository.close();
    });

    authController.add(_FakeUser());
    await container.read(authStateProvider.future);
    await pumpEventQueue();
    expect(repository.watchCount, 1);

    final initial = _task('initial', TaskStatus.belum);
    repository.controllers.single.add([initial]);
    await pumpEventQueue();
    expect(container.read(taskListProvider).requireValue.single.id, initial.id);

    authController.add(_FakeUser());
    await pumpEventQueue();
    expect(repository.watchCount, 2);

    final refreshed = _task('refreshed', TaskStatus.progress);
    repository.controllers.last.add([refreshed]);
    await pumpEventQueue();
    expect(
      container.read(taskListProvider).requireValue.single.id,
      refreshed.id,
    );
  });
}
