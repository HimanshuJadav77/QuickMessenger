// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

import 'package:quick_messenger/core/providers/auth_providers.dart';
import 'package:quick_messenger/core/services/notification_service.dart';
import 'package:quick_messenger/core/services/socket_service.dart';
import 'package:quick_messenger/core/theme/theme_provider.dart';
import 'package:quick_messenger/features/chat/providers/chat_provider.dart';
import 'package:quick_messenger/features/chat/repositories/chat_repository.dart';
import 'package:quick_messenger/features/chat/models/message_model.dart';
import 'package:quick_messenger/features/chat/models/conversation_model.dart';
import 'package:quick_messenger/features/chat/models/call_model.dart';

import 'widget_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<FirebaseAuth>(),
  MockSpec<User>(),
  MockSpec<FirebaseFirestore>(),
  MockSpec<DocumentReference>(),
  MockSpec<QuerySnapshot>(),
  MockSpec<QueryDocumentSnapshot>(),
  MockSpec<DocumentSnapshot>(),
  MockSpec<SocketService>(),
  MockSpec<ChatRepository>(),
  MockSpec<NotificationService>(),
])
void main() {
  setUpAll(() {
    // Mock Firebase for tests
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('Auth Providers', () {
    test('currentUserIdProvider returns empty string when not logged in', () {
      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWith((ref) => Stream.value(null)),
          currentUserProvider.overrideWith((ref) => null),
        ],
      );

      expect(container.read(currentUserIdProvider), '');
    });

    test('currentUserIdProvider returns UID when logged in', () {
      final mockUser = MockUser();
      when(mockUser.uid).thenReturn('test-uid');

      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider
              .overrideWith((ref) => Stream.value(mockUser)),
          currentUserProvider.overrideWith((ref) => mockUser),
        ],
      );

      expect(container.read(currentUserIdProvider), 'test-uid');
    });
  });

  group('Chat Provider', () {
    late MockChatRepository mockRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockChatRepository();
      container = ProviderContainer(
        overrides: [
          chatRepositoryProvider.overrideWithValue(mockRepo),
          currentUserIdProvider.overrideWithValue('test-uid'),
          // Override conversationsProvider in tests
          conversationsProvider.overrideWith((ref) {
            final repo = ref.watch(chatRepositoryProvider);
            return ConversationsNotifier(repo);
          }),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('ConversationsNotifier loads conversations on init', () async {
      when(mockRepo.getConversations()).thenAnswer((_) async => []);

      final notifier = container.read(conversationsProvider.notifier);
      await notifier.loadConversations();

      expect(container.read(conversationsProvider),
          isA<AsyncData<List<ConversationModel>>>());
    });

    test('sendMessage adds message to state optimistically', () async {
      final message = MessageModel(
        messageId: 'msg-1',
        conversationId: 'conv_123',
        senderId: 'user-1',
        receiverId: 'user-2',
        text: 'Hello',
        status: 'pending',
        clientCreatedAt: DateTime.now().toIso8601String(),
      );

      when(mockRepo.sendMessage(
        senderId: 'user-1',
        receiverId: 'user-2',
        text: 'Hello',
        participantName: 'Test User',
        participantImageUrl: 'https://example.com/avatar.png',
      )).thenAnswer((_) async => message);

      final notifier = container.read(
        chatMessagesProvider('conv_test').notifier,
      );

      await notifier.sendMessage(
        senderId: 'user-1',
        receiverId: 'user-2',
        text: 'Hello',
        participantName: 'Test User',
        participantImageUrl: 'https://example.com/avatar.png',
      );

      container.read(chatMessagesProvider('conv_test')).whenData((messages) {
        expect(messages.length, 1);
        expect(messages.first.text, 'Hello');
        expect(messages.first.status, 'pending');
      });
    });

    test('toggleReaction adds reaction for current user', () async {
      when(mockRepo.toggleReaction(
        'conv_test',
        'msg-1',
        '❤️',
        'user-2',
      )).thenAnswer((_) async => {});

      final notifier =
          container.read(chatMessagesProvider('conv_test').notifier);
      await notifier.toggleReaction('msg-1', '❤️', 'user-2', 'user-1');

      verify(mockRepo.toggleReaction(
        'conv_test',
        'msg-1',
        '❤️',
        'user-2',
      )).called(1);
    });
  });

  group('Message Model', () {
    test('fromMap parses status correctly', () {
      final map = {
        'message_id': 'msg-1',
        'conversation_id': 'conv_123',
        'sender_id': 'user-1',
        'receiver_id': 'user-2',
        'type': 'text',
        'text': 'Hello',
        'status': 'seen',
        'is_deleted_for_me': false,
        'is_deleted_for_everyone': false,
        'is_edited': false,
        'reactions': {'user-1': '👍'},
        'client_created_at': DateTime.now().toIso8601String(),
      };

      final message = MessageModel.fromMap(map);

      expect(message.messageId, 'msg-1');
      expect(message.conversationId, 'conv_123');
      expect(message.status, 'seen');
      expect(message.reactions['user-1'], '👍');
    });

    test('copyWith preserves unchanged fields', () {
      final original = MessageModel(
        messageId: 'msg-1',
        conversationId: 'conv_123',
        senderId: 'user-1',
        receiverId: 'user-2',
        text: 'Hello',
        status: 'pending',
        clientCreatedAt: '2024-01-01T00:00:00.000Z',
      );

      final updated = original.copyWith(status: 'sent');

      expect(updated.messageId, original.messageId);
      expect(updated.conversationId, original.conversationId);
      expect(updated.text, original.text);
      expect(updated.status, 'sent');
      expect(updated.clientCreatedAt, original.clientCreatedAt);
    });

    test('copyWith with reactions', () {
      final original = MessageModel(
        messageId: 'msg-1',
        conversationId: 'conv_123',
        senderId: 'user-1',
        receiverId: 'user-2',
        text: 'Hello',
        status: 'sent',
        clientCreatedAt: '2024-01-01T00:00:00.000Z',
        reactions: {'user-1': '👍'},
      );

      final updated = original.copyWith(reactions: {'user-1': '❤️'});

      expect(updated.reactions['user-1'], '❤️');
    });
  });

  group('Conversation Model', () {
    test('fromMap parses fields correctly', () {
      final map = {
        'id': 'conv_123',
        'participant_id': 'user-2',
        'participant_name': 'John',
        'participant_imageurl': 'https://example.com/avatar.png',
        'last_message': 'Hello',
        'last_timestamp': '2024-01-01T00:00:00.000Z',
        'unread_count': 5,
        'is_pinned': false,
        'is_archived': false,
        'is_muted': false,
      };

      final conv = ConversationModel.fromMap(map);

      expect(conv.id, 'conv_123');
      expect(conv.participantId, 'user-2');
      expect(conv.participantName, 'John');
      expect(conv.unreadCount, 5);
      expect(conv.isPinned, false);
    });

    test('copyWith updates only specified fields', () {
      final original = ConversationModel(
        id: 'conv_123',
        participantId: 'user-2',
        participantName: 'John',
        participantImageUrl: 'https://example.com/avatar.png',
        lastMessage: 'Hello',
        lastTimestamp: '2024-01-01T00:00:00.000Z',
        unreadCount: 0,
        isPinned: false,
        isArchived: false,
        isMuted: false,
      );

      final updated = original.copyWith(unreadCount: 5, isPinned: true);

      expect(updated.unreadCount, 5);
      expect(updated.isPinned, true);
      expect(updated.lastMessage, original.lastMessage);
      expect(updated.participantName, original.participantName);
    });
  });

  group('Conversation ID', () {
    test('getConversationId is deterministic', () {
      final repo = ChatRepository();
      final id1 = repo.getConversationId('user-a', 'user-b');
      final id2 = repo.getConversationId('user-b', 'user-a');

      expect(id1, id2);
      expect(id1, 'conv_user-a_user-b');
    });

    test('getConversationId uses conv_ prefix', () {
      final repo = ChatRepository();
      final id = repo.getConversationId('user-1', 'user-2');
      expect(id.startsWith('conv_'), true);
    });

    test('getConversationId handles special characters', () {
      final repo = ChatRepository();
      final id = repo.getConversationId('user@domain.com', 'user-2');

      expect(id, 'conv_user-2_user@domain.com');
    });
  });

  group('Socket Service', () {
    test('SocketService singleton', () {
      expect(SocketService.instance, isNotNull);
      expect(SocketService.instance, same(SocketService.instance));
    });

    test('serverUrl can be overridden', () {
      SocketService.setServerUrl('https://custom-server.com');
      expect(SocketService.serverUrl, 'https://custom-server.com');

      // Reset for other tests
      SocketService.setServerUrl('https://quickmessengerserver.onrender.com');
    });
  });

  group('Call Service', () {
    test('CallModel copyWith works correctly', () {
      final call = CallModel(
        callId: 'call-1',
        callerId: 'user-1',
        callerName: 'John',
        callerAvatar: 'https://example.com/avatar.png',
        receiverId: 'user-2',
        callType: CallType.video,
        status: CallStatus.calling,
      );

      final updated = call.copyWith(status: CallStatus.connected);

      expect(updated.status, CallStatus.connected);
      expect(updated.callId, call.callId);
      expect(updated.callerId, call.callerId);
    });

    test('CallModel fromMap handles missing fields', () {
      final map = {
        'callId': 'call-1',
        'callerId': 'user-1',
        'callerName': 'John',
        'callerAvatar': '',
        'receiverId': 'user-2',
        'callType': 'video',
        'status': 'calling',
      };

      final call = CallModel.fromMap(map);

      expect(call.callId, 'call-1');
      expect(call.callType, CallType.video);
      expect(call.status, CallStatus.calling);
      expect(call.channelId, isNull);
      expect(call.token, isNull);
    });
  });

  group('Theme System', () {
    test('ThemeState copyWith works', () {
      final state = ThemeState(
        mode: ThemeMode.system,
        accentColor: const Color(0xFF2563EB),
      );

      final updated = state.copyWith(mode: ThemeMode.dark);

      expect(updated.mode, ThemeMode.dark);
      expect(updated.accentColor, const Color(0xFF2563EB));
    });
  });

  group('Chat Repository', () {
    test('getConversationId is deterministic', () {
      final repo = ChatRepository();
      final id1 = repo.getConversationId('user-a', 'user-b');
      final id2 = repo.getConversationId('user-b', 'user-a');

      expect(id1, id2);
    });

    test('getConversationId uses conv_ prefix', () {
      final repo = ChatRepository();
      final id = repo.getConversationId('user-1', 'user-2');
      expect(id.startsWith('conv_'), true);
    });
  });
}
