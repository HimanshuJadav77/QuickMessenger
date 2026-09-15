import 'dart:convert';

class MessageModel {
  final String messageId;
  final String conversationId;
  final String? groupId;
  final String senderId;
  final String receiverId;
  final String type;
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
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    final isEveryone = map['is_deleted_for_everyone'] == 1 ||
        map['is_deleted_for_everyone'] == true ||
        map['isDeletedForEveryone'] == true;
    final isMe = map['is_deleted_for_me'] == 1 ||
        map['is_deleted_for_me'] == true ||
        map['isDeletedForMe'] == true;

    final edited = map['is_edited'] == 1 || map['is_edited'] == true || map['isEdited'] == true;

    String contentText = map['text'] ?? map['content'] ?? '';
    if (isEveryone) {
      contentText = 'This message was deleted';
    }

    // Parse reactions map
    Map<String, String> reactionsMap = {};
    final rawReactions = map['reactions'] ?? map['reactions_json'];
    if (rawReactions is Map) {
      reactionsMap = rawReactions.map((k, v) => MapEntry(k.toString(), v.toString()));
    } else if (rawReactions is String && rawReactions.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawReactions);
        if (decoded is Map) {
          reactionsMap = decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
        }
      } catch (_) {}
    }

    return MessageModel(
      messageId: map['message_id'] ?? map['messageId'] ?? '',
      conversationId: map['conversation_id'] ?? map['conversationId'] ?? '',
      groupId: map['group_id'] ?? map['groupId'],
      senderId: map['sender_id'] ?? map['senderId'] ?? '',
      receiverId: map['receiver_id'] ?? map['receiverId'] ?? '',
      type: map['type'] ?? 'text',
      text: contentText,
      status: map['status'] ?? 'pending',
      isDeletedForMe: isMe,
      isDeletedForEveryone: isEveryone,
      isEdited: edited,
      replyToMessageId: map['reply_to_message_id'] ?? map['replyToMessageId'],
      replyToText: map['reply_to_text'] ?? map['replyToText'],
      replyToSenderId: map['reply_to_sender_id'] ?? map['replyToSenderId'],
      reactions: reactionsMap,
      clientCreatedAt: map['client_created_at'] ?? map['clientCreatedAt'] ?? DateTime.now().toIso8601String(),
      serverCreatedAt: map['server_created_at'] ?? map['serverCreatedAt'],
    );
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
    );
  }
}