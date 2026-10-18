import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:task_track/core/providers/connectivity_provider.dart';
import 'package:task_track/core/utils/app_logger.dart';
import 'package:task_track/core/utils/validators.dart';
import 'package:task_track/features/auth/providers/auth_provider.dart';
import 'package:task_track/features/tasks/data/task_repository.dart';
import 'package:task_track/features/tasks/domain/task.dart';
import 'package:task_track/features/tasks/domain/task_status.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return FirestoreTaskRepository();
});

final selectedFilterProvider = StateProvider<TaskStatus?>((ref) => null);

final searchQueryProvider = StateProvider<String>((ref) => '');

final taskSyncErrorProvider = StateProvider<Object?>((ref) => null);

final taskListProvider = AsyncNotifierProvider<TaskListNotifier, List<Task>>(
  TaskListNotifier.new,
);

class TaskListNotifier extends AsyncNotifier<List<Task>> {
  StreamSubscription<List<Task>>? _sub;
  String? _subUid;
  String? _dataOwnerUid;
  int _mutationRevision = 0;
  late TaskRepository _repository;

  String? get dataOwnerUid => _dataOwnerUid;

  @override
  Future<List<Task>> build() async {
    final auth = ref.watch(authStateProvider);
    final repo = ref.read(taskRepositoryProvider);
    _repository = repo;
    final previousSubscription = _sub;
    _sub = null;
    _subUid = null;
    _dataOwnerUid = null;
    await previousSubscription?.cancel();

    final user = auth.valueOrNull;
    if (user == null || !user.emailVerified) {
      _mutationRevision++;
      return [];
    }

    final uid = user.uid;
    final first = Completer<List<Task>>();
    _subUid = uid;
    late final StreamSubscription<List<Task>> subscription;
    subscription = repo.watchTasks().listen(
      (tasks) {
        if (_subUid != uid || !_isCurrentUser(uid)) return;
        if (!first.isCompleted) first.complete(tasks);
        _dataOwnerUid = uid;
        state = AsyncData(tasks);
      },
      onError: (Object e, StackTrace st) {
        if (_subUid != uid || !_isCurrentUser(uid)) return;
        if (!first.isCompleted) first.completeError(e);
        state = AsyncError(e, st);
      },
    );
    _sub = subscription;
    ref.onDispose(() {
      if (identical(_sub, subscription)) {
        _sub = null;
        _subUid = null;
        _dataOwnerUid = null;
      }
      unawaited(subscription.cancel());
    });
    return first.future;
  }

  Future<void> addTask({
    required String title,
    required String subject,
    required String description,
    required DateTime deadline,
    TaskStatus status = TaskStatus.belum,
  }) async {
    final uid = _requireCurrentUid();
    final normalizedTitle = title.trim();
    final normalizedSubject = subject.trim();
    final normalizedDescription = description.trim();
    _validateTaskInput(
      title: normalizedTitle,
      subject: normalizedSubject,
      description: normalizedDescription,
      deadline: deadline,
    );
    final repo = _repository;
    final now = DateTime.now();
    final task = Task(
      id: const Uuid().v4(),
      title: normalizedTitle,
      subject: normalizedSubject,
      description: normalizedDescription,
      deadline: deadline,
      status: status,
      createdAt: now,
      updatedAt: now,
    );
    final rollback = state;
    final revision = ++_mutationRevision;
    final prev = rollback.valueOrNull ?? [];
    state = AsyncData(
      [...prev, task]..sort((a, b) => a.deadline.compareTo(b.deadline)),
    );
    await _persist(
      rollback: rollback,
      uid: uid,
      revision: revision,
      write: () => repo.createTask(task),
    );
  }

