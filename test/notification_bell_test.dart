import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_track/core/constants/app_theme.dart';
import 'package:task_track/features/tasks/domain/task.dart';
import 'package:task_track/features/tasks/domain/task_status.dart';
import 'package:task_track/features/tasks/providers/reminder_provider.dart';
import 'package:task_track/shared/widgets/notification_bell.dart';

Task _task(int index) {
  final now = DateTime.now();
  return Task(
    id: '$index',
    title: 'Task $index',
    subject: 'Testing',
    description: '',
    deadline: now.add(const Duration(hours: 1)),
    status: TaskStatus.belum,
    createdAt: now,
    updatedAt: now,
  );
}

Future<void> _pump(WidgetTester tester, int count) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        remindersProvider.overrideWithValue(
          AsyncData(List.generate(count, _task)),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(body: Center(child: NotificationBell())),
      ),
    ),
  );
}

void main() {
  testWidgets('notification badge remains compact and expands for counts', (
    tester,
  ) async {
    await _pump(tester, 0);
    expect(find.byKey(const ValueKey('notification_badge')), findsNothing);

    await _pump(tester, 1);
    final badge = find.byKey(const ValueKey('notification_badge'));
    expect(find.text('1'), findsOneWidget);
    expect(tester.getSize(badge), const Size.square(16));

    await _pump(tester, 10);
    expect(find.text('10'), findsOneWidget);
    expect(tester.getSize(badge).width, greaterThan(16));
    expect(tester.getSize(badge).height, 16);

    await _pump(tester, 100);
    expect(find.text('99+'), findsOneWidget);
    final labels = tester
        .widgetList<Semantics>(find.byType(Semantics))
        .map((widget) => widget.properties.label);
    expect(labels, contains('Notifications, 100'));
    expect(tester.takeException(), isNull);
  });
}
