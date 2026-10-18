// Opt-in rendering audit, not a pixel-perfect golden assertion.
// flutter test test/visual_review_test.dart --dart-define=RENDER_REVIEW=true
import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:task_track/core/constants/app_theme.dart';

import 'support/visual_review.dart';

class _RealNetwork extends HttpOverrides {}

void main() {
  testWidgets(
    'render actual screens for visual material review',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final cache = Directory('build/visual_review/font_cache')
        ..createSync(recursive: true);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (_) async => cache.absolute.path,
      );
      late ThemeData theme;
      final manifest = jsonDecode(
        await rootBundle.loadString('FontManifest.json'),
      ) as List<dynamic>;
      for (final family in manifest) {
        final loader = FontLoader(family['family'] as String);
        for (final font in family['fonts'] as List<dynamic>) {
          loader.addFont(rootBundle.load(font['asset'] as String));
        }
        await loader.load();
      }
      await tester.runAsync(
        () => HttpOverrides.runWithHttpOverrides(() async {
          GoogleFonts.config.allowRuntimeFetching = true;
          theme = AppTheme.darkTheme;
          await GoogleFonts.pendingFonts();
        }, _RealNetwork()),
      );
      final images = <ui.Image>[];
      for (final scene in [
        'home',
        'tasks',
        'calendar',
        'profile',
        'login',
        'register',
        'reset',
        'verification',
        'setup',
        'form',
        'detail',
        'notifications',
        'feedback',
        'confirmation',
        'identity',
      ]) {
        final prefs = await reviewPreferences();
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: ReviewApp(
              key: UniqueKey(),
              prefs: prefs,
              scene: scene,
              theme: theme,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 120));
        });
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull, reason: scene);
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage();
          images.add(image);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final dir = Directory('build/visual_review')
            ..createSync(recursive: true);
          await File('${dir.path}/${scene}_dark.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
        });
      }
      await tester.runAsync(() async {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        for (var i = 0; i < images.length; i++) {
          canvas.drawImage(
            images[i],
            Offset((i % 4) * 390, (i ~/ 4) * 844),
            Paint(),
          );
        }
        final picture = recorder.endRecording();
        final sheet = await picture.toImage(1560, 3376);
        final bytes = await sheet.toByteData(format: ui.ImageByteFormat.png);
        await File('build/visual_review/contact_dark.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        for (final image in images) {
          image.dispose();
        }
        sheet.dispose();
        picture.dispose();
      });
      await tester.pumpWidget(const SizedBox.shrink());
    },
    skip: !const bool.fromEnvironment('RENDER_REVIEW'),
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
