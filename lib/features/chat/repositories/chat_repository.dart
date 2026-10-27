import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/local_database_helper.dart';
import '../../../core/services/socket_service.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../models/group_model.dart';

class ChatRepository {
  final String _explicitUserId;
  String get currentUserId => _explicitUserId.isNotEmpty
      ? _explicitUserId
      : (FirebaseAuth.instance.currentUser?.uid ?? '');
  final LocalDatabaseHelper _dbHelper;
  final SocketService _socketService;
  final Uuid _uuid = const Uuid();

  final StreamController<MessageModel> _messageReceivedController =
      StreamController<MessageModel>.broadcast();
  final StreamController<Map<String, dynamic>> _messageStatusController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _messageDeletedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _messageEditedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _messageReactionController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<void> _conversationUpdateController =
      StreamController<void>.broadcast();
  final StreamController<void> _groupUpdateController =
      StreamController<void>.broadcast();

  ChatRepository({
    String? currentUserId,
    LocalDatabaseHelper? dbHelper,
    SocketService? socketService,
  })  : _explicitUserId = currentUserId ?? '',
        _dbHelper = dbHelper ?? LocalDatabaseHelper.instance,
        _socketService = socketService ?? SocketService.instance {
    _initSocketListeners();
  }

  void notifyConversationUpdate() {
    if (!_conversationUpdateController.isClosed) {
      _conversationUpdateController.add(null);
    }
  }

  Stream<MessageModel> get onMessageReceivedStream =>
      _messageReceivedController.stream;
  Stream<Map<String, dynamic>> get onMessageStatusStream =>
      _messageStatusController.stream;
  Stream<Map<String, dynamic>> get onMessageDeletedStream =>
      _messageDeletedController.stream;
  Stream<Map<String, dynamic>> get onMessageEditedStream =>
      _messageEditedController.stream;
  Stream<Map<String, dynamic>> get onMessageReactionStream =>
      _messageReactionController.stream;
  Stream<void> get onConversationUpdateStream =>
      _conversationUpdateController.stream;
  Stream<void> get onGroupUpdateStream => _groupUpdateController.stream;

  final StreamController<MessageModel> _groupMessageReceivedController =
      StreamController<MessageModel>.broadcast();
  final StreamController<Map<String, dynamic>> _groupMessageStatusController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _groupMessageDeletedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _groupMessageEditedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _groupMessageReactionController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<MessageModel> get onGroupMessageReceivedStream =>
      _groupMessageReceivedController.stream;
  Stream<Map<String, dynamic>> get onGroupMessageStatusStream =>
      _groupMessageStatusController.stream;
  Stream<Map<String, dynamic>> get onGroupMessageDeletedStream =>
      _groupMessageDeletedController.stream;
  Stream<Map<String, dynamic>> get onGroupMessageEditedStream =>
      _groupMessageEditedController.stream;
  Stream<Map<String, dynamic>> get onGroupMessageReactionStream =>
      _groupMessageReactionController.stream;

  StreamSubscription? _connectionStateSub;
  StreamSubscription? _groupCreatedSub;
  StreamSubscription? _groupMessageReceivedSub;

  void dispose() {
    _connectionStateSub?.cancel();
    _groupCreatedSub?.cancel();
    _groupMessageReceivedSub?.cancel();

    _socketService.onMessageReceived = null;
    _socketService.onMessageSent = null;
    _socketService.onMessageDelivered = null;
    _socketService.onReadReceipt = null;
    _socketService.onMessageDeleted = null;
    _socketService.onMessageEdited = null;
    _socketService.onMessageReactionUpdated = null;
    _socketService.onSyncComplete = null;
    _socketService.onErrorEvent = null;

    _messageReceivedController.close();
    _messageStatusController.close();
    _messageDeletedController.close();
    _messageEditedController.close();
    _messageReactionController.close();
    _conversationUpdateController.close();
    _groupUpdateController.close();
    _groupMessageReceivedController.close();
    _groupMessageStatusController.close();
    _groupMessageDeletedController.close();
    _groupMessageEditedController.close();
    _groupMessageReactionController.close();
  }

