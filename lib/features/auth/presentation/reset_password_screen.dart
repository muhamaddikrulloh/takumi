import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:task_track/core/constants/app_colors.dart';
import 'package:task_track/core/constants/app_constants.dart';
import 'package:task_track/core/localization/app_translations.dart';
import 'package:task_track/core/utils/validators.dart';
import 'package:task_track/features/auth/data/auth_repository.dart';
import 'package:task_track/features/auth/presentation/widgets/auth_header.dart';
import 'package:task_track/features/auth/providers/auth_provider.dart';
import 'package:task_track/shared/widgets/ambient_background.dart';
import 'package:task_track/shared/widgets/app_feedback.dart';
import 'package:task_track/shared/widgets/glass_card.dart';
import 'package:task_track/shared/widgets/glass_text_field.dart';
import 'package:task_track/shared/widgets/neon_button.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;
  bool _isLoading = false;
  bool _isResending = false;
  bool _hasSentResetLink = false;

  bool get _isBusy => _isLoading || _isResending;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  void _scheduleCooldownTicks() {
    _cooldownTimer?.cancel();
    if (_cooldownSeconds <= 0) return;

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final remaining = _resendRemainingSeconds();
      if (remaining != _cooldownSeconds) {
        setState(() => _cooldownSeconds = remaining);
      }
      if (remaining <= 0) timer.cancel();
    });
  }

  void _refreshCooldown() {
    final remaining = _resendRemainingSeconds();
    _setCooldown(remaining);
  }

  void _setCooldown(int seconds) {
    setState(() => _cooldownSeconds = seconds);
    _scheduleCooldownTicks();
  }

  int _resendRemainingSeconds() {
    final email = _emailController.text.trim();
    if (email.isEmpty) return 0;
    final retryAfter = ref
        .read(passwordResetRateLimiterProvider)
        .resendStatus(email)
        .retryAfter;
    return _durationInSeconds(retryAfter);
  }

  int _durationInSeconds(Duration duration) {
    return (duration.inMilliseconds + 999) ~/ 1000;
  }

  String _formatCountdown(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    final paddedMinutes = minutes.toString().padLeft(2, '0');
    final paddedSeconds = seconds.toString().padLeft(2, '0');
    return hours > 0
        ? '$hours:$paddedMinutes:$paddedSeconds'
        : '$paddedMinutes:$paddedSeconds';
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink({bool isResend = false}) async {
    if (_isBusy || (isResend && _cooldownSeconds > 0)) return;
    if (!isResend && !_formKey.currentState!.validate()) return;

    setState(() {
      if (isResend) {
        _isResending = true;
      } else {
        _isLoading = true;
      }
    });
    try {
      final email = _emailController.text.trim();
      final limiter = ref.read(passwordResetRateLimiterProvider);
      if (isResend) {
        final result = await limiter.tryAcquireResend(email);
        if (!mounted) return;

        _setCooldown(_durationInSeconds(result.retryAfter));
        if (!result.allowed) return;
      } else {
        final result = await limiter.tryAcquireInitial(email);
        if (!mounted) return;
        if (!result.allowed) {
          _showInitialRateLimit(result.retryAfter);
          return;
        }
      }

      await ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
      if (mounted) _handleResetAccepted(isResend: isResend);
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        if (error.code == 'user-not-found') {
          _handleResetAccepted(isResend: isResend);
        } else {
          _showRequestError(error);
        }
      }
    } catch (error) {
      if (mounted) _showRequestError(error);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isResending = false;
        });
      }
    }
  }

  void _handleResetAccepted({required bool isResend}) {
    setState(() => _hasSentResetLink = true);
    if (!isResend) {
      _refreshCooldown();
      AppFeedback.show(
        context,
        message: context.tr('password_reset_sent'),
        type: AppFeedbackType.success,
        aboveNavigation: false,
      );
    }
  }

  void _showInitialRateLimit(Duration retryAfter) {
    AppFeedback.show(
      context,
      message: context.tr(
        'password_reset_hourly_limit',
        args: {'time': _formatCountdown(_durationInSeconds(retryAfter))},
      ),
      type: AppFeedbackType.warning,
      aboveNavigation: false,
    );
  }

  void _showRequestError(Object error) {
    AppFeedback.show(
      context,
      message: context.tr(AuthRepository.getAuthErrorMessage(error)),
      type: AppFeedbackType.error,
      aboveNavigation: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final resendLabel = context.tr(
      'password_reset_resend_cooldown',
      args: {'time': _formatCountdown(_cooldownSeconds)},
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const Positioned.fill(
            child: AmbientBackground(style: AmbientBackgroundStyle.auth),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, viewport) {
                final minHeight = viewport.maxHeight > AppConstants.spacingHero
                    ? viewport.maxHeight - AppConstants.spacingHero
                    : 0.0;
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.screenPadding,
                    vertical: AppConstants.spacingXXL,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 480,
                        minHeight: minHeight,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AuthHeader(
                            title: context.tr('reset_password_header'),
                            description: context.tr(
                              'reset_password_description',
                            ),
                          ),
                          const SizedBox(height: AppConstants.spacingSection),
                          GlassCard(
                            level: GlassLevel.elevated,
                            padding: const EdgeInsets.all(
                              AppConstants.spacingXL,
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  GlassTextField(
                                    controller: _emailController,
                                    hintText: context.tr('email_hint'),
                                    labelText: context.tr('email'),
                                    keyboardType: TextInputType.emailAddress,
                                    enabled: !_isBusy && !_hasSentResetLink,
                                    validator: (value) {
                                      final key = Validators.validateEmail(
                                        value,
                                      );
                                      return key == null
                                          ? null
                                          : context.tr(key);
                                    },
                                    prefixIcon: Icon(
                                      PhosphorIconsRegular.envelope,
                                      color: p.iconColor,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: AppConstants.spacingLG,
                                  ),
                                  NeonButton(
                                    label: _hasSentResetLink
                                        ? context.tr(
                                            'password_reset_sent_button',
                                          )
                                        : context.tr('reset_password_button'),
                                    isLoading: _isLoading,
                                    icon: _hasSentResetLink
                                        ? null
                                        : PhosphorIconsBold.arrowRight,
                                    onPressed: _isBusy || _hasSentResetLink
                                        ? null
                                        : () => _sendResetLink(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_hasSentResetLink) ...[
                            const SizedBox(height: AppConstants.spacingSM),
                            TextButton(
                              onPressed: _isBusy || _cooldownSeconds > 0
                                  ? null
                                  : () => _sendResetLink(isResend: true),
                              style: TextButton.styleFrom(
                                minimumSize: const Size(
                                  AppConstants.minTouchTarget,
                                  AppConstants.minTouchTarget,
                                ),
                                foregroundColor: p.primaryOrange,
                                disabledForegroundColor: p.textSecondary,
                              ),
                              child: Text(
                                _cooldownSeconds > 0
                                    ? resendLabel
                                    : context.tr(
                                        'password_reset_resend_prompt',
                                      ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                          const SizedBox(height: AppConstants.spacingMD),
                          NeonButton(
                            label: context.tr('back_to_login'),
                            type: NeonButtonType.secondary,
                            icon: Icons.arrow_back_rounded,
                            onPressed: _isBusy
                                ? null
                                : () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
