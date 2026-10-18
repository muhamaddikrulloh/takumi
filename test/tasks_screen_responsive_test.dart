import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_track/core/constants/app_theme.dart';
import 'package:task_track/features/tasks/domain/task.dart';
import 'package:task_track/features/tasks/domain/task_status.dart';
import 'package:task_track/features/tasks/presentation/tasks_screen.dart';
import 'package:task_track/features/tasks/providers/task_provider.dart';

const _filterKeys = <ValueKey<String>>[
  ValueKey('task_filter_all'),
  ValueKey('task_filter_pending'),
  ValueKey('task_filter_progress'),
  ValueKey('task_filter_done'),
];

class _StaticTaskListNotifier extends TaskListNotifier {
  _StaticTaskListNotifier(this.tasks);

  final List<Task> tasks;

  @override
  Future<List<Task>> build() async => tasks;
}

Task _task(String id, TaskStatus status, int deadlineOffset) {
  final now = DateTime(2026, 10, 3, 12);
  return Task(
    id: id,
    title: '$id task',
    subject: 'Testing',
    description: '',
    deadline: now.add(Duration(days: deadlineOffset)),
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

Future<ProviderContainer> _pumpTasksScreen(
  WidgetTester tester, {
  required double width,
  required Locale locale,
  List<Task> tasks = const [],
  double textScale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 800);
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });

  final container = ProviderContainer(
    overrides: [
      taskListProvider.overrideWith(() => _StaticTaskListNotifier(tasks)),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: locale,
        supportedLocales: const [Locale('id'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.darkTheme,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          );
        },
        home: const TasksScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void _expectFiltersInsideViewport(
  WidgetTester tester, {
  required double width,
  required List<String> labels,
  required int activeIndex,
  double maxHeight = 52,
}) {
  final rowFinder = find.byKey(const ValueKey('task_filter_row'));
  expect(rowFinder, findsOneWidget);
  expect(
    find.descendant(
      of: rowFinder,
      matching: find.byType(SingleChildScrollView),
    ),
    findsNothing,
  );

  final rowRect = tester.getRect(rowFinder);
  expect(rowRect.left, closeTo(20, 0.01));
  expect(rowRect.right, closeTo(width - 20, 0.01));

  final chipRects = <Rect>[];
  for (var index = 0; index < _filterKeys.length; index++) {
    final chipFinder = find.byKey(_filterKeys[index]);
    expect(chipFinder, findsOneWidget);
    final chipRect = tester.getRect(chipFinder);
    chipRects.add(chipRect);
    expect(chipRect.left, greaterThanOrEqualTo(rowRect.left));
    expect(chipRect.right, lessThanOrEqualTo(rowRect.right));
    expect(chipRect.top, closeTo(rowRect.top, 0.01));
    expect(chipRect.bottom, closeTo(rowRect.bottom, 0.01));
    expect(chipRect.height, greaterThanOrEqualTo(48));
    expect(chipRect.height, lessThanOrEqualTo(maxHeight));

    final surfaceFinder = find.descendant(
      of: chipFinder,
      matching: find.byKey(const ValueKey('filter_visual_surface')),
    );
    expect(surfaceFinder, findsOneWidget);
    final surfaceRect = tester.getRect(surfaceFinder);
    expect(surfaceRect.height, closeTo(40, 0.01));
    expect(surfaceRect.width, closeTo(chipRect.width, 0.01));
    expect(surfaceRect.center, chipRect.center);

    final iconFinder = find.descendant(
      of: chipFinder,
      matching: find.byType(Icon),
    );
    expect(iconFinder, findsOneWidget);
    final iconRect = tester.getRect(iconFinder);

    final labelFinder = find.descendant(
      of: chipFinder,
      matching: find.text(labels[index]),
    );
    if (index == activeIndex) {
      expect(labelFinder, findsOneWidget);
      final label = tester.widget<Text>(labelFinder);
      final labelRect = tester.getRect(labelFinder);
      expect(label.maxLines, 1);
      expect(label.softWrap, isFalse);
      expect(labelRect.left, greaterThan(iconRect.right));
      expect(labelRect.right, lessThanOrEqualTo(chipRect.right));
      expect(labelRect.top, greaterThanOrEqualTo(surfaceRect.top));
      expect(labelRect.bottom, lessThanOrEqualTo(surfaceRect.bottom));
      expect(labelRect.center.dy, closeTo(surfaceRect.center.dy, 0.01));
      expect(iconRect.center.dy, greaterThanOrEqualTo(labelRect.center.dy));
      expect(iconRect.center.dy - labelRect.center.dy, lessThanOrEqualTo(1.01));
      expect(
        (iconRect.left + labelRect.right) / 2,
        closeTo(chipRect.center.dx, 0.01),
      );
    } else {
      expect(labelFinder, findsNothing);
      expect(iconRect.center.dx, closeTo(chipRect.center.dx, 0.01));
      expect(iconRect.center.dy, closeTo(chipRect.center.dy, 0.01));
    }
  }

  for (var index = 1; index < chipRects.length; index++) {
    expect(
      chipRects[index].left - chipRects[index - 1].right,
      closeTo(8, 0.01),
    );
  }

  final inactiveRects = [
    for (var index = 0; index < chipRects.length; index++)
      if (index != activeIndex) chipRects[index],
  ];
  for (final rect in inactiveRects.skip(1)) {
    expect(rect.width, closeTo(inactiveRects.first.width, 0.01));
  }
  expect(
    chipRects[activeIndex].width,
    closeTo(inactiveRects.first.width * 2, 0.01),
  );
  expect(tester.takeException(), isNull);
}

void main() {
  final scenarios =
      <({String name, double width, Locale locale, List<String> labels})>[
        (
          name: 'compact Indonesian',
          width: 320,
          locale: const Locale('id'),
          labels: const ['Semua', 'Belum', 'Progres', 'Selesai'],
        ),
        (
          name: 'compact English',
          width: 320,
          locale: const Locale('en'),
          labels: const ['All', 'Pending', 'In Progress', 'Completed'],
        ),
        (
          name: 'normal Indonesian',
          width: 412,
          locale: const Locale('id'),
          labels: const ['Semua', 'Belum', 'Progres', 'Selesai'],
        ),
        (
          name: 'normal English',
          width: 412,
          locale: const Locale('en'),
          labels: const ['All', 'Pending', 'In Progress', 'Completed'],
        ),
      ];

  for (final scenario in scenarios) {
    testWidgets('shows all four filters for ${scenario.name}', (tester) async {
      await _pumpTasksScreen(
        tester,
        width: scenario.width,
        locale: scenario.locale,
      );

      _expectFiltersInsideViewport(
        tester,
        width: scenario.width,
        labels: scenario.labels,
        activeIndex: 0,
      );

      await tester.tap(find.byKey(const ValueKey('task_filter_done')));
      await tester.pumpAndSettle();
      _expectFiltersInsideViewport(
        tester,
        width: scenario.width,
        labels: scenario.labels,
        activeIndex: 3,
      );
    });
  }

  testWidgets('keeps full English labels at compact width and increased text', (
    tester,
  ) async {
    await _pumpTasksScreen(
      tester,
      width: 320,
      locale: const Locale('en'),
      textScale: 1.3,
    );
    await tester.tap(find.byKey(const ValueKey('task_filter_progress')));
    await tester.pumpAndSettle();

    _expectFiltersInsideViewport(
      tester,
      width: 320,
      labels: const ['All', 'Pending', 'In Progress', 'Completed'],
      activeIndex: 2,
    );
  });

  testWidgets('filter taps keep the existing status behavior', (tester) async {
    final tasks = [
      _task('pending', TaskStatus.belum, 3),
      _task('progress', TaskStatus.progress, 2),
      _task('done', TaskStatus.done, 1),
    ];
    final container = await _pumpTasksScreen(
      tester,
      width: 320,
      locale: const Locale('en'),
      tasks: tasks,
    );

    expect(container.read(filteredTasksProvider).requireValue, hasLength(3));
    _expectFiltersInsideViewport(
      tester,
      width: 320,
      labels: const ['All', 'Pending', 'In Progress', 'Completed'],
      activeIndex: 0,
    );

    final initialAllWidth = tester
        .getSize(find.byKey(const ValueKey('task_filter_all')))
        .width;
    final initialPendingWidth = tester
        .getSize(find.byKey(const ValueKey('task_filter_pending')))
        .width;
    await tester.tap(find.byKey(const ValueKey('task_filter_pending')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final transitioningAllWidth = tester
        .getSize(find.byKey(const ValueKey('task_filter_all')))
        .width;
    final transitioningPendingWidth = tester
        .getSize(find.byKey(const ValueKey('task_filter_pending')))
        .width;
    expect(transitioningAllWidth, lessThan(initialAllWidth));
    expect(transitioningAllWidth, greaterThan(initialPendingWidth));
    expect(transitioningPendingWidth, greaterThan(initialPendingWidth));
    expect(transitioningPendingWidth, lessThan(initialAllWidth));
    await tester.pumpAndSettle();
    expect(container.read(selectedFilterProvider), TaskStatus.belum);
    expect(
      container.read(filteredTasksProvider).requireValue.map((task) => task.id),
      ['pending'],
    );
    _expectFiltersInsideViewport(
      tester,
      width: 320,
      labels: const ['All', 'Pending', 'In Progress', 'Completed'],
      activeIndex: 1,
    );

    await tester.tap(find.byKey(const ValueKey('task_filter_progress')));
    await tester.pumpAndSettle();
    expect(container.read(selectedFilterProvider), TaskStatus.progress);
    expect(
      container.read(filteredTasksProvider).requireValue.map((task) => task.id),
      ['progress'],
    );
    _expectFiltersInsideViewport(
      tester,
      width: 320,
      labels: const ['All', 'Pending', 'In Progress', 'Completed'],
      activeIndex: 2,
    );

    await tester.tap(find.byKey(const ValueKey('task_filter_done')));
    await tester.pumpAndSettle();
    expect(container.read(selectedFilterProvider), TaskStatus.done);
    expect(
      container.read(filteredTasksProvider).requireValue.map((task) => task.id),
      ['done'],
    );
    _expectFiltersInsideViewport(
      tester,
      width: 320,
      labels: const ['All', 'Pending', 'In Progress', 'Completed'],
      activeIndex: 3,
    );

    await tester.tap(find.byKey(const ValueKey('task_filter_all')));
    await tester.pumpAndSettle();
    expect(container.read(selectedFilterProvider), isNull);
    expect(container.read(filteredTasksProvider).requireValue, hasLength(3));
    _expectFiltersInsideViewport(
      tester,
      width: 320,
      labels: const ['All', 'Pending', 'In Progress', 'Completed'],
      activeIndex: 0,
    );
  });
}
