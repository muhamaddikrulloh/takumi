import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:task_track/core/constants/app_colors.dart';
import 'package:task_track/core/constants/app_theme.dart';
import 'package:task_track/features/tasks/domain/task.dart';
import 'package:task_track/features/tasks/domain/task_status.dart';
import 'package:task_track/features/tasks/presentation/modals/task_detail_modal.dart';
import 'package:task_track/shared/widgets/bottom_nav_bar.dart';
import 'package:task_track/shared/widgets/neon_button.dart';

Future<void> _pumpButton(WidgetTester tester, {required NeonButtonType type}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: NeonButton(label: 'Action', type: type, onPressed: () {}),
      ),
    ),
  );
}

Task _task(TaskStatus status) {
  final now = DateTime.now();
  return Task(
    id: status.name,
    title: 'Semantic task',
    subject: 'Testing',
    description: '',
    deadline: now.add(const Duration(days: 3)),
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

Future<void> _pumpTaskDetail(WidgetTester tester, TaskStatus status) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('id'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: TaskDetailModal(key: ValueKey(status), task: _task(status)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpBottomNav(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        bottomNavigationBar: BottomNavBar(
          currentIndex: 0,
          onTap: (_) {},
          onFabPressed: () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(initializeDateFormatting);

  testWidgets('semantic buttons use centralized dark colors', (tester) async {
    const palette = AppPalette.dark;
    final cases = <({NeonButtonType type, Color background, Color foreground})>[
      (
        type: NeonButtonType.primary,
        background: palette.primaryOrange,
        foreground: palette.onPrimary,
      ),
      (
        type: NeonButtonType.inProgress,
        background: palette.primaryOrange,
        foreground: palette.onPrimary,
      ),
      (
        type: NeonButtonType.completed,
        background: palette.statusCompleted,
        foreground: palette.onSuccess,
      ),
      (
        type: NeonButtonType.danger,
        background: palette.destructive.withValues(alpha: 0.12),
        foreground: palette.destructive,
      ),
    ];

    for (final testCase in cases) {
      await _pumpButton(tester, type: testCase.type);
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(
        button.style?.backgroundColor?.resolve(<WidgetState>{}),
        testCase.background,
      );
      expect(
        button.style?.foregroundColor?.resolve(<WidgetState>{}),
        testCase.foreground,
      );
    }

    await _pumpBottomNav(tester);
    final fab = tester.widget<Container>(
      find.byKey(const ValueKey('primary_action_fab')),
    );
    expect((fab.decoration! as BoxDecoration).color, palette.primaryOrange);

    final activeItem = find.byKey(const ValueKey('bottom_nav_item_home'));
    final inactiveItem = find.byKey(const ValueKey('bottom_nav_item_tasks'));
    final activeIcon = tester.widget<Icon>(
      find.descendant(of: activeItem, matching: find.byType(Icon)),
    );
    final activeText = tester.widget<Text>(
      find.descendant(of: activeItem, matching: find.text('Home')),
    );
    final inactiveText = tester.widget<Text>(
      find.descendant(of: inactiveItem, matching: find.text('Tasks')),
    );
    final activeSurface = tester.widget<AnimatedContainer>(
      find.descendant(of: activeItem, matching: find.byType(AnimatedContainer)),
    );
    expect(activeIcon.color, palette.primaryOrange);
    expect(activeText.style?.color, palette.primaryOrange);
    expect(inactiveText.style?.color, palette.textSecondary);
    expect(activeSurface.decoration, isNull);
  });

  testWidgets('task detail actions use the destination status semantics', (
    tester,
  ) async {
    await _pumpTaskDetail(tester, TaskStatus.belum);
    expect(
      tester
          .widget<NeonButton>(find.widgetWithText(NeonButton, 'Start (50%)'))
          .type,
      NeonButtonType.inProgress,
    );
    expect(
      tester
          .widget<NeonButton>(find.widgetWithText(NeonButton, 'Delete Task'))
          .type,
      NeonButtonType.danger,
    );

    await _pumpTaskDetail(tester, TaskStatus.progress);
    expect(
      tester
          .widget<NeonButton>(find.widgetWithText(NeonButton, 'Finish (100%)'))
          .type,
      NeonButtonType.completed,
    );
    expect(
      tester
          .widget<NeonButton>(find.widgetWithText(NeonButton, 'Delete Task'))
          .type,
      NeonButtonType.danger,
    );
  });
}
