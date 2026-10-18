import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:task_track/core/utils/app_logger.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

typedef NotificationTapHandler = Future<bool> Function(String taskId);

class TaskReminderSchedule {
  TaskReminderSchedule({
    required this.taskId,
    required this.title,
    required this.deadlineTitle,
    required this.deadline,
    required List<String> bodies,
  }) : bodies = List.unmodifiable(bodies);

  final String taskId;
  final String title;
  final String deadlineTitle;
  final DateTime deadline;
  final List<String> bodies;
}

class ReminderReconciliationResult {
  const ReminderReconciliationResult({
    required this.pendingBefore,
    required this.kept,
    required this.cancelled,
    required this.scheduled,
    required this.failures,
  });

  final int pendingBefore;
  final int kept;
  final int cancelled;
  final int scheduled;
  final int failures;

  bool get succeeded => failures == 0;
}

class NotificationService {
  NotificationService._();

  static const _channelId = 'task_reminders';
  static const _channelName = 'Pengingat Tugas';
  static const _channelDesc = 'Pengingat deadline tugas';
  static const reminderTierCount = 5;
  static const reminderHoursBefore = [72, 24, 12, 3, 0];
  static const _payloadRoot = 'task_track:task_reminder:';
  static const _payloadPrefix = '${_payloadRoot}v1:';
  static const _maxNotificationId = 0x7FFFFFFF;
  static const _taskSlotCount = (_maxNotificationId + 1) ~/ reminderTierCount;
  static final _legacyTaskIdPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-'
    r'[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );
  static final _fnvOffset = BigInt.parse('cbf29ce484222325', radix: 16);
  static final _fnvPrime = BigInt.parse('100000001b3', radix: 16);
  static final _uint64Mask = BigInt.parse('ffffffffffffffff', radix: 16);

  static final _plugin = FlutterLocalNotificationsPlugin();
  static Future<void> _operationTail = Future<void>.value();
  static Future<bool>? _initialization;
  static Object? _initializationError;
  static bool _isInitialized = false;
  static bool? _notificationsEnabled;
  static bool _exactAlarmEnabled = true;
  static NotificationTapHandler? _onTap;
  static final List<String> _pendingTapTaskIds = [];
  static final Set<int> _handledResponseIds = {};
  static bool _drainingTaps = false;
  static bool _tapDispatchRequested = false;

  static bool get exactAlarmEnabled => _exactAlarmEnabled;
  static bool get isInitialized => _isInitialized;
  static bool? get notificationsEnabled => _notificationsEnabled;
  static Object? get initializationError => _initializationError;
  static List<String> get pendingTapTaskIds =>
      List.unmodifiable(_pendingTapTaskIds);

  static NotificationTapHandler? get onTap => _onTap;

  static set onTap(NotificationTapHandler? handler) {
    _onTap = handler;
    if (handler != null) unawaited(dispatchPendingTaps());
  }

  static AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  /// Initializes notifications without allowing plugin failures to abort app
  /// startup. Returns whether the core plugin initialization succeeded.
  static Future<bool> init() => _initialization ??= _initialize();

