import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:task_track/core/constants/app_colors.dart';
import 'package:task_track/core/constants/app_constants.dart';
import 'package:task_track/core/localization/app_translations.dart';
import 'package:task_track/core/providers/locale_provider.dart';
import 'package:task_track/core/utils/validators.dart';
import 'package:task_track/features/auth/providers/auth_provider.dart';
import 'package:task_track/features/profile/domain/profile.dart';
import 'package:task_track/features/profile/presentation/profile_identity_modal.dart';
import 'package:task_track/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:task_track/features/profile/providers/profile_provider.dart';
import 'package:task_track/shared/widgets/ambient_background.dart';
import 'package:task_track/shared/widgets/app_feedback.dart';
import 'package:task_track/shared/widgets/action_confirmation_dialog.dart';
import 'package:task_track/shared/widgets/bottom_nav_bar.dart';
import 'package:task_track/shared/widgets/error_view.dart';
import 'package:task_track/shared/widgets/glass_card.dart';
import 'package:task_track/shared/widgets/glass_text_field.dart';
import 'package:task_track/shared/widgets/neon_button.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _institutionController;
  late final TextEditingController _majorController;
  bool _editingInstitution = false;
  bool _editingMajor = false;
  int _institutionSaveGeneration = 0;
  int _majorSaveGeneration = 0;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider).valueOrNull;
    _institutionController = TextEditingController(
      text: profile?.institution ?? '',
    );
    _majorController = TextEditingController(text: profile?.major ?? '');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final profile = ref.read(profileProvider).valueOrNull;
    if (profile != null) {
      if (!_editingInstitution &&
          _institutionController.text != profile.institution) {
        _institutionController.text = profile.institution;
      }
      if (!_editingMajor && _majorController.text != profile.major) {
        _majorController.text = profile.major;
      }
    }
  }

  @override
  void dispose() {
    _institutionController.dispose();
    _majorController.dispose();
    super.dispose();
  }

  Future<void> _saveInstitution() async {
    final value = _institutionController.text.trim();
    final validationError = Validators.validateInstitution(value);
    if (validationError != null) {
      _showMessage(_profileValidationMessage(validationError));
      return;
    }

    final saveGeneration = ++_institutionSaveGeneration;
    setState(() => _editingInstitution = false);
    var saved = false;
    try {
      saved = await ref.read(profileProvider.notifier).updateInstitution(value);
    } catch (_) {
      saved = false;
    }
    if (!mounted || saveGeneration != _institutionSaveGeneration) return;
    if (!saved) {
      setState(() => _editingInstitution = true);
      _showMessage(context.tr('error_generic'));
    }
  }

  Future<void> _saveMajor() async {
    final value = _majorController.text.trim();
    final validationError = Validators.validateMajor(value);
    if (validationError != null) {
      _showMessage(_profileValidationMessage(validationError));
      return;
    }

    final saveGeneration = ++_majorSaveGeneration;
    setState(() => _editingMajor = false);
    var saved = false;
    try {
      saved = await ref.read(profileProvider.notifier).updateMajor(value);
    } catch (_) {
      saved = false;
    }
    if (!mounted || saveGeneration != _majorSaveGeneration) return;
    if (!saved) {
      setState(() => _editingMajor = true);
      _showMessage(context.tr('error_generic'));
    }
  }

  String _profileValidationMessage(String key) {
    final isIndonesian = Localizations.localeOf(context).languageCode == 'id';
    return switch (key) {
      'error_institution_too_long' =>
        isIndonesian
            ? 'Institusi maksimal ${Validators.profileInstitutionMaxLength} karakter'
            : 'Institution must be ${Validators.profileInstitutionMaxLength} characters or fewer',
      'error_major_too_long' =>
        isIndonesian
            ? 'Jurusan maksimal ${Validators.profileMajorMaxLength} karakter'
            : 'Major must be ${Validators.profileMajorMaxLength} characters or fewer',
      _ => context.tr('error_generic'),
    };
  }

  void _showMessage(
    String message, {
    AppFeedbackType type = AppFeedbackType.error,
  }) {
    AppFeedback.show(
      context,
      message: message,
      type: type,
      aboveNavigation: true,
    );
  }

  Future<void> _editIdentity(Profile profile) async {
    final saved = await ProfileIdentityModal.show(context, profile);
    if (saved == true && mounted) {
      _showMessage(
        context.tr('profile_updated'),
        type: AppFeedbackType.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final profileAsync = ref.watch(profileProvider);
    final locale = ref.watch(localeProvider);
    final authUser = ref.watch(authStateProvider).valueOrNull;
    final isGoogleUser =
        authUser?.providerData.any((info) => info.providerId == 'google.com') ??
        false;
    const bottomPad = BottomNavBar.contentClearance;

    if (profileAsync.isLoading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            const Positioned.fill(
              child: AmbientBackground(style: AmbientBackgroundStyle.profile),
            ),
            SafeArea(
              child: Center(
                child: CircularProgressIndicator(
                  color: p.primaryOrange,
                  strokeWidth: 2,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (profileAsync.hasError) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            const Positioned.fill(
              child: AmbientBackground(style: AmbientBackgroundStyle.profile),
            ),
            SafeArea(
              child: ErrorView(onRetry: () => ref.invalidate(profileProvider)),
            ),
          ],
        ),
      );
    }

    final profile = profileAsync.value!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const Positioned.fill(
            child: AmbientBackground(style: AmbientBackgroundStyle.profile),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingXL,
                vertical: AppConstants.spacingLG,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: AppConstants.spacingLG),

                  // Photo & Name Header
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    p.primaryOrange.withValues(alpha: 0.24),
                                    p.accentViolet.withValues(alpha: 0.08),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.45, 1.0],
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(1),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: p.primaryOrange,
                              ),
                              child: ProfileAvatar(
                                avatarId: profile.avatarId,
                                photoUrl: profile.photoUrl,
                                size: 96,
                                fallbackColor: p.iconColor,
                              ),
                            ),
                            Positioned(
                              right: 6,
                              bottom: 24,
                              child: Material(
                                color: Colors.transparent,
                                shape: const CircleBorder(),
                                child: InkWell(
                                  key: const ValueKey('edit_profile_identity'),
                                  customBorder: const CircleBorder(),
                                  onTap: () => _editIdentity(profile),
                                  child: SizedBox.square(
                                    dimension: AppConstants.minTouchTarget,
                                    child: Center(
                                      child: Container(
                                        key: const ValueKey(
                                          'edit_profile_identity_visual',
                                        ),
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          color: p.primaryOrange,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: p.shadowDark.withValues(
                                                alpha: p.shadowDark.a * 0.35,
                                              ),
                                              blurRadius: 10,
                                              spreadRadius: -3,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          PhosphorIconsBold.pencilSimple,
                                          color: p.onPrimary,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppConstants.spacingSM),
                        Text(
                          profile.displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: AppConstants.fontProfile,
                            fontWeight: FontWeight.w600,
                            color: p.textPrimary,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          profile.email,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: AppConstants.fontBody,
                            color: p.textSecondary.withValues(alpha: 0.96),
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: AppConstants.spacingSM),
                        GlassCard(
                          level: GlassLevel.control,
                          blurEnabled: false,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusSmall,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isGoogleUser)
                                Image.asset(
                                  'assets/images/google_logo.png',
                                  width: 14,
                                  height: 14,
                                )
                              else
                                Icon(
                                  PhosphorIconsRegular.envelopeSimple,
                                  size: 14,
                                  color: p.textSecondary,
                                ),
                              const SizedBox(width: AppConstants.spacingXS),
                              Flexible(
                                child: Text(
                                  context.tr(
                                    isGoogleUser ? 'google_auth' : 'email_auth',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: AppConstants.fontBadge,
                                    color: p.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    height: 1.1,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppConstants.spacingXXL),

                  // Academic Info Section
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      context.tr('academic_info'),
                      style: TextStyle(
                        fontSize: AppConstants.fontSection,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingLG),
                  GlassCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingLG,
                      vertical: AppConstants.spacingMD,
                    ),
                    child: Column(
                      children: [
                        _InfoRow(
                          key: const ValueKey('academic_institution_row'),
                          icon: PhosphorIconsRegular.buildings,
                          label: context.tr('university'),
                          value: profile.institution.isEmpty
                              ? context.tr('not_filled')
                              : profile.institution,
                          isPlaceholder: profile.institution.isEmpty,
                          isEditing: _editingInstitution,
                          controller: _institutionController,
                          hintText: context.tr('university_hint'),
                          accentColor: p.primaryOrange,
                          onEdit: () => setState(() {
                            _institutionController.text = profile.institution;
                            _editingMajor = false;
                            _editingInstitution = true;
                          }),
                          onSave: _saveInstitution,
                          maxLength: Validators.profileInstitutionMaxLength,
                        ),
                        Divider(
                          height: AppConstants.spacingXL,
                          color: p.divider,
                        ),
                        _InfoRow(
                          key: const ValueKey('academic_major_row'),
                          icon: PhosphorIconsRegular.bookOpen,
                          label: context.tr('major'),
                          value: profile.major.isEmpty
                              ? context.tr('not_filled')
                              : profile.major,
                          isPlaceholder: profile.major.isEmpty,
                          isEditing: _editingMajor,
                          controller: _majorController,
                          hintText: context.tr('major_hint'),
                          accentColor: p.primaryOrange,
                          onEdit: () => setState(() {
                            _majorController.text = profile.major;
                            _editingInstitution = false;
                            _editingMajor = true;
                          }),
                          onSave: _saveMajor,
                          maxLength: Validators.profileMajorMaxLength,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppConstants.spacingXXL),

                  // App Settings Section
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      context.tr('settings'),
                      style: TextStyle(
                        fontSize: AppConstants.fontSection,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingLG),
                  GlassCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingLG,
                      vertical: AppConstants.spacingMD,
                    ),
                    child: Column(
                      children: [
                        // Language Selector
                        _SettingsRow(
                          icon: PhosphorIconsRegular.globe,
                          label: context.tr('language'),
                          trailing: _LanguageSelector(currentLocale: locale),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppConstants.spacingXXL),

                  // Account Action (Logout) — red tinted surface, no hard border
                  NeonButton(
                    label: context.tr('logout'),
                    type: NeonButtonType.danger,
                    icon: PhosphorIconsRegular.signOut,
                    onPressed: _confirmLogout,
                  ),
                  const SizedBox(height: AppConstants.spacingSection),
                  SizedBox(height: bottomPad),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await ActionConfirmationDialog.show(
      context,
      icon: PhosphorIconsRegular.signOut,
      title: context.tr('logout_confirm_title'),
      description: context.tr('logout_confirm_body'),
      actionLabel: context.tr('logout_confirm_action'),
      cancelLabel: context.tr('cancel'),
    );
    if (confirmed == true) {
      try {
        await ref.read(authRepositoryProvider).signOut();
      } catch (_) {
        if (mounted) _showMessage(context.tr('logout_failed'));
      }
    }
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;

  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: p.primaryOrange.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: p.primaryOrange, size: 22),
        ),
        const SizedBox(width: AppConstants.spacingMD),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: AppConstants.fontBody,
              fontWeight: FontWeight.w600,
              color: p.textPrimary,
            ),
          ),
        ),
        trailing,
      ],
    );
  }
}

