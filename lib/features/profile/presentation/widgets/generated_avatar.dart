import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:task_track/core/constants/app_colors.dart';
import 'package:task_track/features/profile/domain/avatar_catalog.dart';

class GeneratedAvatar extends StatelessWidget {
  const GeneratedAvatar({
    super.key,
    required this.avatarId,
    required this.size,
  });

  final String avatarId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final index = AvatarCatalog.ids.indexOf(avatarId);
    final palette = AppColors.of(context);
    return ClipOval(
      child: CustomPaint(
        size: Size.square(size),
        painter: _AvatarPainter(index < 0 ? 0 : index, palette),
      ),
    );
  }
}

class _AvatarPainter extends CustomPainter {
  const _AvatarPainter(this.index, this.palette);

  final int index;
  final AppPalette palette;

  static const _skinTones = <Color>[
    Color(0xFFF6D0B1),
    Color(0xFFDDA77B),
    Color(0xFF8D5524),
    Color(0xFFF1C27D),
    Color(0xFFC68642),
    Color(0xFFFFDBAC),
    Color(0xFFB8734A),
    Color(0xFFE0AC69),
    Color(0xFF7A4A2E),
    Color(0xFFF3C6A5),
  ];

  static const _hairColors = <Color>[
    Color(0xFF33251F),
    Color(0xFF171717),
    Color(0xFF5A3825),
    Color(0xFFD7A028),
    Color(0xFF2A1B15),
    Color(0xFF8E4B2B),
    Color(0xFF101820),
    Color(0xFF4A2C2A),
    Color(0xFF241C1A),
    Color(0xFFB36B35),
  ];

  List<Color> get _backgroundColors {
    final primary = switch (index) {
      0 || 5 => palette.primaryOrange,
      1 || 8 => palette.accentViolet,
      2 || 4 => palette.statusCompleted,
      3 || 7 => palette.statusPending,
      _ => palette.textSecondary,
    };
    final secondary = switch (index) {
      0 || 4 || 7 || 8 => palette.primaryOrange,
      1 || 3 => palette.accentViolet,
      2 || 9 => palette.statusCompleted,
      5 => palette.statusPending,
      _ => palette.backgroundDark,
    };
    return [
      Color.alphaBlend(
        primary.withValues(alpha: 0.78),
        palette.backgroundPrimary,
      ),
      Color.alphaBlend(
        secondary.withValues(alpha: 0.46),
        palette.backgroundDark,
      ),
    ];
  }

  Color get _shirtColor {
    final accent = switch (index) {
      0 || 4 || 7 => palette.accentViolet,
      1 || 3 || 6 => palette.primaryOrange,
      2 || 8 => palette.statusCompleted,
      5 => palette.textSecondary,
      _ => palette.statusPending,
    };
    return Color.alphaBlend(
      accent.withValues(alpha: 0.88),
      palette.backgroundDark,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width;
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _backgroundColors,
        ).createShader(rect),
    );

    final softGlow = Paint()
      ..color = palette.glassHighlight.withValues(alpha: 0.16);
    canvas.drawCircle(
      Offset(scale * 0.18, scale * 0.18),
      scale * 0.24,
      softGlow,
    );

    final shirtPaint = Paint()..color = _shirtColor;
    final shoulders = Path()
      ..moveTo(scale * 0.12, scale)
      ..quadraticBezierTo(scale * 0.18, scale * 0.72, scale * 0.5, scale * 0.72)
      ..quadraticBezierTo(scale * 0.82, scale * 0.72, scale * 0.88, scale)
      ..close();
    canvas.drawPath(shoulders, shirtPaint);

