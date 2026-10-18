import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:task_track/core/constants/app_colors.dart';
import 'package:task_track/core/constants/app_constants.dart';
import 'package:task_track/core/localization/app_translations.dart';
import 'package:task_track/core/utils/validators.dart';
import 'package:task_track/features/profile/domain/avatar_catalog.dart';
import 'package:task_track/features/profile/domain/profile.dart';
import 'package:task_track/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:task_track/features/profile/providers/profile_provider.dart';
import 'package:task_track/shared/widgets/app_feedback.dart';
import 'package:task_track/shared/widgets/glass_icon_button.dart';
import 'package:task_track/shared/widgets/glass_modal_shell.dart';
import 'package:task_track/shared/widgets/glass_text_field.dart';
import 'package:task_track/shared/widgets/neon_button.dart';

class ProfileIdentityModal extends ConsumerStatefulWidget {
  const ProfileIdentityModal({super.key, required this.profile});

  final Profile profile;

  static Future<bool?> show(BuildContext context, Profile profile) {
    return showGlassBottomSheet<bool>(
      context,
      builder: (_) => ProfileIdentityModal(profile: profile),
    );
  }

  @override
  ConsumerState<ProfileIdentityModal> createState() =>
      _ProfileIdentityModalState();
}

class _ProfileIdentityModalState extends ConsumerState<ProfileIdentityModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final List<String> _avatarOptions;
  late String _selectedAvatarId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.displayName);
    final hasAccountPhoto = widget.profile.photoUrl?.trim().isNotEmpty == true;
    _avatarOptions = AvatarCatalog.choices(
      hasAccountPhoto: hasAccountPhoto,
      selectedId: widget.profile.avatarId,
    );
    _selectedAvatarId =
        AvatarCatalog.isAvailable(
          widget.profile.avatarId,
          photoUrl: widget.profile.photoUrl,
        )
        ? widget.profile.avatarId!
        : hasAccountPhoto
        ? AvatarCatalog.accountPhotoId
        : AvatarCatalog.forSeed(widget.profile.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final saved = await ref
        .read(profileProvider.notifier)
        .updateIdentity(
          displayName: _nameController.text,
          avatarId: _selectedAvatarId,
        );
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() => _saving = false);
    AppFeedback.show(
      context,
      message: context.tr('profile_update_failed'),
      type: AppFeedbackType.error,
      aboveNavigation: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);

    return GlassModalShell(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.tr('edit_profile_title'),
                      style: TextStyle(
                        color: p.textPrimary,
                        fontSize: AppConstants.fontSection,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  GlassIconButton(
                    icon: PhosphorIconsRegular.x,
                    tooltip: context.tr('cancel'),
                    color: p.textSecondary,
                    size: AppConstants.minTouchTarget,
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingLG),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: p.primaryOrange,
                    boxShadow: [
                      BoxShadow(
                        color: p.primaryOrange.withValues(alpha: 0.28),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: ProfileAvatar(
                    avatarId: _selectedAvatarId,
                    photoUrl: widget.profile.photoUrl,
                    size: 88,
                    fallbackColor: p.iconColor,
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingXL),
              Text(
                context.tr('choose_avatar'),
                style: TextStyle(
                  color: p.textPrimary,
                  fontSize: AppConstants.fontBody,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppConstants.spacingMD),
              LayoutBuilder(
                builder: (context, constraints) {
                  const spacing = AppConstants.spacingSM;
                  final fittedColumns =
                      ((constraints.maxWidth + spacing) /
                              (AppConstants.minTouchTarget + spacing))
                          .floor();
                  final crossAxisCount = fittedColumns.clamp(1, 5);
                  final reduceMotion =
                      MediaQuery.maybeOf(context)?.disableAnimations ?? false;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _avatarOptions.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing,
                    ),
                    itemBuilder: (context, index) {
                      final avatarId = _avatarOptions[index];
                      final selected = avatarId == _selectedAvatarId;
                      return Semantics(
                        label: avatarId == AvatarCatalog.accountPhotoId
                            ? context.tr('google_profile_photo')
                            : context.tr(
                                'avatar_option',
                                args: {'n': '${index + 1}'},
                              ),
                        button: true,
                        selected: selected,
                        child: GestureDetector(
                          key: ValueKey('edit_$avatarId'),
                          behavior: HitTestBehavior.opaque,
                          onTap: _saving
                              ? null
                              : () => setState(
                                  () => _selectedAvatarId = avatarId,
                                ),
                          child: AnimatedContainer(
                            duration: reduceMotion
                                ? Duration.zero
                                : AppConstants.animationFast,
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: selected ? p.primaryOrange : p.glassBorder,
                            ),
                            child: LayoutBuilder(
                              builder: (context, avatarConstraints) {
                                return ProfileAvatar(
                                  avatarId: avatarId,
                                  photoUrl: widget.profile.photoUrl,
                                  size: avatarConstraints.maxWidth,
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
              const SizedBox(height: AppConstants.spacingXL),
              GlassTextField(
                controller: _nameController,
                maxLength: Validators.profileDisplayNameMaxLength,
                enabled: !_saving,
                hintText: context.tr('full_name_hint'),
                labelText: context.tr('full_name'),
                prefixIcon: Icon(PhosphorIconsRegular.user, color: p.iconColor),
                validator: (value) {
                  final key = Validators.validateFullName(value);
                  return key == null ? null : context.tr(key);
                },
              ),
              const SizedBox(height: AppConstants.spacingLG),
              NeonButton(
                label: context.tr('save_changes'),
                icon: PhosphorIconsRegular.check,
                isLoading: _saving,
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
