import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../core/config/app_config.dart';
import '../../../core/database/local_database_helper.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/services/drive_service.dart';
import '../../../core/services/socket_service.dart';
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

final userProfileProvider = FutureProvider.autoDispose
    .family<Map<String, String>, String>((ref, uid) async {
  if (uid.isEmpty) {
    return {'username': 'User', 'imageurl': '', 'about': '', 'email': ''};
  }

  final repo = ref.watch(chatRepositoryProvider);
  final conversations = await repo.getConversations();
  final matching = conversations.where(
    (c) =>
        c.participantId == uid &&
        c.participantName != 'User' &&
        c.participantName.isNotEmpty,
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
    final doc =
        await FirebaseFirestore.instance.collection("Users").doc(uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      final resolvedName = (data['username'] ?? '').toString();
      if (resolvedName.isNotEmpty && resolvedName != 'User') {
        final profile = {
          'username': resolvedName,
          'imageurl':
              (data['userimageurl'] ?? data['imageurl'] ?? '').toString(),
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

class ConversationsNotifier
    extends StateNotifier<AsyncValue<List<ConversationModel>>> {
  final ChatRepository _repository;
  StreamSubscription? _sub;

  ConversationsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadConversations();
    _sub = _repository.onConversationUpdateStream.listen((_) {
      loadConversations();
    });
    _performInitialSyncIfNeeded();
  }

  Future<void> _performInitialSyncIfNeeded() async {
    final uid = _repository.currentUserId;
    if (uid.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSynced = prefs.getBool('initial_firestore_sync_$uid') ?? false;
      if (!hasSynced) {
        // Single one-time initial fetch from Firestore for bootstrap
        final snap = await FirebaseFirestore.instance
            .collection("Users")
            .doc(uid)
            .collection("chats")
            .get();
        if (snap.docs.isNotEmpty) {
          await _repository.syncConversationsFromFirestore(snap);
          await loadConversations();
        }
        await prefs.setBool('initial_firestore_sync_$uid', true);
      }
    } catch (_) {}
  }

  Future<void> loadConversations() async {
    try {
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
    super.dispose();
  }
}

final conversationsProvider = StateNotifierProvider<ConversationsNotifier,
    AsyncValue<List<ConversationModel>>>((ref) {
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
  // Normalize both IDs by stripping common prefixes
  final clean1 = id1.replaceFirst('conv_', '').replaceFirst('group_', '');
  final clean2 = id2.replaceFirst('conv_', '').replaceFirst('group_', '');
  return clean1 == clean2;
}

class ChatMessagesNotifier
    extends StateNotifier<AsyncValue<List<MessageModel>>> {
  final ChatRepository _repository;
  final String conversationId;
  StreamSubscription? _msgSub;
  StreamSubscription? _statusSub;
  StreamSubscription? _deleteSub;
  StreamSubscription? _editSub;
  StreamSubscription? _reactionSub;
  int _loadOffset = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  ChatMessagesNotifier(this._repository, this.conversationId)
      : super(const AsyncValue.loading()) {
    loadMessages();
    _listenToEvents();
  }

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  Future<void> loadMessages({bool reset = true}) async {
    if (reset) {
      _loadOffset = 0;
      _hasMore = true;
      state = const AsyncValue.loading();
    }
    if (_isLoadingMore) return;
    if (!_hasMore && !reset) return;

    _isLoadingMore = true;
    try {
      final messages = await _repository.getMessages(
        conversationId,
        limit: AppConfig.messagesPageSize,
        offset: _loadOffset,
      );
      if (reset) {
        _hasMore = messages.length >= AppConfig.messagesPageSize;
        _loadOffset = messages.length;
        state = AsyncValue.data(MessageModel.sortAndDeduplicate(messages));
      } else {
        _hasMore = messages.length >= AppConfig.messagesPageSize;
        _loadOffset += messages.length;
        state.whenData((list) {
          state = AsyncValue.data(
              MessageModel.sortAndDeduplicate([...messages, ...list]));
        });
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> loadMore() async {
    await loadMessages(reset: false);
  }

  void _listenToEvents() {
    _msgSub = _repository.onMessageReceivedStream.listen((msg) {
      if (_convMatches(msg.conversationId, conversationId)) {
        state.whenData((list) {
          state = AsyncValue.data(
              MessageModel.sortAndDeduplicate([...list, msg]));
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
              if ((m.status == 'delivered' || m.status == 'sent') &&
                  (newStatus == 'sent' || newStatus == 'pending')) {
                return m;
              }
              return m.copyWith(status: newStatus);
            } else if (targetMsgId == null &&
                (newStatus == 'read' || newStatus == 'seen')) {
              if (m.senderId == _repository.currentUserId &&
                  (m.status == 'sent' || m.status == 'delivered')) {
                return m.copyWith(status: 'read');
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
            final filtered =
                list.where((m) => m.messageId != targetMsgId).toList();
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

      if (_convMatches(targetConvId, conversationId) &&
          targetMsgId != null &&
          rawReactions is Map) {
        final Map<String, String> reactionsMap =
            rawReactions.map((k, v) => MapEntry(k.toString(), v.toString()));
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

  Future<void> sendMessage({
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
    final message = await _repository.sendMessage(
      senderId: senderId,
      receiverId: receiverId,
      text: text,
      replyToMessageId: replyToMessageId,
      replyToText: replyToText,
      replyToSenderId: replyToSenderId,
      participantName: participantName,
      participantImageUrl: participantImageUrl,
      type: type,
      fileUrl: fileUrl,
      localPath: localPath,
      driveFileId: driveFileId,
      fileName: fileName,
      fileSize: fileSize,
    );

    state.whenData((list) {
      state = AsyncValue.data(
          MessageModel.sortAndDeduplicate([...list, message]));
    });

    _repository.notifyConversationUpdate();
  }

  Future<void> sendMediaMessage({
    required String senderId,
    required String receiverId,
    required File file,
    required String type,
    String? fileName,
    String? caption,
    String? replyToMessageId,
    String? replyToText,
    String? replyToSenderId,
    String? participantName,
    String? participantImageUrl,
  }) async {
    final sep = Platform.isWindows ? '\\' : '/';
    final resolvedFileName = fileName ?? file.path.split(sep).last;
    final fileSize = file.existsSync() ? file.lengthSync() : 0;
    final messageId = const Uuid().v4();
    final clientCreatedAt = DateTime.now().toIso8601String();
    final displayText =
        (caption != null && caption.isNotEmpty) ? caption : resolvedFileName;

    // 1. Optimistic Message Model with status = 'uploading'
    final optimisticMessage = MessageModel(
      messageId: messageId,
      conversationId: conversationId,
      senderId: senderId,
      receiverId: receiverId,
      type: type,
      text: displayText,
      replyToMessageId: replyToMessageId,
      replyToText: replyToText,
      replyToSenderId: replyToSenderId,
      status: 'uploading',
      clientCreatedAt: clientCreatedAt,
      localPath: file.path,
      fileName: resolvedFileName,
      fileSize: fileSize,
    );

    // 2. Persist to local database immediately
    final effectiveUserId = _repository.currentUserId.isNotEmpty
        ? _repository.currentUserId
        : senderId;
    await LocalDatabaseHelper.instance
        .insertMessage(effectiveUserId, optimisticMessage.toMap());

    await LocalDatabaseHelper.instance.upsertConversation(
      currentUserId: effectiveUserId,
      conversationId: conversationId,
      participantId: receiverId,
      participantName: participantName,
      participantImageUrl: participantImageUrl,
      lastMessage: type == 'image' ? '📷 Photo' : '📎 $resolvedFileName',
      lastTimestamp: clientCreatedAt,
      unreadCount: 0,
    );

    // 3. Immediately update UI state so media bubble appears with uploading state
    state.whenData((list) {
      state = AsyncValue.data(
          MessageModel.sortAndDeduplicate([...list, optimisticMessage]));
    });
    _repository.notifyConversationUpdate();

    // 4. Background upload to Google Drive
    try {
      final ext = file.path.split('.').last.toLowerCase();
      String mimeType;
      switch (ext) {
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        case 'gif':
          mimeType = 'image/gif';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
        case 'pdf':
          mimeType = 'application/pdf';
          break;
        case 'mp4':
          mimeType = 'video/mp4';
          break;
        case 'mp3':
          mimeType = 'audio/mpeg';
          break;
        case 'zip':
          mimeType = 'application/zip';
          break;
        default:
          mimeType = 'application/octet-stream';
      }

      Map<String, dynamic>? upload;
      try {
        upload = await DriveService.instance.uploadMediaFile(
          file: file,
          fileName: resolvedFileName,
          mimeType: mimeType,
        );
      } catch (e) {
        debugPrint("[ChatProvider] Drive upload exception: $e");
      }

      // Seamless fallback to Firebase Storage if Drive upload fails or returns null
      if (upload == null || upload['fileUrl'] == null) {
        try {
          debugPrint(
              "[ChatProvider] Drive upload unavailable. Uploading to Firebase Storage...");
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('chat_media')
              .child(conversationId)
              .child(
                  '${DateTime.now().millisecondsSinceEpoch}_$resolvedFileName');

          final task = await storageRef.putFile(
            file,
            SettableMetadata(contentType: mimeType),
          );
          final downloadUrl = await task.ref.getDownloadURL();
          upload = {
            'fileUrl': downloadUrl,
            'fileName': resolvedFileName,
            'fileSize': file.existsSync() ? file.lengthSync() : fileSize,
            'driveFileId': null,
          };
          debugPrint(
              "[ChatProvider] Firebase Storage upload succeeded: $downloadUrl");
        } catch (storageErr) {
          debugPrint(
              "[ChatProvider] Firebase Storage upload failed: $storageErr");
        }
      }

      if (upload != null && upload['fileUrl'] != null) {
        final fileUrl = upload['fileUrl'] as String;
        final driveFileId = upload['driveFileId'] as String?;
        final uploadedSize = upload['fileSize'] as int? ?? fileSize;

        // Update local database
        await LocalDatabaseHelper.instance.updateMessageMedia(
          effectiveUserId,
          messageId,
          fileUrl: fileUrl,
          driveFileId: driveFileId,
          fileName: resolvedFileName,
          fileSize: uploadedSize,
          status: 'sent',
        );

        // Emit over socket to recipient
        SocketService.instance.emitSendMessage(
          messageId: messageId,
          receiverId: receiverId,
          type: type,
          text: displayText,
          replyToMessageId: replyToMessageId,
          replyToText: replyToText,
          replyToSenderId: replyToSenderId,
          clientCreatedAt: clientCreatedAt,
          fileUrl: fileUrl,
          driveFileId: driveFileId,
          fileName: resolvedFileName,
          fileSize: uploadedSize,
        );

        // Update in-memory state
        state.whenData((list) {
          final updated = list.map((m) {
            if (m.messageId == messageId) {
              return m.copyWith(
                fileUrl: fileUrl,
                driveFileId: driveFileId,
                fileSize: uploadedSize,
                status: 'sent',
              );
            }
            return m;
          }).toList();
          state = AsyncValue.data(updated);
        });
      } else {
        // Upload failed
        await LocalDatabaseHelper.instance
            .updateMessageStatus(effectiveUserId, messageId, 'failed');
        state.whenData((list) {
          final updated = list.map((m) {
            if (m.messageId == messageId) {
              return m.copyWith(status: 'failed');
            }
            return m;
          }).toList();
          state = AsyncValue.data(updated);
        });
      }
    } catch (_) {
      await LocalDatabaseHelper.instance
          .updateMessageStatus(effectiveUserId, messageId, 'failed');
      state.whenData((list) {
        final updated = list.map((m) {
          if (m.messageId == messageId) {
            return m.copyWith(status: 'failed');
          }
          return m;
        }).toList();
        state = AsyncValue.data(updated);
      });
    }
  }

  Future<void> updateMessageLocalPath(
      String messageId, String localPath) async {
    final uid = _repository.currentUserId;
    if (uid.isNotEmpty) {
      await LocalDatabaseHelper.instance
          .updateMessageLocalPath(uid, messageId, localPath);
      state.whenData((list) {
        final updated = list.map((m) {
          if (m.messageId == messageId) {
            return m.copyWith(localPath: localPath);
          }
          return m;
        }).toList();
        state = AsyncValue.data(updated);
      });
    }
  }

  Future<void> editMessage(
      String messageId, String newText, String receiverId) async {
    await _repository.editMessage(
        conversationId, messageId, newText, receiverId);
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

  Future<void> toggleReaction(String messageId, String emoji, String receiverId,
      String currentUserId) async {
    await _repository.toggleReaction(
        conversationId, messageId, emoji, receiverId);
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
    await _repository.deleteMessageForEveryone(
        conversationId, messageId, receiverId);
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

  Future<void> markAsRead(String participantId) async {
    await _repository.markConversationAsRead(conversationId, participantId);
    state.whenData((list) {
      final updated = list.map((m) {
        if (m.senderId == participantId &&
            (m.status == 'sent' || m.status == 'delivered')) {
          return m.copyWith(status: 'read');
        }
        return m;
      }).toList();
      state = AsyncValue.data(updated);
    });
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

final chatMessagesProvider = StateNotifierProvider.autoDispose
    .family<ChatMessagesNotifier, AsyncValue<List<MessageModel>>, String>(
        (ref, conversationId) {
  final repo = ref.watch(chatRepositoryProvider);
  return ChatMessagesNotifier(repo, conversationId);
});

/// Group messages notifier — mirrors [ChatMessagesNotifier] but for group chats.
class GroupMessagesNotifier
    extends StateNotifier<AsyncValue<List<MessageModel>>> {
  final ChatRepository _repository;
  final String groupId;
  StreamSubscription? _msgSub;
  StreamSubscription? _statusSub;
  StreamSubscription? _deleteSub;
  StreamSubscription? _editSub;
  StreamSubscription? _reactionSub;
  int _loadOffset = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  GroupMessagesNotifier(this._repository, this.groupId)
      : super(const AsyncValue.loading()) {
    loadMessages();
    _listenToEvents();
  }

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  Future<void> loadMessages({bool reset = true}) async {
    if (reset) {
      _loadOffset = 0;
      _hasMore = true;
      state = const AsyncValue.loading();
    }
    if (_isLoadingMore) return;
    if (!_hasMore && !reset) return;

    _isLoadingMore = true;
    try {
      final messages = await _repository.getGroupMessages(
        groupId,
        limit: AppConfig.messagesPageSize,
        offset: _loadOffset,
      );
      if (reset) {
        _hasMore = messages.length >= AppConfig.messagesPageSize;
        _loadOffset = messages.length;
        state = AsyncValue.data(MessageModel.sortAndDeduplicate(messages));
      } else {
        _hasMore = messages.length >= AppConfig.messagesPageSize;
        _loadOffset += messages.length;
        state.whenData((list) {
          state = AsyncValue.data(
              MessageModel.sortAndDeduplicate([...messages, ...list]));
        });
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> loadMore() async {
    await loadMessages(reset: false);
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
      state = AsyncValue.data(
          MessageModel.sortAndDeduplicate([...list, message]));
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

  Future<void> toggleReaction(
      String messageId, String emoji, String currentUserId) async {
    await _repository.toggleGroupReaction(
        groupId, messageId, emoji, currentUserId);
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

  void _listenToEvents() {
    _msgSub = _repository.onGroupMessageReceivedStream.listen((msg) {
      if (msg.groupId == groupId) {
        state.whenData((list) {
          state = AsyncValue.data(
              MessageModel.sortAndDeduplicate([...list, msg]));
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
              if (m.status == 'delivered' &&
                  (newStatus == 'sent' || newStatus == 'pending')) {
                return m;
              }
              if (m.status == 'sent' && newStatus == 'pending') {
                return m;
              }
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
            final filtered =
                list.where((m) => m.messageId != targetMsgId).toList();
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

      if (targetGroupId == groupId &&
          targetMsgId != null &&
          rawReactions is Map) {
        final Map<String, String> reactionsMap =
            rawReactions.map((k, v) => MapEntry(k.toString(), v.toString()));
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

  Future<void> updateMessageLocalPath(
      String messageId, String localPath) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isNotEmpty) {
      await LocalDatabaseHelper.instance
          .updateMessageLocalPath(uid, messageId, localPath);
    }
    state.whenData((list) {
      final updated = list.map((m) {
        if (m.messageId == messageId) {
          return m.copyWith(localPath: localPath);
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

final groupMessagesProvider = StateNotifierProvider.autoDispose
    .family<GroupMessagesNotifier, AsyncValue<List<MessageModel>>, String>(
        (ref, groupId) {
  final repo = ref.watch(chatRepositoryProvider);
  return GroupMessagesNotifier(repo, groupId);
});
