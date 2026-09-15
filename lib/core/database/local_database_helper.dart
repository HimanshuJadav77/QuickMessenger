import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabaseHelper {
  static final LocalDatabaseHelper instance = LocalDatabaseHelper._internal();
  static Database? _database;

  LocalDatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'quick_messenger.db');

    return await openDatabase(
      path,
      version: 7,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE conversations(
        id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        participant_id TEXT NOT NULL,
        participant_name TEXT,
        participant_imageurl TEXT,
        last_message TEXT,
        last_timestamp TEXT,
        unread_count INTEGER DEFAULT 0,
        is_pinned INTEGER DEFAULT 0,
        is_archived INTEGER DEFAULT 0,
        is_muted INTEGER DEFAULT 0,
        PRIMARY KEY (id, user_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE messages(
        message_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        conversation_id TEXT NOT NULL,
        sender_id TEXT NOT NULL,
        receiver_id TEXT NOT NULL,
        type TEXT DEFAULT 'text',
        text TEXT NOT NULL,
        status TEXT DEFAULT 'pending',
        is_deleted_for_me INTEGER DEFAULT 0,
        is_deleted_for_everyone INTEGER DEFAULT 0,
        is_edited INTEGER DEFAULT 0,
        reply_to_message_id TEXT,
        reply_to_text TEXT,
        reply_to_sender_id TEXT,
        reactions_json TEXT,
        client_created_at TEXT NOT NULL,
        server_created_at TEXT,
        PRIMARY KEY (message_id, user_id)
      )
    ''');

    await _createGroupTables(db);

    await db.execute('''
      CREATE TABLE user_profiles(
        uid TEXT NOT NULL,
        user_id TEXT NOT NULL,
        username TEXT,
        display_name TEXT,
        about TEXT,
        email TEXT,
        image_url TEXT,
        last_updated TEXT NOT NULL,
        PRIMARY KEY (uid, user_id)
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_messages_user_conv ON messages(user_id, conversation_id)',
    );
    await db.execute(
      'CREATE INDEX idx_messages_created_at ON messages(client_created_at)',
    );
  }

  Future<void> _createGroupTables(Database db) async {
    await db.execute('''
      CREATE TABLE groups(
        group_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        image_url TEXT,
        created_by TEXT NOT NULL,
        created_at TEXT NOT NULL,
        my_role TEXT DEFAULT 'member',
        member_count INTEGER DEFAULT 1,
        PRIMARY KEY (group_id, user_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE group_members(
        group_id TEXT NOT NULL,
        uid TEXT NOT NULL,
        username TEXT NOT NULL,
        display_name TEXT,
        image_url TEXT,
        role TEXT DEFAULT 'member',
        joined_at TEXT NOT NULL,
        PRIMARY KEY (group_id, uid)
      )
    ''');

    await db.execute('''
      CREATE TABLE group_messages(
        message_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        group_id TEXT NOT NULL,
        sender_id TEXT NOT NULL,
        sender_name TEXT,
        type TEXT DEFAULT 'text',
        text TEXT NOT NULL,
        status TEXT DEFAULT 'sent',
        reactions_json TEXT,
        client_created_at TEXT NOT NULL,
        PRIMARY KEY (message_id, user_id)
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_group_messages_user_group ON group_messages(user_id, group_id)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS conversations');
      await db.execute('DROP TABLE IF EXISTS messages');
      await _onCreate(db, newVersion);
      return;
    }

    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE messages ADD COLUMN is_deleted_for_me INTEGER DEFAULT 0');
        await db.execute('ALTER TABLE messages ADD COLUMN is_deleted_for_everyone INTEGER DEFAULT 0');
      } catch (_) {}
    }

    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE messages ADD COLUMN is_edited INTEGER DEFAULT 0');
        await db.execute('ALTER TABLE messages ADD COLUMN reply_to_message_id TEXT');
        await db.execute('ALTER TABLE messages ADD COLUMN reply_to_text TEXT');
        await db.execute('ALTER TABLE messages ADD COLUMN reply_to_sender_id TEXT');
        await db.execute('ALTER TABLE messages ADD COLUMN reactions_json TEXT');
      } catch (_) {}
    }

    if (oldVersion < 6) {
      try {
        await _createGroupTables(db);
      } catch (_) {}
    }

    if (oldVersion < 7) {
      try {
        await db.execute('''
          CREATE TABLE user_profiles(
            uid TEXT NOT NULL,
            user_id TEXT NOT NULL,
            username TEXT,
            display_name TEXT,
            about TEXT,
            email TEXT,
            image_url TEXT,
            last_updated TEXT NOT NULL,
            PRIMARY KEY (uid, user_id)
          )
        ''');
      } catch (_) {}
    }
  }

  Future<void> upsertGroup(String currentUserId, Map<String, dynamic> groupData) async {
    if (currentUserId.isEmpty) return;
    final db = await database;
    await db.insert(
      'groups',
      {
        'group_id': groupData['group_id'] ?? groupData['groupId'],
        'user_id': currentUserId,
        'name': groupData['name'] ?? 'Group',
        'description': groupData['description'] ?? '',
        'image_url': groupData['image_url'] ?? groupData['imageUrl'] ?? '',
        'created_by': groupData['created_by'] ?? groupData['createdBy'] ?? currentUserId,
        'created_at': groupData['created_at'] ?? groupData['createdAt'] ?? DateTime.now().toIso8601String(),
        'my_role': groupData['my_role'] ?? groupData['myRole'] ?? 'member',
        'member_count': groupData['member_count'] ?? groupData['memberCount'] ?? 1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getGroups(String currentUserId) async {
    if (currentUserId.isEmpty) return [];
    final db = await database;
    return await db.rawQuery('''
      SELECT g.*,
             (SELECT text FROM group_messages gm WHERE gm.group_id = g.group_id AND gm.user_id = g.user_id ORDER BY gm.client_created_at DESC LIMIT 1) as last_message,
             (SELECT client_created_at FROM group_messages gm WHERE gm.group_id = g.group_id AND gm.user_id = g.user_id ORDER BY gm.client_created_at DESC LIMIT 1) as last_timestamp
      FROM groups g
      WHERE g.user_id = ?
      ORDER BY COALESCE(last_timestamp, g.created_at) DESC
    ''', [currentUserId]);
  }

  Future<Map<String, dynamic>?> getLatestGroupMessage(String currentUserId, String groupId) async {
    if (currentUserId.isEmpty || groupId.isEmpty) return null;
    final db = await database;
    final res = await db.query(
      'group_messages',
      where: 'group_id = ? AND user_id = ?',
      whereArgs: [groupId, currentUserId],
      orderBy: 'client_created_at DESC',
      limit: 1,
    );
    if (res.isNotEmpty) return res.first;
    return null;
  }

  Future<void> insertGroupMembers(String groupId, List<Map<String, dynamic>> members) async {
    if (groupId.isEmpty || members.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final member in members) {
      batch.insert(
        'group_members',
        {
          'group_id': groupId,
          'uid': member['uid'],
          'username': member['username'] ?? 'User',
          'display_name': member['display_name'] ?? member['displayName'] ?? member['username'] ?? 'User',
          'image_url': member['image_url'] ?? member['imageUrl'] ?? '',
          'role': member['role'] ?? 'member',
          'joined_at': member['joined_at'] ?? member['joinedAt'] ?? DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getGroupMembers(String groupId) async {
    if (groupId.isEmpty) return [];
    final db = await database;
    return await db.query(
      'group_members',
      where: 'group_id = ?',
      whereArgs: [groupId],
      orderBy: 'joined_at ASC',
    );
  }

  Future<void> deleteGroup(String currentUserId, String groupId) async {
    if (currentUserId.isEmpty || groupId.isEmpty) return;
    final db = await database;
    await db.delete('groups', where: 'group_id = ? AND user_id = ?', whereArgs: [groupId, currentUserId]);
    await db.delete('group_members', where: 'group_id = ?', whereArgs: [groupId]);
    await db.delete('group_messages', where: 'group_id = ? AND user_id = ?', whereArgs: [groupId, currentUserId]);
  }

  Future<void> insertGroupMessage(String currentUserId, Map<String, dynamic> msgData) async {
    if (currentUserId.isEmpty) return;
    final db = await database;
    await db.insert(
      'group_messages',
      {
        'message_id': msgData['message_id'] ?? msgData['messageId'],
        'user_id': currentUserId,
        'group_id': msgData['group_id'] ?? msgData['groupId'],
        'sender_id': msgData['sender_id'] ?? msgData['senderId'],
        'sender_name': msgData['sender_name'] ?? msgData['senderName'] ?? 'Member',
        'type': msgData['type'] ?? 'text',
        'text': msgData['text'] ?? '',
        'status': msgData['status'] ?? 'sent',
        'reactions_json': msgData['reactions_json'],
        'client_created_at': msgData['client_created_at'] ?? msgData['clientCreatedAt'] ?? DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getGroupMessages(String currentUserId, String groupId, {int limit = 50, int offset = 0}) async {
    if (currentUserId.isEmpty) return [];
    final db = await database;
    return await db.query(
      'group_messages',
      where: 'group_id = ? AND user_id = ?',
      whereArgs: [groupId, currentUserId],
      orderBy: 'client_created_at ASC',
      limit: limit,
      offset: offset,
    );
  }

  Future<void> upsertConversation({
    required String currentUserId,
    required String conversationId,
    required String participantId,
    String? participantName,
    String? participantImageUrl,
    required String lastMessage,
    required String lastTimestamp,
    int? unreadCount,
    int? unreadIncrement,
  }) async {
    if (currentUserId.isEmpty) return;
    final db = await database;

    final existing = await db.query(
      'conversations',
      where: 'id = ? AND user_id = ?',
      whereArgs: [conversationId, currentUserId],
    );

    if (existing.isNotEmpty) {
      final currentUnread = (existing.first['unread_count'] as int?) ?? 0;
      int newUnread;
      if (unreadCount != null) {
        newUnread = unreadCount;
      } else if (unreadIncrement != null) {
        newUnread = currentUnread + unreadIncrement;
      } else {
        newUnread = currentUnread;
      }

      final Map<String, dynamic> updateValues = {
        'last_message': lastMessage,
        'last_timestamp': lastTimestamp,
        'unread_count': newUnread,
      };

      if (participantName != null && participantName.isNotEmpty && participantName != 'User') {
        updateValues['participant_name'] = participantName;
      }
      if (participantImageUrl != null && participantImageUrl.isNotEmpty) {
        updateValues['participant_imageurl'] = participantImageUrl;
      }

      await db.update(
        'conversations',
        updateValues,
        where: 'id = ? AND user_id = ?',
        whereArgs: [conversationId, currentUserId],
      );
    } else {
      final initialUnread = unreadCount ?? (unreadIncrement ?? 0);
      await db.insert(
        'conversations',
        {
          'id': conversationId,
          'user_id': currentUserId,
          'participant_id': participantId,
          'participant_name': (participantName != null && participantName.isNotEmpty) ? participantName : 'User',
          'participant_imageurl': participantImageUrl ?? '',
          'last_message': lastMessage,
          'last_timestamp': lastTimestamp,
          'unread_count': initialUnread,
          'is_pinned': 0,
          'is_archived': 0,
          'is_muted': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<Map<String, dynamic>?> getConversation(String currentUserId, String conversationId) async {
    if (currentUserId.isEmpty || conversationId.isEmpty) return null;
    final db = await database;
    final cleanId = conversationId.startsWith('conv_') ? conversationId : 'conv_$conversationId';
    final rawId = conversationId.replaceFirst('conv_', '');
    final res = await db.query(
      'conversations',
      where: '(id = ? OR id = ?) AND user_id = ?',
      whereArgs: [cleanId, rawId, currentUserId],
      limit: 1,
    );
    if (res.isNotEmpty) return res.first;
    return null;
  }

  Future<List<Map<String, dynamic>>> getConversations(String currentUserId) async {
    if (currentUserId.isEmpty) return [];
    final db = await database;
    return await db.query(
      'conversations',
      where: 'user_id = ? AND last_message IS NOT NULL AND TRIM(last_message) != "" AND last_message != "Tap to chat"',
      whereArgs: [currentUserId],
      orderBy: 'is_pinned DESC, last_timestamp DESC',
    );
  }

  Future<void> togglePinConversation(String currentUserId, String conversationId, bool isPinned) async {
    if (currentUserId.isEmpty) return;
    final db = await database;
    await db.update(
      'conversations',
      {'is_pinned': isPinned ? 1 : 0},
      where: 'id = ? AND user_id = ?',
      whereArgs: [conversationId, currentUserId],
    );
  }

  Future<void> toggleArchiveConversation(String currentUserId, String conversationId, bool isArchived) async {
    if (currentUserId.isEmpty) return;
    final db = await database;
    await db.update(
      'conversations',
      {'is_archived': isArchived ? 1 : 0},
      where: 'id = ? AND user_id = ?',
      whereArgs: [conversationId, currentUserId],
    );
  }

  Future<void> toggleMuteConversation(String currentUserId, String conversationId, bool isMuted) async {
    if (currentUserId.isEmpty) return;
    final db = await database;
    await db.update(
      'conversations',
      {'is_muted': isMuted ? 1 : 0},
      where: 'id = ? AND user_id = ?',
      whereArgs: [conversationId, currentUserId],
    );
  }

  Future<void> markUnreadConversation(String currentUserId, String conversationId) async {
    if (currentUserId.isEmpty) return;
    final db = await database;
    await db.update(
      'conversations',
      {'unread_count': 1},
      where: 'id = ? AND user_id = ?',
      whereArgs: [conversationId, currentUserId],
    );
  }

  Future<void> resetUnreadCount(String currentUserId, String conversationId) async {
    if (currentUserId.isEmpty) return;
    final db = await database;
    final cleanId = conversationId.startsWith('conv_') ? conversationId : 'conv_$conversationId';
    final rawId = conversationId.replaceFirst('conv_', '');
    await db.update(
      'conversations',
      {'unread_count': 0},
      where: '(id = ? OR id = ?) AND user_id = ?',
      whereArgs: [cleanId, rawId, currentUserId],
    );
  }


  Future<void> deleteConversation(String currentUserId, String conversationId) async {
    if (currentUserId.isEmpty) return;
    final db = await database;
    await db.delete(
      'conversations',
      where: 'id = ? AND user_id = ?',
      whereArgs: [conversationId, currentUserId],
    );
    await db.delete(
      'messages',
      where: 'conversation_id = ? AND user_id = ?',
      whereArgs: [conversationId, currentUserId],
    );
  }

  Future<void> clearConversation(String currentUserId, String conversationId) async {
    if (currentUserId.isEmpty || conversationId.isEmpty) return;
    final db = await database;
    await db.delete(
      'messages',
      where: 'conversation_id = ? AND user_id = ?',
      whereArgs: [conversationId, currentUserId],
    );
    await db.update(
      'conversations',
      {
        'last_message': '',
        'unread_count': 0,
      },
      where: 'id = ? AND user_id = ?',
      whereArgs: [conversationId, currentUserId],
    );
  }

  Future<void> insertMessage(String currentUserId, Map<String, dynamic> messageData) async {
    if (currentUserId.isEmpty) return;
    final db = await database;
    await db.insert(
      'messages',
      {
        'message_id': messageData['message_id'] ?? messageData['messageId'],
        'user_id': currentUserId,
        'conversation_id': messageData['conversation_id'] ?? messageData['conversationId'],
        'sender_id': messageData['sender_id'] ?? messageData['senderId'],
        'receiver_id': messageData['receiver_id'] ?? messageData['receiverId'],
        'type': messageData['type'] ?? 'text',
        'text': messageData['text'] ?? '',
        'status': messageData['status'] ?? 'pending',
        'is_deleted_for_me': (messageData['is_deleted_for_me'] == 1 || messageData['is_deleted_for_me'] == true) ? 1 : 0,
        'is_deleted_for_everyone': (messageData['is_deleted_for_everyone'] == 1 || messageData['is_deleted_for_everyone'] == true) ? 1 : 0,
        'is_edited': (messageData['is_edited'] == 1 || messageData['is_edited'] == true) ? 1 : 0,
        'reply_to_message_id': messageData['reply_to_message_id'] ?? messageData['replyToMessageId'],
        'reply_to_text': messageData['reply_to_text'] ?? messageData['replyToText'],
        'reply_to_sender_id': messageData['reply_to_sender_id'] ?? messageData['replyToSenderId'],
        'reactions_json': messageData['reactions_json'],
        'client_created_at': messageData['client_created_at'] ?? messageData['clientCreatedAt'],
        'server_created_at': messageData['server_created_at'] ?? messageData['serverCreatedAt'],
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getMessagesForConversation(
    String currentUserId,
    String conversationId, {
    int limit = 50,
    int offset = 0,
  }) async {
    if (currentUserId.isEmpty) return [];
    final db = await database;
    final cleanId = conversationId.startsWith('conv_') ? conversationId : 'conv_$conversationId';
    final rawId = conversationId.replaceFirst('conv_', '');
    return await db.query(
      'messages',
      where: '(conversation_id = ? OR conversation_id = ?) AND user_id = ? AND (is_deleted_for_me IS NULL OR is_deleted_for_me = 0)',
      whereArgs: [cleanId, rawId, currentUserId],
      orderBy: 'client_created_at ASC',
      limit: limit,
      offset: offset,
    );
  }

  Future<List<Map<String, dynamic>>> getPendingMessages(String currentUserId) async {
    if (currentUserId.isEmpty) return [];
    final db = await database;
    return await db.query(
      'messages',
      where: 'status = ? AND user_id = ?',
      whereArgs: ['pending', currentUserId],
      orderBy: 'client_created_at ASC',
    );
  }

  Future<void> updateMessageStatus(String currentUserId, String messageId, String status) async {
    if (currentUserId.isEmpty) return;
    final db = await database;
    await db.update(
      'messages',
      {'status': status},
      where: 'message_id = ? AND user_id = ?',
      whereArgs: [messageId, currentUserId],
    );
  }

  Future<void> updateAllMessagesStatusForConversation(String currentUserId, String conversationId, String status) async {
    if (currentUserId.isEmpty) return;
    final db = await database;
    final cleanId = conversationId.startsWith('conv_') ? conversationId : 'conv_$conversationId';
    final rawId = conversationId.replaceFirst('conv_', '');

    if (status == 'read' || status == 'seen') {
      await db.update(
        'messages',
        {'status': status},
        where: '(conversation_id = ? OR conversation_id = ?) AND user_id = ? AND status IN (?, ?)',
        whereArgs: [cleanId, rawId, currentUserId, 'sent', 'delivered'],
      );
    } else {
      await db.update(
        'messages',
        {'status': status},
        where: '(conversation_id = ? OR conversation_id = ?) AND user_id = ?',
        whereArgs: [cleanId, rawId, currentUserId],
      );
    }
  }


  Future<void> updateEditedMessage(String currentUserId, String messageId, String newText) async {
    if (currentUserId.isEmpty) return;
    final db = await database;
    await db.update(
      'messages',
      {
        'text': newText,
        'is_edited': 1,
      },
      where: 'message_id = ? AND user_id = ?',
      whereArgs: [messageId, currentUserId],
    );
  }

  Future<void> updateMessageReactions(String currentUserId, String messageId, String reactionsJson) async {
    if (currentUserId.isEmpty) return;
    final db = await database;
    await db.update(
      'messages',
      {'reactions_json': reactionsJson},
      where: 'message_id = ? AND user_id = ?',
      whereArgs: [messageId, currentUserId],
    );
  }

  Future<void> markMessageDeletedForMe(String currentUserId, String messageId) async {
    if (currentUserId.isEmpty) return;
    final db = await database;
    await db.update(
      'messages',
      {'is_deleted_for_me': 1},
      where: 'message_id = ? AND user_id = ?',
      whereArgs: [messageId, currentUserId],
    );
  }

  Future<void> markMessageDeletedForEveryone(String currentUserId, String messageId) async {
    if (currentUserId.isEmpty) return;
    final db = await database;
    await db.update(
      'messages',
      {
        'is_deleted_for_everyone': 1,
        'text': 'This message was deleted',
      },
      where: 'message_id = ? AND user_id = ?',
      whereArgs: [messageId, currentUserId],
    );
  }

  Future<List<Map<String, dynamic>>> searchAllMessages(String currentUserId, String query) async {
    if (currentUserId.isEmpty || query.trim().isEmpty) return [];
    final db = await database;
    final searchTerm = '%${query.trim()}%';

    final List<Map<String, dynamic>> results = [];

    final messages = await db.rawQuery('''
      SELECT 
        m.message_id, m.text, m.client_created_at, m.type, m.sender_id,
        c.participant_name as chat_name, c.id as chat_id, 'direct' as chat_type, c.participant_imageurl as chat_image, c.participant_id as participant_id
      FROM messages m
      JOIN conversations c ON m.conversation_id = c.id AND m.user_id = c.user_id
      WHERE m.user_id = ? 
        AND m.text LIKE ?
        AND (m.is_deleted_for_me IS NULL OR m.is_deleted_for_me = 0)
        AND (m.is_deleted_for_everyone IS NULL OR m.is_deleted_for_everyone = 0)
      ORDER BY m.client_created_at DESC
      LIMIT 50
    ''', [currentUserId, searchTerm]);
    
    final groupMessages = await db.rawQuery('''
      SELECT 
        gm.message_id, gm.text, gm.client_created_at, gm.type, gm.sender_id,
        g.name as chat_name, g.group_id as chat_id, 'group' as chat_type, g.image_url as chat_image
      FROM group_messages gm
      JOIN groups g ON gm.group_id = g.group_id AND gm.user_id = g.user_id
      WHERE gm.user_id = ? 
        AND gm.text LIKE ?
      ORDER BY gm.client_created_at DESC
      LIMIT 50
    ''', [currentUserId, searchTerm]);

    results.addAll(messages);
    results.addAll(groupMessages);

    results.sort((a, b) {
      final dateA = DateTime.tryParse(a['client_created_at'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dateB = DateTime.tryParse(b['client_created_at'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      return dateB.compareTo(dateA);
    });

    return results;
  }

  // ── User Profiles Cache ──────────────────────────────────────────
  Future<void> upsertUserProfile(String currentUserId, String uid, Map<String, dynamic> profileData) async {
    if (currentUserId.isEmpty || uid.isEmpty) return;
    final db = await database;
    await db.insert(
      'user_profiles',
      {
        'uid': uid,
        'user_id': currentUserId,
        'username': profileData['username'] ?? '',
        'display_name': profileData['display_name'] ?? profileData['displayName'] ?? '',
        'about': profileData['about'] ?? '',
        'email': profileData['email'] ?? '',
        'image_url': profileData['image_url'] ?? profileData['imageUrl'] ?? '',
        'last_updated': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getUserProfile(String currentUserId, String uid) async {
    if (currentUserId.isEmpty || uid.isEmpty) return null;
    final db = await database;
    final results = await db.query(
      'user_profiles',
      where: 'uid = ? AND user_id = ?',
      whereArgs: [uid, currentUserId],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return results.first;
  }

  Future<void> updateUserProfileLocally(String currentUserId, String uid, Map<String, dynamic> updates) async {
    if (currentUserId.isEmpty || uid.isEmpty) return;
    final db = await database;
    updates['last_updated'] = DateTime.now().toIso8601String();
    await db.update(
      'user_profiles',
      updates,
      where: 'uid = ? AND user_id = ?',
      whereArgs: [uid, currentUserId],
    );
  }
}

