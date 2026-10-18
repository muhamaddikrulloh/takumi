import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:task_track/core/constants/app_colors.dart';
import 'package:task_track/core/constants/app_constants.dart';

enum GlassLevel {
  input,
  control,
  subtle,
  standard,
  elevated,
  floating,
  modal,
  navigation,
}

/// Marks descendants that already sit on a blurred glass surface.
///
/// Compact descendants still receive material depth, but skip redundant blur.
class GlassMaterialScope extends InheritedWidget {
  const GlassMaterialScope({super.key, required super.child});

  static bool containsBackdrop(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GlassMaterialScope>() != null;

  @override
  bool updateShouldNotify(GlassMaterialScope oldWidget) => false;
}

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.constraints,
    this.borderRadius,
    this.borderColor,
    this.fillColor,
    this.tintColor,
    this.level = GlassLevel.standard,
    this.blurEnabled = true,
    this.groupedBlur = false,
    this.clipBehavior = Clip.antiAlias,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BoxConstraints? constraints;
  final BorderRadius? borderRadius;
  final Color? borderColor;
  final Color? fillColor;
  final Color? tintColor;
  final GlassLevel level;
  final bool blurEnabled;

  /// Only non-overlapping surfaces in a shared BackdropGroup may opt in.
  final bool groupedBlur;
  final Clip clipBehavior;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final radius = borderRadius ?? _radiusForLevel(level);
    final fill = fillColor ?? _fillForLevel(level, p);
    final tintStrength = _tintStrengthForLevel(level);
    final resolvedFill = tintColor == null
        ? fill
        : Color.alphaBlend(tintColor!.withValues(alpha: tintStrength), fill);
    final blur = _blurForLevel(level);
    final shadow = _shadowForLevel(level, p);
    final suppressNestedBlur =
        GlassMaterialScope.containsBackdrop(context) &&
        level != GlassLevel.modal &&
        level != GlassLevel.navigation;
    final shouldBlur = blurEnabled && !suppressNestedBlur && blur > 0;

    final body = _GlassBody(
      radius: radius,
      fill: resolvedFill,
      borderColor: borderColor ?? p.glassBorder,
      highlightColor: p.glassHighlight,
      shadeColor: p.shadowDark,
      reflectionStrength: _reflectionStrengthForLevel(level),
      edgeStrength: _edgeStrengthForLevel(level),
      padding: padding,
      child: child,
    );
    final filter = ImageFilter.blur(sigmaX: blur, sigmaY: blur);
    Widget surface = DecoratedBox(
      decoration: BoxDecoration(borderRadius: radius, boxShadow: shadow),
      child: ClipRRect(
        borderRadius: radius,
        clipBehavior: clipBehavior,
        child: !shouldBlur
            ? body
            : groupedBlur
            ? BackdropFilter.grouped(filter: filter, child: body)
            : BackdropFilter(filter: filter, child: body),
      ),
    );
    if (constraints != null) {
      surface = ConstrainedBox(constraints: constraints!, child: surface);
    }

    if (onTap == null) return surface;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: _GlassPressable(onTap: onTap!, child: surface),
    );
  }

  static BorderRadius _radiusForLevel(GlassLevel level) {
    return BorderRadius.circular(switch (level) {
      GlassLevel.input => AppConstants.radiusMedium,
      GlassLevel.control => AppConstants.radiusMedium,
      GlassLevel.subtle => AppConstants.radiusMedium,
      GlassLevel.standard => AppConstants.radiusLarge,
      GlassLevel.elevated => AppConstants.radiusPanel,
      GlassLevel.floating => AppConstants.radiusPanel,
      GlassLevel.modal => AppConstants.radiusXLarge,
      GlassLevel.navigation => AppConstants.radiusNavBar,
    });
  }

  static Color _fillForLevel(GlassLevel level, AppPalette p) {
    return switch (level) {
      GlassLevel.input => p.glassFillSubtle,
      GlassLevel.control => p.glassFillSubtle,
      GlassLevel.subtle => p.glassFillSubtle,
      GlassLevel.standard => p.glassFill,
      GlassLevel.elevated => p.glassFillStrong,
      GlassLevel.floating => Color.alphaBlend(
        p.glassFillStrong.withValues(alpha: 0.72),
        p.glassFill,
      ),
      GlassLevel.modal => p.modalSurface,
      GlassLevel.navigation => Color.alphaBlend(
        p.backgroundPrimary.withValues(alpha: 0.24),
        p.glassFill,
      ),
    };
  }

  static double _blurForLevel(GlassLevel level) {
    return switch (level) {
      GlassLevel.input => 0,
      GlassLevel.control => AppConstants.blurControl,
      GlassLevel.subtle => AppConstants.blurSubtle,
      GlassLevel.standard => AppConstants.blurSigma,
      GlassLevel.elevated => AppConstants.blurElevated,
      GlassLevel.floating => AppConstants.blurElevated,
      GlassLevel.modal => AppConstants.blurModal,
      GlassLevel.navigation => AppConstants.blurNavigation,
    };
  }

  static List<BoxShadow> _shadowForLevel(GlassLevel level, AppPalette p) {
    if (level == GlassLevel.input) return const [];
    final elevated =
        level == GlassLevel.elevated ||
        level == GlassLevel.floating ||
        level == GlassLevel.modal ||
        level == GlassLevel.navigation;
    final compact = level == GlassLevel.control || level == GlassLevel.subtle;
    return [
      BoxShadow(
        color: p.shadowDark.withValues(
          alpha:
              p.shadowDark.a *
              (elevated
                  ? 0.22
                  : compact
                  ? 0.12
                  : 0.16),
        ),
        blurRadius: elevated ? 4 : 3,
        spreadRadius: -1,
        offset: const Offset(0, 1),
      ),
      BoxShadow(
        color: p.shadowDark.withValues(
          alpha:
              p.shadowDark.a *
              (elevated
                  ? 0.42
                  : compact
                  ? 0.16
                  : 0.24),
        ),
        blurRadius: elevated
            ? 26
            : compact
            ? 12
            : 18,
        spreadRadius: elevated ? -7 : -5,
        offset: Offset(
          0,
          elevated
              ? 9
              : compact
              ? 3
              : 5,
        ),
      ),
    ];
  }

  static double _tintStrengthForLevel(GlassLevel level) => switch (level) {
    GlassLevel.input => 0.018,
    GlassLevel.control => 0.055,
    GlassLevel.subtle => 0.032,
    GlassLevel.standard => 0.022,
    GlassLevel.elevated => 0.026,
    GlassLevel.floating => 0.032,
    GlassLevel.modal => 0.022,
    GlassLevel.navigation => 0.024,
  };

  static double _reflectionStrengthForLevel(GlassLevel level) =>
      switch (level) {
        GlassLevel.input => 0.46,
        GlassLevel.control => 0.58,
        GlassLevel.subtle => 0.52,
        GlassLevel.standard => 0.68,
        GlassLevel.elevated => 0.8,
        GlassLevel.floating => 0.9,
        GlassLevel.modal => 0.82,
        GlassLevel.navigation => 0.92,
      };

  static double _edgeStrengthForLevel(GlassLevel level) => switch (level) {
    GlassLevel.input => 0.42,
    GlassLevel.control => 0.54,
    GlassLevel.subtle => 0.48,
    GlassLevel.standard => 0.62,
    GlassLevel.elevated => 0.72,
    GlassLevel.floating => 0.82,
    GlassLevel.modal => 0.76,
    GlassLevel.navigation => 0.82,
  };
}

