import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

/// Authenticated HTTP Client using Google OAuth headers.
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }

  @override
  void close() {
    _client.close();
    super.close();
  }
}

class DriveService {
  static final DriveService instance = DriveService._internal();
  DriveService._internal();

  static const String appFolderName = 'QuickMessenger Media';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId:
        '85470283732-h8m9kmnclgovhmvnana691eh8p3ekl5g.apps.googleusercontent.com',
    scopes: [
      'email',
      'profile',
      drive.DriveApi.driveFileScope,
    ],
  );

  GoogleSignIn get googleSignIn => _googleSignIn;

  Future<drive.DriveApi?> _getDriveApi() async {
    GoogleSignInAccount? account = _googleSignIn.currentUser;
    account ??= await _googleSignIn.signInSilently();
    account ??= await _googleSignIn.signIn();
    if (account == null) return null;

    final authHeaders = await account.authHeaders;
    final client = GoogleAuthClient(authHeaders);
    return drive.DriveApi(client);
  }

  /// Get or create the dedicated 'QuickMessenger Media' folder in user's Drive.
  Future<String?> getOrCreateAppFolder() async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return null;

      final fileList = await driveApi.files.list(
        q: "mimeType = 'application/vnd.google-apps.folder' and name = '$appFolderName' and trashed = false",
        spaces: 'drive',
        $fields: 'files(id, name)',
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        return fileList.files!.first.id;
      }

      // Create new folder
      final folderMetadata = drive.File()
        ..name = appFolderName
        ..mimeType = 'application/vnd.google-apps.folder';

      final created = await driveApi.files.create(
        folderMetadata,
        $fields: 'id',
      );
      return created.id;
    } catch (_) {
      return null;
    }
  }

  /// Uploads a media file (image or document) to the user's Drive folder.
  /// Sets read permission so the chat participant can download it.
  Future<Map<String, dynamic>?> uploadMediaFile({
    required File file,
    required String fileName,
    required String mimeType,
  }) async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return null;

      final folderId = await getOrCreateAppFolder();
      final parentList = folderId != null ? [folderId] : <String>[];

      final driveFile = drive.File()
        ..name = fileName
        ..parents = parentList
        ..mimeType = mimeType;

      final media = drive.Media(file.openRead(), file.lengthSync());

      final uploaded = await driveApi.files.create(
        driveFile,
        uploadMedia: media,
        $fields: 'id, name, size, mimeType, webContentLink, webViewLink',
      );

      final fileId = uploaded.id;
      if (fileId == null) return null;

      // Make file accessible to anyone with the link
      try {
        final permission = drive.Permission()
          ..role = 'reader'
          ..type = 'anyone';

        await driveApi.permissions.create(
          permission,
          fileId,
          $fields: 'id',
        );
      } catch (_) {}

      // Refetch link
      final sharedFile = await driveApi.files.get(
        fileId,
        $fields: 'id, name, size, webContentLink, webViewLink',
      ) as drive.File;

      // Generate direct, reliable CDN/download links for participants
      final bool isImage = mimeType.startsWith('image/');
      final downloadUrl = isImage
          ? 'https://lh3.googleusercontent.com/d/$fileId'
          : 'https://drive.usercontent.google.com/download?id=$fileId&export=download&authuser=0&confirm=t';

      return {
        'driveFileId': fileId,
        'fileName': sharedFile.name ?? fileName,
        'fileSize': int.tryParse(sharedFile.size ?? '') ?? file.lengthSync(),
        'fileUrl': downloadUrl,
        'webViewLink': sharedFile.webViewLink ?? '',
      };
    } catch (e) {
      return null;
    }
  }

  /// Downloads file content directly from Drive API stream if public link is inaccessible.
  Future<bool> downloadFileToLocal(String driveFileId, File targetFile) async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return false;
      final media = await driveApi.files.get(
        driveFileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;
      final sink = targetFile.openWrite();
      await media.stream.pipe(sink);
      await sink.close();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Calculates total storage space consumed by QuickMessenger files on Google Drive.
  Future<Map<String, dynamic>> getStorageUsage() async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) {
        return {'totalBytes': 0, 'fileCount': 0};
      }

      final folderId = await getOrCreateAppFolder();
      if (folderId == null) {
        return {'totalBytes': 0, 'fileCount': 0};
      }

      final fileList = await driveApi.files.list(
        q: "'$folderId' in parents and trashed = false and mimeType != 'application/vnd.google-apps.folder'",
        spaces: 'drive',
        $fields: 'files(id, name, size)',
      );

      int totalBytes = 0;
      int count = 0;
      if (fileList.files != null) {
        for (final f in fileList.files!) {
          final size = int.tryParse(f.size ?? '') ?? 0;
          totalBytes += size;
          count++;
        }
      }

      return {'totalBytes': totalBytes, 'fileCount': count};
    } catch (_) {
      return {'totalBytes': 0, 'fileCount': 0};
    }
  }

  /// Lists all files stored in the QuickMessenger Drive folder.
  Future<List<Map<String, dynamic>>> listDriveFiles() async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return [];

      final folderId = await getOrCreateAppFolder();
      if (folderId == null) return [];

      final fileList = await driveApi.files.list(
        q: "'$folderId' in parents and trashed = false and mimeType != 'application/vnd.google-apps.folder'",
        spaces: 'drive',
        $fields: 'files(id, name, size, createdTime, webContentLink)',
      );

      if (fileList.files == null) return [];
      return fileList.files!
          .map((f) => {
                'id': f.id ?? '',
                'name': f.name ?? 'File',
                'size': int.tryParse(f.size ?? '') ?? 0,
                'createdTime': f.createdTime?.toIso8601String() ?? '',
              })
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Deletes a file from Google Drive by its file ID.
  Future<bool> deleteFile(String driveFileId) async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return false;
      await driveApi.files.delete(driveFileId);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Deletes all files in the QuickMessenger Drive folder.
  Future<bool> deleteAllAppFiles() async {
    try {
      final files = await listDriveFiles();
      for (final f in files) {
        final id = f['id'] as String?;
        if (id != null && id.isNotEmpty) {
          await deleteFile(id);
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Alias for deleteAllAppFiles
  Future<bool> deleteAllAppMedia() => deleteAllAppFiles();
}
