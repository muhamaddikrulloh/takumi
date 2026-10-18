import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_track/core/utils/date_formatter.dart';

Widget _host(Widget child) => MaterialApp(
  locale: const Locale('id'),
  supportedLocales: const [Locale('id')],
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: child,
);

void main() {
  testWidgets('formatDeadline memilih kategori sesuai jarak', (tester) async {
    final now = DateTime(2026, 1, 10, 12);
    String? minutes, hours, tomorrow, days, overdue;
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) {
            minutes = DateFormatter.formatDeadline(
              context,
              now.add(const Duration(minutes: 30)),
              now,
            );
            hours = DateFormatter.formatDeadline(
              context,
              now.add(const Duration(hours: 5)),
              now,
            );
            tomorrow = DateFormatter.formatDeadline(
              context,
              now.add(const Duration(days: 1)),
              now,
            );
            days = DateFormatter.formatDeadline(
              context,
              now.add(const Duration(days: 3)),
              now,
            );
            overdue = DateFormatter.formatDeadline(
              context,
              now.subtract(const Duration(hours: 1)),
              now,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(minutes, '30 menit lagi');
    expect(hours, '5 jam lagi');
    expect(tomorrow, 'Besok');
    expect(days, '3 hari lagi');
    expect(overdue, 'Sudah lewat');

    expect(
      DateFormatter.isUrgent(now.add(const Duration(days: 3)), now),
      isTrue,
    );
    expect(
      DateFormatter.isUrgent(now.add(const Duration(days: 3, seconds: 1)), now),
      isFalse,
    );
    expect(DateFormatter.isUrgent(now, now), isTrue);
    expect(
      DateFormatter.isUrgent(now.subtract(const Duration(seconds: 1)), now),
      isFalse,
    );
  });
}
