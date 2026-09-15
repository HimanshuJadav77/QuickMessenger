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

  factory GroupMemberModel.fromMap(Map<String, dynamic> map) {
    return GroupMemberModel(
      groupId: map['group_id'] ?? map['groupId'] ?? '',
      uid: map['uid'] ?? '',
      username: map['username'] ?? '',
      displayName: map['display_name'] ?? map['displayName'] ?? map['username'] ?? 'User',
      imageUrl: map['image_url'] ?? map['imageUrl'] ?? '',
      role: map['role'] ?? 'member',
      joinedAt: map['joined_at'] ?? map['joinedAt'] ?? '',
    );
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

