import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show MaterialApp, ThemeData;
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_messenger/core/services/avatar_cache_service.dart';
import 'package:quick_messenger/core/services/media_cache_service.dart';
import 'package:quick_messenger/core/services/user_profile_cache_service.dart';
import 'package:quick_messenger/core/theme/app_colors.dart';
import 'package:quick_messenger/core/theme/app_spacing.dart';
import 'package:quick_messenger/core/widgets/app_filter_chip.dart';
import 'package:quick_messenger/core/widgets/app_screen_header.dart';
import 'package:quick_messenger/core/widgets/app_switch.dart';
import 'package:quick_messenger/core/widgets/user_avatar.dart';
import 'package:quick_messenger/features/chat/models/conversation_model.dart';
import 'package:quick_messenger/features/chat/models/message_model.dart';

void main() {
  group('MediaCacheService', () {
    final cacheService = MediaCacheService.instance;

    test('getCacheKey produces deterministic key for identical URLs', () {
      const url1 =
          'https://drive.google.com/uc?export=download&id=1AbCdEfGhIjKlMnOp';
      const url2 =
          'https://drive.google.com/uc?export=download&id=1AbCdEfGhIjKlMnOp';

      final key1 = cacheService.getCacheKey(url: url1);
      final key2 = cacheService.getCacheKey(url: url2);

      expect(key1, isNotEmpty);
      expect(key1, equals(key2));
    });

    test('getCacheKey extracts Drive ID when present', () {
      const driveUrl = 'https://drive.google.com/file/d/FILE_ID_12345/view';
      final key = cacheService.getCacheKey(url: driveUrl);

      expect(key, contains('FILE_ID_12345'));
    });

    test('getCacheKey uses explicit driveFileId when provided', () {
      const url = 'https://example.com/something';
      final key =
          cacheService.getCacheKey(url: url, driveFileId: 'explicit_drive_id');

      expect(key, equals('drive_explicit_drive_id'));
    });

    test('getCacheKey produces different keys for distinct URLs', () {
      const urlA = 'https://example.com/media/file_a.png';
      const urlB = 'https://example.com/media/file_b.png';

      final keyA = cacheService.getCacheKey(url: urlA);
      final keyB = cacheService.getCacheKey(url: urlB);

      expect(keyA, isNot(equals(keyB)));
    });
  });

  group('AvatarCacheService', () {
    final avatarService = AvatarCacheService.instance;

    test('getCacheKey produces deterministic key scoped to user and url', () {
      const url = 'https://example.com/avatars/user_1.jpg';
      final key1 = avatarService.getCacheKey(userId: 'user123', url: url);
      final key2 = avatarService.getCacheKey(userId: 'user123', url: url);

      expect(key1, equals(key2));
      expect(key1, contains('user123'));
    });

    test('getCacheKey extracts Google Drive ID for avatar link', () {
      const driveUrl = 'https://drive.google.com/file/d/AVATAR_DRIVE_999/view';
      final key = avatarService.getCacheKey(userId: 'user456', url: driveUrl);

      expect(key, contains('AVATAR_DRIVE_999'));
    });

    test('getCacheKey distinguishes different users with same image URL', () {
      const url = 'https://example.com/default_avatar.png';
      final keyAlice = avatarService.getCacheKey(userId: 'alice', url: url);
      final keyBob = avatarService.getCacheKey(userId: 'bob', url: url);

      expect(keyAlice, isNot(equals(keyBob)));
    });
  });

  group('AppAvatarSize & UserAvatar', () {
    test('AppAvatarSize constants adhere to design system specifications', () {
      expect(AppAvatarSize.listTile, 26.0);
      expect(AppAvatarSize.header, 18.0);
      expect(AppAvatarSize.compact, 20.0);
      expect(AppAvatarSize.chip, 22.0);
      expect(AppAvatarSize.settingsHero, 30.0);
      expect(AppAvatarSize.profileHero, 48.0);
      expect(AppAvatarSize.callHero, 55.0);

      // Verify listTile diameter is 52px
      expect(AppAvatarSize.listTile * 2, 52.0);
    });

    test('UserAvatar.formatDirectImageUrl converts Google Drive links', () {
      const driveViewUrl =
          'https://drive.google.com/file/d/test_drive_id_999/view?usp=sharing';
      final formatted = UserAvatar.formatDirectImageUrl(driveViewUrl);

      expect(formatted,
          equals('https://lh3.googleusercontent.com/d/test_drive_id_999'));
    });

    test('UserAvatar.formatDirectImageUrl preserves non-Drive URLs', () {
      const standardUrl = 'https://images.unsplash.com/photo-123456';
      final formatted = UserAvatar.formatDirectImageUrl(standardUrl);

      expect(formatted, equals(standardUrl));
    });
  });

  group('AppFilterChip Widget', () {
    testWidgets('renders label and handles tap event', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: Center(
              child: AppFilterChip(
                label: 'All Chats',
                isSelected: false,
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('All Chats'), findsOneWidget);
      await tester.tap(find.text('All Chats'));
      expect(tapped, isTrue);
    });

    testWidgets('renders count badge when count > 0', (tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: CupertinoPageScaffold(
            child: Center(
              child: AppFilterChip(
                label: 'Unread',
                count: 5,
                isSelected: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Unread'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });
  });

  group('AppSwitch Widget', () {
    testWidgets('renders CupertinoSwitch and triggers onChanged callback',
        (tester) async {
      bool switchVal = false;

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: Center(
              child: StatefulBuilder(
                builder: (context, setState) {
                  return AppSwitch(
                    value: switchVal,
                    onChanged: (val) {
                      setState(() => switchVal = val);
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CupertinoSwitch), findsOneWidget);
      await tester.tap(find.byType(CupertinoSwitch));
      await tester.pumpAndSettle();

      expect(switchVal, isTrue);
    });
  });

  group('AppColors Adaptive Tokens', () {
    test('onPrimary contrasts against textPrimary', () {
      final onDark = AppColors.onPrimary(true);
      final onLight = AppColors.onPrimary(false);

      expect(onDark, isNot(equals(AppColors.textPrimary(true))));
      expect(onLight, isNot(equals(AppColors.textPrimary(false))));
    });

    test('bubbleMeText contrasts against bubbleMe in both dark and light modes',
        () {
      final lightBubbleBg = AppColors.bubbleMe(false);
      final lightBubbleText = AppColors.bubbleMeText(false);
      expect(lightBubbleBg, isNot(equals(lightBubbleText)));

      final darkBubbleBg = AppColors.bubbleMe(true);
      final darkBubbleText = AppColors.bubbleMeText(true);
      expect(darkBubbleBg, isNot(equals(darkBubbleText)));
    });

    test('bubbleOtherText contrasts against bubbleOther in both modes', () {
      final lightOtherBg = AppColors.bubbleOther(false);
      final lightOtherText = AppColors.bubbleOtherText(false);
      expect(lightOtherBg, isNot(equals(lightOtherText)));

      final darkOtherBg = AppColors.bubbleOther(true);
      final darkOtherText = AppColors.bubbleOtherText(true);
      expect(darkOtherBg, isNot(equals(darkOtherText)));
    });

    test('onPrimary returns high-contrast foreground based on surface luminance', () {
      // Default dark accent is white, so onPrimary must be black
      expect(AppColors.onPrimary(true), equals(const Color(0xFF000000)));
      // Default light accent is black, so onPrimary must be white
      expect(AppColors.onPrimary(false), equals(const Color(0xFFFFFFFF)));
      // Explicit light surface -> black foreground
      expect(AppColors.onPrimary(true, const Color(0xFFFFFFFF)), equals(const Color(0xFF000000)));
      // Explicit dark surface -> white foreground
      expect(AppColors.onPrimary(false, const Color(0xFF000000)), equals(const Color(0xFFFFFFFF)));
    });
  });

  group('MessageModel.sortAndDeduplicate & Ordering', () {
    test('sorts out-of-order messages in strict chronological ascending order',
        () {
      final msg1 = MessageModel(
        messageId: 'm1',
        conversationId: 'c1',
        senderId: 'u1',
        receiverId: 'u2',
        text: 'First message',
        clientCreatedAt: '2026-10-15T10:00:00.000Z',
      );
      final msg2 = MessageModel(
        messageId: 'm2',
        conversationId: 'c1',
        senderId: 'u2',
        receiverId: 'u1',
        text: 'Second message',
        clientCreatedAt: '2026-10-15T10:05:00.000Z',
      );
      final msg3 = MessageModel(
        messageId: 'm3',
        conversationId: 'c1',
        senderId: 'u1',
        receiverId: 'u2',
        text: 'Third message',
        clientCreatedAt: '2026-10-15T10:10:00.000Z',
      );

      // Pass in reverse/scrambled order (e.g. from socket sync or stream race)
      final scrambled = [msg3, msg1, msg2];
      final sorted = MessageModel.sortAndDeduplicate(scrambled);

      expect(sorted.length, 3);
      expect(sorted[0].messageId, 'm1');
      expect(sorted[1].messageId, 'm2');
      expect(sorted[2].messageId, 'm3');
    });

    test('deduplicates identical message IDs and preserves advanced status',
        () {
      final pendingMsg = MessageModel(
        messageId: 'msg_dup',
        conversationId: 'c1',
        senderId: 'u1',
        receiverId: 'u2',
        text: 'Hello world',
        status: 'pending',
        clientCreatedAt: '2026-10-15T12:00:00.000Z',
      );
      final readMsg = MessageModel(
        messageId: 'msg_dup',
        conversationId: 'c1',
        senderId: 'u1',
        receiverId: 'u2',
        text: 'Hello world',
        status: 'read',
        clientCreatedAt: '2026-10-15T12:00:00.000Z',
      );

      final merged = MessageModel.sortAndDeduplicate([pendingMsg, readMsg]);

      expect(merged.length, 1);
      expect(merged.first.messageId, 'msg_dup');
      expect(merged.first.status, 'read');
    });

    test('tiebreaks equal timestamps deterministically by messageId', () {
      final msgA = MessageModel(
        messageId: 'msg_aaa',
        conversationId: 'c1',
        senderId: 'u1',
        receiverId: 'u2',
        text: 'Alpha',
        clientCreatedAt: '2026-10-15T12:00:00.000Z',
      );
      final msgB = MessageModel(
        messageId: 'msg_bbb',
        conversationId: 'c1',
        senderId: 'u1',
        receiverId: 'u2',
        text: 'Beta',
        clientCreatedAt: '2026-10-15T12:00:00.000Z',
      );

      final order1 = MessageModel.sortAndDeduplicate([msgB, msgA]);
      final order2 = MessageModel.sortAndDeduplicate([msgA, msgB]);

      expect(order1.map((m) => m.messageId), equals(['msg_aaa', 'msg_bbb']));
      expect(order2.map((m) => m.messageId), equals(['msg_aaa', 'msg_bbb']));
    });

    test('MessageModel.fromDb matches exact SQLite row schema', () {
      final dbRow = {
        'message_id': 'm_db_1',
        'conversation_id': 'conv_u1_u2',
        'sender_id': 'u1',
        'receiver_id': 'u2',
        'type': 'text',
        'text': 'Hello from DB',
        'status': 'delivered',
        'is_deleted_for_me': 0,
        'is_deleted_for_everyone': 0,
        'is_edited': 1,
        'client_created_at': '2026-10-15T08:00:00.000Z',
        'reactions_json': '{"u2":"❤️"}',
      };
      final m = MessageModel.fromDb(dbRow);
      expect(m.messageId, equals('m_db_1'));
      expect(m.conversationId, equals('conv_u1_u2'));
      expect(m.senderId, equals('u1'));
      expect(m.receiverId, equals('u2'));
      expect(m.text, equals('Hello from DB'));
      expect(m.status, equals('delivered'));
      expect(m.isEdited, isTrue);
      expect(m.clientCreatedAt, equals('2026-10-15T08:00:00.000Z'));
      expect(m.reactions['u2'], equals('❤️'));
    });

    test('MessageModel.fromServer matches exact Quick_Messenger_Server schema',
        () {
      final serverPayload = {
        'messageId': 'm_srv_1',
        'conversationId': 'conv_u1_u2',
        'senderId': 'u1',
        'receiverId': 'u2',
        'type': 'text',
        'text': 'Hello from Server',
        'status': 'sent',
        'isDeletedForEveryone': false,
        'isEdited': false,
        'clientCreatedAt': '2026-10-15T08:05:00.000Z',
        'reactions': {'u2': '👍'},
      };
      final m = MessageModel.fromServer(serverPayload);
      expect(m.messageId, equals('m_srv_1'));
      expect(m.conversationId, equals('conv_u1_u2'));
      expect(m.senderId, equals('u1'));
      expect(m.receiverId, equals('u2'));
      expect(m.text, equals('Hello from Server'));
      expect(m.status, equals('sent'));
      expect(m.clientCreatedAt, equals('2026-10-15T08:05:00.000Z'));
      expect(m.reactions['u2'], equals('👍'));
    });

    test('ConversationModel exact fromDb and fromServer matching', () {
      final dbConv = {
        'id': 'conv_1',
        'participant_id': 'p1',
        'participant_name': 'Alice',
        'participant_imageurl': 'https://example.com/pic.png',
        'last_message': 'Hey',
        'last_timestamp': '2026-10-15T09:00:00.000Z',
        'unread_count': 3,
        'is_pinned': 1,
      };
      final cDb = ConversationModel.fromDb(dbConv);
      expect(cDb.id, equals('conv_1'));
      expect(cDb.participantId, equals('p1'));
      expect(cDb.participantName, equals('Alice'));
      expect(cDb.unreadCount, equals(3));
      expect(cDb.isPinned, isTrue);

      final srvConv = {
        'conversationId': 'conv_2',
        'participantId': 'p2',
        'participantName': 'Bob',
        'participantImageUrl': '',
        'lastMessage': 'Yo',
        'lastTimestamp': '2026-10-15T09:10:00.000Z',
        'unreadCount': 0,
        'isPinned': false,
      };
      final cSrv = ConversationModel.fromServer(srvConv);
      expect(cSrv.id, equals('conv_2'));
      expect(cSrv.participantId, equals('p2'));
      expect(cSrv.participantName, equals('Bob'));
      expect(cSrv.unreadCount, equals(0));
      expect(cSrv.isPinned, isFalse);
    });
  });

  group('AppScreenHeader Widget', () {
    testWidgets('renders title and actions on the same horizontal row',
        (tester) async {
      bool actionPressed = false;

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: AppScreenHeader(
              title: 'Chats',
              actions: [
                AppHeaderIconButton(
                  icon: CupertinoIcons.plus,
                  isPrimary: true,
                  onPressed: () => actionPressed = true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Chats'), findsOneWidget);
      expect(find.byType(AppHeaderIconButton), findsOneWidget);

      await tester.tap(find.byType(AppHeaderIconButton));
      expect(actionPressed, isTrue);
    });
  });

  group('UserProfileCacheService & Sync Lookups', () {
    final profileService = UserProfileCacheService.instance;

    setUp(() {
      profileService.clearMemory();
    });

    test('getProfileSync returns null on empty or uncached user ID', () {
      expect(profileService.getProfileSync(''), isNull);
      expect(profileService.getProfileSync('uncached_user_123'), isNull);
    });

    test('setMemoryCache enables instant synchronous 0ms hits', () {
      final sample = {
        'username': 'Alice',
        'display_name': 'Alice Wonder',
        'email': 'alice@example.com',
        'image_url': 'https://example.com/alice.png',
      };
      profileService.setMemoryCache('user_alice_1', sample);

      final hit = profileService.getProfileSync('user_alice_1');
      expect(hit, isNotNull);
      expect(hit!['username'], equals('Alice'));
      expect(hit['email'], equals('alice@example.com'));
    });

    test('invalidate removes specific user from memory cache', () {
      profileService.setMemoryCache('user_bob_2', {'username': 'Bob'});
      expect(profileService.getProfileSync('user_bob_2'), isNotNull);

      profileService.invalidate('user_bob_2');
      expect(profileService.getProfileSync('user_bob_2'), isNull);
    });

    test('clearMemory purges all cached profiles', () {
      profileService.setMemoryCache('u1', {'username': 'U1'});
      profileService.setMemoryCache('u2', {'username': 'U2'});

      expect(profileService.getProfileSync('u1'), isNotNull);
      expect(profileService.getProfileSync('u2'), isNotNull);

      profileService.clearMemory();
      expect(profileService.getProfileSync('u1'), isNull);
      expect(profileService.getProfileSync('u2'), isNull);
    });
  });

  group('MediaCacheService Synchronous Cache Hits', () {
    final cacheService = MediaCacheService.instance;

    test(
        'getCachedPathSync returns null when file is uncached or does not exist on disk',
        () {
      const url = 'https://example.com/unseen_image.png';
      expect(cacheService.getCachedPathSync(url: url), isNull);
    });
  });

  group('Theme Brightness & Contrast Verification', () {
    testWidgets('AppColors.isDarkMode resolves correctly with CupertinoTheme',
        (tester) async {
      bool? darkResult;
      bool? lightResult;

      await tester.pumpWidget(
        CupertinoApp(
          theme: const CupertinoThemeData(brightness: Brightness.dark),
          home: Builder(
            builder: (context) {
              darkResult = AppColors.isDarkMode(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(darkResult, isTrue);

      await tester.pumpWidget(
        CupertinoApp(
          theme: const CupertinoThemeData(brightness: Brightness.light),
          home: Builder(
            builder: (context) {
              lightResult = AppColors.isDarkMode(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(lightResult, isFalse);
    });

    testWidgets('AppColors.isDarkMode resolves correctly with Material Theme',
        (tester) async {
      bool? darkResult;
      bool? lightResult;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Builder(
            builder: (context) {
              darkResult = AppColors.isDarkMode(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(darkResult, isTrue);

      await tester.pumpWidget(
        MaterialApp(
          key: const ValueKey('light_app'),
          theme: ThemeData.light(),
          home: Builder(
            builder: (context) {
              lightResult = AppColors.isDarkMode(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(lightResult, isFalse);
    });

    test(
        'Dark mode tokens provide strong luminance contrast against black background',
        () {
      final darkText = AppColors.textPrimary(true);
      final darkBg = AppColors.background(true);

      // Verify dark background is OLED black
      expect(darkBg, equals(const Color(0xFF000000)));

      // Primary text in dark mode must have luminance > 0.70 (light color on black)
      expect(darkText.computeLuminance(), greaterThan(0.70));

      // Light mode primary text on white background must have luminance < 0.05 (dark color on white)
      final lightText = AppColors.textPrimary(false);
      expect(lightText.computeLuminance(), lessThan(0.05));
    });

    test('Semantic accents adapt to active brightness', () {
      expect(AppColors.accent(true), equals(const Color(0xFFFFFFFF)));
      expect(AppColors.accent(false), equals(const Color(0xFF000000)));
    });
  });

  group('AppBar Trailing Action & AppHeaderIconButton Theme Contrast', () {
    testWidgets(
        'AppHeaderIconButton primary button maintains high contrast in Dark OLED mode',
        (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          theme: const CupertinoThemeData(
            brightness: Brightness.dark,
            primaryColor: Color(0xFFFFFFFF), // Dark OLED white accent
          ),
          home: CupertinoPageScaffold(
            child: Center(
              child: AppHeaderIconButton(
                icon: CupertinoIcons.plus,
                isPrimary: true,
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      final iconFinder = find.byType(Icon);
      expect(iconFinder, findsOneWidget);
      final icon = tester.widget<Icon>(iconFinder);

      // Icon MUST NOT be white on white
      expect(icon.color, isNot(equals(const Color(0xFFFFFFFF))));
      // Icon color must have low luminance (dark/black) on the white circular background
      expect(icon.color?.computeLuminance(), lessThan(0.2));
    });

    testWidgets(
        'AppHeaderIconButton primary button maintains high contrast in Light mode',
        (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          theme: const CupertinoThemeData(
            brightness: Brightness.light,
            primaryColor: Color(0xFF000000), // Light mode black accent
          ),
          home: CupertinoPageScaffold(
            child: Center(
              child: AppHeaderIconButton(
                icon: CupertinoIcons.plus,
                isPrimary: true,
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      final iconFinder = find.byType(Icon);
      expect(iconFinder, findsOneWidget);
      final icon = tester.widget<Icon>(iconFinder);

      // Icon MUST NOT be black on black
      expect(icon.color, isNot(equals(const Color(0xFF000000))));
      // Icon color must have high luminance (white) on the black circular background
      expect(icon.color?.computeLuminance(), greaterThan(0.8));
    });
  });

  group('AppSpacing & ListTile Design System', () {
    test('Standardized ListTile tokens adhere to metrics specification', () {
      expect(AppSpacing.listTilePadding,
          equals(const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0)));
      expect(AppSpacing.listTileLeadingSize, equals(52.0));
      expect(AppSpacing.listTileLeadingToTitle, equals(12.0));
      // Leading size of 52 perfectly matches AppAvatarSize.listTile * 2
      expect(AppSpacing.listTileLeadingSize, equals(AppAvatarSize.listTile * 2));
    });
  });

  group('Deleted Message Theme & Readability', () {
    test(
        'Deleted message text color provides clear readability in both light and dark modes',
        () {
      final darkMuted = AppColors.textMuted(true);
      final lightMuted = AppColors.textMuted(false);

      // Must be readable against deleted bubble backgrounds
      expect(darkMuted, equals(AppColors.darkTextMuted));
      expect(lightMuted, equals(AppColors.lightTextMuted));

      // Light mode muted text must never be pure white
      expect(lightMuted, isNot(equals(const Color(0xFFFFFFFF))));

      // Dark mode muted text must never be pure black
      expect(darkMuted, isNot(equals(const Color(0xFF000000))));
    });
  });

  group('AppSwitch Theme Contrast & Behavior', () {
    testWidgets('AppSwitch renders properly with active contrast thumb in Dark OLED mode',
        (tester) async {
      bool switchVal = true;
      await tester.pumpWidget(
        CupertinoApp(
          theme: const CupertinoThemeData(brightness: Brightness.dark),
          home: CupertinoPageScaffold(
            child: Center(
              child: AppSwitch(
                value: switchVal,
                activeColor: const Color(0xFFFFFFFF),
                onChanged: (v) => switchVal = v,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(AppSwitch), findsOneWidget);
      expect(find.byType(CupertinoSwitch), findsOneWidget);
    });
  });
}