  static Future<bool> _initialize() async {
    try {
      tzdata.initializeTimeZones();
      try {
        final tzName = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(tzName.identifier));
      } catch (error) {
        logDebug(
          'Notification timezone setup failed; using UTC fallback',
          error: error,
        );
      }

      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_notification'),
      );
      final initialized = await _plugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: _handleTap,
      );
      if (initialized == false) {
        throw StateError('Local notification plugin returned false');
      }
      _isInitialized = true;
      _initializationError = null;
    } catch (error, stackTrace) {
      _isInitialized = false;
      _initializationError = error;
      logDebug(
        'Notification initialization failed',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }

    try {
      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp ?? false) {
        _queueResponse(launchDetails?.notificationResponse);
      }
    } catch (error) {
      logDebug('Notification launch details unavailable', error: error);
    }

    await refreshExactAlarmStatus();
    return true;
  }

  /// Requests notification access after the app has a visible, resumed UI.
  static Future<bool> requestNotificationPermission() async {
    if (!await init()) return false;
    final android = _android;
    if (android == null) return false;

    try {
      _notificationsEnabled =
          await android.requestNotificationsPermission() ?? false;
    } catch (error) {
      _notificationsEnabled = false;
      logDebug('Notification permission request failed', error: error);
    }
    return _notificationsEnabled!;
  }

  static Future<void> refreshExactAlarmStatus() async {
    try {
      _exactAlarmEnabled =
          await _android?.canScheduleExactNotifications() ?? true;
    } catch (error) {
      _exactAlarmEnabled = false;
      logDebug(
        'Exact alarm status unavailable; using inexact alarms',
        error: error,
      );
    }
  }

  static Future<void> requestExactAlarmPermission() async {
    try {
      await _android?.requestExactAlarmsPermission();
    } catch (error) {
      logDebug('Exact alarm permission request failed', error: error);
    }
    await refreshExactAlarmStatus();
  }

  static Future<void> _handleTap(NotificationResponse response) async {
    _queueResponse(response);
  }

  static void _queueResponse(NotificationResponse? response) {
    final taskId = _taskIdFromPayload(response?.payload);
    if (taskId == null) return;
    final responseId = response?.id;
    if (responseId != null && !_handledResponseIds.add(responseId)) return;
    if (_pendingTapTaskIds.contains(taskId)) return;
    _pendingTapTaskIds.add(taskId);
    unawaited(dispatchPendingTaps());
  }

  /// Retries queued notification taps. A tap remains queued until [onTap]
  /// returns true, allowing callers to wait for navigation and task data.
  static Future<void> dispatchPendingTaps() async {
    if (_drainingTaps) {
      _tapDispatchRequested = true;
      return;
    }
    _drainingTaps = true;
    try {
      while (_pendingTapTaskIds.isNotEmpty) {
        final handler = _onTap;
        if (handler == null) return;
        final taskId = _pendingTapTaskIds.first;
        var handled = false;
        try {
          handled = await handler(taskId);
        } catch (error, stackTrace) {
          logDebug(
            'Notification tap handling failed',
            error: error,
            stackTrace: stackTrace,
          );
        }
        if (!handled) return;
        _pendingTapTaskIds.removeAt(0);
      }
    } finally {
      _drainingTaps = false;
      if (_tapDispatchRequested) {
        _tapDispatchRequested = false;
        unawaited(dispatchPendingTaps());
      }
    }
  }

  /// Returns the deterministic primary ID for a task/tier. Scheduling may
  /// probe another five-ID block if an actual pending-ID collision is found.
  static int notificationIdForTask(String taskId, int tier) {
    RangeError.checkValidIndex(tier, reminderHoursBefore, 'tier');
    final slot = (_stableHash64(taskId) % BigInt.from(_taskSlotCount)).toInt();
    return slot * reminderHoursBefore.length + tier;
  }

  static BigInt _stableHash64(String value) {
    var hash = _fnvOffset;
    for (final byte in utf8.encode(value)) {
      hash ^= BigInt.from(byte);
      hash = (hash * _fnvPrime) & _uint64Mask;
    }
    return hash;
  }

  /// Makes OS-persisted reminders exactly match [reminders]. Pass only active,
  /// non-completed tasks. Stale, changed, malformed, and elapsed tiers owned by
  /// this service are cancelled before missing tiers are scheduled.
  static Future<ReminderReconciliationResult> reconcileTaskReminders({
    required Iterable<TaskReminderSchedule> reminders,
  }) {
    final desired = List<TaskReminderSchedule>.of(reminders);
    return _serialized(() => _reconcile(desired));
  }

  /// Removes pending and already displayed notifications when the account
  /// changes so content from the previous session cannot remain visible.
  static Future<bool> clearAllNotifications() {
    return _serialized(() async {
      _pendingTapTaskIds.clear();
      _handledResponseIds.clear();
      try {
        await _plugin.cancelAll();
        return true;
      } catch (error) {
        logDebug('Failed to clear notifications', error: error);
        return false;
      }
    });
  }

  static Future<ReminderReconciliationResult> _reconcile(
    List<TaskReminderSchedule> desired,
  ) async {
    final desiredByTask = <String, TaskReminderSchedule>{};
    var validationFailures = 0;
    for (final reminder in desired) {
      if (reminder.bodies.length != reminderHoursBefore.length ||
          desiredByTask.containsKey(reminder.taskId)) {
        validationFailures++;
      } else {
        desiredByTask[reminder.taskId] = reminder;
      }
    }
    if (validationFailures > 0) {
      return ReminderReconciliationResult(
        pendingBefore: 0,
        kept: 0,
        cancelled: 0,
        scheduled: 0,
        failures: validationFailures,
      );
    }

    final pending = await _tryPendingRequests();
    if (pending == null) {
      return const ReminderReconciliationResult(
        pendingBefore: 0,
        kept: 0,
        cancelled: 0,
        scheduled: 0,
        failures: 1,
      );
    }

    final desiredTaskIds = desiredByTask.keys.toSet();
    final foreignIds = <int>{};
    final preferredSlots = <String, int>{};
    for (final request in pending) {
      final payload = _decodePayload(request.payload);
      if (!_isManagedRequest(request, desiredTaskIds)) {
        foreignIds.add(request.id);
        continue;
      }
      if (payload != null && desiredTaskIds.contains(payload.taskId)) {
        final slot = _slotFromId(request.id, payload.tier);
        if (slot != null) {
          preferredSlots.putIfAbsent(payload.taskId, () => slot);
        }
      }
    }

    final assignedIds = <int>{};
    final assignedSlots = <String, int>{};
    final ordered = desiredByTask.values.toList()
      ..sort((left, right) {
        final leftHasSlot = preferredSlots.containsKey(left.taskId);
        final rightHasSlot = preferredSlots.containsKey(right.taskId);
        if (leftHasSlot != rightHasSlot) return leftHasSlot ? -1 : 1;
        return left.taskId.compareTo(right.taskId);
      });
    for (final reminder in ordered) {
      final blocked = <int>{...foreignIds, ...assignedIds};
      final preferred = preferredSlots[reminder.taskId];
      final slot =
          preferred != null && !_idsForSlot(preferred).any(blocked.contains)
          ? preferred
          : _findAvailableSlot(reminder.taskId, blocked);
      assignedSlots[reminder.taskId] = slot;
      assignedIds.addAll(_idsForSlot(slot));
    }

    final now = tz.TZDateTime.now(tz.local);
    final expected = <int, _ExpectedReminder>{};
    for (final reminder in desiredByTask.values) {
      final slot = assignedSlots[reminder.taskId]!;
      for (var tier = 0; tier < reminderHoursBefore.length; tier++) {
        final fireAt = _fireAt(reminder.deadline, tier);
        if (fireAt.isBefore(now)) continue;
        final id = slot * reminderHoursBefore.length + tier;
        expected[id] = _ExpectedReminder(
          id: id,
          title: tier == reminderHoursBefore.length - 1
              ? reminder.deadlineTitle
              : reminder.title,
          body: reminder.bodies[tier],
          fireAt: fireAt,
          payload: _encodePayload(reminder.taskId, tier, reminder.deadline),
        );
      }
    }

    var kept = 0;
    var cancelled = 0;
    var scheduled = 0;
    var failures = 0;
    final missing = Map<int, _ExpectedReminder>.of(expected);
    for (final request in pending) {
      if (!_isManagedRequest(request, desiredTaskIds)) continue;
      final wanted = expected[request.id];
      if (wanted != null && wanted.matches(request)) {
        kept++;
        missing.remove(request.id);
      } else if (await _cancel(request.id)) {
        cancelled++;
      } else {
        failures++;
      }
    }

    final missingInOrder = missing.values.toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    for (final reminder in missingInOrder) {
      if (await _scheduleOne(
        id: reminder.id,
        title: reminder.title,
        body: reminder.body,
        fireAt: reminder.fireAt,
        payload: reminder.payload,
      )) {
        scheduled++;
      } else {
        failures++;
      }
    }

    return ReminderReconciliationResult(
      pendingBefore: pending.length,
      kept: kept,
      cancelled: cancelled,
      scheduled: scheduled,
      failures: failures,
    );
  }

  static Future<List<PendingNotificationRequest>?> _tryPendingRequests() async {
    try {
      return await _plugin.pendingNotificationRequests();
    } catch (error) {
      logDebug('Pending notification inspection failed', error: error);
      return null;
    }
  }

  static Future<bool> _cancel(int id) async {
    try {
      await _plugin.cancel(id: id);
      return true;
    } catch (error) {
      logDebug('Failed to cancel notification $id', error: error);
      return false;
    }
  }

  static Future<bool> _scheduleOne({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime fireAt,
    required String payload,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        icon: '@drawable/ic_notification',
        importance: Importance.high,
        priority: Priority.high,
        visibility: NotificationVisibility.private,
      ),
    );
    final mode = _exactAlarmEnabled
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: fireAt,
        notificationDetails: details,
        payload: payload,
        androidScheduleMode: mode,
      );
      _handledResponseIds.remove(id);
      return true;
    } catch (error) {
      if (mode != AndroidScheduleMode.exactAllowWhileIdle) {
        logDebug('Failed to schedule notification $id', error: error);
        return false;
      }
      _exactAlarmEnabled = false;
      try {
        await _plugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: fireAt,
          notificationDetails: details,
          payload: payload,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
        _handledResponseIds.remove(id);
        return true;
      } catch (fallbackError) {
        logDebug(
          'Failed to schedule notification $id with exact and inexact modes',
          error: fallbackError,
        );
        return false;
      }
    }
  }

  static tz.TZDateTime _fireAt(DateTime deadline, int tier) {
    return tz.TZDateTime.from(
      deadline.subtract(Duration(hours: reminderHoursBefore[tier])),
      tz.local,
    );
  }

  static Iterable<int> _idsForSlot(int slot) sync* {
    final base = slot * reminderHoursBefore.length;
    for (var tier = 0; tier < reminderHoursBefore.length; tier++) {
      yield base + tier;
    }
  }

  static int _findAvailableSlot(String taskId, Set<int> blockedIds) {
    final primary =
        notificationIdForTask(taskId, 0) ~/ reminderHoursBefore.length;
    for (var attempt = 0; attempt <= blockedIds.length; attempt++) {
      final slot = (primary + attempt) % _taskSlotCount;
      if (!_idsForSlot(slot).any(blockedIds.contains)) return slot;
    }
    throw StateError('No notification ID block available');
  }

  static int? _slotFromId(int id, int tier) {
    final base = id - tier;
    if (base < 0 || base % reminderHoursBefore.length != 0) return null;
    final slot = base ~/ reminderHoursBefore.length;
    return slot < _taskSlotCount ? slot : null;
  }

  static String _encodePayload(String taskId, int tier, DateTime deadline) {
    return '$_payloadPrefix${jsonEncode({'taskId': taskId, 'tier': tier, 'deadline': deadline.toUtc().millisecondsSinceEpoch})}';
  }

  static _ReminderPayload? _decodePayload(String? value) {
    if (value == null || !value.startsWith(_payloadPrefix)) return null;
    try {
      final decoded = jsonDecode(value.substring(_payloadPrefix.length));
      if (decoded is! Map<String, dynamic>) return null;
      final taskId = decoded['taskId'];
      final tier = decoded['tier'];
      final deadline = decoded['deadline'];
      if (taskId is! String ||
          tier is! int ||
          deadline is! int ||
          tier < 0 ||
          tier >= reminderHoursBefore.length) {
        return null;
      }
      DateTime.fromMillisecondsSinceEpoch(deadline, isUtc: true);
      return _ReminderPayload(taskId, tier, deadline);
    } catch (_) {
      return null;
    }
  }

  static String? _taskIdFromPayload(String? value) {
    if (value == null || value.isEmpty) return null;
    final payload = _decodePayload(value);
    if (payload != null) return payload.taskId;
    if (value.startsWith(_payloadRoot)) return null;
    return value;
  }

  static bool _isManagedRequest(
    PendingNotificationRequest request,
    Set<String> desiredTaskIds,
  ) {
    final payload = request.payload;
    if (payload?.startsWith(_payloadRoot) ?? false) return true;
    return desiredTaskIds.contains(payload) || _looksLikeLegacyTaskId(payload);
  }

  static bool _looksLikeLegacyTaskId(String? value) {
    return value != null && _legacyTaskIdPattern.hasMatch(value);
  }

  static Future<T> _serialized<T>(Future<T> Function() operation) async {
    final previous = _operationTail;
    final release = Completer<void>();
    _operationTail = release.future;
    await previous;
    try {
      final initialization = _initialization;
      if (initialization != null) await initialization;
      return await operation();
    } finally {
      release.complete();
    }
  }

  @visibleForTesting
  static void debugQueueTapForTesting({
    required int notificationId,
    required String taskId,
  }) {
    _queueResponse(
      NotificationResponse(
        id: notificationId,
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: taskId,
      ),
    );
  }

  @visibleForTesting
  static void debugResetForTesting() {
    _operationTail = Future<void>.value();
    _initialization = null;
    _initializationError = null;
    _isInitialized = false;
    _notificationsEnabled = null;
    _exactAlarmEnabled = true;
    _onTap = null;
    _pendingTapTaskIds.clear();
    _handledResponseIds.clear();
    _drainingTaps = false;
    _tapDispatchRequested = false;
  }
}

class _ReminderPayload {
  const _ReminderPayload(this.taskId, this.tier, this.deadlineMilliseconds);

  final String taskId;
  final int tier;
  final int deadlineMilliseconds;
}

class _ExpectedReminder {
  const _ExpectedReminder({
    required this.id,
    required this.title,
    required this.body,
    required this.fireAt,
    required this.payload,
  });

  final int id;
  final String title;
  final String body;
  final tz.TZDateTime fireAt;
  final String payload;

  bool matches(PendingNotificationRequest request) {
    return request.title == title &&
        request.body == body &&
        request.payload == payload;
  }
}