  String getConversationId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return 'conv_${ids[0]}_${ids[1]}';
  }

  String? getParticipantIdFromConversationId(String conversationId) {
    final cleanId = conversationId.startsWith('conv_')
        ? conversationId.substring(5)
        : conversationId;
    final parts = cleanId.split('_');
    if (parts.length != 2) return null;
    final currentUid = currentUserId;
    if (currentUid.isEmpty) return null;
    return parts[0] == currentUid ? parts[1] : parts[0];
  }

  void _initSocketListeners() {
    _socketService.onMessageReceived = (data) async {
      final message = MessageModel.fromMap(data);

      final activeConv = _socketService.activeConversationId;
      final isCurrentChatActive = activeConv != null &&
          (activeConv == message.conversationId ||
              activeConv.replaceFirst('conv_', '') ==
                  message.conversationId.replaceFirst('conv_', ''));
      final effectiveStatus = isCurrentChatActive ? 'read' : 'delivered';
      final messageToStore = message.copyWith(status: effectiveStatus);

      await _dbHelper.insertMessage(currentUserId, messageToStore.toMap());

      // Resolve participant display name and avatar
      String? resolvedName = data['senderName'] ?? data['participantName'];
      String? resolvedImage =
          data['senderAvatarUrl'] ?? data['participantImageUrl'];

      if (resolvedName == null ||
          resolvedName.isEmpty ||
          resolvedName == 'User') {
        // 1. Check local cached user profile
        final localProfile =
            await _dbHelper.getUserProfile(currentUserId, message.senderId);
        if (localProfile != null &&
            localProfile['username']?.isNotEmpty == true) {
          resolvedName = localProfile['username'];
          resolvedImage ??= localProfile['image_url'];
        } else {
          // 2. Check existing conversation record
          final existingConv = await _dbHelper.getConversation(
              currentUserId, message.conversationId);
          if (existingConv != null &&
              existingConv['participant_name'] != null &&
              existingConv['participant_name'] != 'User' &&
              existingConv['participant_name'].toString().isNotEmpty) {
            resolvedName = existingConv['participant_name'];
            resolvedImage ??= existingConv['participant_imageurl'];
          } else {
            // 3. Fallback: Quick Firestore profile fetch
            try {
              final snap = await FirebaseFirestore.instance
                  .collection("Users")
                  .doc(message.senderId)
                  .get();
              if (snap.exists) {
                final uData = snap.data() ?? {};
                resolvedName =
                    (uData['username'] ?? uData['name'] ?? 'User').toString();
                resolvedImage =
                    (uData['userimageurl'] ?? uData['imageurl'] ?? '')
                        .toString();
                await _dbHelper
                    .upsertUserProfile(currentUserId, message.senderId, {
                  'username': resolvedName,
                  'display_name': resolvedName,
                  'image_url': resolvedImage,
                });
              }
            } catch (_) {}
          }
        }
      }

      final unreadIncrement = isCurrentChatActive ? 0 : 1;

      await _dbHelper.upsertConversation(
        currentUserId: currentUserId,
        conversationId: message.conversationId,
        participantId: message.senderId,
        participantName: resolvedName ?? 'User',
        participantImageUrl: resolvedImage ?? '',
        lastMessage: message.text,
        lastTimestamp: message.clientCreatedAt,
        unreadCount: isCurrentChatActive ? 0 : null,
        unreadIncrement: isCurrentChatActive ? null : unreadIncrement,
      );

      _messageReceivedController.add(messageToStore);
      _conversationUpdateController.add(null);

      _socketService.emitMessageDelivered(
        conversationId: message.conversationId,
        messageId: message.messageId,
        senderId: message.senderId,
      );

      if (isCurrentChatActive) {
        _socketService.emitMarkRead(
          conversationId: message.conversationId,
          senderId: message.senderId,
          messageIds: [message.messageId],
        );
      }
    };

    _socketService.onMessageSent = (data) async {
      final messageId = data['messageId'];
      final conversationId = data['conversationId'];
      if (messageId != null) {
        await _dbHelper.updateMessageStatus(currentUserId, messageId, 'sent');
        _messageStatusController.add({
          'messageId': messageId,
          'conversationId': conversationId,
          'status': 'sent',
        });
      }
    };

    _socketService.onMessageDelivered = (data) async {
      final messageId = data['messageId'];
      final conversationId = data['conversationId'];
      if (messageId != null) {
        await _dbHelper.updateMessageStatus(
            currentUserId, messageId, 'delivered');
        _messageStatusController.add({
          'messageId': messageId,
          'conversationId': conversationId,
          'status': 'delivered',
        });
      }
    };

    _socketService.onReadReceipt = (data) async {
      final conversationId = data['conversationId'];
      final messageId = data['messageId'];
      final rawIds = data['messageIds'];
      final List<String> messageIds = (rawIds is List)
          ? rawIds
              .map((e) => e.toString())
              .where((id) => id.isNotEmpty)
              .toList()
          : (messageId != null && messageId.toString().isNotEmpty
              ? [messageId.toString()]
              : []);

      if (conversationId != null && messageIds.isNotEmpty) {
        await _dbHelper.updateSentMessagesStatusForConversation(
          currentUserId,
          conversationId,
          'read',
          messageIds: messageIds,
        );
        for (final id in messageIds) {
          _messageStatusController.add({
            'messageId': id,
            'conversationId': conversationId,
            'status': 'read',
          });
        }
        _conversationUpdateController.add(null);
      }
    };

    _socketService.onMessageDeleted = (data) async {
      final messageId = data['messageId'];
      final conversationId = data['conversationId'];
      final deleteType = data['deleteType'];

      if (messageId != null) {
        if (deleteType == 'for_everyone') {
          await _dbHelper.markMessageDeletedForEveryone(
              currentUserId, messageId);
        } else {
          await _dbHelper.markMessageDeletedForMe(currentUserId, messageId);
        }

        _messageDeletedController.add({
          'messageId': messageId,
          'conversationId': conversationId,
          'deleteType': deleteType ?? 'for_me',
        });

        _conversationUpdateController.add(null);
      }
    };

    _socketService.onMessageEdited = (data) async {
      final messageId = data['messageId'];
      final conversationId = data['conversationId'];
      final newText = data['text'];

      if (messageId != null && newText != null) {
        await _dbHelper.updateEditedMessage(currentUserId, messageId, newText);
        _messageEditedController.add({
          'messageId': messageId,
          'conversationId': conversationId,
          'text': newText,
        });
      }
    };

    _socketService.onMessageReactionUpdated = (data) async {
      final messageId = data['messageId'];
      final conversationId = data['conversationId'];
      final reactions = data['reactions'];

      if (messageId != null && reactions != null) {
        final reactionsJson = jsonEncode(reactions);
        await _dbHelper.updateMessageReactions(
            currentUserId, messageId, reactionsJson);
        _messageReactionController.add({
          'messageId': messageId,
          'conversationId': conversationId,
          'reactions': reactions,
        });
      }
    };

    _socketService.onSyncComplete = (data) async {
      final List? messages = data['messages'];
      if (messages != null && messages.isNotEmpty) {
        final List<MessageModel> parsed = [];
        for (var raw in messages) {
          if (raw is Map) {
            final msg = MessageModel.fromMap(Map<String, dynamic>.from(raw));
            parsed.add(msg);
          }
        }
        // Deterministically sort and deduplicate in ascending chronological order
        final sorted = MessageModel.sortAndDeduplicate(parsed);
        for (final msg in sorted) {
          await _dbHelper.insertMessage(currentUserId, msg.toMap());
          _messageReceivedController.add(msg);
        }
        _conversationUpdateController.add(null);
      }
    };

    _socketService.onErrorEvent = (data) async {
      final messageId = data['messageId'];
      final conversationId = data['conversationId'];
      if (messageId != null) {
        await _dbHelper.updateMessageStatus(currentUserId, messageId, 'failed');
        _messageStatusController.add({
          'messageId': messageId,
          'conversationId': conversationId,
          'status': 'failed',
        });
      }
    };

    _connectionStateSub =
        _socketService.connectionStateStream.listen((isConnected) {
      if (isConnected) {
        retryPendingMessages();
        _socketService.emitSyncUnseen();
        if (_socketService.activeConversationId != null) {
          syncMessages(_socketService.activeConversationId!);
        }
      }
    });

    _groupCreatedSub = _socketService.onGroupCreatedStream.listen((data) async {
      final Map<String, dynamic> groupMap = (data['group'] is Map)
          ? Map<String, dynamic>.from(data['group'])
          : data;
      final groupId = groupMap['groupId'] ?? groupMap['group_id'];
      if (groupId != null && currentUserId.isNotEmpty) {
        await _dbHelper.upsertGroup(currentUserId, groupMap);
        if (groupMap['members'] is List) {
          final members = List<Map<String, dynamic>>.from(groupMap['members']);
          await _dbHelper.insertGroupMembers(groupId.toString(), members);
        }
        _groupUpdateController.add(null);
      }
    });

    _groupMessageReceivedSub =
        _socketService.onGroupMessageReceivedStream.listen((data) async {
      final groupId = data['groupId'] ?? data['group_id'];
      if (groupId != null && currentUserId.isNotEmpty) {
        await _dbHelper.insertGroupMessage(currentUserId, data);
        try {
          final msg = MessageModel.fromMap(Map<String, dynamic>.from(data));
          _groupMessageReceivedController.add(msg);
        } catch (_) {}
        _groupUpdateController.add(null);
      }
    });
  }

  Future<MessageModel> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
    String? replyToMessageId,
    String? replyToText,
    String? replyToSenderId,
    String? participantName,
    String? participantImageUrl,
    String type = 'text',
    String? fileUrl,
    String? localPath,
    String? driveFileId,
    String? fileName,
    int? fileSize,
  }) async {
    final messageId = _uuid.v4();
    final conversationId = getConversationId(senderId, receiverId);
    final clientCreatedAt = DateTime.now().toIso8601String();

    final message = MessageModel(
      messageId: messageId,
      conversationId: conversationId,
      senderId: senderId,
      receiverId: receiverId,
      type: type,
      text: text,
      replyToMessageId: replyToMessageId,
      replyToText: replyToText,
      replyToSenderId: replyToSenderId,
      status: 'pending',
      clientCreatedAt: clientCreatedAt,
      fileUrl: fileUrl,
      localPath: localPath,
      driveFileId: driveFileId,
      fileName: fileName,
      fileSize: fileSize,
    );

    final effectiveUserId = currentUserId.isNotEmpty ? currentUserId : senderId;

    await _dbHelper.insertMessage(effectiveUserId, message.toMap());

    await _dbHelper.upsertConversation(
      currentUserId: effectiveUserId,
      conversationId: conversationId,
      participantId: receiverId,
      participantName: participantName,
      participantImageUrl: participantImageUrl,
      lastMessage: type == 'image'
          ? '📷 Photo'
          : (type == 'file' ? '📎 $fileName' : text),
      lastTimestamp: clientCreatedAt,
      unreadCount: 0,
    );

    notifyConversationUpdate();

    // 1. Immediately emit over socket for instant real-time delivery
    _socketService.emitSendMessage(
      messageId: messageId,
      receiverId: receiverId,
      type: type,
      text: text,
      replyToMessageId: replyToMessageId,
      replyToText: replyToText,
      replyToSenderId: replyToSenderId,
      clientCreatedAt: clientCreatedAt,
      fileUrl: fileUrl,
      driveFileId: driveFileId,
      fileName: fileName,
      fileSize: fileSize,
    );

    // 2. Cloud Firestore sync in background (non-blocking)
    _syncMessageToFirestore(
      senderId: senderId,
      receiverId: receiverId,
      messageId: messageId,
      text: text,
      type: type,
      clientCreatedAt: clientCreatedAt,
      participantName: participantName,
      participantImageUrl: participantImageUrl,
    );

    return message;
  }

  void _syncMessageToFirestore({
    required String senderId,
    required String receiverId,
    required String messageId,
    required String text,
    required String type,
    required String clientCreatedAt,
    String? participantName,
    String? participantImageUrl,
  }) async {
    // NOTE: Firestore sync is now handled exclusively by the Socket.IO server.
    // Flutter only writes to local SQLite. The Node.js server persists to Firestore
    // and handles offline sync when users come back online.
    // This ensures:
    // - Single chat entry per conversation (normalized via getConversationId)
    // - No duplicate writes from Flutter side
    // - Server handles offline->online sync immediately
    // - Consistent data across all devices
  }

  Future<void> toggleReaction(String conversationId, String messageId,
      String emoji, String receiverId) async {
    _socketService.emitToggleReaction(
      conversationId: conversationId,
      messageId: messageId,
      emoji: emoji,
      receiverId: receiverId,
    );
  }

  Future<void> editMessage(String conversationId, String messageId,
      String newText, String receiverId) async {
    await _dbHelper.updateEditedMessage(currentUserId, messageId, newText);
    _socketService.emitEditMessage(
      conversationId: conversationId,
      messageId: messageId,
      newText: newText,
      receiverId: receiverId,
    );
    _messageEditedController.add({
      'messageId': messageId,
      'conversationId': conversationId,
      'text': newText,
    });
    _conversationUpdateController.add(null);
  }

  Future<void> deleteMessageForMe(
      String conversationId, String messageId) async {
    await _dbHelper.markMessageDeletedForMe(currentUserId, messageId);
    _socketService.emitDeleteForMe(
        conversationId: conversationId, messageId: messageId);
    _messageDeletedController.add({
      'messageId': messageId,
      'conversationId': conversationId,
      'deleteType': 'for_me',
    });
    _conversationUpdateController.add(null);
  }

  Future<void> deleteMessageForEveryone(
      String conversationId, String messageId, String receiverId) async {
    await _dbHelper.markMessageDeletedForEveryone(currentUserId, messageId);
    _socketService.emitDeleteForEveryone(
      conversationId: conversationId,
      messageId: messageId,
      receiverId: receiverId,
    );
    _messageDeletedController.add({
      'messageId': messageId,
      'conversationId': conversationId,
      'deleteType': 'for_everyone',
    });
    _conversationUpdateController.add(null);
  }

  Future<void> togglePinConversation(
      String conversationId, bool isPinned) async {
    await _dbHelper.togglePinConversation(
        currentUserId, conversationId, isPinned);
    _conversationUpdateController.add(null);
  }

  Future<void> toggleArchiveConversation(
      String conversationId, bool isArchived) async {
    await _dbHelper.toggleArchiveConversation(
        currentUserId, conversationId, isArchived);
    _conversationUpdateController.add(null);
  }

  Future<void> toggleMuteConversation(
      String conversationId, bool isMuted) async {
    await _dbHelper.toggleMuteConversation(
        currentUserId, conversationId, isMuted);
    _conversationUpdateController.add(null);
  }

  Future<void> markUnreadConversation(String conversationId) async {
    await _dbHelper.markUnreadConversation(currentUserId, conversationId);
    _conversationUpdateController.add(null);
  }

  Future<void> deleteConversation(String conversationId) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;

    final participantId = getParticipantIdFromConversationId(conversationId);

    await _dbHelper.deleteConversation(uid, conversationId);

    if (participantId != null && participantId.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(uid)
            .collection('chats')
            .doc(participantId)
            .delete();
      } catch (_) {}
    }

    if (participantId != null && participantId.isNotEmpty) {
      await _dbHelper.addDeletedConversationTombstone(
          uid, conversationId, participantId);
    }

    _conversationUpdateController.add(null);
  }

  Future<void> retryPendingMessages() async {
    final pending = await _dbHelper.getPendingMessages(currentUserId);
    for (var raw in pending) {
      final msg = MessageModel.fromMap(raw);
      _socketService.emitSendMessage(
        messageId: msg.messageId,
        receiverId: msg.receiverId,
        type: msg.type,
        text: msg.text,
        replyToMessageId: msg.replyToMessageId,
        replyToText: msg.replyToText,
        replyToSenderId: msg.replyToSenderId,
        clientCreatedAt: msg.clientCreatedAt,
      );
    }
  }

  Future<List<MessageModel>> getMessages(String conversationId,
      {int limit = 50, int offset = 0}) async {
    final rawMessages = await _dbHelper.getMessagesForConversation(
      currentUserId,
      conversationId,
      limit: limit,
      offset: offset,
    );
    return rawMessages.map((map) => MessageModel.fromMap(map)).toList();
  }

  Future<List<ConversationModel>> getConversations() async {
    final rawConversations = await _dbHelper.getConversations(currentUserId);
    return rawConversations
        .map((map) => ConversationModel.fromMap(map))
        .toList();
  }

  Future<void> syncConversationsFromFirestore(QuerySnapshot snapshot) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;

    for (var doc in snapshot.docs) {
      final participantId = doc.id;
      final conversationId = getConversationId(uid, participantId);

      final isDeleted =
          await _dbHelper.isConversationDeleted(uid, conversationId);
      if (isDeleted) {
        continue;
      }

      final data = doc.data() as Map<String, dynamic>? ?? {};
      final lastMsg = (data['lastMessage'] ?? '').toString().trim();
      if (lastMsg.isEmpty || lastMsg == 'Tap to chat') {
        continue;
      }
      final lastTime =
          (data['lastTimestamp'] ?? DateTime.now().toIso8601String())
              .toString();
      String participantName = (data['participantName'] ?? '').toString();
      String participantImageUrl =
          (data['participantImageUrl'] ?? '').toString();

      if (participantName.isEmpty || participantName == 'User') {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection("Users")
              .doc(participantId)
              .get();
          if (userDoc.exists) {
            final uData = userDoc.data() ?? {};
            participantName =
                (uData['username'] ?? uData['name'] ?? 'User').toString();
            participantImageUrl =
                (uData['imageurl'] ?? uData['userimageurl'] ?? '').toString();
            await _dbHelper.upsertUserProfile(uid, participantId, {
              'username': participantName,
              'display_name': participantName,
              'image_url': participantImageUrl,
            });
          }
        } catch (_) {}
      }

      await _dbHelper.upsertConversation(
        currentUserId: uid,
        conversationId: conversationId,
        participantId: participantId,
        participantName: participantName.isNotEmpty ? participantName : 'User',
        participantImageUrl: participantImageUrl,
        lastMessage: lastMsg,
        lastTimestamp: lastTime,
      );
    }
  }

  Future<void> markConversationAsRead(
      String conversationId, String participantId) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;

    // 1. Get ALL unread incoming message IDs BEFORE resetting status
    final unreadMessages =
        await _dbHelper.getUnreadMessages(uid, conversationId);
    final unreadMessageIds = unreadMessages
        .where((m) => (m['sender_id'] ?? '').toString() != uid)
        .map((m) => (m['message_id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toList();

    // 2. Mark incoming messages as read in local SQLite
    await _dbHelper.updateIncomingMessagesStatusForConversation(
      uid,
      conversationId,
      'read',
      messageIds: unreadMessageIds.isNotEmpty ? unreadMessageIds : null,
    );

    // 3. Reset unread count to 0 in SQLite conversation record
    await _dbHelper.resetUnreadCount(uid, conversationId);

    // 4. Send read receipts over Socket.IO ONLY if there are unread messages to acknowledge
    if (unreadMessageIds.isNotEmpty) {
      _socketService.emitMarkRead(
        conversationId: conversationId,
        senderId: participantId,
        messageIds: unreadMessageIds,
      );
    }

    // 5. Notify conversation stream so UI unread badges update immediately
    _conversationUpdateController.add(null);
  }

  Future<void> syncMessages(String conversationId) async {
    final messages = await getMessages(conversationId, limit: 1);
    final lastMessageId = messages.isNotEmpty ? messages.last.messageId : null;
    _socketService.emitSyncMessages(
        conversationId: conversationId, lastMessageId: lastMessageId);
  }

  Future<void> upsertUserProfile(String currentUserId, String uid,
      Map<String, dynamic> profileData) async {
    await _dbHelper.upsertUserProfile(currentUserId, uid, profileData);
  }

  // Group message methods
  Future<List<MessageModel>> getGroupMessages(String groupId,
      {int limit = 50, int offset = 0}) async {
    final rawMessages = await _dbHelper.getGroupMessages(currentUserId, groupId,
        limit: limit, offset: offset);
    return rawMessages.map((map) => MessageModel.fromMap(map)).toList();
  }

  Future<MessageModel> sendGroupMessage({
    required String senderId,
    required String groupId,
    required String text,
    String type = 'text',
  }) async {
    final messageId = _uuid.v4();
    final clientCreatedAt = DateTime.now().toIso8601String();

    final message = MessageModel(
      messageId: messageId,
      conversationId: 'group_$groupId',
      groupId: groupId,
      senderId: senderId,
      receiverId: '', // group messages don't have a single receiver
      type: type,
      text: text,
      status: 'pending',
      clientCreatedAt: clientCreatedAt,
    );

    await _dbHelper.insertGroupMessage(currentUserId, message.toMap());

    _socketService.emitSendGroupMessage(
      messageId: messageId,
      groupId: groupId,
      senderName: '', // Will be filled by socket
      type: type,
      text: text,
      clientCreatedAt: clientCreatedAt,
    );

    return message;
  }

  Future<void> editGroupMessage(
      String groupId, String messageId, String newText) async {
    await _dbHelper.updateEditedMessage(currentUserId, messageId, newText);
    _socketService.emitEditGroupMessage(
      groupId: groupId,
      messageId: messageId,
      newText: newText,
    );
    _groupMessageEditedController.add({
      'messageId': messageId,
      'groupId': groupId,
      'text': newText,
    });
    _groupUpdateController.add(null);
  }

  Future<void> toggleGroupReaction(String groupId, String messageId,
      String emoji, String currentUserId) async {
    _socketService.emitToggleGroupReaction(
      groupId: groupId,
      messageId: messageId,
      emoji: emoji,
      userId: currentUserId,
    );
  }

  Future<void> deleteGroupMessageForMe(String groupId, String messageId) async {
    await _dbHelper.markMessageDeletedForMe(currentUserId, messageId);
    _socketService.emitDeleteGroupForMe(groupId: groupId, messageId: messageId);
    _groupMessageDeletedController.add({
      'messageId': messageId,
      'groupId': groupId,
      'deleteType': 'for_me',
    });
    _groupUpdateController.add(null);
  }

  Future<void> deleteGroupMessageForEveryone(
      String groupId, String messageId) async {
    await _dbHelper.markMessageDeletedForEveryone(currentUserId, messageId);
    _socketService.emitDeleteGroupForEveryone(
      groupId: groupId,
      messageId: messageId,
    );
    _groupMessageDeletedController.add({
      'messageId': messageId,
      'groupId': groupId,
      'deleteType': 'for_everyone',
    });
    _groupUpdateController.add(null);
  }

  Future<GroupModel> createGroup({
    required String groupId,
    required String name,
    String description = '',
    String imageUrl = '',
    required List<Map<String, dynamic>> members,
  }) async {
    final now = DateTime.now().toIso8601String();
    final memberCount = members.length + 1;

    final group = GroupModel(
      groupId: groupId,
      name: name,
      description: description,
      imageUrl: imageUrl,
      createdBy: currentUserId,
      createdAt: now,
      myRole: 'owner',
      memberCount: memberCount,
      lastMessage: null,
      lastTimestamp: now,
      unreadCount: 0,
    );

    await _dbHelper.upsertGroup(currentUserId, group.toMap());

    final allMembers = [
      {
        'group_id': groupId,
        'uid': currentUserId,
        'username': 'You',
        'display_name': 'You',
        'image_url': '',
        'role': 'owner',
        'joined_at': now,
      },
      ...members.map((m) => {
            'group_id': groupId,
            'uid': m['uid'],
            'username': m['username'] ?? 'User',
            'display_name': m['displayName'] ?? m['username'] ?? 'User',
            'image_url': m['imageurl'] ?? m['imageUrl'] ?? '',
            'role': 'member',
            'joined_at': now,
          }),
    ];
    await _dbHelper.insertGroupMembers(groupId, allMembers);

    final memberUids = members.map((m) => m['uid'].toString()).toList();
    _socketService.emitCreateGroup(
      groupId: groupId,
      name: name,
      description: description,
      imageUrl: imageUrl,
      initialMemberUids: memberUids,
    );

    _groupUpdateController.add(null);
    return group;
  }

  Future<List<GroupModel>> getGroups() async {
    final rawGroups = await _dbHelper.getGroups(currentUserId);
    if (rawGroups.isEmpty && currentUserId.isNotEmpty) {
      syncGroupsFromFirestore();
    }
    return rawGroups.map((map) => GroupModel.fromMap(map)).toList();
  }

  Future<void> upsertGroupFromMap(Map<String, dynamic> data) async {
    if (currentUserId.isEmpty) return;
    await _dbHelper.upsertGroup(currentUserId, data);
    _groupUpdateController.add(null);
  }

  Future<void> syncGroupsFromFirestore() async {
    final uid = currentUserId;
    if (uid.isEmpty) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('groups')
          .where('memberUids', arrayContains: uid)
          .get();
      for (final doc in snap.docs) {
        await _dbHelper.upsertGroup(uid, doc.data());
      }
      _groupUpdateController.add(null);
    } catch (_) {}
  }

  /// Local-first group profile: group row + member rows from SQLite.
  Future<Map<String, dynamic>?> getGroupProfile(String groupId) async {
    final groups = await getGroups();
    final match = groups.where((g) => g.groupId == groupId).toList();
    if (match.isEmpty) return null;
    final members = await _dbHelper.getGroupMembers(groupId);
    return {'group': match.first, 'members': members};
  }

  void notifyGroupUpdated() {
    _groupUpdateController.add(null);
  }

  /// Deletes a group if owner: cleans up Firestore group document and subcollections,
  /// removes all local group records from SQLite, and triggers a sync update.
  Future<void> deleteGroup(String groupId) async {
    if (groupId.isEmpty) return;
    try {
      final groupDoc =
          FirebaseFirestore.instance.collection('groups').doc(groupId);
      final membersSnap = await groupDoc.collection('members').get();
      for (final doc in membersSnap.docs) {
        await doc.reference.delete();
      }
      final messagesSnap = await groupDoc.collection('messages').get();
      for (final doc in messagesSnap.docs) {
        await doc.reference.delete();
      }
      await groupDoc.delete();
    } catch (e) {
      // Offline fallback or permission catch
    }

    await _dbHelper.deleteGroup(currentUserId, groupId);
    _groupUpdateController.add(null);
  }

  /// Leaves a group if member: removes member record from Firestore,
  /// decrements memberCount, purges local SQLite cache, and triggers a sync update.
  Future<void> leaveGroup(String groupId) async {
    if (groupId.isEmpty || currentUserId.isEmpty) return;
    try {
      final groupDoc =
          FirebaseFirestore.instance.collection('groups').doc(groupId);
      await groupDoc.collection('members').doc(currentUserId).delete();
      await groupDoc.update({
        'memberCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Offline fallback
    }

    await _dbHelper.deleteGroup(currentUserId, groupId);
    _groupUpdateController.add(null);
  }
}
