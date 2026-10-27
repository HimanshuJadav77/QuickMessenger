class GroupModel {
  final String groupId;
  final String name;
  final String description;
  final String imageUrl;
  final String createdBy;
  final String createdAt;
  final String myRole;
  final int memberCount;
  final String? lastMessage;
  final String? lastTimestamp;
  final int unreadCount;

  const GroupModel({
    required this.groupId,
    required this.name,
    this.description = '',
    this.imageUrl = '',
    required this.createdBy,
    required this.createdAt,
    this.myRole = 'member',
    this.memberCount = 1,
    this.lastMessage,
    this.lastTimestamp,
    this.unreadCount = 0,
  });

  /// Exact match constructor for SQLite database rows.
  factory GroupModel.fromDb(Map<String, dynamic> map) {
    return GroupModel(
      groupId: (map['group_id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      imageUrl: (map['image_url'] ?? '').toString(),
      createdBy: (map['created_by'] ?? '').toString(),
      createdAt: (map['created_at'] ?? '').toString(),
      myRole: (map['my_role'] ?? 'member').toString(),
      memberCount: map['member_count'] is int
          ? map['member_count'] as int
          : int.tryParse(map['member_count']?.toString() ?? '1') ?? 1,
      lastMessage: map['last_message']?.toString(),
      lastTimestamp: map['last_timestamp']?.toString(),
      unreadCount: map['unread_count'] is int
          ? map['unread_count'] as int
          : int.tryParse(map['unread_count']?.toString() ?? '0') ?? 0,
    );
  }

  /// Exact match constructor for Server / Socket.IO / Firestore payloads.
  factory GroupModel.fromServer(Map<String, dynamic> map) {
    return GroupModel(
      groupId: (map['groupId'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      imageUrl: (map['imageUrl'] ?? '').toString(),
      createdBy: (map['createdBy'] ?? '').toString(),
      createdAt: (map['createdAt'] ?? '').toString(),
      myRole: (map['myRole'] ?? 'member').toString(),
      memberCount: map['memberCount'] is int
          ? map['memberCount'] as int
          : (map['memberUids'] is List
              ? (map['memberUids'] as List).length
              : int.tryParse(map['memberCount']?.toString() ?? '1') ?? 1),
      lastMessage: map['lastMessage']?.toString(),
      lastTimestamp: map['lastTimestamp']?.toString(),
      unreadCount: map['unreadCount'] is int
          ? map['unreadCount'] as int
          : int.tryParse(map['unreadCount']?.toString() ?? '0') ?? 0,
    );
  }

  /// Unified constructor dispatching directly to [fromDb] or [fromServer].
  factory GroupModel.fromMap(Map<String, dynamic> map) {
    if (map.containsKey('group_id') || map.containsKey('created_by')) {
      return GroupModel.fromDb(map);
    }
    return GroupModel.fromServer(map);
  }

  Map<String, dynamic> toMap() {
    return {
      'group_id': groupId,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'created_by': createdBy,
      'created_at': createdAt,
      'my_role': myRole,
      'member_count': memberCount,
      'last_message': lastMessage,
      'last_timestamp': lastTimestamp,
      'unread_count': unreadCount,
    };
  }

  GroupModel copyWith({
    String? groupId,
    String? name,
    String? description,
    String? imageUrl,
    String? createdBy,
    String? createdAt,
    String? myRole,
    int? memberCount,
    String? lastMessage,
    String? lastTimestamp,
    int? unreadCount,
  }) {
    return GroupModel(
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      myRole: myRole ?? this.myRole,
      memberCount: memberCount ?? this.memberCount,
      lastMessage: lastMessage ?? this.lastMessage,
      lastTimestamp: lastTimestamp ?? this.lastTimestamp,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
