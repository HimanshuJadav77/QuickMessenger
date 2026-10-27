import 'dart:convert';

class MessageModel {
  final String messageId;
  final String conversationId;
  final String? groupId;
  final String senderId;
  final String receiverId;
  final String type; // 'text', 'image', 'file', 'video', 'audio'
  final String text;
  final String status; // 'pending', 'sent', 'delivered', 'read'
  final bool isDeletedForMe;
  final bool isDeletedForEveryone;
  final bool isEdited;
  final String? replyToMessageId;
  final String? replyToText;
  final String? replyToSenderId;
  final Map<String, String> reactions; // userId -> emoji
  final String clientCreatedAt;
  final String? serverCreatedAt;

  // Media / Google Drive fields
  final String? fileUrl; // Direct Google Drive download/content link
  final String? localPath; // Absolute local file path on device storage
  final String? driveFileId; // Google Drive file ID for deletion & management
  final String? fileName; // Display file name
  final int? fileSize; // File size in bytes

  MessageModel({
    required this.messageId,
    required this.conversationId,
    this.groupId,
    required this.senderId,
    required this.receiverId,
    this.type = 'text',
    required this.text,
    this.status = 'pending',
    this.isDeletedForMe = false,
    this.isDeletedForEveryone = false,
    this.isEdited = false,
    this.replyToMessageId,
    this.replyToText,
    this.replyToSenderId,
    this.reactions = const {},
    required this.clientCreatedAt,
    this.serverCreatedAt,
    this.fileUrl,
    this.localPath,
    this.driveFileId,
    this.fileName,
    this.fileSize,
  });

