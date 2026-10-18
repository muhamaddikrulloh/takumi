import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:task_track/core/constants/app_colors.dart';
import 'package:task_track/core/constants/app_constants.dart';
import 'package:task_track/core/localization/app_translations.dart';
import 'package:task_track/core/utils/validators.dart';
import 'package:task_track/features/auth/providers/auth_provider.dart';
import 'package:task_track/features/profile/domain/avatar_catalog.dart';
import 'package:task_track/features/profile/domain/profile.dart';
import 'package:task_track/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:task_track/features/profile/providers/profile_provider.dart';
import 'package:task_track/shared/widgets/ambient_background.dart';
import 'package:task_track/shared/widgets/app_feedback.dart';
import 'package:task_track/shared/widgets/glass_card.dart';
import 'package:task_track/shared/widgets/glass_text_field.dart';
import 'package:task_track/shared/widgets/neon_button.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key, required this.initialProfile});

  final Profile initialProfile;

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _institutionController;
  late final TextEditingController _majorController;
  late final List<String> _avatarOptions;
  late String _selectedAvatarId;
  bool _saving = false;
  bool _signingOut = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialProfile.displayName,
    );
    _institutionController = TextEditingController(
      text: widget.initialProfile.institution,
    );
    _majorController = TextEditingController(text: widget.initialProfile.major);
    final hasAccountPhoto =
        widget.initialProfile.photoUrl?.trim().isNotEmpty == true;
    _avatarOptions = AvatarCatalog.choices(
      hasAccountPhoto: hasAccountPhoto,
      selectedId: widget.initialProfile.avatarId,
    );
    _selectedAvatarId =
        AvatarCatalog.isAvailable(
          widget.initialProfile.avatarId,
          photoUrl: widget.initialProfile.photoUrl,
        )
        ? widget.initialProfile.avatarId!
        : hasAccountPhoto
        ? AvatarCatalog.accountPhotoId
        : AvatarCatalog.forSeed(widget.initialProfile.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _institutionController.dispose();
    _majorController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_saving || _signingOut || !_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final saved = await ref
        .read(profileProvider.notifier)
        .completeSetup(
          displayName: _nameController.text,
          institution: _institutionController.text,
          major: _majorController.text,
          avatarId: _selectedAvatarId,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (!saved) {
      AppFeedback.show(
        context,
        message: context.tr('profile_setup_failed'),
        type: AppFeedbackType.error,
        aboveNavigation: false,
      );
    }
  }

  Future<void> _signOut() async {
    if (_saving || _signingOut) return;
    setState(() => _signingOut = true);
    try {
      await ref.read(authRepositoryProvider).signOut();
    } catch (_) {
      if (mounted) {
        AppFeedback.show(
          context,
          message: context.tr('logout_failed'),
          type: AppFeedbackType.error,
          aboveNavigation: false,
        );
      }
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final busy = _saving || _signingOut;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const Positioned.fill(
            child: AmbientBackground(style: AmbientBackgroundStyle.auth),
          ),
          SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(
                AppConstants.screenPadding,
                AppConstants.spacingXL,
                AppConstants.screenPadding,
                AppConstants.spacingSection,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: p.primaryOrange,
                              boxShadow: [
                                BoxShadow(
                                  color: p.primaryOrange.withValues(
                                    alpha: 0.18,
                                  ),
                                  blurRadius: AppConstants.spacingLG,
                                ),
                              ],
                            ),
                            child: ProfileAvatar(
                              avatarId: _selectedAvatarId,
                              photoUrl: widget.initialProfile.photoUrl,
                              size: 96,
                              fallbackColor: p.iconColor,
                            ),
                          ),
                          const SizedBox(height: AppConstants.spacingLG),
                          Text(
                            context.tr('profile_setup_title'),
                            textAlign: TextAlign.center,
                            style: textTheme.headlineLarge?.copyWith(
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: AppConstants.spacingSM),
                          Text(
                            context.tr('profile_setup_description'),
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium?.copyWith(
                              color: p.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.spacingSection),
                      GlassCard(
                        level: GlassLevel.standard,
                        padding: const EdgeInsets.all(AppConstants.spacingLG),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('choose_avatar'),
                              style: textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppConstants.spacingLG),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                const spacing = AppConstants.spacingSM;
                                final fittedColumns =
                                    ((constraints.maxWidth + spacing) /
                                            (AppConstants.minTouchTarget +
                                                spacing))
                                        .floor();
                                final crossAxisCount = fittedColumns < 1
                                    ? 1
                                    : fittedColumns > 5
                                    ? 5
                                    : fittedColumns;
                                return GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _avatarOptions.length,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: crossAxisCount,
                                        crossAxisSpacing: spacing,
                                        mainAxisSpacing: spacing,
                                      ),
                                  itemBuilder: (context, index) {
                                    final avatarId = _avatarOptions[index];
                                    final selected =
                                        avatarId == _selectedAvatarId;
                                    return Semantics(
                                      label:
                                          avatarId ==
                                              AvatarCatalog.accountPhotoId
                                          ? context.tr('google_profile_photo')
                                          : context.tr(
                                              'avatar_option',
                                              args: {'n': '${index + 1}'},
                                            ),
                                      button: true,
                                      selected: selected,
                                      child: GestureDetector(
                                        key: ValueKey('avatar_$avatarId'),
                                        behavior: HitTestBehavior.opaque,
                                        onTap: busy
                                            ? null
                                            : () => setState(
                                                () => _selectedAvatarId =
                                                    avatarId,
                                              ),
                                        child: AnimatedContainer(
                                          duration: reduceMotion
                                              ? Duration.zero
                                              : AppConstants.animationFast,
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: selected
                                                ? p.primaryOrange
                                                : p.glassBorder,
                                            boxShadow: selected
                                                ? [
                                                    BoxShadow(
                                                      color: p.primaryOrange
                                                          .withValues(
                                                            alpha: 0.2,
                                                          ),
                                                      blurRadius: AppConstants
                                                          .spacingMD,
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: LayoutBuilder(
                                            builder: (context, constraints) {
                                              return ProfileAvatar(
                                                avatarId: avatarId,
                                                photoUrl: widget
                                                    .initialProfile
                                                    .photoUrl,
                                                size: constraints.maxWidth,
                                                fallbackColor: p.iconColor,
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingLG),
                      GlassCard(
                        level: GlassLevel.elevated,
                        padding: const EdgeInsets.all(AppConstants.spacingXL),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              GlassTextField(
                                controller: _nameController,
                                maxLength:
                                    Validators.profileDisplayNameMaxLength,
                                hintText: context.tr('full_name_hint'),
                                labelText: context.tr('full_name'),
                                enabled: !busy,
                                validator: (value) {
                                  final key = Validators.validateFullName(
                                    value,
                                  );
                                  return key == null ? null : context.tr(key);
                                },
                                prefixIcon: Icon(
                                  PhosphorIconsRegular.user,
                                  color: p.iconColor,
                                ),
                              ),
                              const SizedBox(height: AppConstants.spacingMD),
                              GlassTextField(
                                controller: _institutionController,
                                maxLength:
                                    Validators.profileInstitutionMaxLength,
                                hintText: context.tr('university_hint'),
                                labelText: context.tr('university_optional'),
                                enabled: !busy,
                                validator: (value) {
                                  final key = Validators.validateInstitution(
                                    value,
                                  );
                                  return key == null ? null : context.tr(key);
                                },
                                prefixIcon: Icon(
                                  PhosphorIconsRegular.buildings,
                                  color: p.iconColor,
                                ),
                              ),
                              const SizedBox(height: AppConstants.spacingMD),
                              GlassTextField(
                                controller: _majorController,
                                maxLength: Validators.profileMajorMaxLength,
                                hintText: context.tr('major_hint'),
                                labelText: context.tr('major_optional'),
                                enabled: !busy,
                                validator: (value) {
                                  final key = Validators.validateMajor(value);
                                  return key == null ? null : context.tr(key);
                                },
                                prefixIcon: Icon(
                                  PhosphorIconsRegular.bookOpen,
                                  color: p.iconColor,
                                ),
                              ),
                              const SizedBox(height: AppConstants.spacingLG),
                              NeonButton(
                                label: context.tr('profile_setup_save'),
                                icon: PhosphorIconsRegular.check,
                                isLoading: _saving,
                                onPressed: busy ? null : _saveProfile,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingMD),
                      TextButton.icon(
                        onPressed: busy ? null : _signOut,
                        icon: _signingOut
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(PhosphorIconsRegular.signOut),
                        label: Text(context.tr('logout')),
                        style: TextButton.styleFrom(
                          foregroundColor: p.destructive,
                          minimumSize: const Size(
                            0,
                            AppConstants.minTouchTarget,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
