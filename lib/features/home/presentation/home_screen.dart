import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:task_track/core/constants/app_colors.dart';
import 'package:task_track/core/constants/app_constants.dart';
import 'package:task_track/core/localization/app_translations.dart';
import 'package:task_track/core/providers/connectivity_provider.dart';
import 'package:task_track/core/utils/date_formatter.dart';
import 'package:task_track/features/home/providers/home_provider.dart';
import 'package:task_track/features/profile/domain/profile.dart';
import 'package:task_track/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:task_track/features/profile/providers/profile_provider.dart';
import 'package:task_track/features/tasks/presentation/modals/task_detail_modal.dart';
import 'package:task_track/features/tasks/presentation/widgets/task_card.dart';
import 'package:task_track/shared/widgets/ambient_background.dart';
import 'package:task_track/shared/widgets/bottom_nav_bar.dart';
import 'package:task_track/shared/widgets/empty_state.dart';
import 'package:task_track/shared/widgets/error_view.dart';
import 'package:task_track/shared/widgets/glass_card.dart';
import 'package:task_track/shared/widgets/glass_icon_button.dart';
import 'package:task_track/shared/widgets/glass_modal_shell.dart';
import 'package:task_track/shared/widgets/loading_view.dart';
import 'package:task_track/shared/widgets/notification_bell.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, this.onAvatarTap});

  final VoidCallback? onAvatarTap;

  static String _greetingName(BuildContext context, String displayName) {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return context.tr('student');
    return trimmed.split(' ').first;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = AppColors.of(context);
    final profile =
        ref.watch(profileProvider).valueOrNull ??
        ref.watch(profileGateProvider).valueOrNull ??
        const Profile(displayName: '', email: '', institution: '', major: '');
    final belumAsync = ref.watch(belumTasksProvider);
    final progressAsync = ref.watch(progressTasksProvider);
    final doneAsync = ref.watch(completedTasksProvider);
    final urgentAsync = ref.watch(urgentTasksProvider);
    final upcomingAsync = ref.watch(upcomingTasksProvider);
    final isOnline = ref.watch(connectivityProvider).valueOrNull ?? true;
    const bottomPad = BottomNavBar.contentClearance;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const Positioned.fill(child: AmbientBackground()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingXL,
                vertical: AppConstants.spacingLG,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Greeting
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Semantics(
                              button: true,
                              label: context.tr('profile'),
                              child: Material(
                                color: Colors.transparent,
                                shape: const CircleBorder(),
                                child: InkWell(
                                  key: const ValueKey('home_profile_avatar'),
                                  customBorder: const CircleBorder(),
                                  onTap: onAvatarTap,
                                  child: Container(
                                    padding: const EdgeInsets.all(1),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: p.primaryOrange,
                                    ),
                                    child: CircleAvatar(
                                      radius: 24,
                                      backgroundColor: p.backgroundDark,
                                      child: ProfileAvatar(
                                        avatarId: profile.avatarId,
                                        photoUrl: profile.photoUrl,
                                        size: 48,
                                        fallbackColor: p.iconColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppConstants.spacingMD),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.tr(
                                      'greeting',
                                      args: {
                                        'name': _greetingName(
                                          context,
                                          profile.displayName,
                                        ),
                                      },
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: AppConstants.fontTask,
                                      fontWeight: FontWeight.bold,
                                      color: p.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    context.tr('motivation'),
                                    key: const ValueKey('home_motivation'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: AppConstants.fontSecondary,
                                      color: p.textSecondary.withValues(
                                        alpha: 0.94,
                                      ),
                                      fontWeight: FontWeight.w500,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppConstants.spacingSM),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isOnline)
                            GlassIconButton(
                              icon: PhosphorIconsRegular.cloudSlash,
                              color: p.destructive,
                              tooltip: context.tr('offline_mode_title'),
                              onPressed: () => showGlassDialog(
                                context,
                                builder: (ctx) => _OfflineInfoDialog(
                                  title: context.tr('offline_mode_title'),
                                  description: context.tr('offline_mode_desc'),
                                ),
                              ),
                            ),
                          if (!isOnline)
                            const SizedBox(width: AppConstants.spacingSM),
                          const NotificationBell(),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spacingXXL),

                  // Urgent Deadline Banner
                  urgentAsync.when(
                    data: (tasks) {
                      if (tasks.isEmpty) return const SizedBox.shrink();
                      final nextTask = tasks.first;
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppConstants.spacingXXL,
                        ),
                        child: GlassCard(
                          level: GlassLevel.elevated,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.spacingLG,
                            vertical: AppConstants.spacingLG,
                          ),
                          onTap: () => TaskDetailModal.show(context, nextTask),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(
                                  AppConstants.spacingSM,
                                ),
                                decoration: BoxDecoration(
                                  color: p.destructive.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  PhosphorIconsRegular.warning,
                                  color: p.destructive,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: AppConstants.spacingMD),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${context.tr('urgent_banner')} (${DateFormatter.formatDeadline(context, nextTask.deadline)}).',
                                      style: TextStyle(
                                        fontSize: AppConstants.fontBody,
                                        fontWeight: FontWeight.w500,
                                        color: p.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: AppConstants.spacingXS,
                                    ),
                                    Text(
                                      nextTask.title,
                                      style: TextStyle(
                                        fontSize: AppConstants.fontBody,
                                        fontWeight: FontWeight.w600,
                                        color: p.textPrimary,
                                        height: 1.3,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (error, stackTrace) => const SizedBox.shrink(),
                  ),

                  // Status Distribution Bar Chart
                  _StatusBarChartCard(
                    belumAsync: belumAsync,
                    progressAsync: progressAsync,
                    doneAsync: doneAsync,
                  ),
                  const SizedBox(height: AppConstants.spacingSection),

                  // Upcoming Tasks Header
                  Text(
                    context.tr('upcoming_tasks'),
                    style: TextStyle(
                      fontSize: AppConstants.fontSection,
                      fontWeight: FontWeight.bold,
                      color: p.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingMD),

                  // Upcoming Tasks List
                  upcomingAsync.when(
                    data: (tasks) {
                      if (tasks.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: EmptyState(
                            icon: PhosphorIconsRegular.checkSquare,
                            title: context.tr('no_tasks'),
                            subtitle: context.tr('no_tasks_subtitle'),
                          ),
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: tasks.length > 3 ? 3 : tasks.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: AppConstants.spacingMD),
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return TaskCard(
                            task: task,
                            onTap: () => TaskDetailModal.show(context, task),
                          );
                        },
                      );
                    },
                    loading: () => const LoadingView(),
                    error: (err, _) => const ErrorView(),
                  ),
                  SizedBox(height: bottomPad),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBarChartCard extends StatelessWidget {
  final AsyncValue<int> belumAsync;
  final AsyncValue<int> progressAsync;
  final AsyncValue<int> doneAsync;

  const _StatusBarChartCard({
    required this.belumAsync,
    required this.progressAsync,
    required this.doneAsync,
  });

  @override
  Widget build(BuildContext context) {
    final belum = belumAsync.valueOrNull;
    final progress = progressAsync.valueOrNull;
    final done = doneAsync.valueOrNull;

    return GlassCard(
      padding: const EdgeInsets.all(AppConstants.spacingLG),
      child: belumAsync.hasError || progressAsync.hasError || doneAsync.hasError
          ? const ErrorView()
          : belum == null || progress == null || done == null
          ? const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          : _StatusBarBody(belum: belum, progress: progress, done: done),
    );
  }
}

class _StatusBarBody extends StatelessWidget {
  final int belum;
  final int progress;
  final int done;

  const _StatusBarBody({
    required this.belum,
    required this.progress,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final total = belum + progress + done;

    final slices = <_BarSlice>[
      _BarSlice(
        label: context.tr('pending'),
        value: belum,
        color: p.statusPending,
      ),
      _BarSlice(
        label: context.tr('in_progress'),
        value: progress,
        color: p.primaryOrange,
      ),
      _BarSlice(
        label: context.tr('completed'),
        value: done,
        color: p.statusCompleted,
      ),
    ];

    final yMaxV = [belum, progress, done].fold<int>(0, (m, v) => v > m ? v : m);
    final yMax = yMaxV <= 0 ? 1.0 : yMaxV.toDouble();

    return Column(
      children: [
        Column(
          children: [
            Text(
              '$total',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: p.textPrimary,
                height: 1,
              ),
            ),
            const SizedBox(height: AppConstants.spacingXS),
            Text(
              context.tr('total_tasks'),
              style: TextStyle(
                fontSize: AppConstants.fontSecondary,
                color: p.textSecondary,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingLG),
        SizedBox(
          height: 180,
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppConstants.spacingMD,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      4,
                      (_) => Container(
                        height: 1,
                        color: p.textSecondary.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < slices.length; i++)
                    Expanded(
                      child: _BarStatColumn(slice: slices[i], yMax: yMax),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppConstants.spacingLG),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < slices.length; i++)
              Expanded(
                child: Column(
                  children: [
                    Text(
                      slices[i].label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: AppConstants.fontSecondary,
                        color: p.textSecondary,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${slices[i].value}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: AppConstants.fontBody,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _BarSlice {
  final String label;
  final int value;
  final Color color;

  const _BarSlice({
    required this.label,
    required this.value,
    required this.color,
  });
}

class _BarStatColumn extends StatelessWidget {
  final _BarSlice slice;
  final double yMax;

  const _BarStatColumn({required this.slice, required this.yMax});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final ratio = yMax <= 0 ? 0.0 : (slice.value / yMax).clamp(0.0, 1.0);
        final plotHeight = availableHeight - AppConstants.spacingMD * 2;
        final rawHeight = plotHeight * ratio;
        final barHeight = slice.value == 0
            ? 0.0
            : rawHeight.clamp(4.0, plotHeight).toDouble();
        final reduceMotion =
            MediaQuery.maybeOf(context)?.disableAnimations ?? false;

        return Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppConstants.spacingMD,
            ),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: barHeight),
              duration: reduceMotion
                  ? Duration.zero
                  : AppConstants.animationContent,
              curve: Curves.easeOutCubic,
              builder: (context, animatedHeight, _) => Container(
                width: (constraints.maxWidth * 0.55)
                    .clamp(24.0, 68.0)
                    .toDouble(),
                height: animatedHeight,
                decoration: BoxDecoration(
                  color: slice.color,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OfflineInfoDialog extends StatelessWidget {
  const _OfflineInfoDialog({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return GlassDialogShell(
      tintColor: p.destructive,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: p.destructive.withValues(alpha: 0.12),
            ),
            child: Icon(
              PhosphorIconsRegular.cloudSlash,
              color: p.destructive,
              size: 28,
            ),
          ),
          const SizedBox(height: AppConstants.spacingLG),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppConstants.spacingSM),
          Text(
            description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: p.textSecondary),
          ),
        ],
      ),
    );
  }
}
