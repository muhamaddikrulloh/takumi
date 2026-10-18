import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:task_track/core/constants/app_colors.dart';
import 'package:task_track/features/tasks/domain/task_status.dart';

class StatusHelper {
  StatusHelper._();

  static Color getColor(TaskStatus status, [AppPalette? palette]) {
    final p = palette ?? AppPalette.dark;
    switch (status) {
      case TaskStatus.belum:
        return p.statusPending;
      case TaskStatus.progress:
        return p.primaryOrange;
      case TaskStatus.done:
        return p.statusCompleted;
    }
  }

  static Color getForegroundColor(TaskStatus status, [AppPalette? palette]) {
    final p = palette ?? AppPalette.dark;
    return switch (status) {
      TaskStatus.belum => p.statusPendingForeground,
      TaskStatus.progress => p.statusProgressForeground,
      TaskStatus.done => p.statusCompletedForeground,
    };
  }

  static double getProgressValue(TaskStatus status) {
    switch (status) {
      case TaskStatus.belum:
        return 0.0;
      case TaskStatus.progress:
        return 0.5;
      case TaskStatus.done:
        return 1.0;
    }
  }

  static String getLabelKey(TaskStatus status) {
    switch (status) {
      case TaskStatus.belum:
        return 'pending';
      case TaskStatus.progress:
        return 'in_progress';
      case TaskStatus.done:
        return 'completed';
    }
  }

  static String getPercentLabel(TaskStatus status) {
    switch (status) {
      case TaskStatus.belum:
        return '0%';
      case TaskStatus.progress:
        return '50%';
      case TaskStatus.done:
        return '100%';
    }
  }

  static IconData getIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.belum:
        return PhosphorIconsRegular.circle;
      case TaskStatus.progress:
        return PhosphorIconsRegular.clock;
      case TaskStatus.done:
        return PhosphorIconsRegular.checkCircle;
    }
  }
}
