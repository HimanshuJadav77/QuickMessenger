import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/local_database_helper.dart';
import '../../../core/providers/auth_providers.dart';
import '../repositories/chat_repository.dart';
import '../models/message_model.dart';
import '../models/conversation_model.dart';
import '../models/group_model.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  final repo = ChatRepository(currentUserId: uid);
  ref.onDispose(() => repo.dispose());
  return repo;
});

final userProfileProvider = FutureProvider.autoDispose.family<Map<String, String>, String>((ref, uid) async {
  if (uid.isEmpty) return {'username': 'User', 'imageurl': '', 'about': '', 'email': ''};

  final repo = ref.watch(chatRepositoryProvider);
  final conversations = await repo.getConversations();
  final matching = conversations.where(
    (c) => c.participantId == uid && c.participantName != 'User' && c.participantName.isNotEmpty,
  );
  if (matching.isNotEmpty) {
    final conv = matching.first;
    // Cache the profile locally
    ref.read(chatRepositoryProvider).upsertUserProfile(
      repo.currentUserId,
      uid,
      {
        'username': conv.participantName,
        'display_name': conv.participantName,
        'image_url': conv.participantImageUrl,
        'about': '',
        'email': '',
      },
    );
    return {
      'username': conv.participantName,
      'imageurl': conv.participantImageUrl,
      'about': '',
      'email': '',
    };
  }

  // Check local cache first
  final dbHelper = LocalDatabaseHelper.instance;
  final cachedProfile = await dbHelper.getUserProfile(repo.currentUserId, uid);
  if (cachedProfile != null && cachedProfile['username']?.isNotEmpty == true) {
    return {
      'username': cachedProfile['username']?.toString() ?? 'User',
      'imageurl': cachedProfile['image_url']?.toString() ?? '',
      'about': cachedProfile['about']?.toString() ?? '',
      'email': cachedProfile['email']?.toString() ?? '',
    };
  }

  // Fallback to Firebase
  try {
    final doc = await FirebaseFirestore.instance.collection("Users").doc(uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      final resolvedName = (data['username'] ?? '').toString();
      if (resolvedName.isNotEmpty && resolvedName != 'User') {
        final profile = {
          'username': resolvedName,
          'imageurl': (data['userimageurl'] ?? data['imageurl'] ?? '').toString(),
          'about': (data['about'] ?? '').toString(),
          'email': (data['email'] ?? '').toString(),
        };
        // Cache the profile locally
        await dbHelper.upsertUserProfile(repo.currentUserId, uid, {
          'username': resolvedName,
          'display_name': resolvedName,
          'image_url': profile['imageurl'],
          'about': profile['about'],
          'email': profile['email'],
        });
        return profile;
      }
    }
  } catch (_) {}

  return {'username': 'User', 'imageurl': '', 'about': '', 'email': ''};
});

class ConversationsNotifier extends StateNotifier<AsyncValue<List<ConversationModel>>> {
  final ChatRepository _repository;
  StreamSubscription? _sub;
  StreamSubscription? _firestoreSub;

  ConversationsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadConversations();
    _sub = _repository.onConversationUpdateStream.listen((_) {
      loadConversations();
    });
    _initFirestoreListener();
  }

  void _initFirestoreListener() {
    final uid = _repository.currentUserId;
    if (uid.isNotEmpty) {
      _firestoreSub = FirebaseFirestore.instance
          .collection("Users")
          .doc(uid)
          .collection("chats")
          .snapshots()
          .listen((snap) async {
        await _repository.syncConversationsFromFirestore(snap);
        await loadConversations();
      });
    }
  }

  Future<void> loadConversations() async {
    try {
      if (_firestoreSub == null && _repository.currentUserId.isNotEmpty) {
        _initFirestoreListener();
      }
      final conversations = await _repository.getConversations();
      state = AsyncValue.data(conversations);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> togglePin(String conversationId, bool isPinned) async {
    await _repository.togglePinConversation(conversationId, isPinned);
    await loadConversations();
  }

  Future<void> toggleArchive(String conversationId, bool isArchived) async {
    await _repository.toggleArchiveConversation(conversationId, isArchived);
    await loadConversations();
  }

  Future<void> toggleMute(String conversationId, bool isMuted) async {
    await _repository.toggleMuteConversation(conversationId, isMuted);
    await loadConversations();
  }

  Future<void> markUnread(String conversationId) async {
    await _repository.markUnreadConversation(conversationId);
    await loadConversations();
  }

  Future<void> deleteConversation(String conversationId) async {
    await _repository.deleteConversation(conversationId);
    await loadConversations();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _firestoreSub?.cancel();
    super.dispose();
  }
}

final conversationsProvider =
    StateNotifierProvider<ConversationsNotifier, AsyncValue<List<ConversationModel>>>((ref) {
  final repo = ref.watch(chatRepositoryProvider);
  return ConversationsNotifier(repo);
});

class GroupsNotifier extends StateNotifier<AsyncValue<List<GroupModel>>> {
  final ChatRepository _repository;
  StreamSubscription? _sub;
  StreamSubscription? _firestoreSub;

  GroupsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadGroups();
    _sub = _repository.onGroupUpdateStream.listen((_) {
      loadGroups();
    });
    _initFirestoreListener();
  }

  void _initFirestoreListener() {
    final uid = _repository.currentUserId;
    if (uid.isNotEmpty) {
      _firestoreSub = FirebaseFirestore.instance
          .collection('groups')
          .where('memberUids', arrayContains: uid)
          .snapshots()
          .listen((snap) async {
        for (final doc in snap.docs) {
          await _repository.upsertGroupFromMap(doc.data());
        }
        await loadGroups();
      });
    }
  }

  Future<void> loadGroups() async {
    try {
      if (_firestoreSub == null && _repository.currentUserId.isNotEmpty) {
        _initFirestoreListener();
      }
      final groups = await _repository.getGroups();
      state = AsyncValue.data(groups);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<GroupModel> createGroup({
    required String groupId,
    required String name,
    String description = '',
    String imageUrl = '',
    required List<Map<String, dynamic>> members,
  }) async {
    final group = await _repository.createGroup(
      groupId: groupId,
      name: name,
      description: description,
      imageUrl: imageUrl,
      members: members,
    );
    state.whenData((list) {
      final filtered = list.where((g) => g.groupId != groupId).toList();
      state = AsyncValue.data([group, ...filtered]);
    });
    return group;
  }

  Future<void> deleteGroup(String groupId) async {
    await _repository.deleteGroup(groupId);
    state.whenData((list) {
      state = AsyncValue.data(list.where((g) => g.groupId != groupId).toList());
    });
  }

  Future<void> leaveGroup(String groupId) async {
    await _repository.leaveGroup(groupId);
    state.whenData((list) {
      state = AsyncValue.data(list.where((g) => g.groupId != groupId).toList());
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _firestoreSub?.cancel();
    super.dispose();
  }
}

final groupsProvider =
    StateNotifierProvider<GroupsNotifier, AsyncValue<List<GroupModel>>>((ref) {
  final repo = ref.watch(chatRepositoryProvider);
  return GroupsNotifier(repo);
});

bool _convMatches(String? id1, String? id2) {
  if (id1 == null || id2 == null) return false;
  final clean1 = id1.replaceFirst('conv_', '');
  final clean2 = id2.replaceFirst('conv_', '');
  return clean1 == clean2;
}

class ChatMessagesNotifier extends StateNotifier<AsyncValue<List<MessageModel>>> {
  final ChatRepository _repository;
  final String conversationId;
  StreamSubscription? _msgSub;
  StreamSubscription? _statusSub;
  StreamSubscription? _deleteSub;
  StreamSubscription? _editSub;
  StreamSubscription? _reactionSub;

  ChatMessagesNotifier(this._repository, this.conversationId)
      : super(const AsyncValue.loading()) {
    loadMessages();
    _listenToEvents();
  }

  void _listenToEvents() {
    _msgSub = _repository.onMessageReceivedStream.listen((msg) {
      if (_convMatches(msg.conversationId, conversationId)) {
        state.whenData((list) {
          final exists = list.any((m) => m.messageId == msg.messageId);
          if (!exists) {
            state = AsyncValue.data([...list, msg]);
          }
        });
      }
    });

    _statusSub = _repository.onMessageStatusStream.listen((data) {
      final targetConvId = data['conversationId'];
      final targetMsgId = data['messageId'];
      final newStatus = data['status'];

      if (targetConvId == null || _convMatches(targetConvId, conversationId)) {
        state.whenData((list) {
          final updated = list.map((m) {
            if (targetMsgId != null && m.messageId == targetMsgId) {
              if (m.status == 'read' || m.status == 'seen') return m;
              if ((m.status == 'delivered' || m.status == 'sent') && (newStatus == 'sent' || newStatus == 'pending')) return m;
              return m.copyWith(status: newStatus);
            } else if (targetMsgId == null && (newStatus == 'read' || newStatus == 'seen')) {
              if (m.senderId == _repository.currentUserId && (m.status == 'sent' || m.status == 'delivered')) {
                return m.copyWith(status: 'seen');
              }
              return m;
            }
            return m;
          }).toList();
          state = AsyncValue.data(updated);
        });
      }
    });

    _deleteSub = _repository.onMessageDeletedStream.listen((data) {
      final targetConvId = data['conversationId'];
      final targetMsgId = data['messageId'];
      final deleteType = data['deleteType'];

      if (_convMatches(targetConvId, conversationId) && targetMsgId != null) {
        state.whenData((list) {
          if (deleteType == 'for_me') {
            final filtered = list.where((m) => m.messageId != targetMsgId).toList();
            state = AsyncValue.data(filtered);
          } else if (deleteType == 'for_everyone') {
            final updated = list.map((m) {
              if (m.messageId == targetMsgId) {
                return m.copyWith(
                  text: 'This message was deleted',
                  isDeletedForEveryone: true,
                );
              }
              return m;
            }).toList();
            state = AsyncValue.data(updated);
          }
        });
      }
    });

    _editSub = _repository.onMessageEditedStream.listen((data) {
      final targetConvId = data['conversationId'];
      final targetMsgId = data['messageId'];
      final newText = data['text'];

      if (_convMatches(targetConvId, conversationId) && targetMsgId != null) {
        state.whenData((list) {
          final updated = list.map((m) {
            if (m.messageId == targetMsgId) {
              return m.copyWith(text: newText, isEdited: true);
            }
            return m;
          }).toList();
          state = AsyncValue.data(updated);
        });
      }
    });

    _reactionSub = _repository.onMessageReactionStream.listen((data) {
      final targetConvId = data['conversationId'];
      final targetMsgId = data['messageId'];
      final rawReactions = data['reactions'];

      if (_convMatches(targetConvId, conversationId) && targetMsgId != null && rawReactions is Map) {
        final Map<String, String> reactionsMap = rawReactions.map((k, v) => MapEntry(k.toString(), v.toString()));
        state.whenData((list) {
          final updated = list.map((m) {
            if (m.messageId == targetMsgId) {
              return m.copyWith(reactions: reactionsMap);
            }
            return m;
          }).toList();
          state = AsyncValue.data(updated);
        });
      }
    });
  }

  Future<void> loadMessages() async {
    try {
      final uid = _repository.currentUserId;
      var messages = await _repository.getMessages(conversationId);
      if (messages.isEmpty) {
        if (uid.isNotEmpty) {
          final cleanParts = conversationId.replaceFirst('conv_', '').split('_');
          final participantId = cleanParts.firstWhere((id) => id != uid, orElse: () => '');
          if (participantId.isNotEmpty) {
            try {
              final snap = await FirebaseFirestore.instance
                  .collection("Users")
                  .doc(uid)
                  .collection("save_chat")
                  .doc(participantId)
                  .collection("messages")
                  .orderBy("time", descending: false)
                  .get();
              for (var doc in snap.docs) {
                final data = doc.data();
                final stateStr = (data['messagestate'] ?? data['status'] ?? '').toString().toLowerCase();
                final String msgStatus;
                if (stateStr == 'seen' || stateStr == 'read') {
                  msgStatus = 'seen';
                } else if (stateStr == 'delivered') {
                  msgStatus = 'delivered';
                } else if (stateStr == 'send' || stateStr == 'sent') {
                  msgStatus = 'sent';
                } else {
                  msgStatus = 'pending';
                }
                final msg = MessageModel(
                  messageId: doc.id,
                  conversationId: conversationId,
                  senderId: (data['sender'] ?? data['senderId'] ?? '').toString(),
                  receiverId: (data['receiver'] ?? data['receiverId'] ?? '').toString(),
                  type: (data['type'] ?? 'text').toString(),
                  text: (data['message'] ?? data['text'] ?? '').toString(),
                  status: msgStatus,
                  clientCreatedAt: (data['clientCreatedAt'] ?? DateTime.now().toIso8601String()).toString(),
                );
                await LocalDatabaseHelper.instance.insertMessage(uid, msg.toMap());
              }
              if (snap.docs.isEmpty) {
                final canonicalSnap = await FirebaseFirestore.instance
                    .collection("conversations")
                    .doc(conversationId)
                    .collection("messages")
                    .orderBy("clientCreatedAt", descending: false)
                    .limit(50)
                    .get();
                for (var doc in canonicalSnap.docs) {
                  final data = doc.data();
                  final stateStr = (data['status'] ?? '').toString().toLowerCase();
                  final String msgStatus;
                  if (stateStr == 'seen' || stateStr == 'read') {
                    msgStatus = 'seen';
                  } else if (stateStr == 'delivered') {
                    msgStatus = 'delivered';
                  } else if (stateStr == 'send' || stateStr == 'sent') {
                    msgStatus = 'sent';
                  } else {
                    msgStatus = 'pending';
                  }
                  final msg = MessageModel(
                    messageId: doc.id,
                    conversationId: conversationId,
                    senderId: (data['senderId'] ?? '').toString(),
                    receiverId: (data['receiverId'] ?? '').toString(),
                    type: (data['type'] ?? 'text').toString(),
                    text: (data['text'] ?? '').toString(),
                    status: msgStatus,
                    clientCreatedAt: (data['clientCreatedAt'] ?? DateTime.now().toIso8601String()).toString(),
                  );
                  await LocalDatabaseHelper.instance.insertMessage(uid, msg.toMap());
                }
              }
              messages = await _repository.getMessages(conversationId);
            } catch (_) {}
          }
        }
      } else if (uid.isNotEmpty) {
        try {
          final lastTimestamp = messages.last.clientCreatedAt;
          final newSnap = await FirebaseFirestore.instance
              .collection("conversations")
              .doc(conversationId)
              .collection("messages")
              .where("clientCreatedAt", isGreaterThan: lastTimestamp)
              .orderBy("clientCreatedAt", descending: false)
              .limit(50)
              .get();

          if (newSnap.docs.isNotEmpty) {
            for (var doc in newSnap.docs) {
              final data = doc.data();
              final stateStr = (data['status'] ?? '').toString().toLowerCase();
              final String msgStatus;
              if (stateStr == 'seen' || stateStr == 'read') {
                msgStatus = 'seen';
              } else if (stateStr == 'delivered') {
                msgStatus = 'delivered';
              } else if (stateStr == 'send' || stateStr == 'sent') {
                msgStatus = 'sent';
              } else {
                msgStatus = 'pending';
              }
              final msg = MessageModel(
                messageId: doc.id,
                conversationId: conversationId,
                senderId: (data['senderId'] ?? '').toString(),
                receiverId: (data['receiverId'] ?? '').toString(),
                type: (data['type'] ?? 'text').toString(),
                text: (data['text'] ?? '').toString(),
                status: msgStatus,
                clientCreatedAt: (data['clientCreatedAt'] ?? DateTime.now().toIso8601String()).toString(),
              );
              await LocalDatabaseHelper.instance.insertMessage(uid, msg.toMap());
            }
            messages = await _repository.getMessages(conversationId);
          }
        } catch (_) {}
      }
      state = AsyncValue.data(messages);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }


  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
    String? replyToMessageId,
    String? replyToText,
    String? replyToSenderId,
    String? participantName,
    String? participantImageUrl,
  }) async {
    final message = await _repository.sendMessage(
      senderId: senderId,
      receiverId: receiverId,
      text: text,
      replyToMessageId: replyToMessageId,
      replyToText: replyToText,
      replyToSenderId: replyToSenderId,
      participantName: participantName,
      participantImageUrl: participantImageUrl,
    );

    state.whenData((list) {
      final exists = list.any((m) => m.messageId == message.messageId);
      if (!exists) {
        state = AsyncValue.data([...list, message]);
      }
    });

    _repository.notifyConversationUpdate();
  }

  Future<void> editMessage(String messageId, String newText, String receiverId) async {
    await _repository.editMessage(conversationId, messageId, newText, receiverId);
    state.whenData((list) {
      final updated = list.map((m) {
        if (m.messageId == messageId) {
          return m.copyWith(text: newText, isEdited: true);
        }
        return m;
      }).toList();
      state = AsyncValue.data(updated);
    });
  }

  Future<void> toggleReaction(String messageId, String emoji, String receiverId, String currentUserId) async {
    await _repository.toggleReaction(conversationId, messageId, emoji, receiverId);
    state.whenData((list) {
      final updated = list.map((m) {
        if (m.messageId == messageId) {
          final Map<String, String> newReactions = Map.from(m.reactions);
          if (newReactions[currentUserId] == emoji) {
            newReactions.remove(currentUserId);
          } else {
            newReactions[currentUserId] = emoji;
          }
          return m.copyWith(reactions: newReactions);
        }
        return m;
      }).toList();
      state = AsyncValue.data(updated);
    });
  }

  Future<void> deleteForMe(String messageId) async {
    await _repository.deleteMessageForMe(conversationId, messageId);
    state.whenData((list) {
      final filtered = list.where((m) => m.messageId != messageId).toList();
      state = AsyncValue.data(filtered);
    });
  }

  Future<void> deleteForEveryone(String messageId, String receiverId) async {
    await _repository.deleteMessageForEveryone(conversationId, messageId, receiverId);
    state.whenData((list) {
      final updated = list.map((m) {
        if (m.messageId == messageId) {
          return m.copyWith(
            text: 'This message was deleted',
            isDeletedForEveryone: true,
          );
        }
        return m;
      }).toList();
      state = AsyncValue.data(updated);
    });
  }

  Future<void> markAsRead(String senderId) async {
    await _repository.markConversationAsRead(conversationId, senderId);
    await loadMessages();
  }

  Future<void> clearConversation() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    await LocalDatabaseHelper.instance.clearConversation(uid, conversationId);
    state = const AsyncValue.data([]);
    _repository.notifyConversationUpdate();
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    _statusSub?.cancel();
    _deleteSub?.cancel();
    _editSub?.cancel();
    _reactionSub?.cancel();
    super.dispose();
  }
}

final chatMessagesProvider = StateNotifierProvider.autoDispose.family<ChatMessagesNotifier,
    AsyncValue<List<MessageModel>>, String>((ref, conversationId) {
  final repo = ref.watch(chatRepositoryProvider);
  return ChatMessagesNotifier(repo, conversationId);
});

/// Group messages notifier — mirrors [ChatMessagesNotifier] but for group chats.
class GroupMessagesNotifier extends StateNotifier<AsyncValue<List<MessageModel>>> {
  final ChatRepository _repository;
  final String groupId;
  StreamSubscription? _msgSub;
  StreamSubscription? _statusSub;
  StreamSubscription? _deleteSub;
  StreamSubscription? _editSub;
  StreamSubscription? _reactionSub;

  GroupMessagesNotifier(this._repository, this.groupId)
      : super(const AsyncValue.loading()) {
    loadMessages();
    _listenToEvents();
  }

  void _listenToEvents() {
    _msgSub = _repository.onGroupMessageReceivedStream.listen((msg) {
      if (msg.groupId == groupId) {
        state.whenData((list) {
          final exists = list.any((m) => m.messageId == msg.messageId);
          if (!exists) {
            state = AsyncValue.data([...list, msg]);
          }
        });
      }
    });

    _statusSub = _repository.onGroupMessageStatusStream.listen((data) {
      final targetGroupId = data['groupId'];
      final targetMsgId = data['messageId'];
      final newStatus = data['status'];

      if (targetGroupId == groupId || targetGroupId == null) {
        state.whenData((list) {
          final updated = list.map((m) {
            if (targetMsgId != null && m.messageId == targetMsgId) {
              if (m.status == 'read') return m;
              if (m.status == 'delivered' && (newStatus == 'sent' || newStatus == 'pending')) return m;
              if (m.status == 'sent' && newStatus == 'pending') return m;
              return m.copyWith(status: newStatus);
            } else if (targetMsgId == null && newStatus == 'read') {
              return m.copyWith(status: 'read');
            }
            return m;
          }).toList();
          state = AsyncValue.data(updated);
        });
      }
    });

    _deleteSub = _repository.onGroupMessageDeletedStream.listen((data) {
      final targetGroupId = data['groupId'];
      final targetMsgId = data['messageId'];
      final deleteType = data['deleteType'];

      if (targetGroupId == groupId && targetMsgId != null) {
        state.whenData((list) {
          if (deleteType == 'for_me') {
            final filtered = list.where((m) => m.messageId != targetMsgId).toList();
            state = AsyncValue.data(filtered);
          } else if (deleteType == 'for_everyone') {
            final updated = list.map((m) {
              if (m.messageId == targetMsgId) {
                return m.copyWith(
                  text: 'This message was deleted',
                  isDeletedForEveryone: true,
                );
              }
              return m;
            }).toList();
            state = AsyncValue.data(updated);
          }
        });
      }
    });

    _editSub = _repository.onGroupMessageEditedStream.listen((data) {
      final targetGroupId = data['groupId'];
      final targetMsgId = data['messageId'];
      final newText = data['text'];

      if (targetGroupId == groupId && targetMsgId != null) {
        state.whenData((list) {
          final updated = list.map((m) {
            if (m.messageId == targetMsgId) {
              return m.copyWith(text: newText, isEdited: true);
            }
            return m;
          }).toList();
          state = AsyncValue.data(updated);
        });
      }
    });

    _reactionSub = _repository.onGroupMessageReactionStream.listen((data) {
      final targetGroupId = data['groupId'];
      final targetMsgId = data['messageId'];
      final rawReactions = data['reactions'];

      if (targetGroupId == groupId && targetMsgId != null && rawReactions is Map) {
        final Map<String, String> reactionsMap = rawReactions.map((k, v) => MapEntry(k.toString(), v.toString()));
        state.whenData((list) {
          final updated = list.map((m) {
            if (m.messageId == targetMsgId) {
              return m.copyWith(reactions: reactionsMap);
            }
            return m;
          }).toList();
          state = AsyncValue.data(updated);
        });
      }
    });
  }

  Future<void> loadMessages() async {
    try {
      final messages = await _repository.getGroupMessages(groupId);
      state = AsyncValue.data(messages);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> sendMessage({
    required String senderId,
    required String groupId,
    required String text,
  }) async {
    final message = await _repository.sendGroupMessage(
      senderId: senderId,
      groupId: groupId,
      text: text,
    );

    state.whenData((list) {
      final exists = list.any((m) => m.messageId == message.messageId);
      if (!exists) {
        state = AsyncValue.data([...list, message]);
      }
    });
  }

  Future<void> editMessage(String messageId, String newText) async {
    await _repository.editGroupMessage(groupId, messageId, newText);
    state.whenData((list) {
      final updated = list.map((m) {
        if (m.messageId == messageId) {
          return m.copyWith(text: newText, isEdited: true);
        }
        return m;
      }).toList();
      state = AsyncValue.data(updated);
    });
  }

  Future<void> toggleReaction(String messageId, String emoji, String currentUserId) async {
    await _repository.toggleGroupReaction(groupId, messageId, emoji, currentUserId);
    state.whenData((list) {
      final updated = list.map((m) {
        if (m.messageId == messageId) {
          final Map<String, String> newReactions = Map.from(m.reactions);
          if (newReactions[currentUserId] == emoji) {
            newReactions.remove(currentUserId);
          } else {
            newReactions[currentUserId] = emoji;
          }
          return m.copyWith(reactions: newReactions);
        }
        return m;
      }).toList();
      state = AsyncValue.data(updated);
    });
  }

  Future<void> deleteForMe(String messageId) async {
    await _repository.deleteGroupMessageForMe(groupId, messageId);
    state.whenData((list) {
      final filtered = list.where((m) => m.messageId != messageId).toList();
      state = AsyncValue.data(filtered);
    });
  }

  Future<void> deleteForEveryone(String messageId) async {
    await _repository.deleteGroupMessageForEveryone(groupId, messageId);
    state.whenData((list) {
      final updated = list.map((m) {
        if (m.messageId == messageId) {
          return m.copyWith(
            text: 'This message was deleted',
            isDeletedForEveryone: true,
          );
        }
        return m;
      }).toList();
      state = AsyncValue.data(updated);
    });
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    _statusSub?.cancel();
    _deleteSub?.cancel();
    _editSub?.cancel();
    _reactionSub?.cancel();
    super.dispose();
  }
}

final groupMessagesProvider = StateNotifierProvider.autoDispose.family<GroupMessagesNotifier,
    AsyncValue<List<MessageModel>>, String>((ref, groupId) {
  final repo = ref.watch(chatRepositoryProvider);
  return GroupMessagesNotifier(repo, groupId);
});
