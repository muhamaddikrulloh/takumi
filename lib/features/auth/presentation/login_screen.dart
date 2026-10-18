import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:task_track/core/constants/app_colors.dart';
import 'package:task_track/core/constants/app_constants.dart';
import 'package:task_track/core/localization/app_translations.dart';
import 'package:task_track/core/utils/validators.dart';
import 'package:task_track/features/auth/data/auth_repository.dart';
import 'package:task_track/features/auth/presentation/register_screen.dart';
import 'package:task_track/features/auth/presentation/reset_password_screen.dart';
import 'package:task_track/features/auth/presentation/widgets/auth_header.dart';
import 'package:task_track/features/auth/providers/auth_provider.dart';
import 'package:task_track/shared/widgets/ambient_background.dart';
import 'package:task_track/shared/widgets/app_feedback.dart';
import 'package:task_track/shared/widgets/glass_card.dart';
import 'package:task_track/shared/widgets/glass_text_field.dart';
import 'package:task_track/shared/widgets/neon_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
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

  void _goToRegister() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
  }

  void _goToResetPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ResetPasswordScreen(initialEmail: _emailController.text.trim()),
      ),
    );
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
                            title: context.tr('login_header'),
                            description: context.tr('login_subtitle'),
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
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _isLoading
                                          ? null
                                          : _goToResetPassword,
                                      child: Text(
                                        context.tr('forgot_password'),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: AppConstants.spacingSM,
                                  ),
                                  NeonButton(
                                    label: context.tr('login'),
                                    isLoading: _isLoading,
                                    icon: PhosphorIconsBold.arrowRight,
                                    onPressed: _isLoading
                                        ? null
                                        : _signInWithEmail,
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
                                context.tr('no_account'),
                                style: textTheme.bodyMedium?.copyWith(
                                  color: p.textSecondary,
                                ),
                              ),
                              TextButton(
                                onPressed: _goToRegister,
                                style: TextButton.styleFrom(
                                  minimumSize: const Size.square(
                                    AppConstants.minTouchTarget,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppConstants.spacingSM,
                                  ),
                                ),
                                child: Text(context.tr('register_here')),
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
