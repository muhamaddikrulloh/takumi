import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:task_track/core/constants/app_colors.dart';
import 'package:task_track/core/constants/app_constants.dart';
import 'package:task_track/core/localization/app_translations.dart';
import 'package:task_track/features/tasks/providers/reminder_provider.dart';
import 'package:task_track/features/tasks/presentation/modals/task_detail_modal.dart';
import 'package:task_track/shared/widgets/glass_card.dart';
import 'package:task_track/shared/widgets/notification_sheet.dart';

class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = AppColors.of(context);
    final count = ref.watch(remindersProvider).valueOrNull?.length ?? 0;
    final label = count > 0
        ? '${context.tr('notifications')}, $count'
        : context.tr('notifications');

    return Tooltip(
      message: context.tr('notifications'),
      child: GlassCard(
        level: GlassLevel.control,
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(AppConstants.radiusPanel),
        semanticLabel: label,
        onTap: () async {
          final task = await NotificationSheet.show(context);
          if (task != null && context.mounted) {
            await TaskDetailModal.show(context, task);
          }
        },
        child: SizedBox.square(
          dimension: AppConstants.minTouchTarget,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Icon(PhosphorIconsRegular.bell, color: p.iconColor, size: 22),
              if (count > 0)
                Positioned(
                  right: 3,
                  top: 3,
                  child: Container(
                    key: const ValueKey('notification_badge'),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: p.destructive,
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusPill,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        key: const ValueKey('notification_badge_text'),
                        style: TextStyle(
                          color: p.onDestructive,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
