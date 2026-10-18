import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:task_track/core/constants/app_colors.dart';
import 'package:task_track/core/constants/app_constants.dart';
import 'package:task_track/core/localization/app_translations.dart';
import 'package:task_track/shared/widgets/glass_card.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onFabPressed,
  });

  static const double navBarHeight = AppConstants.navBarHeight;
  static const double navBarBottomMargin = AppConstants.navBarBottomMargin;
  static const double occupiedHeight =
      AppConstants.navBarHeight + AppConstants.navBarTopInset;
  static const double contentClearance =
      AppConstants.navContentClearance + AppConstants.spacingMD;

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onFabPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: occupiedHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: navBarHeight,
            child: GlassCard(
              level: GlassLevel.navigation,
              padding: EdgeInsets.zero,
              borderRadius: BorderRadius.circular(AppConstants.radiusNavBar),
              child: Row(
                children: [
                  Expanded(
                    child: _NavItem(
                      key: const ValueKey('bottom_nav_item_home'),
                      icon: PhosphorIconsRegular.house,
                      label: context.tr('home'),
                      isActive: currentIndex == 0,
                      onTap: () => onTap(0),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      key: const ValueKey('bottom_nav_item_tasks'),
                      icon: PhosphorIconsRegular.listChecks,
                      label: context.tr('tasks'),
                      isActive: currentIndex == 1,
                      onTap: () => onTap(1),
                    ),
                  ),
                  const SizedBox(width: 60),
                  Expanded(
                    child: _NavItem(
                      key: const ValueKey('bottom_nav_item_calendar'),
                      icon: PhosphorIconsRegular.calendarBlank,
                      label: context.tr('calendar'),
                      isActive: currentIndex == 2,
                      onTap: () => onTap(2),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      key: const ValueKey('bottom_nav_item_profile'),
                      icon: PhosphorIconsRegular.userCircle,
                      label: context.tr('profile'),
                      isActive: currentIndex == 3,
                      onTap: () => onTap(3),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(top: 0, child: _FabButton(onPressed: onFabPressed)),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final color = isActive ? p.primaryOrange : p.textSecondary;
    return Semantics(
      button: true,
      selected: isActive,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          child: AnimatedContainer(
            duration: AppConstants.animationFast,
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingXS,
              vertical: AppConstants.spacingSM,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingXS,
              vertical: AppConstants.spacingXS,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: isActive ? 1.04 : 1,
                  duration: AppConstants.animationFast,
                  curve: Curves.easeOutCubic,
                  child: Icon(icon, size: 22, color: color),
                ),
                const SizedBox(height: AppConstants.spacingXS),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppConstants.fontBadge,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: color,
                      height: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FabButton extends StatelessWidget {
  const _FabButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final label = context.tr('add_task');
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Container(
              key: const ValueKey('primary_action_fab'),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: p.primaryOrange,
                border: Border.all(
                  color: p.glassHighlight.withValues(alpha: 0.32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: p.shadowDark.withValues(alpha: 0.52),
                    blurRadius: 20,
                    spreadRadius: -5,
                    offset: const Offset(0, 9),
                  ),
                ],
              ),
              child: Icon(
                PhosphorIconsRegular.plus,
                color: p.onPrimary,
                size: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
