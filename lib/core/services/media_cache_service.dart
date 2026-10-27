import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'drive_service.dart';

class MediaCacheService {
  static final MediaCacheService instance = MediaCacheService._internal();
  MediaCacheService._internal();

  final Dio _dio = Dio();
  final Map<String, Future<String?>> _inFlightDownloads = {};
  final Map<String, String> _memoryPathCache = {};

  /// Synchronously checks if the file path is already known in memory (0ms hit).
  String? getCachedPathSync({required String url, String? driveFileId}) {
    final key = getCacheKey(url: url, driveFileId: driveFileId);
    final cached = _memoryPathCache[key];
    if (cached != null && File(cached).existsSync()) {
      return cached;
    }
    return null;
  }

  /// Records a verified local file path in memory cache for 0ms lookup.
  void setMemoryCachedPath({
    required String url,
    String? driveFileId,
    required String localPath,
  }) {
    final key = getCacheKey(url: url, driveFileId: driveFileId);
    _memoryPathCache[key] = localPath;
  }

  /// Generates a stable, deterministic cache key for remote attachments.
  String getCacheKey({required String url, String? driveFileId}) {
    if (driveFileId != null && driveFileId.trim().isNotEmpty) {
      return 'drive_${driveFileId.trim()}';
    }
    final idMatch =
        RegExp(r'(?:id=|\/d\/|open\?id=)([a-zA-Z0-9_-]+)').firstMatch(url);
    if (idMatch != null) {
      return 'drive_${idMatch.group(1)}';
    }
    return 'net_${url.hashCode.abs()}';
  }

