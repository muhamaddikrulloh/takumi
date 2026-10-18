class AvatarCatalog {
  AvatarCatalog._();

  static const accountPhotoId = 'account_photo';

  static const ids = <String>[
    'avatar_01',
    'avatar_02',
    'avatar_03',
    'avatar_04',
    'avatar_05',
    'avatar_06',
    'avatar_07',
    'avatar_08',
    'avatar_09',
    'avatar_10',
  ];

  static const defaultId = 'avatar_01';

  static bool isGenerated(String? id) => id != null && ids.contains(id);

  static bool isValid(String? id) {
    return isGenerated(id) || id == accountPhotoId;
  }

  static bool isAvailable(String? id, {required String? photoUrl}) {
    if (isGenerated(id)) return true;
    return id == accountPhotoId && photoUrl?.trim().isNotEmpty == true;
  }

  static List<String> choices({
    required bool hasAccountPhoto,
    String? selectedId,
  }) {
    if (!hasAccountPhoto) return ids;
    final generated = ids.take(9).toList();
    if (isGenerated(selectedId) && !generated.contains(selectedId)) {
      generated[generated.length - 1] = selectedId!;
    }
    return [accountPhotoId, ...generated];
  }

  static String forSeed(String seed) {
    if (seed.isEmpty) return defaultId;
    return ids[seed.hashCode.abs() % ids.length];
  }
}
