import 'package:flutter/material.dart';
import 'package:task_track/core/constants/app_colors.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: p.primaryOrange,
        ),
      ),
    );
  }
}
