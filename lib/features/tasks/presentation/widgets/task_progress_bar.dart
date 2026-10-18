import 'package:flutter/material.dart';
import 'package:task_track/core/constants/app_colors.dart';
import 'package:task_track/core/constants/app_constants.dart';
import 'package:task_track/core/utils/status_helper.dart';
import 'package:task_track/features/tasks/domain/task_status.dart';

class TaskProgressBar extends StatefulWidget {
  final TaskStatus status;

  const TaskProgressBar({super.key, required this.status});

  @override
  State<TaskProgressBar> createState() => _TaskProgressBarState();
}

class _TaskProgressBarState extends State<TaskProgressBar> {
  double _from = 0;
  late double _to = StatusHelper.getProgressValue(widget.status);

  @override
  void didUpdateWidget(covariant TaskProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = StatusHelper.getProgressValue(widget.status);
    if (next != _to) {
      _from = _to;
      _to = next;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final color = StatusHelper.getColor(widget.status, p);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: _from, end: _to),
      duration: reduceMotion ? Duration.zero : AppConstants.animationContent,
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) => ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.radiusPill),
        child: LinearProgressIndicator(
          value: animated,
          minHeight: 4,
          backgroundColor: p.progressTrack,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    );
  }
}
