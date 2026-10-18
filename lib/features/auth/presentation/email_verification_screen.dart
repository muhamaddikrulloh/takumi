import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:task_track/core/constants/app_colors.dart';
import 'package:task_track/core/constants/app_constants.dart';
import 'package:task_track/core/localization/app_translations.dart';
import 'package:task_track/features/auth/providers/auth_provider.dart';
import 'package:task_track/shared/widgets/ambient_background.dart';
import 'package:task_track/shared/widgets/app_feedback.dart';
import 'package:task_track/shared/widgets/glass_card.dart';
import 'package:task_track/shared/widgets/neon_button.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  Timer? _cooldownTimer;
  bool _resending = false;
  bool _checking = false;
  int _resendCooldown = 0;

  static const int _resendCooldownSeconds = 60;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  void _startCooldown() {
    _resendCooldown = _resendCooldownSeconds;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _resendCooldown--;
        if (_resendCooldown <= 0) {
          _cooldownTimer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  String _maskEmail(String email) {
    final at = email.indexOf('@');
    if (at <= 1) return email;
    final local = email.substring(0, at);
    final domain = email.substring(at);
    final maskedLocal = '${local[0]}${'*' * (local.length - 1)}';
    return '$maskedLocal$domain';
  }

  Future<void> _resendEmail() async {
    if (_resendCooldown > 0) return;
    setState(() => _resending = true);
    try {
      await ref.read(authRepositoryProvider).sendEmailVerification();
      if (mounted) {
        _startCooldown();
        AppFeedback.show(
          context,
          message: context.tr('verification_email_sent'),
          type: AppFeedbackType.success,
          aboveNavigation: false,
        );
      }
    } catch (_) {
      if (mounted) {
        AppFeedback.show(
          context,
          message: context.tr('error_generic'),
          type: AppFeedbackType.error,
          aboveNavigation: false,
        );
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _checkVerified() async {
    if (_checking) return;
    setState(() => _checking = true);
    final repo = ref.read(authRepositoryProvider);
    try {
      await repo.reloadUser();
      if (!mounted) return;
      if (repo.isEmailVerified) {
        await repo.currentUser?.getIdToken(true);
        ref.invalidate(authStateProvider);
        return;
      }
      AppFeedback.show(
        context,
        message: context.tr('verify_email_not_verified'),
        type: AppFeedbackType.warning,
        aboveNavigation: false,
      );
    } catch (_) {
      if (mounted) {
        AppFeedback.show(
          context,
          message: context.tr('error_generic'),
          type: AppFeedbackType.error,
          aboveNavigation: false,
        );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final user = ref.watch(authStateProvider).valueOrNull;
    final email = user?.email ?? '';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const Positioned.fill(
            child: AmbientBackground(style: AmbientBackgroundStyle.auth),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.screenPadding,
                  ),
                  sliver: SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppConstants.spacingXL,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                children: [
                                  GlassCard(
                                    level: GlassLevel.subtle,
                                    tintColor: p.primaryOrange,
                                    borderColor: p.primaryOrange.withValues(
                                      alpha: 0.24,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppConstants.radiusMedium,
                                    ),
                                    padding: EdgeInsets.zero,
                                    child: SizedBox.square(
                                      dimension: 64,
                                      child: Icon(
                                        PhosphorIconsRegular.envelope,
                                        size: 30,
                                        color: p.primaryOrange,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: AppConstants.spacingXXL,
                                  ),
                                  Text(
                                    context.tr('verify_email_title'),
                                    textAlign: TextAlign.center,
                                    style: textTheme.headlineLarge,
                                  ),
                                  const SizedBox(
                                    height: AppConstants.spacingMD,
                                  ),
                                  Text(
                                    context.tr('verify_register_hint'),
                                    textAlign: TextAlign.center,
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: p.textSecondary,
                                    ),
                                  ),
                                  if (email.isNotEmpty) ...[
                                    const SizedBox(
                                      height: AppConstants.spacingXS,
                                    ),
                                    Text(
                                      _maskEmail(email),
                                      textAlign: TextAlign.center,
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: p.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(
                                    height: AppConstants.spacingXS,
                                  ),
                                  Text(
                                    context.tr('verify_email_spam_hint'),
                                    textAlign: TextAlign.center,
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: p.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: AppConstants.spacingSM,
                                  ),
                                  TextButton(
                                    onPressed: _resending || _resendCooldown > 0
                                        ? null
                                        : _resendEmail,
                                    style: TextButton.styleFrom(
                                      minimumSize: const Size(
                                        AppConstants.minTouchTarget,
                                        AppConstants.minTouchTarget,
                                      ),
                                      foregroundColor: p.primaryOrange,
                                      disabledForegroundColor: p.textSecondary
                                          .withValues(alpha: 0.7),
                                    ),
                                    child: Text(
                                      _resending
                                          ? context.tr('resending_email')
                                          : _resendCooldown > 0
                                          ? context.tr(
                                              'resend_email_cooldown',
                                              args: {'n': '$_resendCooldown'},
                                            )
                                          : context.tr('resend_link'),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: AppConstants.spacingSection,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    NeonButton(
                                      label: context.tr(
                                        'verified_email_button',
                                      ),
                                      isLoading: _checking,
                                      onPressed: _checking
                                          ? null
                                          : _checkVerified,
                                    ),
                                    const SizedBox(
                                      height: AppConstants.spacingMD,
                                    ),
                                    NeonButton(
                                      label: context.tr('back_to_login'),
                                      type: NeonButtonType.secondary,
                                      onPressed: () async {
                                        await ref
                                            .read(authRepositoryProvider)
                                            .signOut();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
