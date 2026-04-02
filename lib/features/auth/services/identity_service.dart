import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:synchronized/synchronized.dart';

import 'package:github_wallpaper/core/storage/storage_service.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';
import 'package:github_wallpaper/features/auth/services/oauth_service.dart';

class IdentityService {
  IdentityService._();

  static final Lock _lock = Lock();
  static final RegExp _canonicalUserIdPattern =
      RegExp(r'^gw_usr_[a-z0-9]{20,}$');
  static final RegExp _legacyGitHubUidPattern = RegExp(r'^github:\d+$');
  static const String _usersCollection = 'users';
  static const String _emailLinksCollection = 'identity_links_email';
  static const String _githubLinksCollection = 'identity_links_github';
  static const String _legacyLinksCollection = 'legacy_identity_links';

  static FirebaseFirestore? get _dbOrNull {
    if (Firebase.apps.isEmpty) return null;
    return FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'default',
    );
  }

  static bool isCanonicalInternalUserId(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return false;
    return _canonicalUserIdPattern.hasMatch(normalized);
  }

  static bool shouldRefreshLegacyFirebaseSession(User? user) {
    if (user == null || user.isAnonymous) return false;
    return !isCanonicalInternalUserId(user.uid);
  }

  static bool isLegacyGitHubFirebaseUid(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return false;
    return _legacyGitHubUidPattern.hasMatch(normalized);
  }

  static Future<bool> canUseAuthenticatedAppSession({User? user}) async {
    final firebaseUser = user ??
        (Firebase.apps.isEmpty ? null : FirebaseAuth.instance.currentUser);
    if (firebaseUser == null || firebaseUser.isAnonymous) {
      return false;
    }

    try {
      final token = await firebaseUser.getIdTokenResult();
      if (token.signInProvider != 'custom') {
        return false;
      }

      final rawUid = firebaseUser.uid.trim().toLowerCase();
      if (isCanonicalInternalUserId(rawUid)) {
        return true;
      }

      final claimCandidates = [
        token.claims?['gitwall_user_id'],
        token.claims?['internal_user_id'],
        token.claims?['app_user_id'],
      ];
      for (final candidate in claimCandidates) {
        final value = candidate?.toString().trim().toLowerCase();
        if (isCanonicalInternalUserId(value)) {
          return true;
        }
      }

      final githubProviderId = _normalizeText(
        token.claims?['github_provider_id']?.toString(),
      );
      if (githubProviderId != null) {
        return true;
      }

      return isLegacyGitHubFirebaseUid(rawUid);
    } catch (_) {
      return false;
    }
  }

  static Future<String?> getVerifiedGitHubEmail({
    User? user,
    OAuthSession? session,
    bool forceRefreshToken = false,
  }) async {
    return _resolveVerifiedGitHubEmail(
      user,
      session: session,
      forceRefreshToken: forceRefreshToken,
    );
  }

  static Future<String?> getCurrentInternalUserId() async {
    final stored = StorageService.getInternalUserId();
    if (isCanonicalInternalUserId(stored)) {
      return stored!.trim().toLowerCase();
    }
    final user =
        Firebase.apps.isEmpty ? null : FirebaseAuth.instance.currentUser;
    return _canonicalUserIdFromFirebaseUser(user);
  }

  static Future<String?> ensureInternalUserId({
    User? user,
    OAuthSession? session,
  }) async {
    return _lock.synchronized(() async {
      final firebaseUser = user ??
          (Firebase.apps.isEmpty ? null : FirebaseAuth.instance.currentUser);

      final sessionUserId = session?.internalUserId.trim().toLowerCase();
      if (isCanonicalInternalUserId(sessionUserId)) {
        await _persistCanonicalIdentity(
          internalUserId: sessionUserId!,
          firebaseUser: firebaseUser,
          session: session,
        );
        return sessionUserId;
      }

      if (firebaseUser == null || firebaseUser.isAnonymous) {
        return null;
      }

      if (!await canUseAuthenticatedAppSession(user: firebaseUser)) {
        return null;
      }

      final stored = StorageService.getInternalUserId()?.trim().toLowerCase();
      if (isCanonicalInternalUserId(stored)) {
        await _persistCanonicalIdentity(
          internalUserId: stored!,
          firebaseUser: firebaseUser,
          session: session,
        );
        return stored;
      }

      final userIdFromFirebase =
          await _canonicalUserIdFromFirebaseUser(firebaseUser);
      if (isCanonicalInternalUserId(userIdFromFirebase)) {
        await _persistCanonicalIdentity(
          internalUserId: userIdFromFirebase!,
          firebaseUser: firebaseUser,
          session: session,
        );
        return userIdFromFirebase;
      }

      final migratedUserId = await migrateLegacyIdentityIfNeeded(
        firebaseUser: firebaseUser,
        session: session,
      );
      if (isCanonicalInternalUserId(migratedUserId)) {
        return migratedUserId;
      }

      return null;
    });
  }

  static Future<String?> migrateLegacyIdentityIfNeeded({
    required User firebaseUser,
    OAuthSession? session,
  }) async {
    final existing = await _lookupCanonicalInternalUserId(
      firebaseUser: firebaseUser,
      session: session,
    );
    if (isCanonicalInternalUserId(existing)) {
      await _persistCanonicalIdentity(
        internalUserId: existing!,
        firebaseUser: firebaseUser,
        session: session,
      );
      return existing;
    }
    return null;
  }

  static Future<void> applyAuthenticatedSession(
    OAuthSession session, {
    User? firebaseUser,
  }) async {
    await Future.wait([
      StorageService.setUsername(session.username),
      StorageService.setUserEmail(session.email),
      StorageService.setGitHubProviderId(session.githubProviderId),
    ]);
    await ensureInternalUserId(
      user: firebaseUser,
      session: session,
    );
  }

  static Future<void> clearIdentity() async {
    await Future.wait([
      StorageService.clearInternalUserId(),
      StorageService.setLegacyAppUserId(null),
      StorageService.setLegacyFirebaseUid(null),
      StorageService.setGitHubProviderId(null),
    ]);
  }

  static Future<String?> _canonicalUserIdFromFirebaseUser(User? user) async {
    if (user == null || user.isAnonymous) return null;

    final uid = user.uid.trim().toLowerCase();
    if (isCanonicalInternalUserId(uid)) {
      return uid;
    }

    try {
      final token = await user.getIdTokenResult();
      final claimCandidates = [
        token.claims?['gitwall_user_id'],
        token.claims?['internal_user_id'],
        token.claims?['app_user_id'],
      ];
      for (final candidate in claimCandidates) {
        final value = candidate?.toString().trim().toLowerCase();
        if (isCanonicalInternalUserId(value)) {
          return value;
        }
      }
    } catch (_) {}

    return null;
  }

  static Future<String?> _lookupCanonicalInternalUserId({
    required User firebaseUser,
    OAuthSession? session,
  }) async {
    final db = _dbOrNull;
    if (db == null) return null;

    // Keep this lookup order aligned with functions/index.js.
    final legacyFirebaseUid = _legacyFirebaseUid(firebaseUser);
    final githubProviderId = _normalizeText(
      session?.githubProviderId ?? StorageService.getGitHubProviderId(),
    );
    final email =
        await _resolveVerifiedGitHubEmail(firebaseUser, session: session);
    final legacyStoredId = _normalizeLegacyGitHubUid(
      StorageService.getLegacyAppUserId() ?? StorageService.getInternalUserId(),
    );

    final candidateKeys = <String>[
      if (legacyFirebaseUid != null) legacyFirebaseUid,
      if (legacyStoredId != null) legacyStoredId,
    ];

    for (final key in candidateKeys) {
      final linkSnapshot =
          await db.collection(_legacyLinksCollection).doc(key).get();
      final value = _normalizeText(
        linkSnapshot.data()?['internalUserId'] ??
            linkSnapshot.data()?['appUserId'],
      );
      if (isCanonicalInternalUserId(value)) {
        return value;
      }
    }

    if (githubProviderId != null) {
      final githubLink = await db
          .collection(_githubLinksCollection)
          .doc(githubProviderId)
          .get();
      final value = _normalizeText(
        githubLink.data()?['internalUserId'] ?? githubLink.data()?['appUserId'],
      );
      if (isCanonicalInternalUserId(value)) {
        return value;
      }
    }

    if (email != null) {
      final emailLink =
          await db.collection(_emailLinksCollection).doc(email).get();
      final linkedUserId = _normalizeText(
        emailLink.data()?['internalUserId'] ?? emailLink.data()?['appUserId'],
      );
      if (isCanonicalInternalUserId(linkedUserId)) {
        return linkedUserId;
      }

      final legacyUserDoc =
          await db.collection(_usersCollection).doc(email).get();
      final legacyUserId = _normalizeText(
        legacyUserDoc.data()?['internalUserId'] ??
            legacyUserDoc.data()?['appUserId'],
      );
      if (isCanonicalInternalUserId(legacyUserId)) {
        return legacyUserId;
      }
    }

    return null;
  }

  static Future<void> _persistCanonicalIdentity({
    required String internalUserId,
    required User? firebaseUser,
    required OAuthSession? session,
  }) async {
    final canonicalUserId = internalUserId.trim().toLowerCase();
    if (!isCanonicalInternalUserId(canonicalUserId)) {
      throw ArgumentError.value(
        internalUserId,
        'internalUserId',
        'Expected a canonical GitWall user id.',
      );
    }

    final previousStoredId = _normalizeLegacyGitHubUid(
      StorageService.getInternalUserId(),
    );
    if (previousStoredId != null && previousStoredId != canonicalUserId) {
      await StorageService.setLegacyAppUserId(previousStoredId);
    }

    final legacyFirebaseUid = _legacyFirebaseUid(firebaseUser);
    if (legacyFirebaseUid != null && legacyFirebaseUid != canonicalUserId) {
      await StorageService.setLegacyFirebaseUid(legacyFirebaseUid);
    }

    await StorageService.setInternalUserId(canonicalUserId);

    if (session != null) {
      await Future.wait([
        StorageService.setUserEmail(session.email),
        StorageService.setUsername(session.username),
        StorageService.setGitHubProviderId(session.githubProviderId),
      ]);
    }

    await _upsertIdentityDocuments(
      internalUserId: canonicalUserId,
      firebaseUser: firebaseUser,
      session: session,
    );
  }

  static Future<void> _upsertIdentityDocuments({
    required String internalUserId,
    required User? firebaseUser,
    required OAuthSession? session,
  }) async {
    final db = _dbOrNull;
    if (db == null) return;

    try {
      final userRef = db.collection(_usersCollection).doc(internalUserId);
      final userSnapshot = await userRef.get();
      final email =
          await _resolveVerifiedGitHubEmail(firebaseUser, session: session);
      final username = _normalizeText(
        session?.username ?? StorageService.getUsername(),
      );
      final githubProviderId = _normalizeText(
        session?.githubProviderId ?? StorageService.getGitHubProviderId(),
      );
      final legacyAppUserId =
          _normalizeLegacyGitHubUid(StorageService.getLegacyAppUserId());
      final legacyFirebaseUid =
          _normalizeLegacyGitHubUid(StorageService.getLegacyFirebaseUid()) ??
              _legacyFirebaseUid(firebaseUser);

      final batch = db.batch();
      final userPayload = <String, dynamic>{
        'internalUserId': internalUserId,
        'appUserId': internalUserId,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (!userSnapshot.exists) {
        userPayload['createdAt'] = FieldValue.serverTimestamp();
      }
      if (email != null) {
        userPayload['email'] = email;
      }
      if (username != null) {
        userPayload['username'] = username;
      }
      if (githubProviderId != null) {
        userPayload['githubProviderId'] = githubProviderId;
      }

      final providerLinks = <String, dynamic>{};
      if (firebaseUser != null &&
          !firebaseUser.isAnonymous &&
          isCanonicalInternalUserId(firebaseUser.uid)) {
        final canonicalFirebaseUid = firebaseUser.uid.trim().toLowerCase();
        providerLinks['firebase'] = <String, dynamic>{
          'uid': canonicalFirebaseUid,
          'linkedAt': FieldValue.serverTimestamp(),
        };
        userPayload['firebaseUid'] = canonicalFirebaseUid;
      }
      if (githubProviderId != null) {
        providerLinks['github'] = <String, dynamic>{
          'providerId': githubProviderId,
          if (username != null) 'username': username,
          if (email != null) 'email': email,
          'linkedAt': FieldValue.serverTimestamp(),
        };
      }
      if (providerLinks.isNotEmpty) {
        userPayload['providerLinks'] = providerLinks;
      }

      final legacyIds = <String>{
        if (legacyAppUserId != null &&
            !isCanonicalInternalUserId(legacyAppUserId) &&
            legacyAppUserId != internalUserId)
          legacyAppUserId,
        if (legacyFirebaseUid != null &&
            !isCanonicalInternalUserId(legacyFirebaseUid) &&
            legacyFirebaseUid != internalUserId)
          legacyFirebaseUid,
      };
      if (legacyIds.isNotEmpty) {
        userPayload['legacyIds'] = FieldValue.arrayUnion(legacyIds.toList());
      }

      batch.set(userRef, userPayload, SetOptions(merge: true));

      await batch.commit();
    } catch (error, stack) {
      AppLog.error('Identity document sync failed: $error', stack);
    }
  }

  static String? _legacyFirebaseUid(User? user) {
    if (user == null || user.isAnonymous) return null;
    return _normalizeLegacyGitHubUid(user.uid);
  }

  static Future<String?> _resolveVerifiedGitHubEmail(
    User? user, {
    OAuthSession? session,
    bool forceRefreshToken = false,
  }) async {
    final sessionEmail = _normalizeEmail(session?.email);
    if (sessionEmail != null) {
      return sessionEmail;
    }

    if (user != null) {
      try {
        final token = await user.getIdTokenResult(forceRefreshToken);
        final claimEmail = _normalizeEmail(
          token.claims?['github_email']?.toString(),
        );
        if (claimEmail != null) {
          return claimEmail;
        }
      } catch (_) {}
    }

    return null;
  }

  static String? _normalizeEmail(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }

  static String? _normalizeText(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }

  static String? _normalizeLegacyGitHubUid(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return isLegacyGitHubFirebaseUid(normalized) ? normalized : null;
  }
}
