import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:task_track/core/constants/app_colors.dart';
import 'package:task_track/core/constants/app_constants.dart';
import 'package:task_track/shared/widgets/glass_card.dart';

enum AppFeedbackType { success, error, warning, info }

class AppFeedback {
  AppFeedback._();

  static OverlayEntry? _entry;
  static OverlayState? _overlay;
  static GlobalKey<_FeedbackToastState>? _toastKey;

  static void show(
    BuildContext context, {
    required String message,
    AppFeedbackType type = AppFeedbackType.info,
    bool aboveNavigation = false,
    Duration? duration,
  }) {
    _removeCurrent();
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    final key = GlobalKey<_FeedbackToastState>();
    final displayDuration =
        duration ??
        (type == AppFeedbackType.error
            ? const Duration(milliseconds: 3600)
            : const Duration(milliseconds: 2600));
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) {
        final media = MediaQuery.of(overlayContext);
        final safeBottom = aboveNavigation
            ? media.padding.bottom +
                  AppConstants.navContentClearance +
                  AppConstants.spacingMD
            : media.padding.bottom + AppConstants.spacingLG;
        final bottom = math.max(
          safeBottom,
          media.viewInsets.bottom + AppConstants.spacingLG,
        );
        return Positioned(
          left: media.size.width * 0.06,
          right: media.size.width * 0.06,
          bottom: bottom,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: _FeedbackToast(
                key: key,
                message: message,
                type: type,
                displayDuration: displayDuration,
                onDismissed: () {
                  if (identical(_entry, entry)) _removeCurrent();
                },
              ),
            ),
          ),
        );
      },
    );

    _entry = entry;
    _overlay = overlay;
    _toastKey = key;
    overlay.insert(entry);
  }

  static void hide() {
    final key = _toastKey;
    if (key == null) return;
    final entry = _entry;
    key.currentState?.dismiss().then((_) {
      if (identical(_entry, entry)) _removeCurrent();
    });
  }

  static void _removeCurrent() {
    final entry = _entry;
    if (entry != null && (_overlay?.mounted ?? false)) entry.remove();
    _entry = null;
    _overlay = null;
    _toastKey = null;
  }
}

class _FeedbackToast extends StatefulWidget {
  const _FeedbackToast({
    super.key,
    required this.message,
    required this.type,
    required this.displayDuration,
    required this.onDismissed,
  });

  final String message;
  final AppFeedbackType type;
  final Duration displayDuration;
  final VoidCallback onDismissed;

  @override
  State<_FeedbackToast> createState() => _FeedbackToastState();
}

class _FeedbackToastState extends State<_FeedbackToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;
  Timer? _dismissTimer;
  bool _closing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.duration = Duration.zero;
      _controller.reverseDuration = Duration.zero;
      if (!_closing) _controller.value = 1;
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppConstants.animationContent,
      reverseDuration: AppConstants.animationFast,
    );
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _opacity = curved;
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.22),
      end: Offset.zero,
    ).animate(curved);
    _controller.addStatusListener((status) {
      if (_closing && status == AnimationStatus.dismissed) {
        widget.onDismissed();
      }
    });
    _controller.forward();
    _dismissTimer = Timer(widget.displayDuration, dismiss);
  }

  Future<void> dismiss() async {
    if (!mounted || _closing) return;
    _closing = true;
    _dismissTimer?.cancel();
    await _controller.reverse();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final (accent, icon) = switch (widget.type) {
      AppFeedbackType.success => (
        p.statusCompleted,
        PhosphorIconsRegular.checkCircle,
      ),
      AppFeedbackType.error => (
        p.destructive,
        PhosphorIconsRegular.warningCircle,
      ),
      AppFeedbackType.warning => (
        p.primaryOrange,
        PhosphorIconsRegular.warning,
      ),
      AppFeedbackType.info => (p.primaryOrange, PhosphorIconsRegular.info),
    };

    return Semantics(
      container: true,
      liveRegion: true,
      label: widget.message,
      child: FadeTransition(
        opacity: _opacity,
        child: SlideTransition(
          position: _offset,
          child: Material(
            color: Colors.transparent,
            child: GlassCard(
              level: GlassLevel.floating,
              tintColor: accent,
              borderColor: accent.withValues(alpha: 0.14),
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingLG,
                vertical: AppConstants.spacingMD,
              ),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: accent),
                  const SizedBox(width: AppConstants.spacingMD),
                  Expanded(
                    child: Text(
                      widget.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: p.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
