// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  SocketService._();

  static final SocketService instance = SocketService._();

  static String serverUrl = "https://quickmessengerserver.onrender.com";

  static void setServerUrl(String url) {
    serverUrl = url;
  }

  io.Socket? _socket;
  bool _isConnected = false;
  String? _activeConversationId;

  bool get isConnected => _isConnected || (_socket?.connected ?? false);
  String? get activeConversationId => _activeConversationId;

  final StreamController<bool> _connectionStateController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStateStream => _connectionStateController.stream;

  // Callbacks for 1-on-1 chat
  void Function(Map<String, dynamic> data)? onMessageReceived;
  void Function(Map<String, dynamic> data)? onMessageSent;
  void Function(Map<String, dynamic> data)? onMessageDelivered;
  void Function(Map<String, dynamic> data)? onReadReceipt;
  void Function(Map<String, dynamic> data)? onMessageDeleted;
  void Function(Map<String, dynamic> data)? onMessageEdited;
  void Function(Map<String, dynamic> data)? onMessageReactionUpdated;
  void Function(Map<String, dynamic> data)? onTypingStart;
  void Function(Map<String, dynamic> data)? onTypingStop;
  void Function(Map<String, dynamic> data)? onSyncComplete;

  // Callbacks for Calls
  void Function(Map<String, dynamic> data)? onCallOffer;
  void Function(Map<String, dynamic> data)? onCallAnswer;
  void Function(Map<String, dynamic> data)? onCallRejected;
  void Function(Map<String, dynamic> data)? onCallEnded;
  void Function(Map<String, dynamic> data)? onCallTokenReady;
  void Function(Map<String, dynamic> data)? onCallError;
  void Function(Map<String, dynamic> data)? onErrorEvent;

  // Callbacks for Group Chat
  void Function(Map<String, dynamic> data)? onGroupCreated;
  void Function(Map<String, dynamic> data)? onGroupMessageReceived;
  void Function(Map<String, dynamic> data)? onGroupTypingStart;
  void Function(Map<String, dynamic> data)? onGroupTypingStop;

  final StreamController<Map<String, dynamic>> _groupCreatedStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _groupMessageReceivedStreamController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onGroupCreatedStream => _groupCreatedStreamController.stream;
  Stream<Map<String, dynamic>> get onGroupMessageReceivedStream => _groupMessageReceivedStreamController.stream;

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint("[SocketService] Cannot connect: No current Firebase user");
      return;
    }

    final token = await user.getIdToken();
    if (token == null) {
      debugPrint("[SocketService] Cannot connect: Failed to get auth token");
      return;
    }

    debugPrint("[SocketService] Connecting to $serverUrl for user ${user.uid}...");

    _socket?.dispose();

    _socket = io.io(
      serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableReconnection()
          .setReconnectionAttempts(99999)
          .setReconnectionDelay(1500)
          .setAuth({'token': token, 'userId': user.uid})
          .setQuery({'userId': user.uid})
          .build(),
    );

    _registerListeners();
    _socket!.connect();
  }

  void _registerListeners() {
    if (_socket == null) return;

    _socket!.onConnect((_) {
      debugPrint("[SocketService] Connected successfully!");
      _isConnected = true;
      _connectionStateController.add(true);
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        _socket!.emit('user_connected', {'userId': uid});
      }
    });

    _socket!.onDisconnect((reason) {
      debugPrint("[SocketService] Disconnected: $reason");
      _isConnected = false;
      _connectionStateController.add(false);
    });

    _socket!.onConnectError((err) {
      debugPrint("[SocketService] ❌ Connect Error: $err. Check if server at $serverUrl is running and accessible.");
      _isConnected = false;
      _connectionStateController.add(false);
    });

    _socket!.onError((err) {
      debugPrint("[SocketService] ❌ Socket Error: $err");
      _isConnected = false;
      _connectionStateController.add(false);
    });

    _socket!.onReconnectAttempt((attempt) {
      debugPrint("[SocketService] 🔄 Reconnection attempt: $attempt");
    });

    _socket!.on('message_sent', (data) {
      debugPrint("[SocketService] message_sent event: $data");
      if (data is Map<String, dynamic>) {
        onMessageSent?.call(data);
      } else if (data is Map) {
        onMessageSent?.call(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('message_received', (data) {
      debugPrint("[SocketService] message_received event: $data");
      if (data is Map<String, dynamic>) {
        onMessageReceived?.call(data);
      } else if (data is Map) {
        onMessageReceived?.call(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('message_delivered', (data) {
      if (data is Map<String, dynamic>) {
        onMessageDelivered?.call(data);
      } else if (data is Map) {
        onMessageDelivered?.call(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('read_receipt', (data) {
      if (data is Map<String, dynamic>) {
        onReadReceipt?.call(data);
      } else if (data is Map) {
        onReadReceipt?.call(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('message_deleted', (data) {
      if (data is Map<String, dynamic>) {
        onMessageDeleted?.call(data);
      } else if (data is Map) {
        onMessageDeleted?.call(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('message_edited', (data) {
      if (data is Map<String, dynamic>) {
        onMessageEdited?.call(data);
      } else if (data is Map) {
        onMessageEdited?.call(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('message_reaction_updated', (data) {
      if (data is Map<String, dynamic>) {
        onMessageReactionUpdated?.call(data);
      } else if (data is Map) {
        onMessageReactionUpdated?.call(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('typing_start', (data) {
      if (data is Map<String, dynamic>) {
        onTypingStart?.call(data);
      } else if (data is Map) {
        onTypingStart?.call(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('typing_stop', (data) {
      if (data is Map<String, dynamic>) {
        onTypingStop?.call(data);
      } else if (data is Map) {
        onTypingStop?.call(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('sync_complete', (data) {
      if (data is Map<String, dynamic>) {
        onSyncComplete?.call(data);
      } else if (data is Map) {
        onSyncComplete?.call(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('group_created', (data) {
      final mapData = (data is Map<String, dynamic>)
          ? data
          : (data is Map ? Map<String, dynamic>.from(data) : null);
      if (mapData != null) {
        onGroupCreated?.call(mapData);
        _groupCreatedStreamController.add(mapData);
      }
    });

    _socket!.on('added_to_group', (data) {
      final mapData = (data is Map<String, dynamic>)
          ? data
          : (data is Map ? Map<String, dynamic>.from(data) : null);
      if (mapData != null) {
        onGroupCreated?.call(mapData);
        _groupCreatedStreamController.add(mapData);
      }
    });

    _socket!.on('group_message_received', (data) {
      final mapData = (data is Map<String, dynamic>)
          ? data
          : (data is Map ? Map<String, dynamic>.from(data) : null);
      if (mapData != null) {
        onGroupMessageReceived?.call(mapData);
        _groupMessageReceivedStreamController.add(mapData);
      }
    });

    _socket!.on('group_typing_start', (data) {
      if (data is Map<String, dynamic>) {
        onGroupTypingStart?.call(data);
      } else if (data is Map) {
        onGroupTypingStart?.call(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('group_typing_stop', (data) {
      if (data is Map<String, dynamic>) {
        onGroupTypingStop?.call(data);
      } else if (data is Map) {
        onGroupTypingStop?.call(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('call_offer', (data) {
      if (data is Map<String, dynamic>) {
        onCallOffer?.call(data);
      } else if (data is Map) {
        onCallOffer?.call(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('call_answer', (data) {
      if (data is Map<String, dynamic>) {
        onCallAnswer?.call(data);
      } else if (data is Map) {
        onCallAnswer?.call(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('call_rejected', (data) {
      if (data is Map<String, dynamic>) {
        onCallRejected?.call(data);
      } else if (data is Map) {
        onCallRejected?.call(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('call_ended', (data) {
      if (data is Map<String, dynamic>) {
        onCallEnded?.call(data);
      } else if (data is Map) {
        onCallEnded?.call(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('call_token_ready', (data) {
      if (data is Map<String, dynamic>) {
        onCallTokenReady?.call(data);
      } else if (data is Map) {
        onCallTokenReady?.call(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('call_error', (data) {
      if (data is Map<String, dynamic>) {
        onCallError?.call(data);
      } else if (data is Map) {
        onCallError?.call(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('error_event', (data) {
      debugPrint("[SocketService] error_event: $data");
      if (data is Map<String, dynamic>) {
        onErrorEvent?.call(data);
      } else if (data is Map) {
        onErrorEvent?.call(Map<String, dynamic>.from(data));
      }
    });
  }


  void emitCallOffer(Map<String, dynamic> callData) {
    if (_socket == null) return;
    _socket!.emit('call_offer', callData);
  }

  void emitCallAnswer(Map<String, dynamic> callData) {
    if (_socket == null) return;
    _socket!.emit('call_answer', callData);
  }

  void emitCallRejected(Map<String, dynamic> callData) {
    if (_socket == null) return;
    _socket!.emit('call_rejected', callData);
  }

  void emitCallEnded(Map<String, dynamic> callData) {
    if (_socket == null) return;
    _socket!.emit('call_ended', callData);
  }

  void emitSetActiveConversation(String? conversationId) {
    _activeConversationId = conversationId;
    if (_socket == null || !_socket!.connected) {
      connect().then((_) {
        _socket?.emit('set_active_conversation', {
          'conversationId': conversationId,
        });
      });
      return;
    }
    _socket!.emit('set_active_conversation', {
      'conversationId': conversationId,
    });
  }

  void emitSendMessage({
    required String messageId,
    required String receiverId,
    required String type,
    required String text,
    String? replyToMessageId,
    String? replyToText,
    String? replyToSenderId,
    required String clientCreatedAt,
  }) {
    final payload = {
      'messageId': messageId,
      'receiverId': receiverId,
      'type': type,
      'text': text,
      'replyToMessageId': replyToMessageId,
      'replyToText': replyToText,
      'replyToSenderId': replyToSenderId,
      'clientCreatedAt': clientCreatedAt,
    };

    if (_socket == null || !_socket!.connected) {
      debugPrint("[SocketService] Socket disconnected. Auto-connecting to send message $messageId...");
      connect().then((_) {
        _socket?.emit('send_message', payload);
      });
      return;
    }

    _socket!.emit('send_message', payload);
  }


  void emitCreateGroup({
    required String groupId,
    required String name,
    String description = '',
    String imageUrl = '',
    List<String> initialMemberUids = const [],
  }) {
    if (_socket == null) return;
    _socket!.emit('create_group', {
      'groupId': groupId,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'initialMemberUids': initialMemberUids,
    });
  }

void emitSendGroupMessage({
    required String messageId,
    required String groupId,
    String? senderName,
    required String type,
    required String text,
    required String clientCreatedAt,
  }) {
    if (_socket == null) return;
    _socket!.emit('send_group_message', {
      'messageId': messageId,
      'groupId': groupId,
      'senderName': senderName,
      'type': type,
      'text': text,
      'clientCreatedAt': clientCreatedAt,
    });
  }

  void emitEditGroupMessage({
    required String groupId,
    required String messageId,
    required String newText,
  }) {
    if (_socket == null) return;
    _socket!.emit('edit_group_message', {
      'groupId': groupId,
      'messageId': messageId,
      'newText': newText,
    });
  }

  void emitToggleGroupReaction({
    required String groupId,
    required String messageId,
    required String emoji,
    required String userId,
  }) {
    if (_socket == null) return;
    _socket!.emit('toggle_group_reaction', {
      'groupId': groupId,
      'messageId': messageId,
      'emoji': emoji,
      'userId': userId,
    });
  }

  void emitDeleteGroupForMe({
    required String groupId,
    required String messageId,
  }) {
    if (_socket == null) return;
    _socket!.emit('delete_group_message_for_me', {
      'groupId': groupId,
      'messageId': messageId,
    });
  }

  void emitDeleteGroupForEveryone({
    required String groupId,
    required String messageId,
  }) {
    if (_socket == null) return;
    _socket!.emit('delete_group_message_for_everyone', {
      'groupId': groupId,
      'messageId': messageId,
    });
  }

  void emitGroupTypingStart({required String groupId, required List<String> memberUids}) {
    if (_socket == null) return;
    _socket!.emit('group_typing_start', {'groupId': groupId, 'memberUids': memberUids});
  }

  void emitGroupTypingStop({required String groupId, required List<String> memberUids}) {
    if (_socket == null) return;
    _socket!.emit('group_typing_stop', {'groupId': groupId, 'memberUids': memberUids});
  }

  void emitEditMessage({
    required String conversationId,
    required String messageId,
    required String newText,
    required String receiverId,
  }) {
    if (_socket == null) return;
    _socket!.emit('edit_message', {
      'conversationId': conversationId,
      'messageId': messageId,
      'newText': newText,
      'receiverId': receiverId,
    });
  }

  void emitToggleReaction({
    required String conversationId,
    required String messageId,
    required String emoji,
    required String receiverId,
  }) {
    if (_socket == null) return;
    _socket!.emit('toggle_reaction', {
      'conversationId': conversationId,
      'messageId': messageId,
      'emoji': emoji,
      'receiverId': receiverId,
    });
  }

  void emitMessageDelivered({
    required String conversationId,
    required String messageId,
    required String senderId,
  }) {
    final payload = {
      'conversationId': conversationId,
      'messageId': messageId,
      'senderId': senderId,
    };

    if (_socket == null || !_socket!.connected) {
      connect().then((_) {
        _socket?.emit('message_delivered', payload);
      });
      return;
    }

    _socket!.emit('message_delivered', payload);
  }

  void emitMarkRead({
    required String conversationId,
    required String senderId,
  }) {
    final payload = {
      'conversationId': conversationId,
      'senderId': senderId,
    };

    if (_socket == null || !_socket!.connected) {
      connect().then((_) {
        _socket?.emit('mark_read', payload);
      });
      return;
    }

    _socket!.emit('mark_read', payload);
  }


  void emitDeleteForMe({
    required String conversationId,
    required String messageId,
  }) {
    if (_socket == null) return;
    _socket!.emit('delete_message_for_me', {
      'conversationId': conversationId,
      'messageId': messageId,
    });
  }

  void emitDeleteForEveryone({
    required String conversationId,
    required String messageId,
    required String receiverId,
  }) {
    if (_socket == null) return;
    _socket!.emit('delete_message_for_everyone', {
      'conversationId': conversationId,
      'messageId': messageId,
      'receiverId': receiverId,
    });
  }

  void emitTypingStart({
    required String conversationId,
    required String receiverId,
  }) {
    if (_socket == null) return;
    _socket!.emit('typing_start', {
      'conversationId': conversationId,
      'receiverId': receiverId,
    });
  }

  void emitTypingStop({
    required String conversationId,
    required String receiverId,
  }) {
    if (_socket == null) return;
    _socket!.emit('typing_stop', {
      'conversationId': conversationId,
      'receiverId': receiverId,
    });
  }

  void emitSyncMessages({
    required String conversationId,
    String? lastMessageId,
  }) {
    if (_socket == null) return;
    _socket!.emit('sync_messages', {
      'conversationId': conversationId,
      'lastMessageId': lastMessageId,
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _activeConversationId = null;
  }
}

