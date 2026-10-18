import 'package:flutter/material.dart';
import 'package:task_track/core/constants/app_colors.dart';
import 'package:task_track/core/constants/app_constants.dart';
import 'package:task_track/shared/widgets/app_logo.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        children: [
          AppLogo(width: 112, color: p.primaryOrange),
          const SizedBox(height: AppConstants.spacingLG),
          Text(
            title,
            textAlign: TextAlign.center,
            style: textTheme.displaySmall?.copyWith(letterSpacing: -0.5),
          ),
          const SizedBox(height: AppConstants.spacingSM),
          Text(
            description,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: p.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
