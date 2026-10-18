import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_track/core/constants/app_colors.dart';
import 'package:task_track/core/utils/status_helper.dart';
import 'package:task_track/features/tasks/domain/task_status.dart';

void main() {
  test('warna status berbeda per status', () {
    expect(
      StatusHelper.getColor(TaskStatus.belum, AppPalette.dark),
      AppPalette.dark.statusPending,
    );
    expect(
      StatusHelper.getColor(TaskStatus.progress, AppPalette.dark),
      AppPalette.dark.primaryOrange,
    );
    expect(
      StatusHelper.getColor(TaskStatus.done, AppPalette.dark),
      AppPalette.dark.statusCompleted,
    );
  });

  test('dark palette mempertahankan merah dan hijau', () {
    expect(AppPalette.dark.statusPending, const Color(0xFFF05252));
    expect(AppPalette.dark.primaryOrange, AppColors.primaryOrange);
    expect(AppPalette.dark.statusCompleted, const Color(0xFF2FBF8F));
    expect(AppPalette.dark.destructive, const Color(0xFFF05252));
    expect(
      StatusHelper.getColor(TaskStatus.progress, AppPalette.dark),
      AppPalette.dark.primaryOrange,
    );
  });

  test('progress value sesuai mapping 0/50/100', () {
    expect(StatusHelper.getProgressValue(TaskStatus.belum), 0.0);
    expect(StatusHelper.getProgressValue(TaskStatus.progress), 0.5);
    expect(StatusHelper.getProgressValue(TaskStatus.done), 1.0);
  });

  test('label key & persentase', () {
    expect(StatusHelper.getLabelKey(TaskStatus.belum), 'pending');
    expect(StatusHelper.getLabelKey(TaskStatus.progress), 'in_progress');
    expect(StatusHelper.getLabelKey(TaskStatus.done), 'completed');
    expect(StatusHelper.getPercentLabel(TaskStatus.progress), '50%');
    expect(StatusHelper.getPercentLabel(TaskStatus.done), '100%');
  });
}
