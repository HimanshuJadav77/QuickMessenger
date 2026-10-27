class ConversationModel {
  final String id;
  final String participantId;
  final String participantName;
  final String participantImageUrl;
  final String lastMessage;
  final String lastTimestamp;
  final int unreadCount;
  final bool isPinned;
  final bool isArchived;
  final bool isMuted;

  ConversationModel({
    required this.id,
    required this.participantId,
    this.participantName = 'User',
    this.participantImageUrl = '',
    required this.lastMessage,
    required this.lastTimestamp,
    this.unreadCount = 0,
    this.isPinned = false,
    this.isArchived = false,
    this.isMuted = false,
  });

  /// Exact match constructor for SQLite database rows.
  factory ConversationModel.fromDb(Map<String, dynamic> map) {
    return ConversationModel(
      id: (map['id'] ?? '').toString(),
      participantId: (map['participant_id'] ?? '').toString(),
      participantName: (map['participant_name'] ?? 'User').toString(),
      participantImageUrl: (map['participant_imageurl'] ?? '').toString(),
      lastMessage: (map['last_message'] ?? '').toString(),
      lastTimestamp: (map['last_timestamp'] ?? '').toString().isNotEmpty
          ? map['last_timestamp'].toString()
          : DateTime.now().toIso8601String(),
      unreadCount: map['unread_count'] is int
          ? map['unread_count'] as int
          : int.tryParse(map['unread_count']?.toString() ?? '0') ?? 0,
      isPinned: map['is_pinned'] == 1,
      isArchived: map['is_archived'] == 1,
      isMuted: map['is_muted'] == 1,
    );
  }

  /// Exact match constructor for Server / Socket.IO / Firestore payloads.
  factory ConversationModel.fromServer(Map<String, dynamic> map) {
    return ConversationModel(
      id: (map['conversationId'] ?? map['id'] ?? '').toString(),
      participantId: (map['participantId'] ?? '').toString(),
      participantName: (map['participantName'] ?? 'User').toString(),
      participantImageUrl: (map['participantImageUrl'] ?? '').toString(),
      lastMessage: (map['lastMessage'] ?? '').toString(),
      lastTimestamp: (map['lastTimestamp'] ?? '').toString().isNotEmpty
          ? map['lastTimestamp'].toString()
          : DateTime.now().toIso8601String(),
      unreadCount: map['unreadCount'] is int
          ? map['unreadCount'] as int
          : int.tryParse(map['unreadCount']?.toString() ?? '0') ?? 0,
      isPinned: map['isPinned'] == true,
      isArchived: map['isArchived'] == true,
      isMuted: map['isMuted'] == true,
    );
  }

  /// Unified constructor dispatching directly to [fromDb] or [fromServer].
  factory ConversationModel.fromMap(Map<String, dynamic> map) {
    if (map.containsKey('participant_id') || map.containsKey('last_message')) {
      return ConversationModel.fromDb(map);
    }
    return ConversationModel.fromServer(map);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participant_id': participantId,
      'participant_name': participantName,
      'participant_imageurl': participantImageUrl,
      'last_message': lastMessage,
      'last_timestamp': lastTimestamp,
      'unread_count': unreadCount,
      'is_pinned': isPinned ? 1 : 0,
      'is_archived': isArchived ? 1 : 0,
      'is_muted': isMuted ? 1 : 0,
    };
  }

  ConversationModel copyWith({
    String? lastMessage,
    String? lastTimestamp,
    int? unreadCount,
    bool? isPinned,
    bool? isArchived,
    bool? isMuted,
  }) {
    return ConversationModel(
      id: id,
      participantId: participantId,
      participantName: participantName,
      participantImageUrl: participantImageUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      lastTimestamp: lastTimestamp ?? this.lastTimestamp,
      unreadCount: unreadCount ?? this.unreadCount,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      isMuted: isMuted ?? this.isMuted,
    );
  }
}