    final skinPaint = Paint()..color = _skinTones[index];
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(scale * 0.5, scale * 0.7),
          width: scale * 0.19,
          height: scale * 0.24,
        ),
        Radius.circular(scale * 0.08),
      ),
      skinPaint,
    );
    canvas.drawCircle(
      Offset(scale * 0.29, scale * 0.47),
      scale * 0.055,
      skinPaint,
    );
    canvas.drawCircle(
      Offset(scale * 0.71, scale * 0.47),
      scale * 0.055,
      skinPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(scale * 0.5, scale * 0.47),
        width: scale * 0.43,
        height: scale * 0.52,
      ),
      skinPaint,
    );

    _paintHair(canvas, scale, Paint()..color = _hairColors[index]);
    _paintFace(canvas, scale);

    if (index == 2 || index == 7) _paintGlasses(canvas, scale);
    if (index == 4 || index == 9) _paintFreckles(canvas, scale);
  }

  void _paintHair(Canvas canvas, double scale, Paint paint) {
    final style = index % 5;
    final hair = Path();
    switch (style) {
      case 0:
        hair
          ..moveTo(scale * 0.29, scale * 0.43)
          ..quadraticBezierTo(
            scale * 0.31,
            scale * 0.17,
            scale * 0.54,
            scale * 0.2,
          )
          ..quadraticBezierTo(
            scale * 0.76,
            scale * 0.22,
            scale * 0.7,
            scale * 0.46,
          )
          ..quadraticBezierTo(
            scale * 0.57,
            scale * 0.31,
            scale * 0.29,
            scale * 0.43,
          )
          ..close();
        break;
      case 1:
        hair
          ..moveTo(scale * 0.28, scale * 0.45)
          ..quadraticBezierTo(
            scale * 0.3,
            scale * 0.17,
            scale * 0.59,
            scale * 0.2,
          )
          ..lineTo(scale * 0.72, scale * 0.36)
          ..quadraticBezierTo(
            scale * 0.52,
            scale * 0.3,
            scale * 0.28,
            scale * 0.45,
          )
          ..close();
        break;
      case 2:
        for (var i = 0; i < 7; i++) {
          final angle = math.pi + (math.pi * i / 6);
          canvas.drawCircle(
            Offset(
              scale * (0.5 + math.cos(angle) * 0.19),
              scale * (0.39 + math.sin(angle) * 0.17),
            ),
            scale * 0.085,
            paint,
          );
        }
        return;
      case 3:
        hair
          ..moveTo(scale * 0.27, scale * 0.48)
          ..quadraticBezierTo(
            scale * 0.26,
            scale * 0.18,
            scale * 0.5,
            scale * 0.19,
          )
          ..quadraticBezierTo(
            scale * 0.76,
            scale * 0.2,
            scale * 0.73,
            scale * 0.53,
          )
          ..lineTo(scale * 0.66, scale * 0.42)
          ..quadraticBezierTo(
            scale * 0.5,
            scale * 0.28,
            scale * 0.27,
            scale * 0.48,
          )
          ..close();
        break;
      default:
        hair
          ..moveTo(scale * 0.29, scale * 0.43)
          ..quadraticBezierTo(
            scale * 0.34,
            scale * 0.13,
            scale * 0.67,
            scale * 0.24,
          )
          ..lineTo(scale * 0.72, scale * 0.42)
          ..quadraticBezierTo(
            scale * 0.55,
            scale * 0.3,
            scale * 0.29,
            scale * 0.43,
          )
          ..close();
    }
    canvas.drawPath(hair, paint);
  }

  void _paintFace(Canvas canvas, double scale) {
    final featurePaint = Paint()
      ..color = const Color(0xFF241C1A)
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(
      Offset(scale * 0.42, scale * 0.48),
      scale * 0.018,
      featurePaint,
    );
    canvas.drawCircle(
      Offset(scale * 0.58, scale * 0.48),
      scale * 0.018,
      featurePaint,
    );

    final smilePaint = Paint()
      ..color = const Color(0xFF7B3B32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = scale * 0.018
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(scale * 0.5, scale * 0.55),
        width: scale * 0.14,
        height: scale * 0.1,
      ),
      0.15,
      math.pi - 0.3,
      false,
      smilePaint,
    );
  }

  void _paintGlasses(Canvas canvas, double scale) {
    final glasses = Paint()
      ..color = const Color(0xFF222222)
      ..style = PaintingStyle.stroke
      ..strokeWidth = scale * 0.015;
    canvas.drawCircle(
      Offset(scale * 0.42, scale * 0.48),
      scale * 0.065,
      glasses,
    );
    canvas.drawCircle(
      Offset(scale * 0.58, scale * 0.48),
      scale * 0.065,
      glasses,
    );
    canvas.drawLine(
      Offset(scale * 0.485, scale * 0.48),
      Offset(scale * 0.515, scale * 0.48),
      glasses,
    );
  }

  void _paintFreckles(Canvas canvas, double scale) {
    final freckles = Paint()..color = const Color(0x997B3B32);
    for (final x in <double>[0.38, 0.41, 0.59, 0.62]) {
      canvas.drawCircle(
        Offset(scale * x, scale * 0.54),
        scale * 0.008,
        freckles,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter oldDelegate) {
    return oldDelegate.index != index || oldDelegate.palette != palette;
  }
}
