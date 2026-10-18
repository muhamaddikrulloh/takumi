import 'package:flutter/material.dart';
import 'package:task_track/core/constants/app_colors.dart';
import 'package:task_track/core/constants/app_constants.dart';
import 'package:task_track/shared/widgets/glass_modal_shell.dart';
import 'package:task_track/shared/widgets/neon_button.dart';

class ActionConfirmationDialog extends StatelessWidget {
  const ActionConfirmationDialog({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.cancelLabel,
  });

  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final String cancelLabel;

  static Future<bool?> show(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required String actionLabel,
    required String cancelLabel,
    bool nested = false,
  }) {
    return showGlassDialog<bool>(
      context,
      nested: nested,
      builder: (_) => ActionConfirmationDialog(
        icon: icon,
        title: title,
        description: description,
        actionLabel: actionLabel,
        cancelLabel: cancelLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);

    return GlassDialogShell(
      tintColor: p.destructive,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      key: const ValueKey('confirmation_dialog_icon'),
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: p.destructive.withValues(alpha: 0.12),
                      ),
                      child: Icon(icon, color: p.destructive, size: 28),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingXL),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: p.textPrimary,
                      fontSize: AppConstants.fontSection,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingSM),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: p.textSecondary,
                      fontSize: AppConstants.fontBody,
                      fontWeight: FontWeight.w400,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingXXL),
          LayoutBuilder(
            builder: (context, constraints) {
              final stackActions =
                  constraints.maxWidth < 280 ||
                  MediaQuery.textScalerOf(context).scale(1) > 1.3;
              final action = KeyedSubtree(
                key: const ValueKey('confirmation_dialog_action'),
                child: NeonButton(
                  label: actionLabel,
                  type: NeonButtonType.danger,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              );
              final cancel = KeyedSubtree(
                key: const ValueKey('confirmation_dialog_cancel'),
                child: NeonButton(
                  label: cancelLabel,
                  type: NeonButtonType.secondary,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              );

              if (stackActions) {
                return Column(
                  children: [
                    action,
                    const SizedBox(height: AppConstants.spacingMD),
                    cancel,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: action),
                  const SizedBox(width: AppConstants.spacingMD),
                  Expanded(child: cancel),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
