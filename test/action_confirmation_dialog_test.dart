import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_track/core/constants/app_colors.dart';
import 'package:task_track/core/constants/app_theme.dart';
import 'package:task_track/shared/widgets/action_confirmation_dialog.dart';
import 'package:task_track/shared/widgets/glass_card.dart';
import 'package:task_track/shared/widgets/neon_button.dart';

void main() {
  testWidgets(
    'confirmation dialog uses centered content and balanced actions',
    (WidgetTester tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await ActionConfirmationDialog.show(
                    context,
                    icon: Icons.logout,
                    title: 'Keluar dari Akun?',
                    description: 'Apakah Anda yakin ingin keluar dari akun?',
                    actionLabel: 'Keluar',
                    cancelLabel: 'Batal',
                  );
                },
                child: const Text('Buka Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka Dialog'));
      await tester.pumpAndSettle();

      final icon = find.byKey(const ValueKey('confirmation_dialog_icon'));
      final title = find.text('Keluar dari Akun?');
      final description = find.text(
        'Apakah Anda yakin ingin keluar dari akun?',
      );
      final action = find.byKey(const ValueKey('confirmation_dialog_action'));
      final cancel = find.byKey(const ValueKey('confirmation_dialog_cancel'));

      expect(icon, findsOneWidget);
      expect(title, findsOneWidget);
      expect(description, findsOneWidget);
      expect(action, findsOneWidget);
      expect(cancel, findsOneWidget);
      expect(find.byIcon(Icons.close), findsNothing);
      expect(
        tester.widget<GlassCard>(find.byType(GlassCard).first).level,
        GlassLevel.modal,
      );
      final barrier = tester
          .widgetList<ModalBarrier>(find.byType(ModalBarrier))
          .where((candidate) => candidate.color != null)
          .last;
      expect(barrier.color, AppPalette.dark.scrim);
      expect(barrier.color!.a, greaterThan(0.5));
      expect(
        tester
            .widget<Icon>(
              find.descendant(of: icon, matching: find.byIcon(Icons.logout)),
            )
            .color,
        AppPalette.dark.destructive,
      );
      expect(
        tester
            .widget<NeonButton>(
              find.descendant(of: action, matching: find.byType(NeonButton)),
            )
            .type,
        NeonButtonType.danger,
      );

      expect(tester.getCenter(icon).dy, lessThan(tester.getCenter(title).dy));
      expect(
        tester.getCenter(title).dy,
        lessThan(tester.getCenter(description).dy),
      );
      expect(
        tester.getCenter(description).dy,
        lessThan(tester.getCenter(action).dy),
      );

      final actionRect = tester.getRect(action);
      final cancelRect = tester.getRect(cancel);
      expect(actionRect.left, lessThan(cancelRect.left));
      expect(actionRect.width, closeTo(cancelRect.width, 0.01));
      expect(actionRect.height, closeTo(cancelRect.height, 0.01));
      expect(tester.widget<Text>(title).textAlign, TextAlign.center);
      expect(tester.widget<Text>(description).textAlign, TextAlign.center);

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(result, isFalse);
    },
  );
}