class _GlassBody extends StatelessWidget {
  const _GlassBody({
    required this.radius,
    required this.fill,
    required this.borderColor,
    required this.highlightColor,
    required this.shadeColor,
    required this.reflectionStrength,
    required this.edgeStrength,
    required this.padding,
    required this.child,
  });

  final BorderRadius radius;
  final Color fill;
  final Color borderColor;
  final Color highlightColor;
  final Color shadeColor;
  final double reflectionStrength;
  final double edgeStrength;
  final EdgeInsetsGeometry? padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GlassEdgePainter(
        radius: radius,
        edge: borderColor,
        light: highlightColor,
        shade: shadeColor,
        strength: edgeStrength,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(color: fill, borderRadius: radius),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                highlightColor.withValues(
                  alpha: highlightColor.a * 0.075 * reflectionStrength,
                ),
                highlightColor.withValues(alpha: 0),
                shadeColor.withValues(
                  alpha: shadeColor.a * 0.075 * reflectionStrength,
                ),
              ],
              stops: const [0, 0.52, 1],
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: RadialGradient(
                center: const Alignment(0.72, -1.08),
                radius: 1.15,
                colors: [
                  highlightColor.withValues(
                    alpha: highlightColor.a * 0.045 * reflectionStrength,
                  ),
                  highlightColor.withValues(alpha: 0),
                ],
                stops: const [0, 0.72],
              ),
            ),
            child: Padding(
              padding:
                  padding ?? const EdgeInsets.all(AppConstants.cardPadding),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Optical rim: the illuminated edge is bright only near the light source.
/// A second, inset hairline suggests material thickness without outlining it.
class _GlassEdgePainter extends CustomPainter {
  const _GlassEdgePainter({
    required this.radius,
    required this.edge,
    required this.light,
    required this.shade,
    required this.strength,
  });

  final BorderRadius radius;
  final Color edge;
  final Color light;
  final Color shade;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(0.5);
    if (rect.isEmpty) return;
    final rim = radius.toRRect(rect);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppConstants.glassBorderWidth
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          light.withValues(alpha: light.a * 0.72 * strength),
          edge.withValues(alpha: edge.a * 0.34 * strength),
          edge.withValues(alpha: edge.a * 0.04 * strength),
          shade.withValues(alpha: shade.a * 0.08 * strength),
        ],
        stops: const [0, 0.3, 0.7, 1],
      ).createShader(rect);
    canvas.drawRRect(rim, paint);
    paint
      ..strokeWidth = 0.5
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          light.withValues(alpha: light.a * 0.12),
          light.withValues(alpha: 0),
        ],
        stops: const [0, 0.4],
      ).createShader(rect);
    canvas.drawRRect(rim.deflate(1.5), paint);
  }

  @override
  bool shouldRepaint(covariant _GlassEdgePainter oldDelegate) =>
      oldDelegate.radius != radius ||
      oldDelegate.edge != edge ||
      oldDelegate.light != light ||
      oldDelegate.shade != shade ||
      oldDelegate.strength != strength;
}

class _GlassPressable extends StatefulWidget {
  const _GlassPressable({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  State<_GlassPressable> createState() => _GlassPressableState();
}

class _GlassPressableState extends State<_GlassPressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed && !reduceMotion ? 0.985 : 1,
        duration: reduceMotion ? Duration.zero : AppConstants.animationMicro,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
