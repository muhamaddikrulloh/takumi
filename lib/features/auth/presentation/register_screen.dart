import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:task_track/core/constants/app_colors.dart';
import 'package:task_track/core/constants/app_constants.dart';
import 'package:task_track/core/localization/app_translations.dart';
import 'package:task_track/core/utils/app_logger.dart';
import 'package:task_track/core/utils/validators.dart';
import 'package:task_track/features/auth/data/auth_repository.dart';
import 'package:task_track/features/auth/presentation/widgets/auth_header.dart';
import 'package:task_track/features/auth/providers/auth_provider.dart';
import 'package:task_track/shared/widgets/ambient_background.dart';
import 'package:task_track/shared/widgets/app_feedback.dart';
import 'package:task_track/shared/widgets/glass_card.dart';
import 'package:task_track/shared/widgets/glass_text_field.dart';
import 'package:task_track/shared/widgets/neon_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registerWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final cred = await repo.registerWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      final user = cred?.user;
      if (user == null) {
        throw StateError('Firebase did not return the newly created user');
      }
      ref.read(newlyRegisteredUidProvider.notifier).state = user.uid;
      var verificationFailed = false;
      try {
        await repo.sendEmailVerification();
      } catch (error) {
        logDebug(
          'Account created, but verification email failed',
          error: error,
        );
        verificationFailed = true;
      }
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        if (verificationFailed) {
          AppFeedback.show(
            context,
            message: context.tr('error_generic'),
            type: AppFeedbackType.warning,
            aboveNavigation: false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showAuthError(e);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final credential = await repo.signInWithGoogle();
      if (credential == null) return;
      final user = credential.user;
      if (credential.additionalUserInfo?.isNewUser == true && user != null) {
        ref.read(newlyRegisteredUidProvider.notifier).state = user.uid;
      }
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        _showAuthError(e);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToLogin() {
    Navigator.of(context).pop();
  }

  void _showAuthError(Object error) {
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
    final textTheme = Theme.of(context).textTheme;

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
                            title: context.tr('register_header'),
                            description: context.tr('login_description'),
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
                                children: [
                                  GlassTextField(
                                    controller: _emailController,
                                    hintText: context.tr('email_hint'),
                                    labelText: context.tr('email'),
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (v) {
                                      final key = Validators.validateEmail(v);
                                      return key != null
                                          ? context.tr(key)
                                          : null;
                                    },
                                    prefixIcon: Icon(
                                      PhosphorIconsRegular.envelope,
                                      color: p.iconColor,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: AppConstants.spacingMD,
                                  ),
                                  GlassTextField(
                                    controller: _passwordController,
                                    hintText: context.tr('password_hint'),
                                    labelText: context.tr('password'),
                                    obscureText: _obscurePassword,
                                    validator: (v) {
                                      final key = Validators.validatePassword(
                                        v,
                                      );
                                      return key != null
                                          ? context.tr(key)
                                          : null;
                                    },
                                    prefixIcon: Icon(
                                      PhosphorIconsRegular.lockKey,
                                      color: p.iconColor,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? PhosphorIconsRegular.eye
                                            : PhosphorIconsRegular.eyeSlash,
                                        color: p.iconColor,
                                      ),
                                      onPressed: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: AppConstants.spacingMD,
                                  ),
                                  GlassTextField(
                                    controller: _confirmPasswordController,
                                    hintText: context.tr(
                                      'confirm_password_hint',
                                    ),
                                    labelText: context.tr('confirm_password'),
                                    obscureText: _obscureConfirm,
                                    validator: (v) {
                                      final key =
                                          Validators.validateConfirmPassword(
                                            v,
                                            _passwordController.text,
                                          );
                                      return key != null
                                          ? context.tr(key)
                                          : null;
                                    },
                                    prefixIcon: Icon(
                                      PhosphorIconsRegular.lockKey,
                                      color: p.iconColor,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirm
                                            ? PhosphorIconsRegular.eye
                                            : PhosphorIconsRegular.eyeSlash,
                                        color: p.iconColor,
                                      ),
                                      onPressed: () => setState(
                                        () =>
                                            _obscureConfirm = !_obscureConfirm,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: AppConstants.spacingSM,
                                  ),
                                  NeonButton(
                                    label: context.tr('register'),
                                    isLoading: _isLoading,
                                    icon: PhosphorIconsBold.userPlus,
                                    onPressed: _isLoading
                                        ? null
                                        : _registerWithEmail,
                                  ),
                                  const SizedBox(
                                    height: AppConstants.spacingLG,
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Divider(color: p.divider),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppConstants.spacingMD,
                                        ),
                                        child: Text(
                                          context.tr('or'),
                                          style: textTheme.bodySmall?.copyWith(
                                            color: p.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Divider(color: p.divider),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: AppConstants.spacingLG,
                                  ),
                                  NeonButton(
                                    label: context.tr('login_google'),
                                    type: NeonButtonType.secondary,
                                    leading: Image.asset(
                                      'assets/images/google_logo.png',
                                      width: 20,
                                      height: 20,
                                    ),
                                    onPressed: _isLoading
                                        ? null
                                        : _signInWithGoogle,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppConstants.spacingLG),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                context.tr('have_account'),
                                style: textTheme.bodyMedium?.copyWith(
                                  color: p.textSecondary,
                                ),
                              ),
                              TextButton(
                                onPressed: _goToLogin,
                                style: TextButton.styleFrom(
                                  minimumSize: const Size.square(
                                    AppConstants.minTouchTarget,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppConstants.spacingSM,
                                  ),
                                ),
                                child: Text(context.tr('login_here')),
                              ),
                            ],
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