  /// Gets the local media directory for storing downloaded chat media.
  Future<Directory> getMediaDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final mediaDir =
        Directory(p.join(appDocDir.path, 'QuickMessenger', 'Media'));
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }
    return mediaDir;
  }

  /// Validates that a local file exists, is not empty, and is not an HTML error response.
  Future<bool> isFileValid(File file) async {
    try {
      if (!await file.exists()) return false;
      final length = await file.length();
      if (length <= 0) return false;
      if (length < 4096) {
        final headBytes = await file.readAsBytes();
        final headStr = String.fromCharCodes(headBytes.take(180)).toLowerCase();
        if (headStr.contains('<!doctype') ||
            headStr.contains('<html') ||
            headStr.contains('google drive -') ||
            headStr.contains('service login')) {
          return false;
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Checks if a file exists locally given its local path.
  bool fileExists(String? localPath) {
    if (localPath == null || localPath.isEmpty) return false;
    return File(localPath).existsSync();
  }

  /// Looks up whether a valid local copy of a remote attachment is already cached.
  Future<String?> getCachedFilePath({
    required String url,
    required String fileName,
    String? driveFileId,
  }) async {
    try {
      final mediaDir = await getMediaDirectory();
      final cacheKey = getCacheKey(url: url, driveFileId: driveFileId);
      final sanitized = fileName.replaceAll(RegExp(r'[^\w\.-]'), '_');
      final primaryPath = p.join(mediaDir.path, '${cacheKey}_$sanitized');
      final primaryFile = File(primaryPath);

      if (await isFileValid(primaryFile)) {
        _memoryPathCache[cacheKey] = primaryPath;
        return primaryPath;
      }

      // Check if any valid file with this cacheKey prefix exists in media dir
      if (await mediaDir.exists()) {
        final prefix = '${cacheKey}_';
        await for (final entity in mediaDir.list(followLinks: false)) {
          if (entity is File && p.basename(entity.path).startsWith(prefix)) {
            if (await isFileValid(entity)) {
              _memoryPathCache[cacheKey] = entity.path;
              return entity.path;
            }
          }
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Downloads a file from the given URL and saves it to local app media directory.
  /// Reuses existing valid local downloads and deduplicates in-flight requests.
  Future<String?> downloadFile({
    required String url,
    required String fileName,
    String? driveFileId,
    ProgressCallback? onProgress,
  }) async {
    final cacheKey = getCacheKey(url: url, driveFileId: driveFileId);

    // 1. Fast cache check: return existing valid local file if available
    final existingLocalPath = await getCachedFilePath(
      url: url,
      fileName: fileName,
      driveFileId: driveFileId,
    );
    if (existingLocalPath != null) {
      return existingLocalPath;
    }

    // 2. In-flight request deduplication: reuse active download future
    if (_inFlightDownloads.containsKey(cacheKey)) {
      return await _inFlightDownloads[cacheKey];
    }

    // 3. Initiate atomic download
    final downloadFuture = _executeDownload(
      url: url,
      fileName: fileName,
      driveFileId: driveFileId,
      cacheKey: cacheKey,
      onProgress: onProgress,
    );

    _inFlightDownloads[cacheKey] = downloadFuture;

    try {
      return await downloadFuture;
    } finally {
      _inFlightDownloads.remove(cacheKey);
    }
  }

  Future<String?> _executeDownload({
    required String url,
    required String fileName,
    required String? driveFileId,
    required String cacheKey,
    ProgressCallback? onProgress,
  }) async {
    try {
      final mediaDir = await getMediaDirectory();
      final sanitized = fileName.replaceAll(RegExp(r'[^\w\.-]'), '_');
      final targetPath = p.join(mediaDir.path, '${cacheKey}_$sanitized');
      final targetFile = File(targetPath);
      final tempPath = '$targetPath.tmp';
      final tempFile = File(tempPath);

      // Clean up any stale temp file
      if (await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }

      // Extract driveFileId if present in URL
      String? resolvedDriveId = driveFileId;
      if (resolvedDriveId == null || resolvedDriveId.isEmpty) {
        final idMatch =
            RegExp(r'(?:id=|\/d\/|open\?id=)([a-zA-Z0-9_-]+)').firstMatch(url);
        if (idMatch != null) {
          resolvedDriveId = idMatch.group(1);
        }
      }

      final isImage = fileName.toLowerCase().endsWith('.jpg') ||
          fileName.toLowerCase().endsWith('.jpeg') ||
          fileName.toLowerCase().endsWith('.png') ||
          fileName.toLowerCase().endsWith('.gif') ||
          fileName.toLowerCase().endsWith('.webp');

      final downloadCandidates = <String>[];
      if (resolvedDriveId != null && resolvedDriveId.isNotEmpty) {
        if (isImage) {
          downloadCandidates
              .add('https://lh3.googleusercontent.com/d/$resolvedDriveId');
          downloadCandidates.add(
              'https://drive.google.com/thumbnail?id=$resolvedDriveId&sz=w1600');
        }
        downloadCandidates.add(
            'https://drive.usercontent.google.com/download?id=$resolvedDriveId&export=download&authuser=0&confirm=t');
        downloadCandidates.add(
            'https://drive.google.com/uc?export=download&confirm=t&id=$resolvedDriveId');
      }
      if (!downloadCandidates.contains(url)) {
        downloadCandidates.add(url);
      }

      bool success = false;
      for (final candidateUrl in downloadCandidates) {
        try {
          final response = await _dio.download(
            candidateUrl,
            tempPath,
            onReceiveProgress: onProgress,
            options: Options(
              followRedirects: true,
              validateStatus: (status) => status != null && status < 400,
            ),
          );

          if (response.statusCode == 200 && await isFileValid(tempFile)) {
            success = true;
            break;
          } else if (await tempFile.exists()) {
            await tempFile.delete();
          }
        } catch (_) {
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        }
      }

      // If HTTP downloads failed and we have a driveFileId, attempt direct Drive API download
      if (!success && resolvedDriveId != null && resolvedDriveId.isNotEmpty) {
        final apiSuccess = await DriveService.instance
            .downloadFileToLocal(resolvedDriveId, tempFile);
        if (apiSuccess && await isFileValid(tempFile)) {
          success = true;
        } else if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }

      if (success && await tempFile.exists()) {
        // Atomic promote to target path
        if (await targetFile.exists()) {
          await targetFile.delete();
        }
        await tempFile.rename(targetPath);
        return targetPath;
      }

      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Calculates total size of cached local media files in bytes.
  Future<int> getLocalCacheSize() async {
    try {
      final mediaDir = await getMediaDirectory();
      int total = 0;
      await for (final file
          in mediaDir.list(recursive: true, followLinks: false)) {
        if (file is File) {
          total += await file.length();
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  /// Alias for getLocalCacheSize
  Future<int> getCacheSize() => getLocalCacheSize();

  /// Clears local media cache.
  Future<void> clearLocalCache() async {
    try {
      final mediaDir = await getMediaDirectory();
      if (await mediaDir.exists()) {
        await mediaDir.delete(recursive: true);
      }
    } catch (_) {}
  }

  /// Alias for clearLocalCache
  Future<void> clearCache() => clearLocalCache();
}
