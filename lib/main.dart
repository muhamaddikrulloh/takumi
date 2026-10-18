import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_track/app.dart';
import 'package:task_track/core/localization/app_translations.dart';
import 'package:task_track/core/providers/core_providers.dart';
import 'package:task_track/core/providers/locale_provider.dart';
import 'package:task_track/core/services/local_data_service.dart';
import 'package:task_track/core/services/notification_service.dart';
import 'package:task_track/core/utils/app_logger.dart';
import 'package:task_track/features/auth/providers/auth_provider.dart';
import 'package:task_track/features/profile/providers/profile_provider.dart';
import 'package:task_track/features/tasks/domain/task.dart';
import 'package:task_track/features/tasks/domain/task_status.dart';
import 'package:task_track/features/tasks/presentation/modals/task_detail_modal.dart';
import 'package:task_track/features/tasks/providers/task_provider.dart';

final appNavigatorKey = GlobalKey<NavigatorState>();

bool shouldClearTaskRemindersForAuthTransition({
  required bool authPreviouslyResolved,
  required String? previousUid,
  required String? nextUid,
}) {
  if (nextUid == null) {
    return !authPreviouslyResolved || previousUid != null;
  }
  return authPreviouslyResolved && previousUid != nextUid;
}

Future<bool> handleTaskReminderTap({
  required ProviderContainer container,
  required GlobalKey<NavigatorState> navigatorKey,
  required String taskId,
}) async {
  final auth = container.read(authStateProvider);
  if (!auth.hasValue) return false;
  final user = auth.valueOrNull;
  if (user == null || !user.emailVerified) return true;

  final taskState = container.read(taskListProvider);
  if (!taskState.hasValue) return false;
  final task = (taskState.valueOrNull ?? const <Task>[])
      .where((candidate) => candidate.id == taskId)
      .firstOrNull;
  if (task == null) return true;
  final context = navigatorKey.currentContext;
  if (context == null) return false;
  await TaskDetailModal.show(context, task);
  return true;
}

void main() {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  binding.deferFirstFrame();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    logDebug('Uncaught platform error', error: error, stackTrace: stackTrace);
    return true;
  };
  runApp(const _BootstrapApp());
}

class _BootstrapApp extends StatefulWidget {
  const _BootstrapApp();

  @override
  State<_BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<_BootstrapApp> {
  late Future<ProviderContainer> _bootstrapFuture;
  ProviderContainer? _container;
  ProviderSubscription<AsyncValue<User?>>? _authSubscription;
  ProviderSubscription<AsyncValue<List<Task>>>? _taskSubscription;
  ProviderSubscription<Locale>? _localeSubscription;
  String? _activeUid;
  String? _sessionUid;
  bool _authResolved = false;
  bool _firestoreConfigured = false;
  bool _firstFrameReleaseScheduled = false;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = _bootstrap();
  }

  Future<ProviderContainer> _bootstrap() async {
    await initializeDateFormatting();
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }

