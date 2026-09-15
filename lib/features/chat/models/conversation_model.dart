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

  factory ConversationModel.fromMap(Map<String, dynamic> map) {
    return ConversationModel(
      id: map['id'] ?? map['conversationId'] ?? '',
      participantId: map['participant_id'] ?? map['participantId'] ?? '',
      participantName: map['participant_name'] ?? map['participantName'] ?? 'User',
      participantImageUrl: map['participant_imageurl'] ?? map['participantImageUrl'] ?? '',
      lastMessage: map['last_message'] ?? map['lastMessage'] ?? '',
      lastTimestamp: map['last_timestamp'] ?? map['lastTimestamp'] ?? DateTime.now().toIso8601String(),
      unreadCount: map['unread_count'] ?? map['unreadCount'] ?? 0,
      isPinned: map['is_pinned'] == 1 || map['is_pinned'] == true || map['isPinned'] == true,
      isArchived: map['is_archived'] == 1 || map['is_archived'] == true || map['isArchived'] == true,
      isMuted: map['is_muted'] == 1 || map['is_muted'] == true || map['isMuted'] == true,
    );
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

