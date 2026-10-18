import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_track/core/services/notification_service.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const notificationChannel = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );
  const timezoneChannel = MethodChannel('flutter_timezone');

  late List<MethodCall> calls;
  late List<Map<String, Object?>> pending;
  Map<String, Object?>? launchDetails;
  var failInitialization = false;
  var failCancelAll = false;
  var failNextExactSchedule = false;
  var notificationPermissionGranted = true;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    FlutterLocalNotificationsPlatform.instance =
        AndroidFlutterLocalNotificationsPlugin();
    NotificationService.debugResetForTesting();
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.UTC);
    calls = [];
    pending = [];
    launchDetails = null;
    failInitialization = false;
    failCancelAll = false;
    failNextExactSchedule = false;
    notificationPermissionGranted = true;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(timezoneChannel, (call) async => 'Etc/UTC');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(notificationChannel, (call) async {
          calls.add(call);
          switch (call.method) {
            case 'initialize':
              if (failInitialization) {
                throw PlatformException(code: 'initialization_failed');
              }
              return true;
            case 'getNotificationAppLaunchDetails':
              return launchDetails;
            case 'requestNotificationsPermission':
              return notificationPermissionGranted;
            case 'canScheduleExactNotifications':
              return true;
            case 'pendingNotificationRequests':
              return pending.map(Map<String, Object?>.of).toList();
            case 'cancel':
              final arguments = Map<String, Object?>.from(
                call.arguments as Map,
              );
              pending.removeWhere(
                (request) => request['id'] == arguments['id'],
              );
              return null;
            case 'cancelAll':
              if (failCancelAll) {
                throw PlatformException(code: 'cancel_failed');
              }
              pending.clear();
              return null;
            case 'zonedSchedule':
              final arguments = Map<String, Object?>.from(
                call.arguments as Map,
              );
              final platformSpecifics = Map<String, Object?>.from(
                arguments['platformSpecifics']! as Map,
              );
              if (failNextExactSchedule &&
                  platformSpecifics['scheduleMode'] ==
                      AndroidScheduleMode.exactAllowWhileIdle.name) {
                failNextExactSchedule = false;
                throw PlatformException(code: 'exact_alarm_denied');
              }
              pending.removeWhere(
                (request) => request['id'] == arguments['id'],
              );
              pending.add({
                'id': arguments['id']!,
                'title': arguments['title'],
                'body': arguments['body'],
                'payload': arguments['payload'],
              });
              return null;
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(notificationChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(timezoneChannel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  List<MethodCall> scheduledCalls() =>
      calls.where((call) => call.method == 'zonedSchedule').toList();

  List<String> scheduledTimes() => scheduledCalls()
      .map(
        (call) => (call.arguments as Map)['scheduledDateTimeISO8601'] as String,
      )
      .toList();

  TaskReminderSchedule reminder({
    required String taskId,
    required DateTime deadline,
    String title = 'Task',
    String deadlineTitle = 'Deadline passed',
    List<String> bodies = const ['d3', 'd1', 'h12', 'h3', 'deadline'],
  }) {
    return TaskReminderSchedule(
      taskId: taskId,
      title: title,
      deadlineTitle: deadlineTitle,
      deadline: deadline,
      bodies: bodies,
    );
  }

  test('schedules every tier when the deadline is far away', () async {
    final deadline = DateTime.now().add(const Duration(days: 10));
    await NotificationService.reconcileTaskReminders(
      reminders: [reminder(taskId: 't1', title: 'Tugas X', deadline: deadline)],
    );

    final times = scheduledTimes().map(DateTime.parse).toList()
      ..sort((left, right) => left.compareTo(right));

    expect(times, hasLength(5));
    for (var tier = 0; tier < times.length; tier++) {
      final expected = deadline.subtract(
        Duration(hours: NotificationService.reminderHoursBefore[tier]),
      );
      expect(times[tier].difference(expected).inSeconds.abs(), lessThan(60));
    }
    expect(
      pending.every(
        (request) => (request['payload']! as String).startsWith(
          'task_track:task_reminder:v1:',
        ),
      ),
      isTrue,
    );
    expect(
      pending.singleWhere((request) => request['body'] == 'deadline')['title'],
      'Deadline passed',
    );
  });

  test('skips elapsed tiers', () async {
    final deadline = DateTime.now().add(const Duration(hours: 1));
    await NotificationService.reconcileTaskReminders(
      reminders: [reminder(taskId: 't2', title: 'Tugas Y', deadline: deadline)],
    );

    final times = scheduledTimes().map(DateTime.parse).toList();
    expect(times, hasLength(1));
    expect(times.single.difference(deadline).inSeconds.abs(), lessThan(60));
  });

  test('uses stable 31-bit IDs with a disjoint block for tiers', () {
    final ids = [
      for (var tier = 0; tier < NotificationService.reminderTierCount; tier++)
        NotificationService.notificationIdForTask('stable-task', tier),
    ];

    expect(ids, [1147969710, 1147969711, 1147969712, 1147969713, 1147969714]);
    expect(ids.toSet(), hasLength(NotificationService.reminderTierCount));
    expect(ids.every((id) => id >= 0 && id <= 0x7FFFFFFF), isTrue);
  });

  test('probes a safe tier block when a primary ID is occupied', () async {
    final primaryIds = {
      for (var tier = 0; tier < NotificationService.reminderTierCount; tier++)
        NotificationService.notificationIdForTask('collision-target', tier),
    };
    final occupiedId = primaryIds.first;
    pending.add({
      'id': occupiedId,
      'title': 'Foreign',
      'body': 'Do not cancel',
      'payload': 'another_feature:payload',
    });

    await NotificationService.reconcileTaskReminders(
      reminders: [
        reminder(
          taskId: 'collision-target',
          deadline: DateTime.now().add(const Duration(days: 10)),
        ),
      ],
    );

    final scheduledIds = scheduledCalls()
        .map((call) => (call.arguments as Map)['id'] as int)
        .toSet();
    expect(scheduledIds, hasLength(5));
    expect(scheduledIds.intersection(primaryIds), isEmpty);
    expect(scheduledIds.every((id) => id <= 0x7FFFFFFF), isTrue);

    await NotificationService.reconcileTaskReminders(
      reminders: const <TaskReminderSchedule>[],
    );
    expect(pending, hasLength(1));
    expect(pending.single['id'], occupiedId);
  });

  test('falls back from exact to inexact scheduling', () async {
    failNextExactSchedule = true;

    await NotificationService.reconcileTaskReminders(
      reminders: [
        reminder(
          taskId: 'fallback-task',
          deadline: DateTime.now().add(const Duration(days: 10)),
        ),
      ],
    );

    final modes = scheduledCalls().map((call) {
      final arguments = Map<String, Object?>.from(call.arguments as Map);
      final specifics = Map<String, Object?>.from(
        arguments['platformSpecifics']! as Map,
      );
      return specifics['scheduleMode'];
    }).toList();
    expect(modes, hasLength(6));
    expect(modes.first, AndroidScheduleMode.exactAllowWhileIdle.name);
    expect(
      modes.skip(1),
      everyElement(AndroidScheduleMode.inexactAllowWhileIdle.name),
    );
    expect(NotificationService.exactAlarmEnabled, isFalse);
    expect(pending, hasLength(5));
  });

  test('cold-start tap stays queued until the handler is ready', () async {
    launchDetails = {
      'notificationLaunchedApp': true,
      'notificationResponse': <String, Object?>{
        'notificationId': 42,
        'actionId': null,
        'input': null,
        'notificationResponseType':
            NotificationResponseType.selectedNotification.index,
        'payload': 'cold-task',
        'data': <String, Object?>{},
      },
    };
    var ready = false;
    final handled = <String>[];
    NotificationService.onTap = (taskId) async {
      if (!ready) return false;
      handled.add(taskId);
      return true;
    };

    expect(await NotificationService.init(), isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(NotificationService.pendingTapTaskIds, ['cold-task']);
    expect(
      calls.any((call) => call.method == 'getNotificationAppLaunchDetails'),
      isTrue,
    );

    ready = true;
    await NotificationService.dispatchPendingTaps();
    expect(handled, ['cold-task']);
    expect(NotificationService.pendingTapTaskIds, isEmpty);
  });

  test('deduplicates repeated delivery of the same tap response', () async {
    final handled = <String>[];
    NotificationService.onTap = (taskId) async {
      handled.add(taskId);
      return true;
    };

    NotificationService.debugQueueTapForTesting(
      notificationId: 42,
      taskId: 'same-task',
    );
    await Future<void>.delayed(Duration.zero);
    NotificationService.debugQueueTapForTesting(
      notificationId: 42,
      taskId: 'same-task',
    );
    await Future<void>.delayed(Duration.zero);

    expect(handled, ['same-task']);
  });

  test(
    'clearing a session removes pending notifications and tap payloads',
    () async {
      pending.add({
        'id': 42,
        'title': 'Private task',
        'body': 'Previous account content',
        'payload': 'previous-task',
      });
      NotificationService.debugQueueTapForTesting(
        notificationId: 42,
        taskId: 'previous-task',
      );

      expect(await NotificationService.clearAllNotifications(), isTrue);

      expect(pending, isEmpty);
      expect(NotificationService.pendingTapTaskIds, isEmpty);
      expect(calls.where((call) => call.method == 'cancelAll'), hasLength(1));
    },
  );

  test(
    'clearing a session drops tap payloads when plugin cancel fails',
    () async {
      failCancelAll = true;
      NotificationService.debugQueueTapForTesting(
        notificationId: 42,
        taskId: 'previous-task',
      );

      expect(await NotificationService.clearAllNotifications(), isFalse);
      expect(NotificationService.pendingTapTaskIds, isEmpty);
    },
  );

  test('allows a notification ID again after it is rescheduled', () async {
    const taskId = 'rescheduled-task';
    final notificationId = NotificationService.notificationIdForTask(taskId, 0);
    final handled = <String>[];
    NotificationService.onTap = (value) async {
      handled.add(value);
      return true;
    };

    NotificationService.debugQueueTapForTesting(
      notificationId: notificationId,
      taskId: taskId,
    );
    await Future<void>.delayed(Duration.zero);
    await NotificationService.reconcileTaskReminders(
      reminders: [
        reminder(
          taskId: taskId,
          deadline: DateTime.now().add(const Duration(days: 10)),
        ),
      ],
    );
    NotificationService.debugQueueTapForTesting(
      notificationId: notificationId,
      taskId: taskId,
    );
    await Future<void>.delayed(Duration.zero);

    expect(handled, [taskId, taskId]);
  });

  test('initialization failure is reported instead of thrown', () async {
    failInitialization = true;

    expect(await NotificationService.init(), isFalse);
    expect(NotificationService.isInitialized, isFalse);
    expect(NotificationService.initializationError, isA<PlatformException>());
  });

  test('requests notification permission only when explicitly asked', () async {
    notificationPermissionGranted = false;

    expect(await NotificationService.init(), isTrue);
    expect(
      calls.where((call) => call.method == 'requestNotificationsPermission'),
      isEmpty,
    );

    expect(await NotificationService.requestNotificationPermission(), isFalse);
    expect(NotificationService.notificationsEnabled, isFalse);
    expect(
      calls.where((call) => call.method == 'requestNotificationsPermission'),
      hasLength(1),
    );
  });

  test(
    'reconciles persisted reminders after restart and remote changes',
    () async {
      final originalDeadline = DateTime.now().add(const Duration(days: 10));
      await NotificationService.reconcileTaskReminders(
        reminders: [
          reminder(
            taskId: 'active-task',
            title: 'Old title',
            deadline: originalDeadline,
            bodies: const ['old-0', 'old-1', 'old-2', 'old-3', 'old-4'],
          ),
          reminder(
            taskId: 'deleted-remotely',
            title: 'Deleted',
            deadline: originalDeadline,
            bodies: const ['d0', 'd1', 'd2', 'd3', 'd4'],
          ),
        ],
      );
      expect(pending, hasLength(10));

      NotificationService.debugResetForTesting();
      calls.clear();
      final changedDeadline = originalDeadline.add(const Duration(days: 1));
      final desired = TaskReminderSchedule(
        taskId: 'active-task',
        title: 'New title',
        deadlineTitle: 'New deadline title',
        deadline: changedDeadline,
        bodies: ['new-0', 'new-1', 'new-2', 'new-3', 'new-4'],
      );
      final result = await NotificationService.reconcileTaskReminders(
        reminders: [desired],
      );

      expect(result.succeeded, isTrue);
      expect(result.pendingBefore, 10);
      expect(result.cancelled, 10);
      expect(result.scheduled, 5);
      expect(pending, hasLength(5));
      expect(
        pending.where((request) => request['title'] == 'New title'),
        hasLength(4),
      );
      expect(
        pending.singleWhere((request) => request['body'] == 'new-4')['title'],
        'New deadline title',
      );
      expect(
        pending.every(
          (request) => (request['payload']! as String).contains('active-task'),
        ),
        isTrue,
      );

      final unchanged = await NotificationService.reconcileTaskReminders(
        reminders: [desired],
      );
      expect(unchanged.kept, 5);
      expect(unchanged.cancelled, 0);
      expect(unchanged.scheduled, 0);
    },
  );

  test(
    'reconciliation removes legacy task payloads but preserves foreign ones',
    () async {
      const legacyTaskId = '9ec47e42-53b6-4c1c-90fc-46884d00d109';
      pending.addAll([
        {
          'id': 123,
          'title': 'Legacy task',
          'body': 'Stale',
          'payload': legacyTaskId,
        },
        {
          'id': 456,
          'title': 'Other feature',
          'body': 'Keep',
          'payload': 'another_feature:payload',
        },
      ]);

      final result = await NotificationService.reconcileTaskReminders(
        reminders: const <TaskReminderSchedule>[],
      );

      expect(result.cancelled, 1);
      expect(pending, hasLength(1));
      expect(pending.single['id'], 456);
    },
  );
}
