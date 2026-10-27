class GroupMemberModel {
  final String groupId;
  final String uid;
  final String username;
  final String displayName;
  final String imageUrl;
  final String role; // 'owner' | 'admin' | 'member'
  final String joinedAt;

  const GroupMemberModel({
    required this.groupId,
    required this.uid,
    required this.username,
    required this.displayName,
    this.imageUrl = '',
    required this.role,
    required this.joinedAt,
  });

  /// Exact match constructor for SQLite database rows.
  factory GroupMemberModel.fromDb(Map<String, dynamic> map) {
    return GroupMemberModel(
      groupId: (map['group_id'] ?? '').toString(),
      uid: (map['uid'] ?? '').toString(),
      username: (map['username'] ?? '').toString(),
      displayName: (map['display_name'] ?? map['username'] ?? 'User').toString(),
      imageUrl: (map['image_url'] ?? '').toString(),
      role: (map['role'] ?? 'member').toString(),
      joinedAt: (map['joined_at'] ?? '').toString(),
    );
  }

  /// Exact match constructor for Server / Socket.IO / Firestore payloads.
  factory GroupMemberModel.fromServer(Map<String, dynamic> map) {
    return GroupMemberModel(
      groupId: (map['groupId'] ?? '').toString(),
      uid: (map['uid'] ?? '').toString(),
      username: (map['username'] ?? '').toString(),
      displayName: (map['displayName'] ?? map['username'] ?? 'User').toString(),
      imageUrl: (map['imageUrl'] ?? '').toString(),
      role: (map['role'] ?? 'member').toString(),
      joinedAt: (map['joinedAt'] ?? '').toString(),
    );
  }

  /// Unified constructor dispatching directly to [fromDb] or [fromServer].
  factory GroupMemberModel.fromMap(Map<String, dynamic> map) {
    if (map.containsKey('group_id') || map.containsKey('joined_at') || map.containsKey('display_name')) {
      return GroupMemberModel.fromDb(map);
    }
    return GroupMemberModel.fromServer(map);
  }

  Map<String, dynamic> toMap() {
    return {
      'group_id': groupId,
      'uid': uid,
      'username': username,
      'display_name': displayName,
      'image_url': imageUrl,
      'role': role,
      'joined_at': joinedAt,
    };
  }
}
