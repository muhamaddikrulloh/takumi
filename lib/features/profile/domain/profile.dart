class Profile {
  final String displayName;
  final String email;
  final String? photoUrl;
  final String? avatarId;
  final String institution;
  final String major;
  final bool setupComplete;

  const Profile({
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.avatarId,
    required this.institution,
    required this.major,
    this.setupComplete = false,
  });

  Profile copyWith({
    String? displayName,
    String? avatarId,
    String? institution,
    String? major,
    bool? setupComplete,
  }) {
    return Profile(
      displayName: displayName ?? this.displayName,
      email: email,
      photoUrl: photoUrl,
      avatarId: avatarId ?? this.avatarId,
      institution: institution ?? this.institution,
      major: major ?? this.major,
      setupComplete: setupComplete ?? this.setupComplete,
    );
  }
}
