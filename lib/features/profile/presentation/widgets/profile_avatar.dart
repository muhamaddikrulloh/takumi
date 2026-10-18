import 'package:flutter/material.dart';
import 'package:task_track/features/profile/domain/avatar_catalog.dart';
import 'package:task_track/features/profile/presentation/widgets/generated_avatar.dart';
import 'package:task_track/shared/widgets/cached_avatar.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.avatarId,
    required this.photoUrl,
    required this.size,
    required this.fallbackColor,
  });

  final String? avatarId;
  final String? photoUrl;
  final double size;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    if (AvatarCatalog.isGenerated(avatarId)) {
      return GeneratedAvatar(avatarId: avatarId!, size: size);
    }
    return CachedAvatar(
      url: photoUrl,
      size: size,
      fallbackColor: fallbackColor,
    );
  }
}
