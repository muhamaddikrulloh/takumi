import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_track/core/constants/app_colors.dart';
import 'package:task_track/core/constants/app_theme.dart';
import 'package:task_track/shared/widgets/glass_card.dart';
import 'package:task_track/shared/widgets/glass_text_field.dart';

void main() {
  test('dark glass uses a bright edge and layered scrim hierarchy', () {
    expect(AppPalette.dark.glassBorder.computeLuminance(), greaterThan(0.9));
    expect(AppPalette.dark.scrim.a, greaterThan(0.5));
    expect(AppPalette.dark.nestedScrim.a, lessThan(AppPalette.dark.scrim.a));
    expect(
      AppTheme.darkTheme.bottomSheetTheme.modalBarrierColor,
      AppPalette.dark.scrim,
    );
    expect(AppTheme.darkTheme.dialogTheme.barrierColor, AppPalette.dark.scrim);
  });

  testWidgets('text fields use the centralized recessed glass role', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(20),
            child: GlassTextField(labelText: 'Title'),
          ),
        ),
      ),
    );

    final glass = tester.widget<GlassCard>(
      find.descendant(
        of: find.byType(GlassTextField),
        matching: find.byType(GlassCard),
      ),
    );
    expect(glass.level, GlassLevel.input);
    expect(glass.blurEnabled, isFalse);
    expect(
      AppTheme.darkTheme.inputDecorationTheme.enabledBorder!.borderSide,
      BorderSide.none,
    );
  });
}
