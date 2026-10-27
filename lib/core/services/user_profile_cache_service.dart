import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../database/local_database_helper.dart';

/// High-performance local-first user profile caching service.
/// Eliminates N+1 Firestore queries across list tiles, chats, activity, and search screens.
class UserProfileCacheService {
  UserProfileCacheService._internal();
  static final UserProfileCacheService instance =
      UserProfileCacheService._internal();

  final Map<String, Map<String, dynamic>> _memoryCache = {};
  final Map<String, Future<Map<String, dynamic>?>> _inFlightFetches = {};

  /// Synchronously checks if a user profile is already present in memory.
  Map<String, dynamic>? getProfileSync(String uid) {
    if (uid.isEmpty) return null;
    return _memoryCache[uid];
  }

  /// Gets a user profile local-first:
  /// 1. Memory cache check (0ms).
  /// 2. SQLite local database check (instant disk hit).
  /// 3. In-flight request deduplication (prevents duplicate concurrent Firestore fetches).
  /// 4. Authoritative Firestore fetch with automatic local persistence.
  Future<Map<String, dynamic>?> getProfile({
    required String currentUserId,
    required String targetUid,
  }) async {
    if (targetUid.isEmpty) return null;

    // 1. Memory cache check
    if (_memoryCache.containsKey(targetUid)) {
      return _memoryCache[targetUid];
    }

    // 2. Local SQLite check
    if (currentUserId.isNotEmpty) {
      try {
        final local = await LocalDatabaseHelper.instance.getUserProfile(
          currentUserId,
          targetUid,
        );
        if (local != null &&
            (local['username'] ?? '').toString().trim().isNotEmpty) {
          final profile = {
            'username': local['username'],
            'display_name': local['display_name'] ?? local['username'],
            'about': local['about'] ?? '',
            'email': local['email'] ?? '',
            'image_url': local['image_url'] ?? '',
            'userimageurl': local['image_url'] ?? '',
          };
          _memoryCache[targetUid] = profile;
          return profile;
        }
      } catch (_) {}
    }

    // 3. In-flight deduplication
    if (_inFlightFetches.containsKey(targetUid)) {
      return await _inFlightFetches[targetUid];
    }

    // 4. Firestore fetch
    final fetchFuture = _fetchFromFirestore(currentUserId, targetUid);
    _inFlightFetches[targetUid] = fetchFuture;

    try {
      return await fetchFuture;
    } finally {
      _inFlightFetches.remove(targetUid);
    }
  }

  Future<Map<String, dynamic>?> _fetchFromFirestore(
    String currentUserId,
    String targetUid,
  ) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(targetUid)
          .get();
      final data = doc.data();
      if (data == null) return null;

      final username = (data['username'] ?? data['name'] ?? 'User').toString();
      final imageUrl = (data['userimageurl'] ??
              data['imageurl'] ??
              data['image_url'] ??
              data['photoURL'] ??
              '')
          .toString();
      final about = (data['about'] ?? '').toString();
      final email = (data['email'] ?? '').toString();

      final profile = {
        'username': username,
        'display_name': username,
        'about': about,
        'email': email,
        'image_url': imageUrl,
        'userimageurl': imageUrl,
      };

      _memoryCache[targetUid] = profile;

      if (currentUserId.isNotEmpty) {
        await LocalDatabaseHelper.instance.upsertUserProfile(
          currentUserId,
          targetUid,
          profile,
        );
      }

      return profile;
    } catch (_) {
      return null;
    }
  }

  /// Manually sets a memory cache entry (e.g. for testing or optimistic updates).
  void setMemoryCache(String uid, Map<String, dynamic> profile) {
    if (uid.isNotEmpty) {
      _memoryCache[uid] = profile;
    }
  }

  /// Invalidates cached profile when a user updates their profile or avatar.
  void invalidate(String uid) {
    if (uid.isEmpty) return;
    _memoryCache.remove(uid);
    _inFlightFetches.remove(uid);
  }

  /// Clears in-memory cache (e.g. on logout).
  void clearMemory() {
    _memoryCache.clear();
    _inFlightFetches.clear();
  }
}
