import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Local-first Avatar Caching Service for QuickMessenger.
///
/// Features:
/// - Fast synchronous memory-cache check for instantaneous rendering
/// - Persistent local disk cache in app documents directory
/// - In-flight download deduplication to prevent redundant network requests
/// - Atomic download staging via temporary files
/// - Robust cache invalidation when a user's avatar is updated
/// - Graceful fallback on network or format errors
class AvatarCacheService {
  static final AvatarCacheService instance = AvatarCacheService._internal();
  AvatarCacheService._internal();

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'User-Agent': 'Mozilla/5.0 (QuickMessenger-AvatarCache/1.0)',
      },
    ),
  );

  /// In-memory cache for fast synchronous lookup: cacheKey -> localFilePath
  final Map<String, String> _memoryCache = {};

  /// In-flight downloads: cacheKey -> Future<String?>
  final Map<String, Future<String?>> _inFlightDownloads = {};

  Directory? _avatarDir;

  /// Generates a stable, deterministic cache key for an avatar.
  String getCacheKey({String? userId, required String url}) {
    final cleanUrl = url.trim();
    String keyPart;
    if (cleanUrl.contains('drive.google.com') ||
        cleanUrl.contains('googleusercontent.com/d/')) {
      final idMatch = RegExp(r'(?:id=|\/d\/|open\?id=)([a-zA-Z0-9_-]+)')
          .firstMatch(cleanUrl);
      if (idMatch != null) {
        keyPart = 'drive_${idMatch.group(1)}';
      } else {
        keyPart = 'hash_${cleanUrl.hashCode.abs()}';
      }
    } else {
      keyPart = 'hash_${cleanUrl.hashCode.abs()}';
    }

    if (userId != null && userId.trim().isNotEmpty) {
      return 'avatar_${userId.trim()}_$keyPart';
    }
    return 'avatar_$keyPart';
  }

  /// Gets the local avatar storage directory.
  Future<Directory> getAvatarDirectory() async {
    if (_avatarDir != null && await _avatarDir!.exists()) {
      return _avatarDir!;
    }
    final appDocDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDocDir.path, 'QuickMessenger', 'Avatars'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _avatarDir = dir;
    return dir;
  }

  /// Synchronously checks if a cached file exists in memory and on disk.
  String? getCachedPathSync({String? userId, required String url}) {
    if (url.isEmpty || !url.startsWith('http')) return null;
    final cacheKey = getCacheKey(userId: userId, url: url);
    final cachedPath = _memoryCache[cacheKey];
    if (cachedPath != null) {
      try {
        final f = File(cachedPath);
        if (f.existsSync() && f.lengthSync() > 0) {
          return cachedPath;
        }
      } catch (_) {
        _memoryCache.remove(cacheKey);
      }
    }
    if (_avatarDir != null) {
      try {
        final f = File(p.join(_avatarDir!.path, '$cacheKey.jpg'));
        if (f.existsSync() && f.lengthSync() > 0) {
          _memoryCache[cacheKey] = f.path;
          return f.path;
        }
      } catch (_) {}
    }
    return null;
  }

  /// Checks if a cached avatar exists on disk and populates memory cache.
  Future<String?> getCachedPath({String? userId, required String url}) async {
    if (url.isEmpty || !url.startsWith('http')) return null;
    final syncHit = getCachedPathSync(userId: userId, url: url);
    if (syncHit != null) return syncHit;

    final cacheKey = getCacheKey(userId: userId, url: url);
    try {
      final dir = await getAvatarDirectory();
      final targetFile = File(p.join(dir.path, '$cacheKey.jpg'));
      if (await _isValidImageFile(targetFile)) {
        _memoryCache[cacheKey] = targetFile.path;
        return targetFile.path;
      }
    } catch (_) {}
    return null;
  }

  /// Fetches the remote avatar, deduplicating concurrent requests and caching locally.
  Future<String?> getOrFetchAvatar(
      {String? userId, required String url}) async {
    if (url.isEmpty || !url.startsWith('http')) return null;

    final existing = await getCachedPath(userId: userId, url: url);
    if (existing != null) return existing;

    final cacheKey = getCacheKey(userId: userId, url: url);

    // Reuse in-flight download future if one is already running
    if (_inFlightDownloads.containsKey(cacheKey)) {
      return await _inFlightDownloads[cacheKey];
    }

    final downloadFuture = _executeDownload(cacheKey, url);
    _inFlightDownloads[cacheKey] = downloadFuture;

    try {
      return await downloadFuture;
    } finally {
      _inFlightDownloads.remove(cacheKey);
    }
  }

  Future<String?> _executeDownload(String cacheKey, String rawUrl) async {
    try {
      final dir = await getAvatarDirectory();
      final targetFile = File(p.join(dir.path, '$cacheKey.jpg'));
      final tempFile = File(p.join(dir.path,
          '${cacheKey}_${DateTime.now().microsecondsSinceEpoch}.tmp'));

      String downloadUrl = rawUrl;
      // Convert Google Drive open URL to high-speed thumbnail / direct CDN
      if (downloadUrl.contains('drive.google.com')) {
        final idMatch = RegExp(r'(?:id=|\/d\/|open\?id=)([a-zA-Z0-9_-]+)')
            .firstMatch(downloadUrl);
        if (idMatch != null) {
          final fileId = idMatch.group(1);
          downloadUrl = 'https://drive.google.com/thumbnail?id=$fileId&sz=w500';
        }
      }

      await _dio.download(
        downloadUrl,
        tempFile.path,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) => status != null && status < 400,
        ),
      );

      if (await _isValidImageFile(tempFile)) {
        if (await targetFile.exists()) {
          try {
            await targetFile.delete();
          } catch (_) {}
        }
        await tempFile.rename(targetFile.path);
        _memoryCache[cacheKey] = targetFile.path;
        return targetFile.path;
      } else {
        if (await tempFile.exists()) {
          try {
            await tempFile.delete();
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('[AvatarCacheService] Error downloading avatar ($rawUrl): $e');
    }
    return null;
  }

  Future<bool> _isValidImageFile(File file) async {
    try {
      if (!await file.exists()) return false;
      final len = await file.length();
      if (len <= 0) return false;
      if (len < 1024) {
        final bytes = await file.readAsBytes();
        final head = String.fromCharCodes(bytes.take(120)).toLowerCase();
        if (head.contains('<!doctype') ||
            head.contains('<html') ||
            head.contains('error')) {
          return false;
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Invalidates and removes all cached avatar files for a specific user ID.
  Future<void> invalidateUser(String userId) async {
    if (userId.isEmpty) return;
    try {
      _memoryCache.removeWhere((key, _) => key.startsWith('avatar_${userId}_'));
      final dir = await getAvatarDirectory();
      if (await dir.exists()) {
        final prefix = 'avatar_${userId}_';
        await for (final entity in dir.list(followLinks: false)) {
          if (entity is File && p.basename(entity.path).startsWith(prefix)) {
            try {
              await entity.delete();
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      debugPrint(
          '[AvatarCacheService] Error invalidating user avatar ($userId): $e');
    }
  }

  /// Clear entire avatar cache.
  Future<void> clearAll() async {
    _memoryCache.clear();
    try {
      final dir = await getAvatarDirectory();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await dir.create(recursive: true);
      }
    } catch (_) {}
  }
}