class _LanguageSelector extends ConsumerWidget {
  final Locale currentLocale;

  const _LanguageSelector({required this.currentLocale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = AppColors.of(context);
    return PopupMenuButton<Locale>(
      initialValue: currentLocale,
      onSelected: (locale) =>
          ref.read(localeProvider.notifier).setLocale(locale),
      itemBuilder: (context) => [
        const PopupMenuItem(value: Locale('id'), child: Text('Indonesia')),
        const PopupMenuItem(value: Locale('en'), child: Text('English')),
      ],
      child: GlassCard(
        level: GlassLevel.control,
        blurEnabled: false,
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
        constraints: const BoxConstraints(
          minHeight: AppConstants.minTouchTarget,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingMD,
            vertical: AppConstants.spacingSM,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                currentLocale.languageCode == 'en' ? 'English' : 'Indonesia',
                style: TextStyle(
                  fontSize: 12,
                  color: p.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                PhosphorIconsRegular.caretDown,
                size: 16,
                color: p.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isPlaceholder;
  final bool isEditing;
  final TextEditingController controller;
  final String hintText;
  final Color accentColor;
  final VoidCallback onEdit;
  final VoidCallback onSave;
  final int maxLength;

  const _InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.isPlaceholder,
    required this.isEditing,
    required this.controller,
    required this.hintText,
    required this.accentColor,
    required this.onEdit,
    required this.onSave,
    required this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);

    if (isEditing) {
      void finishEditing() {
        FocusManager.instance.primaryFocus?.unfocus();
        onSave();
      }

      return GlassTextField(
        controller: controller,
        maxLength: maxLength,
        autofocus: true,
        hintText: hintText,
        labelText: label,
        prefixIcon: Icon(icon, color: accentColor),
        onTapOutside: (_) => finishEditing(),
        onFieldSubmitted: (_) => finishEditing(),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(width: AppConstants.spacingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppConstants.fontSecondary,
                        color: p.textSecondary.withValues(alpha: 0.94),
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppConstants.fontBody,
                        fontWeight: isPlaceholder
                            ? FontWeight.w500
                            : FontWeight.w600,
                        color: isPlaceholder
                            ? p.textSecondary.withValues(alpha: 0.92)
                            : p.textPrimary,
                        fontStyle: isPlaceholder
                            ? FontStyle.italic
                            : FontStyle.normal,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppConstants.spacingSM),
              Icon(
                PhosphorIconsRegular.caretRight,
                size: 16,
                color: p.textSecondary.withValues(alpha: 0.72),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
