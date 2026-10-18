import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_track/core/constants/app_constants.dart';
import 'package:task_track/core/localization/app_translations.dart';
import 'package:task_track/features/calendar/presentation/calendar_screen.dart';
import 'package:task_track/features/home/presentation/home_screen.dart';
import 'package:task_track/features/profile/presentation/profile_screen.dart';
import 'package:task_track/features/profile/providers/profile_provider.dart';
import 'package:task_track/features/tasks/presentation/modals/task_form_modal.dart';
import 'package:task_track/features/tasks/presentation/tasks_screen.dart';
import 'package:task_track/features/tasks/providers/task_provider.dart';
import 'package:task_track/shared/widgets/app_feedback.dart';
import 'package:task_track/shared/widgets/bottom_nav_bar.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(onAvatarTap: () => _onTabTapped(3)),
      const TasksScreen(),
      const CalendarScreen(),
      const ProfileScreen(),
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onFabPressed() {
    TaskFormModal.show(context);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<Object?>(taskSyncErrorProvider, (_, error) {
      if (error == null) return;
      AppFeedback.show(
        context,
        message: context.tr('sync_failed'),
        type: AppFeedbackType.error,
        aboveNavigation: true,
      );
      ref.read(taskSyncErrorProvider.notifier).state = null;
    });
    ref.listen<Object?>(profileSyncErrorProvider, (_, error) {
      if (error == null) return;
      AppFeedback.show(
        context,
        message: context.tr('sync_failed'),
        type: AppFeedbackType.error,
        aboveNavigation: true,
      );
      ref.read(profileSyncErrorProvider.notifier).state = null;
    });

    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                for (var index = 0; index < _screens.length; index++)
                  TickerMode(
                    enabled: index == _currentIndex,
                    child: _screens[index],
                  ),
              ],
            ),
          ),
          Positioned(
            left: AppConstants.navBarHorizontalMargin,
            right: AppConstants.navBarHorizontalMargin,
            bottom:
                MediaQuery.viewPaddingOf(context).bottom +
                AppConstants.navBarBottomMargin,
            child: BottomNavBar(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              onFabPressed: _onFabPressed,
            ),
          ),
        ],
      ),
    );
  }
}
