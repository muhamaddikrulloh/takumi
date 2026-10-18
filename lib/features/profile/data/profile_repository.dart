import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:task_track/features/profile/domain/avatar_catalog.dart';
import 'package:task_track/features/profile/domain/profile.dart';

class ProfileRepository {
  ProfileRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  User? get _verifiedUser {
    final user = _auth.currentUser;
    return user != null && user.emailVerified ? user : null;
  }

  String? get currentVerifiedUid => _verifiedUser?.uid;

  DocumentReference<Map<String, dynamic>>? get _profileDoc {
    final uid = _verifiedUser?.uid;
    if (uid == null) return null;
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('profile')
        .doc('info');
  }

  User _requireVerifiedUser(String expectedUid) {
    final user = _verifiedUser;
    if (user == null || user.uid != expectedUid) {
      throw StateError('Authenticated user changed before profile write');
    }
    return user;
  }

  DocumentReference<Map<String, dynamic>> _profileDocFor(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('profile')
        .doc('info');
  }

  Profile profileFromAuth() {
    final user = _auth.currentUser;
    return Profile(
      displayName: user?.displayName ?? '',
      email: user?.email ?? '',
      photoUrl: user?.photoURL,
      institution: '',
      major: '',
    );
  }

  Future<Profile> getProfileForSetupGate() async {
    final doc = _profileDoc;
    if (doc == null) return profileFromAuth();

    try {
      final cached = await _loadProfile(
        options: const GetOptions(source: Source.cache),
      );
      if (cached.setupComplete) return cached;
    } on FirebaseException {
      // A missing cache entry is expected on the first login on a device.
    }

    return _loadProfile();
  }

  Future<Profile> _loadProfile({GetOptions? options}) async {
    final fallback = profileFromAuth();
    final doc = _profileDoc;
    if (doc == null) return fallback;

    final snapshot = await doc.get(options);
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return fallback;

    final storedDisplayName = data['display_name'];
    final storedInstitution = data['institution'];
    final storedMajor = data['major'];
    final storedAvatarId = data['avatar_id'];
    final displayName = storedDisplayName is String
        ? storedDisplayName
        : fallback.displayName;
    final institution = storedInstitution is String ? storedInstitution : '';
    final major = storedMajor is String ? storedMajor : '';
    final avatarId = storedAvatarId is String ? storedAvatarId : null;
    final setupComplete =
        data['setup_complete'] == true &&
        displayName.trim().isNotEmpty &&
        AvatarCatalog.isAvailable(avatarId, photoUrl: fallback.photoUrl);

    return Profile(
      displayName: displayName,
      email: fallback.email,
      photoUrl: fallback.photoUrl,
      avatarId: avatarId,
      institution: institution,
      major: major,
      setupComplete: setupComplete,
    );
  }

  Future<void> completeSetup({
    required String expectedUid,
    required String displayName,
    required String institution,
    required String major,
    required String avatarId,
  }) async {
    final user = _requireVerifiedUser(expectedUid);
    final doc = _profileDocFor(expectedUid);

    await user.updateDisplayName(displayName);
    await doc.set({
      'display_name': displayName,
      'institution': institution,
      'major': major,
      'avatar_id': avatarId,
      'setup_complete': true,
      'updated_at': FieldValue.serverTimestamp(),
    });
    await user.reload();
  }

  Future<void> updateInstitution({
    required String expectedUid,
    required String value,
  }) async {
    _requireVerifiedUser(expectedUid);
    final doc = _profileDocFor(expectedUid);
    await doc.set({
      'institution': value,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateIdentity({
    required String expectedUid,
    required String displayName,
    required String avatarId,
  }) async {
    final user = _requireVerifiedUser(expectedUid);
    final doc = _profileDocFor(expectedUid);

    await user.updateDisplayName(displayName);
    await doc.set({
      'display_name': displayName,
      'avatar_id': avatarId,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await user.reload();
  }

  Future<void> updateMajor({
    required String expectedUid,
    required String value,
  }) async {
    _requireVerifiedUser(expectedUid);
    final doc = _profileDocFor(expectedUid);
    await doc.set({
      'major': value,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