  /// Exact match constructor for SQLite database rows.
  factory MessageModel.fromDb(Map<String, dynamic> map) {
    final isEveryone = map['is_deleted_for_everyone'] == 1 ||
        map['is_deleted_for_everyone'] == true;
    final isMe =
        map['is_deleted_for_me'] == 1 || map['is_deleted_for_me'] == true;
    final edited = map['is_edited'] == 1 || map['is_edited'] == true;

    // Parse reactions from JSON string stored in SQLite or direct map
    Map<String, String> reactionsMap = {};
    final rawReactions = map['reactions_json'] ?? map['reactions'];
    if (rawReactions is Map) {
      reactionsMap =
          rawReactions.map((k, v) => MapEntry(k.toString(), v.toString()));
    } else if (rawReactions is String && rawReactions.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawReactions);
        if (decoded is Map) {
          reactionsMap =
              decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
        }
      } catch (_) {}
    }

    return MessageModel(
      messageId: (map['message_id'] ?? '').toString(),
      conversationId: (map['conversation_id'] ?? '').toString(),
      groupId: map['group_id']?.toString(),
      senderId: (map['sender_id'] ?? '').toString(),
      receiverId: (map['receiver_id'] ?? '').toString(),
      type: map['type'] ?? 'text',
      text: isEveryone ? 'This message was deleted' : (map['text'] ?? ''),
      status: map['status'] ?? 'pending',
      isDeletedForMe: isMe,
      isDeletedForEveryone: isEveryone,
      isEdited: edited,
      replyToMessageId: map['reply_to_message_id']?.toString(),
      replyToText: map['reply_to_text']?.toString(),
      replyToSenderId: map['reply_to_sender_id']?.toString(),
      reactions: reactionsMap,
      clientCreatedAt: (map['client_created_at'] ?? '').toString().isNotEmpty
          ? map['client_created_at'].toString()
          : DateTime.now().toIso8601String(),
      serverCreatedAt: map['server_created_at']?.toString(),
      fileUrl: map['file_url']?.toString(),
      localPath: map['local_path']?.toString(),
      driveFileId: map['drive_file_id']?.toString(),
      fileName: map['file_name']?.toString(),
      fileSize: map['file_size'] is int
          ? map['file_size'] as int
          : int.tryParse(map['file_size']?.toString() ?? ''),
    );
  }

  /// Exact match constructor for Server / Socket.IO / Firestore payloads.
  /// Matches exact schemas in Quick_Messenger_Server (chat.events.js, offline-sync.js, group.events.js).
  factory MessageModel.fromServer(Map<String, dynamic> map) {
    final isEveryone = map['isDeletedForEveryone'] == true;
    final isMe = map['isDeletedForMe'] == true;
    final edited = map['isEdited'] == true;

    // Parse reactions map from server payload
    Map<String, String> reactionsMap = {};
    final rawReactions = map['reactions'];
    if (rawReactions is Map) {
      reactionsMap =
          rawReactions.map((k, v) => MapEntry(k.toString(), v.toString()));
    }

    // Parse clientCreatedAt from server payload
    String createdAtStr = '';
    final rawTime = map['clientCreatedAt'] ?? map['createdAt'];
    if (rawTime is String && rawTime.trim().isNotEmpty) {
      createdAtStr = rawTime.trim();
    } else if (rawTime is int) {
      createdAtStr = rawTime > 1000000000000
          ? DateTime.fromMillisecondsSinceEpoch(rawTime).toIso8601String()
          : DateTime.fromMillisecondsSinceEpoch(rawTime * 1000).toIso8601String();
    } else if (rawTime != null) {
      try {
        final dt = (rawTime as dynamic).toDate() as DateTime;
        createdAtStr = dt.toIso8601String();
      } catch (_) {
        createdAtStr = rawTime.toString();
      }
    }
    if (createdAtStr.isEmpty) {
      createdAtStr = DateTime.now().toIso8601String();
    }

    return MessageModel(
      messageId: (map['messageId'] ?? '').toString(),
      conversationId: (map['conversationId'] ?? '').toString(),
      groupId: map['groupId']?.toString(),
      senderId: (map['senderId'] ?? '').toString(),
      receiverId: (map['receiverId'] ?? '').toString(),
      type: map['type'] ?? 'text',
      text: isEveryone ? 'This message was deleted' : (map['text'] ?? ''),
      status: map['status'] ?? 'sent',
      isDeletedForMe: isMe,
      isDeletedForEveryone: isEveryone,
      isEdited: edited,
      replyToMessageId: map['replyToMessageId']?.toString(),
      replyToText: map['replyToText']?.toString(),
      replyToSenderId: map['replyToSenderId']?.toString(),
      reactions: reactionsMap,
      clientCreatedAt: createdAtStr,
      serverCreatedAt: map['createdAt']?.toString(),
      fileUrl: map['fileUrl']?.toString(),
      localPath: map['localPath']?.toString(),
      driveFileId: map['driveFileId']?.toString(),
      fileName: map['fileName']?.toString(),
      fileSize: map['fileSize'] is int
          ? map['fileSize'] as int
          : int.tryParse(map['fileSize']?.toString() ?? ''),
    );
  }

  /// Unified constructor dispatching directly to [fromDb] or [fromServer]
  /// based on whether the payload is from local SQLite (snake_case) or the server (camelCase).
  factory MessageModel.fromMap(Map<String, dynamic> map) {
    if (map.containsKey('message_id') || map.containsKey('client_created_at')) {
      return MessageModel.fromDb(map);
    }
    return MessageModel.fromServer(map);
  }

  Map<String, dynamic> toMap() {
    return {
      'message_id': messageId,
      'conversation_id': conversationId,
      'group_id': groupId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'type': type,
      'text': text,
      'status': status,
      'is_deleted_for_me': isDeletedForMe ? 1 : 0,
      'is_deleted_for_everyone': isDeletedForEveryone ? 1 : 0,
      'is_edited': isEdited ? 1 : 0,
      'reply_to_message_id': replyToMessageId,
      'reply_to_text': replyToText,
      'reply_to_sender_id': replyToSenderId,
      'reactions_json': jsonEncode(reactions),
      'client_created_at': clientCreatedAt,
      'server_created_at': serverCreatedAt,
      'file_url': fileUrl,
      'local_path': localPath,
      'drive_file_id': driveFileId,
      'file_name': fileName,
      'file_size': fileSize,
    };
  }

  MessageModel copyWith({
    String? text,
    String? status,
    bool? isDeletedForMe,
    bool? isDeletedForEveryone,
    bool? isEdited,
    String? replyToMessageId,
    String? replyToText,
    String? replyToSenderId,
    Map<String, String>? reactions,
    String? serverCreatedAt,
    String? fileUrl,
    String? localPath,
    String? driveFileId,
    String? fileName,
    int? fileSize,
  }) {
    return MessageModel(
      messageId: messageId,
      conversationId: conversationId,
      groupId: groupId,
      senderId: senderId,
      receiverId: receiverId,
      type: type,
      text: text ?? this.text,
      status: status ?? this.status,
      isDeletedForMe: isDeletedForMe ?? this.isDeletedForMe,
      isDeletedForEveryone: isDeletedForEveryone ?? this.isDeletedForEveryone,
      isEdited: isEdited ?? this.isEdited,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToText: replyToText ?? this.replyToText,
      replyToSenderId: replyToSenderId ?? this.replyToSenderId,
      reactions: reactions ?? this.reactions,
      clientCreatedAt: clientCreatedAt,
      serverCreatedAt: serverCreatedAt ?? this.serverCreatedAt,
      fileUrl: fileUrl ?? this.fileUrl,
      localPath: localPath ?? this.localPath,
      driveFileId: driveFileId ?? this.driveFileId,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
    );
  }

  /// Deterministically deduplicates messages by messageId and sorts them
  /// in strict chronological ascending order (oldest to newest).
  /// Preserves the most advanced delivery/read status and media paths.
  static List<MessageModel> sortAndDeduplicate(Iterable<MessageModel> messages) {
    final Map<String, MessageModel> map = {};
    for (final m in messages) {
      if (m.messageId.trim().isEmpty) continue;
      final existing = map[m.messageId];
      if (existing == null) {
        map[m.messageId] = m;
      } else {
        final preferredStatus = _moreAdvancedStatus(existing.status, m.status);
        map[m.messageId] = m.copyWith(
          status: preferredStatus,
          localPath: (m.localPath != null && m.localPath!.isNotEmpty)
              ? m.localPath
              : existing.localPath,
          fileUrl: (m.fileUrl != null && m.fileUrl!.isNotEmpty)
              ? m.fileUrl
              : existing.fileUrl,
          driveFileId: (m.driveFileId != null && m.driveFileId!.isNotEmpty)
              ? m.driveFileId
              : existing.driveFileId,
          reactions: m.reactions.isNotEmpty ? m.reactions : existing.reactions,
        );
      }
    }

    final list = map.values.toList();
    list.sort((a, b) {
      DateTime? dtA;
      DateTime? dtB;
      try {
        dtA = DateTime.tryParse(a.clientCreatedAt);
      } catch (_) {}
      try {
        dtB = DateTime.tryParse(b.clientCreatedAt);
      } catch (_) {}

      if (dtA != null && dtB != null) {
        final cmp = dtA.compareTo(dtB);
        if (cmp != 0) return cmp;
      } else if (dtA != null) {
        return -1;
      } else if (dtB != null) {
        return 1;
      }
      return a.messageId.compareTo(b.messageId);
    });
    return list;
  }

  static String _moreAdvancedStatus(String s1, String s2) {
    const rank = {
      'read': 4,
      'seen': 4,
      'delivered': 3,
      'sent': 2,
      'pending': 1,
      'uploading': 1,
      'failed': 0,
    };
    final r1 = rank[s1] ?? 0;
    final r2 = rank[s2] ?? 0;
    return r2 >= r1 ? s2 : s1;
  }
}