  Future<void> updateTask(Task task) async {
    final uid = _requireCurrentUid();
    final repo = _repository;
    final updated = task.copyWith(
      title: task.title.trim(),
      subject: task.subject.trim(),
      description: task.description.trim(),
      updatedAt: DateTime.now(),
    );
    final currentTask = state.valueOrNull
        ?.where((candidate) => candidate.id == updated.id)
        .firstOrNull;
    _validateTaskInput(
      title: updated.title,
      subject: updated.subject,
      description: updated.description,
      deadline: updated.deadline,
      originalDeadline: currentTask?.deadline,
    );
    final rollback = state;
    final revision = ++_mutationRevision;
    final prev = rollback.valueOrNull ?? [];
    state = AsyncData(
      [
        for (final t in prev)
          if (t.id == updated.id) updated else t,
      ]..sort((a, b) => a.deadline.compareTo(b.deadline)),
    );
    await _persist(
      rollback: rollback,
      uid: uid,
      revision: revision,
      write: () => repo.updateTask(updated),
    );
  }

  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    final uid = _requireCurrentUid();
    final prev = state.valueOrNull ?? [];
    final task = prev.where((t) => t.id == taskId).firstOrNull;
    if (task == null) throw StateError('Task not found');
    final repo = _repository;
    final revision = ++_mutationRevision;
    final updated = task.copyWith(status: status, updatedAt: DateTime.now());
    state = AsyncData(
      [
        for (final t in prev)
          if (t.id == updated.id) updated else t,
      ]..sort((a, b) => a.deadline.compareTo(b.deadline)),
    );
    await _persist(
      rollback: AsyncData(prev),
      uid: uid,
      revision: revision,
      write: () => repo.updateTask(updated),
    );
  }

  Future<void> deleteTask(String taskId) async {
    final uid = _requireCurrentUid();
    final repo = _repository;
    final rollback = state;
    final revision = ++_mutationRevision;
    final prev = rollback.valueOrNull ?? [];
    state = AsyncData(prev.where((t) => t.id != taskId).toList());
    await _persist(
      rollback: rollback,
      uid: uid,
      revision: revision,
      write: () => repo.deleteTask(taskId),
    );
  }

  Future<void> _persist({
    required AsyncValue<List<Task>> rollback,
    required String uid,
    required int revision,
    required Future<void> Function() write,
  }) async {
    final writeFuture = write();
    if (ref.read(connectivityProvider).valueOrNull == false) {
      _monitorQueuedWrite(writeFuture, uid);
      return;
    }

    try {
      await writeFuture.timeout(const Duration(seconds: 8));
    } on TimeoutException {
      _monitorQueuedWrite(writeFuture, uid);
    } catch (e, st) {
      logDebug('Task write failed', error: e);
      if (_subUid == uid &&
          _isCurrentUser(uid) &&
          revision == _mutationRevision) {
        state = rollback;
      }
      Error.throwWithStackTrace(e, st);
    }
  }

  void _monitorQueuedWrite(Future<void> write, String uid) {
    unawaited(
      write.catchError((Object error, StackTrace stackTrace) {
        logDebug('Queued task write failed', error: error);
        if (_subUid == uid && _isCurrentUser(uid)) {
          ref.read(taskSyncErrorProvider.notifier).state = error;
        }
      }),
    );
  }

  void _validateTaskInput({
    required String title,
    required String subject,
    required String description,
    required DateTime deadline,
    DateTime? originalDeadline,
  }) {
    final error =
        Validators.validateTitle(title) ??
        Validators.validateSubject(subject) ??
        Validators.validateDescription(description) ??
        Validators.validateDeadline(deadline, originalValue: originalDeadline);
    if (error != null) throw ArgumentError(error);
  }

  String _requireCurrentUid() {
    final uid = _repository.currentVerifiedUid;
    if (uid == null || _subUid != uid) {
      throw StateError('Verified user required');
    }
    return uid;
  }

  bool _isCurrentUser(String uid) =>
      _subUid == uid && _repository.currentVerifiedUid == uid;
}

final filteredTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final tasksAsync = ref.watch(taskListProvider);
  final filter = ref.watch(selectedFilterProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();

  return tasksAsync.whenData((tasks) {
    var filtered = tasks.toList();

    if (filter != null) {
      filtered = filtered.where((t) => t.status == filter).toList();
    }

    if (query.isNotEmpty) {
      filtered = filtered.where((t) {
        return t.title.toLowerCase().contains(query) ||
            t.subject.toLowerCase().contains(query);
      }).toList();
    }

    filtered.sort((a, b) => a.deadline.compareTo(b.deadline));
    return filtered;
  });
});
