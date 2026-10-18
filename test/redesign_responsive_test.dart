import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:task_track/core/constants/app_theme.dart';
import 'package:task_track/features/calendar/presentation/calendar_screen.dart';
import 'package:task_track/features/tasks/domain/task.dart';
import 'package:task_track/features/tasks/domain/task_status.dart';
import 'package:task_track/features/tasks/presentation/modals/task_detail_modal.dart';
import 'package:task_track/features/tasks/providers/task_provider.dart';
import 'package:task_track/shared/widgets/app_feedback.dart';
import 'package:task_track/shared/widgets/bottom_nav_bar.dart';

class _Tasks extends TaskListNotifier {
  @override
  Future<List<Task>> build() async => [];
}

Widget _app(Widget child, {double scale = 1}) => ProviderScope(
  overrides: [taskListProvider.overrideWith(_Tasks.new)],
  child: MaterialApp(
    theme: AppTheme.darkTheme,
    locale: const Locale('en'),
    supportedLocales: const [Locale('en'), Locale('id')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: child,
  ),
);

void main() {
  setUpAll(initializeDateFormatting);

  testWidgets(
    'calendar remains scrollable on short and enlarged-text screens',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final size in [const Size(320, 568), const Size(640, 360)]) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(_app(const CalendarScreen(), scale: 1.5));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
        await tester.pumpAndSettle();
        expect(
          find.text('No tasks for this date!').hitTestable(),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('task detail supports long content at double text scale', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.reset);
    final now = DateTime.now();
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: TaskDetailModal(
            task: Task(
              id: 'long-task',
              title: 'A long assignment title for the final semester project',
              subject: 'Advanced mathematics and computer science',
              description: 'Review the complete assignment before submission.',
              deadline: now.add(const Duration(days: 2)),
              status: TaskStatus.progress,
              createdAt: now,
              updatedAt: now,
            ),
          ),
        ),
        scale: 2,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final deadlineRect = tester.getRect(
      find.byKey(const ValueKey('task_detail_deadline')),
    );
    final statusRect = tester.getRect(
      find.byKey(const ValueKey('task_detail_status')),
    );
    expect(statusRect.left, greaterThan(deadlineRect.left));
    expect(
      statusRect.center.dy,
      inInclusiveRange(deadlineRect.top, deadlineRect.bottom),
    );

    final progressLabel = find.byKey(
      const ValueKey('task_detail_progress_label'),
    );
    final progressValue = find.byKey(
      const ValueKey('task_detail_progress_value'),
    );
    expect(
      tester.getRect(progressValue).right,
      greaterThan(tester.getRect(progressLabel).right),
    );
    final progressHeader = tester.widget<Row>(
      find.byKey(const ValueKey('task_detail_progress_header')),
    );
    expect(progressHeader.crossAxisAlignment, CrossAxisAlignment.baseline);
    expect(progressHeader.textBaseline, TextBaseline.alphabetic);
    await tester.ensureVisible(find.text('Delete Task'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('feedback replaces cleanly and clears dock and keyboard', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.reset);
    late BuildContext host;
    await tester.pumpWidget(
      _app(
        Scaffold(
          resizeToAvoidBottomInset: false,
          body: Builder(
            builder: (context) {
              host = context;
              return const SizedBox.expand();
            },
          ),
          bottomNavigationBar: BottomNavBar(
            currentIndex: 0,
            onTap: (_) {},
            onFabPressed: () {},
          ),
        ),
      ),
    );
    AppFeedback.show(host, message: 'First', aboveNavigation: true);
    // Replacing before the first overlay frame must not leave an orphan toast.
    AppFeedback.show(host, message: 'Saved', aboveNavigation: true);
    await tester.pumpAndSettle();
    expect(find.text('First'), findsNothing);
    expect(
      tester.getRect(find.text('Saved')).bottom,
      lessThan(tester.getRect(find.byType(BottomNavBar)).top),
    );
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.text('Saved')).bottom, lessThan(500));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('dock fits compact width with double text scale', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        Scaffold(
          bottomNavigationBar: BottomNavBar(
            currentIndex: 2,
            onTap: (_) {},
            onFabPressed: () {},
          ),
        ),
        scale: 2,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
