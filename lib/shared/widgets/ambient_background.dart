import 'package:flutter/material.dart';
import 'package:task_track/core/constants/app_colors.dart';

enum AmbientBackgroundStyle { standard, auth, profile }

/// A restrained ambient field designed to create depth behind glass.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({
    super.key,
    this.style = AmbientBackgroundStyle.standard,
  });

  final AmbientBackgroundStyle style;

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return RepaintBoundary(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _AmbientBackgroundPainter(
            baseColor: p.backgroundPrimary,
            depthColor: p.backgroundDark,
            orange: p.primaryOrange,
            violet: p.accentViolet,
            style: style,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _AmbientBackgroundPainter extends CustomPainter {
  const _AmbientBackgroundPainter({
    required this.baseColor,
    required this.depthColor,
    required this.orange,
    required this.violet,
    required this.style,
  });

  final Color baseColor;
  final Color depthColor;
  final Color orange;
  final Color violet;
  final AmbientBackgroundStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(bounds, Paint()..color = baseColor);

    // Elliptical edge glows leave neutral space between ambient sources.
    // Unlike a viewport-wide gradient, its falloff leaves dark space between
    // sources, so an identical glass surface changes with its position.
    _drawEllipticalGlow(
      canvas,
      center: Offset(size.width * 1.14, size.height * 0.48),
      radii: Size(size.width * 0.95, size.height * 0.40),
      color: orange.withValues(alpha: 0.38),
      strength: style == AmbientBackgroundStyle.auth ? 0.65 : 1,
    );
    _drawEllipticalGlow(
      canvas,
      center: Offset(size.width * -0.15, size.height * 0.83),
      radii: Size(size.width * 0.75, size.height * 0.29),
      color: orange.withValues(alpha: 0.12),
    );
    _drawRadialGlow(
      canvas,
      bounds,
      center: const Alignment(-0.8, -0.55),
      radius: 0.9,
      color: baseColor.withValues(alpha: 0.2),
    );

    if (style == AmbientBackgroundStyle.profile) {
      _drawEllipticalGlow(
        canvas,
        center: Offset(size.width * 0.74, size.height * 0.18),
        radii: Size(size.width * 0.64, size.height * 0.23),
        color: violet.withValues(alpha: 0.08),
      );
    }

    final vignette = Paint()
      ..shader = RadialGradient(
        radius: 0.95,
        colors: [
          baseColor.withValues(alpha: 0),
          depthColor.withValues(alpha: 0.34),
        ],
        stops: const [0.48, 1],
      ).createShader(bounds);
    canvas.drawRect(bounds, vignette);
  }

  void _drawEllipticalGlow(
    Canvas canvas, {
    required Offset center,
    required Size radii,
    required Color color,
    double strength = 1,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(radii.width, radii.height);
    const rect = Rect.fromLTRB(-1, -1, 1, 1);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: color.a * strength),
            color.withValues(alpha: color.a * strength * 0.55),
            color.withValues(alpha: color.a * strength * 0.13),
            color.withValues(alpha: 0),
          ],
          stops: const [0, 0.3, 0.64, 1],
          radius: 0.5,
        ).createShader(rect),
    );
    canvas.restore();
  }

  void _drawRadialGlow(
    Canvas canvas,
    Rect bounds, {
    required Alignment center,
    required double radius,
    required Color color,
  }) {
    final paint = Paint()
      ..shader = RadialGradient(
        center: center,
        radius: radius,
        colors: [color, color.withValues(alpha: 0)],
        stops: const [0, 1],
      ).createShader(bounds);
    canvas.drawRect(bounds, paint);
  }

  @override
  bool shouldRepaint(covariant _AmbientBackgroundPainter oldDelegate) {
    return oldDelegate.baseColor != baseColor ||
        oldDelegate.depthColor != depthColor ||
        oldDelegate.orange != orange ||
        oldDelegate.violet != violet ||
        oldDelegate.style != style;
  }
}
