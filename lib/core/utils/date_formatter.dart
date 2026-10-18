import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:task_track/core/localization/app_translations.dart';

class DateFormatter {
  DateFormatter._();

  static String formatDeadline(
    BuildContext context,
    DateTime deadline, [
    DateTime? now,
  ]) {
    final current = now ?? DateTime.now();
    final diff = deadline.difference(current);

    if (diff.isNegative) {
      return context.tr('overdue');
    }

    if (diff.inHours < 1) {
      return context.tr('minutes_left', args: {'n': '${diff.inMinutes}'});
    }

    if (diff.inHours < 24) {
      return context.tr('hours_left', args: {'n': '${diff.inHours}'});
    }

    if (diff.inDays == 1) {
      return context.tr('tomorrow');
    }

    if (diff.inDays < 7) {
      return context.tr('days_left', args: {'n': '${diff.inDays}'});
    }

    return DateFormat(
      'dd MMM yyyy, HH:mm',
      Localizations.localeOf(context).languageCode,
    ).format(deadline);
  }

  static String formatDateTime(DateTime date, Locale locale) {
    return DateFormat('dd MMM yyyy, HH:mm', locale.languageCode).format(date);
  }

  static bool isUrgent(DateTime deadline, [DateTime? now]) {
    final diff = deadline.difference(now ?? DateTime.now());
    return diff <= const Duration(days: 3) && !diff.isNegative;
  }
}
