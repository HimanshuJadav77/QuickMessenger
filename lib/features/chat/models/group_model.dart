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

  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      groupId: map['group_id'] ?? map['groupId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['image_url'] ?? map['imageUrl'] ?? '',
      createdBy: map['created_by'] ?? map['createdBy'] ?? '',
      createdAt: map['created_at'] ?? map['createdAt'] ?? '',
      myRole: map['my_role'] ?? map['myRole'] ?? 'member',
      memberCount: map['member_count'] ?? map['memberCount'] ?? 1,
      lastMessage: map['last_message'] ?? map['lastMessage'],
      lastTimestamp: map['last_timestamp'] ?? map['lastTimestamp'],
      unreadCount: map['unread_count'] ?? map['unreadCount'] ?? 0,
    );
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