    if (!_firestoreConfigured) {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: 100 * 1024 * 1024,
      );
      _firestoreConfigured = true;
    }

    final prefs = await SharedPreferences.getInstance();
    await LocalDataService.clearLegacyPrivateData(prefs);
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    _container = container;
    _configureNotificationTap(container);
    unawaited(_startRuntimeServices(container));
    return container;
  }

  void _configureNotificationTap(ProviderContainer container) {
    NotificationService.onTap = (taskId) async {
      if (_container != container) return true;
      return handleTaskReminderTap(
        container: container,
        navigatorKey: appNavigatorKey,
        taskId: taskId,
      );
    };
  }

  Future<void> _startRuntimeServices(ProviderContainer container) async {
    final initialization = NotificationService.init();
    _coordinateTaskReminders(container);
    final initialized = await initialization;
    if (!initialized || !mounted || _container != container) return;
    _retryNotificationTapAfterFrame();
  }

  void _coordinateTaskReminders(ProviderContainer container) {
    _authSubscription = container.listen(authStateProvider, (_, auth) {
      if (!auth.hasValue || _container != container) return;
      final user = auth.valueOrNull;
      final sessionUid = user?.uid;
      final uid = user != null && user.emailVerified ? user.uid : null;
      final shouldClearSessionData = shouldClearTaskRemindersForAuthTransition(
        authPreviouslyResolved: _authResolved,
        previousUid: _sessionUid,
        nextUid: sessionUid,
      );
      if (shouldClearSessionData) {
        _clearSessionScopedData(container);
      }
      _sessionUid = sessionUid;
      if (!_authResolved || _activeUid != uid) {
        final shouldClear = shouldClearTaskRemindersForAuthTransition(
          authPreviouslyResolved: _authResolved,
          previousUid: _activeUid,
          nextUid: uid,
        );
        _authResolved = true;
        _activeUid = uid;
        if (shouldClear) {
          unawaited(NotificationService.clearAllNotifications());
        }
      }
      if (uid != null && _taskSubscription == null) {
        _taskSubscription = container.listen(taskListProvider, (_, tasks) {
          if (!tasks.hasValue || _container != container) return;
          final currentUser = container.read(authStateProvider).valueOrNull;
          if (currentUser == null ||
              !currentUser.emailVerified ||
              currentUser.uid != _activeUid ||
              container.read(taskListProvider.notifier).dataOwnerUid !=
                  currentUser.uid) {
            return;
          }
          unawaited(
            _reconcileTaskReminders(
              container,
              tasks.valueOrNull ?? const <Task>[],
              currentUser.uid,
            ),
          );
          _retryNotificationTapAfterFrame();
        }, fireImmediately: true);
      }
      _retryNotificationTapAfterFrame();
    }, fireImmediately: true);

    _localeSubscription = container.listen(localeProvider, (_, _) {
      final user = container.read(authStateProvider).valueOrNull;
      final tasks = container.read(taskListProvider);
      if (user == null ||
          !user.emailVerified ||
          user.uid != _activeUid ||
          container.read(taskListProvider.notifier).dataOwnerUid != user.uid ||
          !tasks.hasValue) {
        return;
      }
      unawaited(
        _reconcileTaskReminders(
          container,
          tasks.valueOrNull ?? const <Task>[],
          user.uid,
        ),
      );
    });
  }

  void _clearSessionScopedData(ProviderContainer container) {
    container.read(newlyRegisteredUidProvider.notifier).state = null;
    container.read(selectedFilterProvider.notifier).state = null;
    container.read(searchQueryProvider.notifier).state = '';
    container.read(taskSyncErrorProvider.notifier).state = null;
    container.read(profileSyncErrorProvider.notifier).state = null;
    unawaited(
      LocalDataService.clearAccountPhotoCache(
        container.read(sharedPreferencesProvider),
      ),
    );
  }

  Future<void> _reconcileTaskReminders(
    ProviderContainer container,
    List<Task> tasks,
    String? expectedUid,
  ) async {
    if (_container != container) return;
    if (expectedUid != null) {
      final user = container.read(authStateProvider).valueOrNull;
      if (user == null ||
          !user.emailVerified ||
          user.uid != expectedUid ||
          _activeUid != expectedUid) {
        return;
      }
    }

    final locale = container.read(localeProvider);
    final reminders = [
      for (final task in tasks)
        if (task.status != TaskStatus.done)
          TaskReminderSchedule(
            taskId: task.id,
            title: task.title,
            deadlineTitle: AppTranslations.t(locale, 'reminder_title_overdue'),
            deadline: task.deadline,
            bodies: [
              AppTranslations.t(
                locale,
                'reminder_body_d3',
                args: {'title': task.title},
              ),
              AppTranslations.t(
                locale,
                'reminder_body_d1',
                args: {'title': task.title},
              ),
              AppTranslations.t(
                locale,
                'reminder_body_h12',
                args: {'title': task.title},
              ),
              AppTranslations.t(
                locale,
                'reminder_body_h3',
                args: {'title': task.title},
              ),
              AppTranslations.t(
                locale,
                'reminder_body_overdue',
                args: {'title': task.title},
              ),
            ],
          ),
    ];
    final result = await NotificationService.reconcileTaskReminders(
      reminders: reminders,
    );
    if (!result.succeeded) {
      logDebug(
        'Task reminder reconciliation completed with '
        '${result.failures} failure(s).',
      );
    }
  }

  void _retryNotificationTapAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(NotificationService.dispatchPendingTaps());
    });
  }

  void _retryBootstrap() {
    _disposeRuntime();
    setState(() {
      _bootstrapFuture = _bootstrap();
    });
  }

  void _releaseFirstFrame() {
    if (_firstFrameReleaseScheduled) return;
    _firstFrameReleaseScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.allowFirstFrame();
    });
  }

  void _disposeRuntime() {
    NotificationService.onTap = null;
    _authSubscription?.close();
    _taskSubscription?.close();
    _localeSubscription?.close();
    _authSubscription = null;
    _taskSubscription = null;
    _localeSubscription = null;
    _activeUid = null;
    _sessionUid = null;
    _authResolved = false;
    _container?.dispose();
    _container = null;
  }

  @override
  void dispose() {
    _disposeRuntime();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProviderContainer>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _releaseFirstFrame();
          return UncontrolledProviderScope(
            container: snapshot.requireData,
            child: App(navigatorKey: appNavigatorKey),
          );
        }
        if (snapshot.hasError) {
          _releaseFirstFrame();
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData.dark(useMaterial3: true),
            home: Scaffold(
              body: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48),
                        const SizedBox(height: 16),
                        const Text(
                          'Aplikasi gagal dimulai. Periksa koneksi lalu coba lagi.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _retryBootstrap,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        return const SizedBox.expand();
      },
    );
  }
}
